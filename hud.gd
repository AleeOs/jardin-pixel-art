extends CanvasLayer

signal estado_inventario_cambiado(abierto: bool)
signal semilla_equipada(tipo_semilla: String)
signal monedas_cambiadas(nueva_cantidad: int)

@onready var hotbar_container = $InventarioUI/HotbarContainer
@onready var ventana_inventario: Control = $InventarioUI/VentanaInventario
@onready var boton_inventario: TextureButton = $InventarioUI/BotonInventario
@onready var grid_semillas: GridContainer = $InventarioUI/VentanaInventario/GridSemillas
@onready var slot_plantilla: Control = $InventarioUI/VentanaInventario/GridSemillas/SlotPlantilla
@onready var titulo_inventario: Label = $InventarioUI/VentanaInventario.find_child("TituloInventario", true, false)

@onready var boton_anterior: TextureButton = $InventarioUI/VentanaInventario/BotonAnterior
@onready var boton_siguiente: TextureButton = $InventarioUI/VentanaInventario/BotonSiguiente

# --- NODOS DE ECONOMÍA Y TIENDA ---
@onready var label_monedas: Label = $InventarioUI.find_child("LabelMonedas", true, false)
@onready var boton_pausa: BaseButton = $InventarioUI.find_child("BotonPausa", true, false)
@onready var ventana_pausa: Control = $InventarioUI.find_child("VentanaPausa", true, false)
@onready var panel_slots_pausa: Control = $InventarioUI.find_child("PanelSlotsPausa", true, false)

@onready var boton_tienda: TextureButton = $InventarioUI/BotonTienda
@onready var ventana_tienda: Control = $InventarioUI/VentanaTienda
@onready var grid_tienda: GridContainer = $InventarioUI/VentanaTienda/GridTienda
@onready var slot_tienda_plantilla: Control = $InventarioUI/VentanaTienda/GridTienda/SlotPlantilla
# --- DIALOGO NPC Y PEDIDOS ---
@onready var ventana_dialogo_npc: Control = $InventarioUI/VentanaDialogoNPC
@onready var texto_dialogo_npc: Label = $InventarioUI/VentanaDialogoNPC/TextoDialogo
@onready var boton_aceptar_npc: BaseButton = $InventarioUI/VentanaDialogoNPC/BotonAceptar
@onready var boton_rechazar_npc: BaseButton = $InventarioUI/VentanaDialogoNPC/BotonRechazar

# --- PANEL DE PEDIDOS ACTIVOS ---
@onready var boton_pedidos: BaseButton = $InventarioUI/BotonPedidos
@onready var ventana_pedidos: Control = $InventarioUI/VentanaPedidos
@onready var lista_pedidos: VBoxContainer = $InventarioUI/VentanaPedidos/ListaPedidos
@onready var fila_pedido_plantilla: Control = $InventarioUI/VentanaPedidos/ListaPedidos/FilaPedidoPlantilla

var pedidos_abierto: bool = false
var pausa_abierta: bool = false
signal pausa_cambiada(abierta: bool)
signal antes_de_guardar

const MAX_SLOTS: int = 3
const RUTA_CONFIG_SLOTS: String = "user://ultimo_slot.json"
var slot_activo: int = 0

const NOMBRES_COSECHAS: Dictionary = {
	"trigo_cosechado": "Trigo",
	"remolacha_cosechada": "Remolacha",
	"arbol_cosechado": "Árbol"
}
var pedidos_activos: Array[Dictionary] = []
var dialogo_npc_abierto: bool = false
var _callback_aceptar_actual: Callable
var _callback_rechazar_actual: Callable

var eco_monedas: int = 100
var tienda_abierta: bool = false

# Guardarán las coordenadas exactas de la tierra y las plantas
var tierra_guardada: Dictionary = {}
var plantas_guardadas: Dictionary = {}
var exhibicion_guardada: Dictionary = {}

var inventario_abierto: bool = false
var hotbar_items: Array[String] = ["", "", "", "", ""]
var slot_seleccionado: int = 0
var pagina_actual: int = 0 

var inventario_datos: Dictionary = {
	"trigo": 10,
	"trigo_cosechado": 5,
	"remolacha": 5,
	"remolacha_cosechada": 2,
	"arbol": 3,
	"arbol_cosechado": 1
}

var lista_semillas: Array[String] = ["trigo", "remolacha", "arbol"]
var lista_cosechas: Array[String] = ["trigo_cosechado", "remolacha_cosechada", "arbol_cosechado"]

# --- CATÁLOGO MAESTRO DE CULTIVOS ---
const CATALOGO_PLANTAS: Dictionary = {
	"trigo": {
		"cosecha": "trigo_cosechado",
		"tiempo": 5.0,
		"source_id": 1,
		"etapas": { 1: Vector2i(1, 0), 2: Vector2i(2, 0), 3: Vector2i(4, 0) },
		"precio_compra": 10,
		"precio_venta": 25
	},
	"remolacha": {
		"cosecha": "remolacha_cosechada",
		"tiempo": 7.0,
		"source_id": 1,
		"etapas": { 1: Vector2i(1, 1), 2: Vector2i(2, 1), 3: Vector2i(4, 1) },
		"precio_compra": 20,
		"precio_venta": 50
	},
	"arbol": {
		"cosecha": "arbol_cosechado",
		"tiempo": 10.0,
		"source_id": 2,
		"etapas": { 1: Vector2i(5, 1), 2: Vector2i(0, 0), 3: Vector2i(1, 0) },
		"precio_compra": 40,
		"precio_venta": 110
	}
}

# --- BASE DE DATOS VISUAL ---
var textura_plantas = preload("res://Sprout Lands - Sprites - Basic pack/Sprout Lands - Sprites - Basic pack/Objects/Basic Plants.png")
var textura_naturaleza = preload("res://Sprout Lands - Sprites - Basic pack/Sprout Lands - Sprites - Basic pack/Objects/Basic Grass Biom things 1.png")

@onready var iconos_items: Dictionary = {
	"trigo": crear_icono(textura_plantas, 0, 0, 16, 16),
	"trigo_cosechado": crear_icono(textura_plantas, 80, 0, 16, 16),
	"remolacha": crear_icono(textura_plantas, 0, 16, 16, 16),
	"remolacha_cosechada": crear_icono(textura_plantas, 80, 16, 16, 16),
	"arbol": crear_icono(textura_naturaleza, 80, 16, 16, 16),       # Paquete: Brote (5, 1)
	"arbol_cosechado": crear_icono(textura_naturaleza, 0, 0, 16, 32) # Drop e Inventario: Árbol delgado (0, 0)
}

@onready var texturas_exhibicion: Dictionary = {
	"trigo_cosechado": crear_icono(textura_plantas, 64, 0, 16, 16),
	"remolacha_cosechada": crear_icono(textura_plantas, 64, 16, 16, 16),
	"arbol_cosechado": crear_icono(textura_naturaleza, 16, 0, 32, 32) # Exhibición: Árbol grande (1, 0)
}

func crear_icono(textura_base: Texture2D, x: int, y: int, ancho: int, alto: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = textura_base
	atlas.region = Rect2(x, y, ancho, alto)
	return atlas
# ----------------------------------

func _ready() -> void:
	estado_inventario_cambiado.connect(atenuar_musica)
	
	if ventana_inventario:
		ventana_inventario.visible = false
	if ventana_inventario:
		ventana_inventario.visible = false
		
	if boton_inventario:
		boton_inventario.pressed.connect(toggle_inventario)
	if boton_tienda:
		boton_tienda.pressed.connect(toggle_tienda)
	if ventana_tienda:
		ventana_tienda.visible = false
	if slot_tienda_plantilla:
		slot_tienda_plantilla.visible = false
		
	actualizar_ui_monedas()
	generar_slots_tienda()
		
	if boton_anterior:
		boton_anterior.pressed.connect(_on_pagina_anterior)
	if boton_siguiente:
		boton_siguiente.pressed.connect(_on_pagina_siguiente)
		
	slot_plantilla.visible = false
	
	var slots_hotbar = hotbar_container.get_children()
	for i in range(slots_hotbar.size()):
		if not slots_hotbar[i].gui_input.is_connected(_on_hotbar_slot_clicado):
			slots_hotbar[i].gui_input.connect(_on_hotbar_slot_clicado.bind(i))
	
	seleccionar_slot_hotbar(0)
	generar_slots_inventario()
	dibujar_items_hotbar()
	
	if ventana_dialogo_npc:
		ventana_dialogo_npc.visible = false
	if boton_aceptar_npc:
		boton_aceptar_npc.pressed.connect(_on_dialogo_aceptar)
	if boton_rechazar_npc:
		boton_rechazar_npc.pressed.connect(_on_dialogo_rechazar)
	
	if ventana_pedidos:
		ventana_pedidos.visible = false
	if fila_pedido_plantilla:
		fila_pedido_plantilla.visible = false
	if boton_pedidos:
		boton_pedidos.pressed.connect(toggle_pedidos)
	if boton_pausa:
		boton_pausa.pressed.connect(toggle_pausa)
	
	if ventana_pausa:
		ventana_pausa.visible = false
		var btn_reanudar := ventana_pausa.find_child("BotonReanudar", true, false) as BaseButton
		var btn_guardar := ventana_pausa.find_child("BotonGuardar", true, false) as BaseButton
		var btn_guardar_salir := ventana_pausa.find_child("BotonGuardarYSalir", true, false) as BaseButton
		var btn_salir := ventana_pausa.find_child("BotonSalirJuego", true, false) as BaseButton
		
		if btn_reanudar: btn_reanudar.pressed.connect(toggle_pausa)
		if btn_guardar: btn_guardar.pressed.connect(_abrir_guardado_pausa)
		if btn_guardar_salir: btn_guardar_salir.pressed.connect(_on_guardar_y_salir_inicio)
		if btn_salir:
			btn_salir.visible = not OS.has_feature("web")
			btn_salir.pressed.connect(func(): get_tree().quit())
			
	if panel_slots_pausa:
		panel_slots_pausa.slot_seleccionado.connect(_on_slot_pausa_elegido)	



func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if dialogo_npc_abierto:
				return
			elif inventario_abierto or tienda_abierta or pedidos_abierto:
				cerrar_menus()
			else:
				toggle_pausa()
		elif pausa_abierta:
			return
		elif event.keycode == KEY_I:
			toggle_inventario()
		elif event.keycode == KEY_T:
			toggle_tienda()
		elif event.keycode == KEY_J:
			toggle_pedidos()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5 and not tienda_abierta:
			seleccionar_slot_hotbar(event.keycode - KEY_1)
		elif event.keycode == KEY_F11:
			if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			else:
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func toggle_inventario() -> void:
	inventario_abierto = !inventario_abierto
	if inventario_abierto:
		tienda_abierta = false
		pedidos_abierto = false
		if ventana_tienda: ventana_tienda.visible = false
		if ventana_pedidos: ventana_pedidos.visible = false
	if ventana_inventario:
		ventana_inventario.visible = inventario_abierto
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta or pedidos_abierto)

func toggle_tienda() -> void:
	tienda_abierta = !tienda_abierta
	if tienda_abierta:
		inventario_abierto = false
		pedidos_abierto = false
		if ventana_inventario: ventana_inventario.visible = false
		if ventana_pedidos: ventana_pedidos.visible = false
		generar_slots_tienda()
	if ventana_tienda:
		ventana_tienda.visible = tienda_abierta
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta or pedidos_abierto)

func toggle_pedidos() -> void:
	pedidos_abierto = !pedidos_abierto
	if pedidos_abierto:
		inventario_abierto = false
		tienda_abierta = false
		if ventana_inventario: ventana_inventario.visible = false
		if ventana_tienda: ventana_tienda.visible = false
		generar_lista_pedidos()
	if ventana_pedidos:
		ventana_pedidos.visible = pedidos_abierto
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta or pedidos_abierto)

func cerrar_menus() -> void:
	inventario_abierto = false
	tienda_abierta = false
	pedidos_abierto = false
	if ventana_inventario: ventana_inventario.visible = false
	if ventana_tienda: ventana_tienda.visible = false
	if ventana_pedidos: ventana_pedidos.visible = false
	estado_inventario_cambiado.emit(false)

func _on_pagina_anterior() -> void:
	if pagina_actual > 0:
		pagina_actual -= 1
		generar_slots_inventario()

func _on_pagina_siguiente() -> void:
	if pagina_actual < 1: 
		pagina_actual += 1
		generar_slots_inventario()

func generar_slots_inventario() -> void:
	for hijo in grid_semillas.get_children():
		if hijo != slot_plantilla:
			hijo.queue_free()
			
	if titulo_inventario:
		titulo_inventario.text = "SEMILLAS (1/2)" if pagina_actual == 0 else "COSECHAS (2/2)"
	if boton_anterior:
		boton_anterior.modulate = Color(1, 1, 1, 0.4) if pagina_actual == 0 else Color(1, 1, 1, 1)
	if boton_siguiente:
		boton_siguiente.modulate = Color(1, 1, 1, 0.4) if pagina_actual == 1 else Color(1, 1, 1, 1)
			
	var lista_a_mostrar = lista_semillas if pagina_actual == 0 else lista_cosechas
			
	for tipo in lista_a_mostrar:
		var cantidad = inventario_datos[tipo]
		if cantidad > 0:
			var nuevo_slot = slot_plantilla.duplicate()
			nuevo_slot.visible = true
			grid_semillas.add_child(nuevo_slot)
			
			# ¡NUEVO! Asignar la imagen dinámica al inventario
			var icono_slot = nuevo_slot.find_child("IconoTrigo*", true, false)
			if icono_slot and iconos_items.has(tipo):
				icono_slot.texture = iconos_items[tipo]
			
			var texto_cantidad = nuevo_slot.find_child("CantidadTex*", true, false)
			if texto_cantidad:
				texto_cantidad.text = "x" + str(cantidad)
			
			nuevo_slot.gui_input.connect(_on_slot_clicado.bind(tipo))

func _on_slot_clicado(event: InputEvent, tipo: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		equipar_en_hotbar(tipo)

func _on_hotbar_slot_clicado(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		seleccionar_slot_hotbar(index)

func seleccionar_slot_hotbar(index: int) -> void:
	slot_seleccionado = index
	var slots = hotbar_container.get_children()
	for i in range(slots.size()):
		var marco = slots[i].find_child("MarcoUI*", true, false)
		if marco:
			if i == slot_seleccionado:
				marco.modulate = Color(1.2, 1.2, 0.8)
			else:
				marco.modulate = Color(1, 1, 1)
				
	semilla_equipada.emit(hotbar_items[slot_seleccionado])

func equipar_en_hotbar(tipo: String) -> void:
	if hotbar_items[slot_seleccionado] == tipo:
		hotbar_items[slot_seleccionado] = ""
	else:
		for i in range(hotbar_items.size()):
			if hotbar_items[i] == tipo:
				hotbar_items[i] = ""
		hotbar_items[slot_seleccionado] = tipo
		
	dibujar_items_hotbar()
	semilla_equipada.emit(hotbar_items[slot_seleccionado])

func dibujar_items_hotbar() -> void:
	var slots = hotbar_container.get_children()
	
	for i in range(slots.size()):
		var icono = slots[i].find_child("IconoTrigo*", true, false)
		var texto = slots[i].find_child("CantidadTex*", true, false)
		var tipo = hotbar_items[i]
		
		if tipo != "" and inventario_datos.has(tipo) and inventario_datos[tipo] > 0:
			if icono: 
				icono.visible = true
				# ¡NUEVO! Asignar la imagen dinámica a la Hotbar
				if iconos_items.has(tipo):
					icono.texture = iconos_items[tipo]
			if texto:
				texto.visible = true
				texto.text = "x" + str(inventario_datos[tipo])
		else:
			if icono: icono.visible = false
			if texto: texto.visible = false
			hotbar_items[i] = ""

func agregar_cosecha(tipo: String) -> void:
	if inventario_datos.has(tipo):
		inventario_datos[tipo] += 1
	else:
		inventario_datos[tipo] = 1 
		
	generar_slots_inventario()
	dibujar_items_hotbar()

func gastar_semilla(tipo: String) -> void:
	if inventario_datos.has(tipo) and inventario_datos[tipo] > 0:
		inventario_datos[tipo] -= 1
		
		generar_slots_inventario()
		dibujar_items_hotbar()
		
		if inventario_datos[tipo] <= 0:
			semilla_equipada.emit("")

# --- SISTEMA DE ECO-MONEDAS Y TIENDA ---
func actualizar_ui_monedas() -> void:
	if label_monedas:
		label_monedas.text = str(eco_monedas)
		
func agregar_monedas(cantidad: int) -> void:
	eco_monedas += cantidad
	actualizar_ui_monedas()
	monedas_cambiadas.emit(eco_monedas)

func gastar_monedas(cantidad: int) -> bool:
	if eco_monedas >= cantidad:
		eco_monedas -= cantidad
		actualizar_ui_monedas()
		monedas_cambiadas.emit(eco_monedas)
		return true
	return false

func generar_slots_tienda() -> void:
	if not grid_tienda or not slot_tienda_plantilla: return
	for hijo in grid_tienda.get_children():
		if hijo != slot_tienda_plantilla:
			hijo.queue_free()
			
	for tipo_semilla in lista_semillas:
		var precio: int = CATALOGO_PLANTAS[tipo_semilla]["precio_compra"]
		
		var nuevo_slot = slot_tienda_plantilla.duplicate()
		nuevo_slot.visible = true
		grid_tienda.add_child(nuevo_slot)
		
		var icono_slot = nuevo_slot.find_child("IconoTrigo*", true, false)
		if icono_slot and iconos_items.has(tipo_semilla):
			icono_slot.texture = iconos_items[tipo_semilla]
			
		var texto_precio = nuevo_slot.find_child("CantidadTex*", true, false)
		if texto_precio:
			texto_precio.text = str(precio) + " Eco"
			texto_precio.modulate = Color(1, 1, 1) if eco_monedas >= precio else Color(1, 0.4, 0.4)
			
		nuevo_slot.gui_input.connect(_on_item_tienda_clicado.bind(tipo_semilla))

func _on_item_tienda_clicado(event: InputEvent, tipo_semilla: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		comprar_semilla(tipo_semilla)

func comprar_semilla(tipo_semilla: String) -> void:
	var precio: int = CATALOGO_PLANTAS[tipo_semilla]["precio_compra"]
	if gastar_monedas(precio):
		agregar_cosecha(tipo_semilla)
		generar_slots_tienda()

# --- CONTROL DE DIÁLOGO CON CLIENTES NPC ---
func mostrar_dialogo_npc(mensaje: String, on_aceptar: Callable, on_rechazar: Callable) -> void:
	if not ventana_dialogo_npc: return
	cerrar_menus()
	dialogo_npc_abierto = true
	_callback_aceptar_actual = on_aceptar
	_callback_rechazar_actual = on_rechazar
	texto_dialogo_npc.text = mensaje
	ventana_dialogo_npc.visible = true
	estado_inventario_cambiado.emit(true)

func cerrar_dialogo_npc() -> void:
	dialogo_npc_abierto = false
	if ventana_dialogo_npc:
		ventana_dialogo_npc.visible = false
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta)

func _on_dialogo_aceptar() -> void:
	cerrar_dialogo_npc()
	if _callback_aceptar_actual.is_valid():
		_callback_aceptar_actual.call()

func _on_dialogo_rechazar() -> void:
	cerrar_dialogo_npc()
	if _callback_rechazar_actual.is_valid():
		_callback_rechazar_actual.call()

# --- GESTIÓN DE PEDIDOS ACTIVOS ---
func generar_lista_pedidos() -> void:
	if not lista_pedidos or not fila_pedido_plantilla: return
	
	for hijo in lista_pedidos.get_children():
		if hijo != fila_pedido_plantilla:
			hijo.queue_free()
			
	if pedidos_activos.is_empty():
		var fila_vacia := fila_pedido_plantilla.duplicate()
		fila_vacia.visible = true
		lista_pedidos.add_child(fila_vacia)
		var icono_vacio := fila_vacia.get_node_or_null("IconoCultivo") as TextureRect
		var texto_vacio := fila_vacia.get_node_or_null("TextoPedido") as Label
		var boton_vacio := fila_vacia.get_node_or_null("BotonEntregar") as BaseButton
		if icono_vacio: icono_vacio.visible = false
		if boton_vacio: boton_vacio.visible = false
		if texto_vacio: texto_vacio.text = "No tienes encargos activos."
		return

	for i in range(pedidos_activos.size()):
		var pedido: Dictionary = pedidos_activos[i]
		var item: String = str(pedido["item"])
		var cantidad_req: int = int(pedido["cantidad"])
		var recompensa: int = int(pedido["recompensa"])
		var en_mochila: int = int(inventario_datos.get(item, 0))
		
		var nueva_fila := fila_pedido_plantilla.duplicate()
		nueva_fila.visible = true
		lista_pedidos.add_child(nueva_fila)
		
		var icono := nueva_fila.get_node_or_null("IconoCultivo") as TextureRect
		if icono and iconos_items.has(item):
			icono.texture = iconos_items[item]
			
		var texto := nueva_fila.get_node_or_null("TextoPedido") as Label
		if texto:
			var nombre_bonito: String = NOMBRES_COSECHAS.get(item, item)
			texto.text = "%s (%d/%d)  +$%d" % [nombre_bonito, en_mochila, cantidad_req, recompensa]
			
		var boton := nueva_fila.get_node_or_null("BotonEntregar") as BaseButton
		if boton:
			var puede_entregar: bool = en_mochila >= cantidad_req
			boton.disabled = not puede_entregar
			boton.modulate = Color(1, 1, 1) if puede_entregar else Color(0.6, 0.6, 0.6, 0.7)
			boton.pressed.connect(entregar_pedido.bind(i))

func entregar_pedido(index: int) -> void:
	if index < 0 or index >= pedidos_activos.size(): return
	
	var pedido: Dictionary = pedidos_activos[index]
	var item: String = str(pedido["item"])
	var cantidad_req: int = int(pedido["cantidad"])
	var recompensa: int = int(pedido["recompensa"])
	
	if int(inventario_datos.get(item, 0)) >= cantidad_req:
		inventario_datos[item] -= cantidad_req
		agregar_monedas(recompensa)
		pedidos_activos.remove_at(index)
		
		generar_slots_inventario()
		dibujar_items_hotbar()
		generar_lista_pedidos()

var _salir_tras_guardar: bool = false

func toggle_pausa() -> void:
	pausa_abierta = !pausa_abierta
	if pausa_abierta:
		cerrar_menus()
	else:
		_salir_tras_guardar = false
		if panel_slots_pausa:
			panel_slots_pausa.visible = false
	if ventana_pausa:
		ventana_pausa.visible = pausa_abierta
	pausa_cambiada.emit(pausa_abierta)
	estado_inventario_cambiado.emit(esta_juego_pausado())

func _abrir_guardado_pausa() -> void:
	if panel_slots_pausa:
		panel_slots_pausa.abrir(panel_slots_pausa.Modo.GUARDAR)

func _on_guardar_y_salir_inicio() -> void:
	if slot_activo >= 1 and slot_activo <= MAX_SLOTS:
		guardar_en_slot(slot_activo)
		_volver_a_menu_inicio()
	elif panel_slots_pausa:
		_salir_tras_guardar = true
		panel_slots_pausa.abrir(panel_slots_pausa.Modo.GUARDAR)

func _on_slot_pausa_elegido(num_slot: int, _modo: int) -> void:
	guardar_en_slot(num_slot)
	if _salir_tras_guardar:
		_salir_tras_guardar = false
		_volver_a_menu_inicio()

func _volver_a_menu_inicio() -> void:
	pausa_abierta = false
	if ventana_pausa:
		ventana_pausa.visible = false
	atenuar_musica(false)
	set_hud_visible(false)
	get_tree().change_scene_to_file("res://menu_inicio.tscn")
	
func esta_juego_pausado() -> bool:
	return dialogo_npc_abierto or inventario_abierto or tienda_abierta or pedidos_abierto or pausa_abierta

# --- MOTOR DE PERSISTENCIA JSON (3 SLOTS) ---
func reiniciar_estado_partida() -> void:
	slot_activo = 0
	eco_monedas = 100
	tierra_guardada.clear()
	plantas_guardadas.clear()
	exhibicion_guardada.clear()
	pedidos_activos.clear()
	hotbar_items = ["", "", "", "", ""]
	slot_seleccionado = 0
	pagina_actual = 0
	inventario_datos = {
		"trigo": 10,
		"trigo_cosechado": 5,
		"remolacha": 5,
		"remolacha_cosechada": 2,
		"arbol": 3,
		"arbol_cosechado": 1
	}
	actualizar_ui_monedas()
	generar_slots_inventario()
	dibujar_items_hotbar()

func guardar_en_slot(num_slot: int) -> bool:
	if num_slot < 1 or num_slot > MAX_SLOTS:
		return false
		
	# Solicita a la escena actual (ej. Jardín) que vuelque sus datos antes de escribir
	antes_de_guardar.emit()
	slot_activo = num_slot
	
	var escena_actual_ruta: String = "res://jardin.tscn"
	if get_tree().current_scene and get_tree().current_scene.scene_file_path != "":
		escena_actual_ruta = get_tree().current_scene.scene_file_path
		
	var datos_partida: Dictionary = {
		"fecha": Time.get_datetime_string_from_system(false, true),
		"escena": escena_actual_ruta,
		"eco_monedas": eco_monedas,
		"inventario_datos": inventario_datos.duplicate(true),
		"hotbar_items": hotbar_items.duplicate(),
		"slot_seleccionado": slot_seleccionado,
		"pedidos_activos": pedidos_activos.duplicate(true),
		"exhibicion_guardada": exhibicion_guardada.duplicate(true),
		"tierra_guardada": _serializar_dict_vec2i(tierra_guardada),
		"plantas_guardadas": _serializar_dict_vec2i(plantas_guardadas)
	}
	
	var archivo := FileAccess.open(_obtener_ruta_slot(num_slot), FileAccess.WRITE)
	if archivo == null:
		return false
		
	archivo.store_string(JSON.stringify(datos_partida, "\t"))
	archivo.close()
	_guardar_ultimo_slot(num_slot)
	return true

func cargar_desde_slot(num_slot: int) -> bool:
	var ruta: String = _obtener_ruta_slot(num_slot)
	if not FileAccess.file_exists(ruta):
		return false
		
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return false
		
	var contenido: String = archivo.get_as_text()
	archivo.close()
	
	var json_parseado = JSON.parse_string(contenido)
	if typeof(json_parseado) != TYPE_DICTIONARY:
		return false
		
	var datos: Dictionary = json_parseado
	slot_activo = num_slot
	eco_monedas = int(datos.get("eco_monedas", 100))
	
	# Restaurar inventario asegurando valores enteros
	var inv_raw: Dictionary = datos.get("inventario_datos", {})
	for clave in inv_raw:
		inventario_datos[str(clave)] = int(inv_raw[clave])
		
	# Restaurar hotbar tipada
	var hb_raw: Array = datos.get("hotbar_items", ["", "", "", "", ""])
	hotbar_items = ["", "", "", "", ""]
	for i in range(min(5, hb_raw.size())):
		hotbar_items[i] = str(hb_raw[i])
	slot_seleccionado = int(datos.get("slot_seleccionado", 0))
	
	# Restaurar pedidos activos
	pedidos_activos.clear()
	var ped_raw: Array = datos.get("pedidos_activos", [])
	for p in ped_raw:
		if typeof(p) == TYPE_DICTIONARY:
			pedidos_activos.append({
				"item": str(p.get("item", "")),
				"cantidad": int(p.get("cantidad", 1)),
				"recompensa": int(p.get("recompensa", 25))
			})
			
	exhibicion_guardada = datos.get("exhibicion_guardada", {}).duplicate(true)
	tierra_guardada = _deserializar_dict_vec2i(datos.get("tierra_guardada", {}))
	plantas_guardadas = _deserializar_dict_vec2i(datos.get("plantas_guardadas", {}))
	
	actualizar_ui_monedas()
	seleccionar_slot_hotbar(slot_seleccionado)
	generar_slots_inventario()
	dibujar_items_hotbar()
	_guardar_ultimo_slot(num_slot)
	
	
	if has_node("/root/Transicion"):
		Transicion.viene_de_transicion = false
	set_hud_visible(true)
	var escena_destino: String = str(datos.get("escena", "res://jardin.tscn"))
	get_tree().change_scene_to_file(escena_destino)
	return true

func obtener_info_slot(num_slot: int) -> Dictionary:
	var ruta: String = _obtener_ruta_slot(num_slot)
	if not FileAccess.file_exists(ruta):
		return { "ocupado": false }
		
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		return { "ocupado": false }
		
	var json_parseado = JSON.parse_string(archivo.get_as_text())
	archivo.close()
	
	if typeof(json_parseado) != TYPE_DICTIONARY:
		return { "ocupado": false }
		
	var datos: Dictionary = json_parseado
	return {
		"ocupado": true,
		"monedas": int(datos.get("eco_monedas", 0)),
		"fecha": str(datos.get("fecha", ""))
	}

func obtener_ultimo_slot_jugado() -> int:
	if FileAccess.file_exists(RUTA_CONFIG_SLOTS):
		var archivo := FileAccess.open(RUTA_CONFIG_SLOTS, FileAccess.READ)
		if archivo:
			var parsed = JSON.parse_string(archivo.get_as_text())
			archivo.close()
			if typeof(parsed) == TYPE_DICTIONARY:
				var ultimo: int = int(parsed.get("ultimo_slot", 0))
				if ultimo >= 1 and ultimo <= MAX_SLOTS and FileAccess.file_exists(_obtener_ruta_slot(ultimo)):
					return ultimo
	# Respaldo: devuelve el primer slot ocupado si existe
	for i in range(1, MAX_SLOTS + 1):
		if FileAccess.file_exists(_obtener_ruta_slot(i)):
			return i
	return 0

func _guardar_ultimo_slot(num_slot: int) -> void:
	var archivo := FileAccess.open(RUTA_CONFIG_SLOTS, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify({ "ultimo_slot": num_slot }))
		archivo.close()

func _obtener_ruta_slot(num_slot: int) -> String:
	return "user://partida_slot_%d.json" % num_slot

func _serializar_dict_vec2i(origen: Dictionary) -> Dictionary:
	var resultado: Dictionary = {}
	for coord in origen:
		if coord is Vector2i:
			var clave_str := "%d,%d" % [coord.x, coord.y]
			var valor = origen[coord]
			if valor is Vector2i:
				resultado[clave_str] = { "_vec2i": [valor.x, valor.y] }
			else:
				resultado[clave_str] = valor
	return resultado

func _deserializar_dict_vec2i(origen: Dictionary) -> Dictionary:
	var resultado: Dictionary = {}
	for clave_str in origen:
		var partes: PackedStringArray = str(clave_str).split(",")
		if partes.size() == 2:
			var coord := Vector2i(int(partes[0]), int(partes[1]))
			var valor = origen[clave_str]
			if typeof(valor) == TYPE_DICTIONARY:
				if valor.has("_vec2i"):
					var arr: Array = valor["_vec2i"]
					resultado[coord] = Vector2i(int(arr[0]), int(arr[1]))
				else:
					var copia_limpia: Dictionary = valor.duplicate(true)
					if copia_limpia.has("estado"):
						copia_limpia["estado"] = int(copia_limpia["estado"])
					resultado[coord] = copia_limpia
			else:
				resultado[coord] = valor
	return resultado

func set_hud_visible(es_visible: bool) -> void:
	if has_node("InventarioUI"):
		$InventarioUI.visible = es_visible

func set_hotbar_transparente(transparente: bool) -> void:
	if not hotbar_container:
		return
	var tween := create_tween()
	tween.tween_property(hotbar_container, "modulate:a", 0.25 if transparente else 1.0, 0.2)

func atenuar_musica(atenuar: bool) -> void:
	var bus_idx := AudioServer.get_bus_index("Musica")
	if bus_idx == -1:
		return
	var destino_db := -14.0 if atenuar else 0.0
	var tween := create_tween()
	tween.tween_method(
		func(val: float): AudioServer.set_bus_volume_db(bus_idx, val),
		AudioServer.get_bus_volume_db(bus_idx),
		destino_db,
		0.25
	)

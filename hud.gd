extends CanvasLayer

signal estado_inventario_cambiado(abierto: bool)
signal semilla_equipada(tipo_semilla: String)
signal monedas_cambiadas(nueva_cantidad: int)

@onready var hotbar_container = $InventarioUI/HotbarContainer
@onready var ventana_inventario: Control = $InventarioUI/VentanaInventario
@onready var boton_inventario: TextureButton = $InventarioUI/BotonInventario
@onready var grid_semillas: GridContainer = $InventarioUI/VentanaInventario/GridSemillas
@onready var slot_plantilla: Control = $InventarioUI/VentanaInventario/GridSemillas/SlotPlantilla

@onready var boton_anterior: TextureButton = $InventarioUI/VentanaInventario/BotonAnterior
@onready var boton_siguiente: TextureButton = $InventarioUI/VentanaInventario/BotonSiguiente

# --- NODOS DE ECONOMÍA Y TIENDA ---
@onready var label_monedas: Label = $InventarioUI/LabelMonedas
@onready var boton_tienda: TextureButton = $InventarioUI/BotonTienda
@onready var ventana_tienda: Control = $InventarioUI/VentanaTienda
@onready var grid_tienda: GridContainer = $InventarioUI/VentanaTienda/GridTienda
@onready var slot_tienda_plantilla: Control = $InventarioUI/VentanaTienda/GridTienda/SlotPlantilla

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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			toggle_inventario()
		elif event.keycode == KEY_T:
			toggle_tienda()
		elif event.keycode == KEY_ESCAPE and (inventario_abierto or tienda_abierta):
			cerrar_menus()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5 and not tienda_abierta:
			seleccionar_slot_hotbar(event.keycode - KEY_1)

func toggle_inventario() -> void:
	inventario_abierto = !inventario_abierto
	if inventario_abierto and tienda_abierta:
		tienda_abierta = false
		if ventana_tienda: ventana_tienda.visible = false
		
	if ventana_inventario:
		ventana_inventario.visible = inventario_abierto
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta)

func toggle_tienda() -> void:
	tienda_abierta = !tienda_abierta
	if tienda_abierta and inventario_abierto:
		inventario_abierto = false
		if ventana_inventario: ventana_inventario.visible = false
		
	if ventana_tienda:
		ventana_tienda.visible = tienda_abierta
	if tienda_abierta:
		generar_slots_tienda()
	estado_inventario_cambiado.emit(inventario_abierto or tienda_abierta)

func cerrar_menus() -> void:
	inventario_abierto = false
	tienda_abierta = false
	if ventana_inventario: ventana_inventario.visible = false
	if ventana_tienda: ventana_tienda.visible = false
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
		label_monedas.text = "Eco-Monedas: " + str(eco_monedas)

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
			texto_precio.text = "$" + str(precio)
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

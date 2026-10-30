extends CanvasLayer

signal estado_inventario_cambiado(abierto: bool)
signal semilla_equipada(tipo_semilla: String)

@onready var hotbar_container = $InventarioUI/HotbarContainer
@onready var ventana_inventario: Control = $InventarioUI/VentanaInventario
@onready var boton_inventario: TextureButton = $InventarioUI/BotonInventario
@onready var grid_semillas: GridContainer = $InventarioUI/VentanaInventario/GridSemillas
@onready var slot_plantilla: Control = $InventarioUI/VentanaInventario/GridSemillas/SlotPlantilla

@onready var boton_anterior: TextureButton = $InventarioUI/VentanaInventario/BotonAnterior
@onready var boton_siguiente: TextureButton = $InventarioUI/VentanaInventario/BotonSiguiente

# Guardarán las coordenadas exactas de la tierra y las plantas
var tierra_guardada: Dictionary = {}
var plantas_guardadas: Dictionary = {}

var inventario_abierto: bool = false
var hotbar_items: Array[String] = ["", "", "", "", ""]
var slot_seleccionado: int = 0
var pagina_actual: int = 0 

var inventario_datos: Dictionary = {
	"trigo": 5,
	"trigo_cosechado": 0 
}

var lista_semillas: Array[String] = ["trigo"]
var lista_cosechas: Array[String] = ["trigo_cosechado"]

# --- NUEVA BASE DE DATOS VISUAL ---
var textura_plantas = preload("res://Sprout Lands - Sprites - Basic pack/Sprout Lands - Sprites - Basic pack/Objects/Basic Plants.png")

# Recortamos los íconos creando un AtlasTexture por código (x, y, ancho, alto)
@onready var iconos_items: Dictionary = {
	"trigo": crear_icono(0, 0, 16, 16),          # Semilla (Coordenada 1 del tilemap)
	"trigo_cosechado": crear_icono(80, 0, 16, 16) # Planta madura (Coordenada 4 del tilemap)
}
# Añade esto debajo de tus otros diccionarios en hud.gd
@onready var texturas_exhibicion: Dictionary = {
	"trigo_cosechado": crear_icono(64, 0, 16, 16) # La textura de la planta madura en la tierra
}
func crear_icono(x: int, y: int, ancho: int, alto: int) -> AtlasTexture:
	var atlas = AtlasTexture.new()
	atlas.atlas = textura_plantas
	atlas.region = Rect2(x, y, ancho, alto)
	return atlas
# ----------------------------------

func _ready() -> void:
	if ventana_inventario:
		ventana_inventario.visible = false
		
	if boton_inventario:
		boton_inventario.pressed.connect(toggle_inventario)
		
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
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			seleccionar_slot_hotbar(event.keycode - KEY_1)

func toggle_inventario() -> void:
	inventario_abierto = !inventario_abierto
	if ventana_inventario:
		ventana_inventario.visible = inventario_abierto
	estado_inventario_cambiado.emit(inventario_abierto)

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

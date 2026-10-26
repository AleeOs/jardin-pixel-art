extends CanvasLayer

signal estado_inventario_cambiado(abierto: bool)
signal semilla_equipada(tipo_semilla: String)

# ⚠️ RUTAS PRINCIPALES (Arrastra tus nodos aquí si te da error en la línea 7 u 8)
@onready var hotbar_container = $InventarioUI/HotbarContainer
@onready var ventana_inventario: Control = $InventarioUI/VentanaInventario
@onready var boton_inventario: TextureButton = $InventarioUI/BotonInventario
@onready var grid_semillas: GridContainer = $InventarioUI/VentanaInventario/GridSemillas
@onready var slot_plantilla: Control = $InventarioUI/VentanaInventario/GridSemillas/SlotPlantilla

var inventario_abierto: bool = false

# --- SISTEMA DE HOTBAR DE 5 SLOTS ---
var hotbar_items: Array[String] = ["", "", "", "", ""] # Memoria de las 5 casillas
var slot_seleccionado: int = 0 # Casilla activa (va del 0 al 4)

var inventario_datos: Dictionary = {
	"trigo": 5
}

func _ready() -> void:
	if ventana_inventario:
		ventana_inventario.visible = false
		
	if boton_inventario:
		boton_inventario.pressed.connect(toggle_inventario)
		
	slot_plantilla.visible = false
	generar_slots_inventario()
	
	# NUEVO: Conectar los clics del ratón a cada casilla de la Hotbar
	var slots_hotbar = hotbar_container.get_children()
	for i in range(slots_hotbar.size()):
		# Conectamos el evento y le pasamos su número de índice (del 0 al 4)
		if not slots_hotbar[i].gui_input.is_connected(_on_hotbar_slot_clicado):
			slots_hotbar[i].gui_input.connect(_on_hotbar_slot_clicado.bind(i))
	
	# Inicia la partida con el Slot 1 (índice 0) seleccionado y la barra dibujada
	seleccionar_slot_hotbar(0)
	dibujar_items_hotbar()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		# Tecla I para el inventario
		if event.keycode == KEY_I:
			toggle_inventario()
			
		# Teclas del 1 al 5 para mover la selección de la Hotbar
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			# KEY_1 equivale a índice 0, KEY_2 a índice 1, etc.
			seleccionar_slot_hotbar(event.keycode - KEY_1)

func toggle_inventario() -> void:
	inventario_abierto = !inventario_abierto
	if ventana_inventario:
		ventana_inventario.visible = inventario_abierto
	estado_inventario_cambiado.emit(inventario_abierto)

func generar_slots_inventario() -> void:
	for hijo in grid_semillas.get_children():
		if hijo != slot_plantilla:
			hijo.queue_free()
			
	for tipo in inventario_datos.keys():
		var cantidad = inventario_datos[tipo]
		if cantidad > 0:
			var nuevo_slot = slot_plantilla.duplicate()
			nuevo_slot.visible = true
			grid_semillas.add_child(nuevo_slot)
			
			var texto_cantidad = nuevo_slot.find_child("CantidadTex*", true, false)
			if texto_cantidad:
				texto_cantidad.text = "x" + str(cantidad)
			
			nuevo_slot.gui_input.connect(_on_slot_clicado.bind(tipo))

func _on_slot_clicado(event: InputEvent, tipo: String) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		equipar_en_hotbar(tipo)

# --- FUNCIONES NUEVAS PARA LOS 5 SLOTS ---

func seleccionar_slot_hotbar(index: int) -> void:
	slot_seleccionado = index
	
	# 1. Actualizar el brillo de los marcos
	var slots = hotbar_container.get_children()
	for i in range(slots.size()):
		var marco = slots[i].find_child("MarcoUI*", true, false)
		if marco:
			if i == slot_seleccionado:
				marco.modulate = Color(1.2, 1.2, 0.8) # Brilla
			else:
				marco.modulate = Color(1, 1, 1) # Normal
				
	# 2. Avisar al jugador qué tiene en la mano ahora mismo
	semilla_equipada.emit(hotbar_items[slot_seleccionado])

func equipar_en_hotbar(tipo: String) -> void:
	# Si ya está equipada en la casilla actual, simplemente la quitamos
	if hotbar_items[slot_seleccionado] == tipo:
		hotbar_items[slot_seleccionado] = ""
	else:
		# Si la vamos a equipar, PRIMERO buscamos si estaba en otra casilla y la borramos
		for i in range(hotbar_items.size()):
			if hotbar_items[i] == tipo:
				hotbar_items[i] = ""
				
		# LUEGO, la ponemos en la casilla que tenemos seleccionada
		hotbar_items[slot_seleccionado] = tipo
		
	dibujar_items_hotbar()
	semilla_equipada.emit(hotbar_items[slot_seleccionado])

func dibujar_items_hotbar() -> void:
	var slots = hotbar_container.get_children()
	
	for i in range(slots.size()):
		var icono = slots[i].find_child("IconoTrigo*", true, false)
		var texto = slots[i].find_child("CantidadTex*", true, false)
		var tipo = hotbar_items[i]
		
		# Si hay una semilla asignada y tenemos cantidad mayor a 0
		if tipo != "" and inventario_datos.has(tipo) and inventario_datos[tipo] > 0:
			if icono: icono.visible = true
			if texto:
				texto.visible = true
				texto.text = "x" + str(inventario_datos[tipo])
		else:
			# Casilla vacía o semilla agotada
			if icono: icono.visible = false
			if texto: texto.visible = false
			hotbar_items[i] = "" # Limpiamos la memoria de ese slot

func gastar_semilla(tipo: String) -> void:
	if inventario_datos.has(tipo) and inventario_datos[tipo] > 0:
		inventario_datos[tipo] -= 1
		
		generar_slots_inventario() # Actualiza números del panel
		dibujar_items_hotbar()     # Actualiza números de las 5 casillas de abajo
		
		if inventario_datos[tipo] <= 0:
			semilla_equipada.emit("")
func _on_hotbar_slot_clicado(event: InputEvent, index: int) -> void:
	# Detectar clic izquierdo del ratón o touchpad en la hotbar
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		seleccionar_slot_hotbar(index)

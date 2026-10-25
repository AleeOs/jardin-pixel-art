extends CanvasLayer

signal estado_inventario_cambiado(abierto: bool)

@onready var cantidad_label: Label = $InventarioUI/HotbarContainer/Slot1/MarcoUI/CantidadText
@onready var ventana_inventario: Control = $InventarioUI/VentanaInventario
@onready var boton_inventario: TextureButton = $InventarioUI/BotonInventario
var inventario_abierto: bool = false

func _ready() -> void:
	# Asegurar que la ventana comience oculta al iniciar la partida
	if ventana_inventario:
		ventana_inventario.visible = false
		
	# Conectar el botón visual si existe en el nodo
	if boton_inventario:
		boton_inventario.pressed.connect(toggle_inventario)

func _unhandled_input(event: InputEvent) -> void:
	# Abrir y cerrar con la tecla 'I'
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_I:
			toggle_inventario()

func toggle_inventario() -> void:
	inventario_abierto = !inventario_abierto
	
	if ventana_inventario:
		ventana_inventario.visible = inventario_abierto
		
	# Emitir señal para detener o reanudar al personaje
	estado_inventario_cambiado.emit(inventario_abierto)

func actualizar_trigo(cantidad: int) -> void:
	if cantidad_label:
		cantidad_label.text = "x" + str(cantidad)

extends Control

@export var radio_maximo: float = 48.0
@export var zona_muerta: float = 0.2

@onready var perilla: Control = $Perilla
@onready var flechas := {
	"ui_up": get_node_or_null("FlechaArriba"),
	"ui_down": get_node_or_null("FlechaAbajo"),
	"ui_left": get_node_or_null("FlechaIzquierda"),
	"ui_right": get_node_or_null("FlechaDerecha")
}

var dedo_activo: int = -1
var centro_base: Vector2

func _ready() -> void:
	await get_tree().process_frame
	centro_base = size * 0.5
	_centrar_perilla()

func _exit_tree() -> void:
	_soltar_palanca()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or HudGlobal.esta_juego_pausado():
		if dedo_activo != -1:
			_soltar_palanca()
		return

	if event is InputEventScreenTouch:
		if event.pressed and dedo_activo == -1:
			if get_global_rect().has_point(event.position):
				dedo_activo = event.index
				_actualizar_palanca(event.position)
		elif not event.pressed and event.index == dedo_activo:
			_soltar_palanca()

	elif event is InputEventScreenDrag and event.index == dedo_activo:
		_actualizar_palanca(event.position)

func _actualizar_palanca(pos_global_dedo: Vector2) -> void:
	var pos_local := get_global_transform_with_canvas().affine_inverse() * pos_global_dedo
	var desplazamiento := (pos_local - centro_base).limit_length(radio_maximo)
	
	if perilla:
		perilla.position = centro_base + desplazamiento - (perilla.size * 0.5)
		
	var vector := desplazamiento / radio_maximo
	if vector.length() < zona_muerta:
		vector = Vector2.ZERO
		
	_aplicar_direcciones(vector)

func _soltar_palanca() -> void:
	dedo_activo = -1
	_centrar_perilla()
	_aplicar_direcciones(Vector2.ZERO)

func _centrar_perilla() -> void:
	if perilla:
		perilla.position = centro_base - (perilla.size * 0.5)

func _aplicar_direcciones(vec: Vector2) -> void:
	_actualizar_accion("ui_left", maxf(0.0, -vec.x))
	_actualizar_accion("ui_right", maxf(0.0, vec.x))
	_actualizar_accion("ui_up", maxf(0.0, -vec.y))
	_actualizar_accion("ui_down", maxf(0.0, vec.y))

func _actualizar_accion(accion: String, fuerza: float) -> void:
	if fuerza > 0.0:
		Input.action_press(accion, fuerza)
	else:
		if Input.is_action_pressed(accion):
			Input.action_release(accion)
			
	var flecha: CanvasItem = flechas.get(accion)
	if flecha:
		flecha.modulate = Color(1.25, 1.15, 0.85) if fuerza > 0.0 else Color(1, 1, 1, 0.75)

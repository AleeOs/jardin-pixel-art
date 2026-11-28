extends CanvasLayer

@onready var color_rect = $ColorRect

var viene_de_transicion: bool = false

func _ready() -> void:
	layer = 100
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0
	color_rect.visible = false

func cambiar_escena(ruta_destino: String) -> void:
	ejecutar_con_transicion(func():
		get_tree().change_scene_to_file(ruta_destino)
	, true)

func ejecutar_con_transicion(accion: Callable, usar_marcador_puerta: bool = false) -> void:
	viene_de_transicion = usar_marcador_puerta
	color_rect.visible = true
	
	var tween_in := create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 1.0, 0.25)
	await tween_in.finished
	
	await get_tree().process_frame
	
	if accion.is_valid():
		await accion.call()
		
	await get_tree().process_frame
	
	var tween_out := create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 0.0, 0.25)
	await tween_out.finished
	
	color_rect.visible = false
	viene_de_transicion = false

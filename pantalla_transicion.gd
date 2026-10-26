extends CanvasLayer

@onready var color_rect = $ColorRect

func _ready() -> void:
	# Forzamos la configuración por código para evitar errores visuales
	layer = 100
	color_rect.color = Color(0, 0, 0, 1) # Aseguramos que sea negro
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT) # Lo estiramos a toda la pantalla
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Evitamos que bloquee clics
	color_rect.modulate.a = 0
	color_rect.visible = false

func cambiar_escena(ruta_destino: String) -> void:
	color_rect.visible = true
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	await tween_in.finished
	
	get_tree().change_scene_to_file(ruta_destino)
	
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	color_rect.visible = false

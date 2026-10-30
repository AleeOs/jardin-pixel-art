extends CanvasLayer

@onready var color_rect = $ColorRect

# Esta es la variable clave que faltaba
var viene_de_transicion: bool = false 

func _ready() -> void:
	layer = 100
	color_rect.color = Color(0, 0, 0, 1)
	color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	color_rect.modulate.a = 0
	color_rect.visible = false

func cambiar_escena(ruta_destino: String) -> void:
	# Al cruzar una puerta, avisamos que SÍ hay transición
	viene_de_transicion = true 
	color_rect.visible = true
	
	var tween_in = create_tween()
	tween_in.tween_property(color_rect, "modulate:a", 1.0, 0.5)
	await tween_in.finished
	
	get_tree().change_scene_to_file(ruta_destino)
	
	var tween_out = create_tween()
	tween_out.tween_property(color_rect, "modulate:a", 0.0, 0.5)
	await tween_out.finished
	
	color_rect.visible = false
	
	# Reiniciamos la variable por seguridad
	viene_de_transicion = false

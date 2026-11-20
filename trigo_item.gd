extends Area2D

@onready var sprite: Sprite2D = $Sprite2D
var tipo_cosecha: String = "trigo_cosechado"

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# Desactivamos Region para que el AtlasTexture no se recorte en blanco
	sprite.region_enabled = false
	if HudGlobal.iconos_items.has(tipo_cosecha):
		sprite.texture = HudGlobal.iconos_items[tipo_cosecha]
	
	var tween_salto := create_tween()
	tween_salto.tween_property(sprite, "position:y", -12.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_salto.tween_property(sprite, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween_salto.finished.connect(iniciar_flotado)

func iniciar_flotado() -> void:
	var tween_flotado := create_tween().set_loops()
	tween_flotado.tween_property(sprite, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_flotado.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		HudGlobal.agregar_cosecha(tipo_cosecha)
		queue_free()

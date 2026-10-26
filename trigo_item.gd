extends Area2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	# EFECTO 1: Salto suave hacia arriba al aparecer
	var tween_salto := create_tween()
	tween_salto.tween_property(sprite, "position:y", -12.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_salto.tween_property(sprite, "position:y", 0.0, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	
	tween_salto.finished.connect(iniciar_flotado)

func iniciar_flotado() -> void:
	# EFECTO 2: Flotado suave infinito (arriba y abajo)
	var tween_flotado := create_tween().set_loops()
	tween_flotado.tween_property(sprite, "position:y", -3.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_flotado.tween_property(sprite, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_body_entered(body: Node2D) -> void:
	# Si el jugador toca la espiga, se envía al inventario de cosechas y desaparece
	if body.is_in_group("player") or body.name == "Player":
		var hud_node = body.get_parent().get_node_or_null("HUD")
		
		# Le avisamos al HUD que guarde una planta cosechada
		if hud_node and hud_node.has_method("agregar_cosecha"):
			hud_node.agregar_cosecha("trigo_cosechado")
			print("🌾 ¡Trigo recolectado y enviado al inventario!")
			
		# El ítem desaparece del suelo
		queue_free()

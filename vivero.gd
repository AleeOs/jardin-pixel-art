extends Node2D

@onready var jugador = $Player
@onready var puerta = $PuertaTransicion

func _ready() -> void:
	if not Transicion.viene_de_transicion:
		return 
		
	var punto_spawn = puerta.get_node("PuntoSpawn")
	jugador.global_position = punto_spawn.global_position
	
	# Apagamos TODO el cerebro del jugador para que no cambie la animación
	jugador.set_physics_process(false)
	jugador.set_process(false)
	
	var anim_gato = jugador.get_node("AnimationPlayer")
	anim_gato.play("idle_up") # Forzamos que mire hacia arriba a la pared
	jugador.visible = false
	
	await get_tree().create_timer(0.5).timeout 
	
	var anim_puerta = puerta.get_node("AnimationPlayer")
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play("abrir")
		await anim_puerta.animation_finished
	
	jugador.visible = true
	anim_gato.play("walk_up") # Camina hacia arriba (-Y)
	
	var tween = create_tween()
	tween.tween_property(jugador, "global_position:y", jugador.global_position.y - 40, 0.5)
	await tween.finished
	
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play_backwards("abrir")
		
	anim_gato.play("idle_up")
	
	# Le devolvemos el control
	jugador.set_physics_process(true)
	jugador.set_process(true)

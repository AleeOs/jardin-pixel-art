extends Node2D

@onready var jugador = $Player
@onready var puerta = $PuertaTransicion

func _ready() -> void:
	cargar_cultivos_guardados()
	if not Transicion.viene_de_transicion:
		return 
		
	var punto_spawn = puerta.get_node("PuntoSpawn")
	jugador.global_position = punto_spawn.global_position
	
	# Bloqueo total
	jugador.set_physics_process(false)
	jugador.set_process(false)
	
	var anim_gato = jugador.get_node("AnimationPlayer")
	anim_gato.play("idle_down") # Forzamos que mire hacia la calle
	jugador.visible = false
	
	await get_tree().create_timer(0.5).timeout
	
	var anim_puerta = puerta.get_node("AnimationPlayer")
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play("abrir")
		await anim_puerta.animation_finished
	
	jugador.visible = true
	anim_gato.play("walk_down") # Camina hacia abajo (+Y)
	
	var tween = create_tween()
	tween.tween_property(jugador, "global_position:y", jugador.global_position.y + 40, 0.5)
	await tween.finished
	
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play_backwards("abrir")
		
	anim_gato.play("idle_down")
	
	# Le devolvemos el control
	jugador.set_physics_process(true)
	jugador.set_process(true)

func cargar_cultivos_guardados() -> void:
	# Dibujamos toda la tierra arada que guardamos
	for coord in HudGlobal.tierra_guardada:
		var variante = HudGlobal.tierra_guardada[coord]
		jugador.cultivo_layer.set_cell(coord, 0, variante)
		
	# Dibujamos todas las plantas en su etapa de crecimiento exacta
	for coord in HudGlobal.plantas_guardadas:
		var estado = HudGlobal.plantas_guardadas[coord]
		var atlas_coord = Vector2i(1, 0) # Por defecto Semilla
		
		if estado == 2:
			atlas_coord = Vector2i(2, 0) # Brote
		elif estado == 3:
			atlas_coord = Vector2i(4, 0) # Maduro
			
		jugador.plantas_layer.set_cell(coord, 1, atlas_coord)

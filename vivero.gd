extends Node2D

@onready var jugador = $Player
@onready var puerta = $PuertaTransicion
@onready var puerta_npcs = $PuertaNPCs
@onready var ruta_npcs = $PuntosRutaNPC

var escena_npc = preload("res://npc_cliente.tscn")
var indice_rol: int = 0
var clientes_en_tienda: int = 0
const MAX_CLIENTES: int = 3 # Con 4 puestos disponibles, siempre habrá al menos 1 libre

# Diccionarios de reserva: { Marker2D: npc_o_null }
var puestos_exhibicion: Dictionary = {}
var puestos_mostrador: Dictionary = {}

func _ready() -> void:
	inicializar_puestos()
	iniciar_generador_clientes()
	
	if not Transicion.viene_de_transicion:
		return 
		
	var punto_spawn = puerta.get_node("PuntoSpawn")
	jugador.global_position = punto_spawn.global_position
	
	jugador.set_physics_process(false)
	jugador.set_process(false)
	
	var anim_gato = jugador.get_node("AnimationPlayer")
	anim_gato.play("idle_up")
	jugador.visible = false
	
	await get_tree().create_timer(0.5).timeout 
	
	var anim_puerta = puerta.get_node("AnimationPlayer")
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play("abrir")
		await anim_puerta.animation_finished
	
	jugador.visible = true
	anim_gato.play("walk_up")
	
	var tween = create_tween()
	tween.tween_property(jugador, "global_position:y", jugador.global_position.y - 40, 0.5)
	await tween.finished
	
	if anim_puerta.has_animation("abrir"):
		anim_puerta.play_backwards("abrir")
		
	anim_gato.play("idle_up")
	
	jugador.set_physics_process(true)
	jugador.set_process(true)

func inicializar_puestos() -> void:
	if not ruta_npcs: return
	var cont_ex = ruta_npcs.get_node_or_null("PuntosExhibicion")
	if cont_ex:
		for marker in cont_ex.get_children():
			puestos_exhibicion[marker] = null
			
	var cont_most = ruta_npcs.get_node_or_null("PuntosMostrador")
	if cont_most:
		for marker in cont_most.get_children():
			puestos_mostrador[marker] = null

func reservar_puesto_exhibicion(npc: Node2D) -> Vector2:
	var libres: Array = []
	for marker in puestos_exhibicion:
		if puestos_exhibicion[marker] == null:
			libres.append(marker)
	if libres.size() > 0:
		var elegido: Marker2D = libres.pick_random()
		puestos_exhibicion[elegido] = npc
		return elegido.global_position
	return ruta_npcs.get_node("PuntoEntrada").global_position

func liberar_puesto_exhibicion(npc: Node2D) -> void:
	for marker in puestos_exhibicion:
		if puestos_exhibicion[marker] == npc:
			puestos_exhibicion[marker] = null

func reservar_puesto_mostrador(npc: Node2D) -> Vector2:
	for marker in puestos_mostrador:
		if puestos_mostrador[marker] == null:
			puestos_mostrador[marker] = npc
			return marker.global_position
	return ruta_npcs.get_node("PuntoEntrada").global_position

func liberar_puesto_mostrador(npc: Node2D) -> void:
	for marker in puestos_mostrador:
		if puestos_mostrador[marker] == npc:
			puestos_mostrador[marker] = null

func iniciar_generador_clientes() -> void:
	await get_tree().create_timer(2.0).timeout
	intentar_spawnear_cliente()
	
	var timer := Timer.new()
	timer.wait_time = 7.0
	timer.autostart = true
	timer.timeout.connect(intentar_spawnear_cliente)
	add_child(timer)

func intentar_spawnear_cliente() -> void:
	if clientes_en_tienda >= MAX_CLIENTES or not ruta_npcs or not puerta_npcs:
		return
		
	var roles = [0, 1, 2] # 0 = COMPRADOR, 1 = PEDIDO, 2 = CURIOSO
	var rol_elegido: int = roles[indice_rol % roles.size()]
	indice_rol += 1
	
	var nuevo_npc = escena_npc.instantiate()
	nuevo_npc.global_position = puerta_npcs.get_node("PuntoSpawn").global_position
	
	var p_entrada: Vector2 = ruta_npcs.get_node("PuntoEntrada").global_position
	nuevo_npc.inicializar_cliente(rol_elegido, puerta_npcs, p_entrada, self)
	nuevo_npc.cliente_se_fue.connect(_on_cliente_se_fue)
	
	add_child(nuevo_npc)
	clientes_en_tienda += 1

func _on_cliente_se_fue(npc: Node2D) -> void:
	liberar_puesto_exhibicion(npc)
	liberar_puesto_mostrador(npc)
	clientes_en_tienda = max(0, clientes_en_tienda - 1)

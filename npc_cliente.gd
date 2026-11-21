extends CharacterBody2D

signal cliente_se_fue(npc: Node2D)

enum Rol { COMPRADOR, PEDIDO, CURIOSO }
enum Estado { ENTRANDO, YENDO_EXHIBICION, MIRANDO, YENDO_MOSTRADOR, ESPERANDO_ATENCION, SALIENDO, CRUZANDO_PUERTA }

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var label_estado: Label = get_node_or_null("LabelEstado")

var rol_actual: Rol = Rol.COMPRADOR
var estado_actual: Estado = Estado.ENTRANDO
var velocidad: float = 35.0
var ultima_dir: String = "down"

var gestor_vivero: Node2D
var puerta_npc: Area2D
var punto_entrada: Vector2
var destino_actual: Vector2

var jugador_cerca: bool = false
var objetivo_venta: Dictionary = {}
var objetivo_pedido: Dictionary = {}

const NOMBRES_BONITOS: Dictionary = {
	"trigo_cosechado": "Trigo",
	"remolacha_cosechada": "Remolacha",
	"arbol_cosechado": "Árbol"
}

func inicializar_cliente(rol_asignado: Rol, puerta: Area2D, p_entrada: Vector2, vivero_ref: Node2D) -> void:
	rol_actual = rol_asignado
	puerta_npc = puerta
	punto_entrada = p_entrada
	gestor_vivero = vivero_ref

func _ready() -> void:
	set_mensaje("")
	iniciar_entrada()

func iniciar_entrada() -> void:
	if gestor_vivero == null and get_parent().has_method("reservar_puesto_exhibicion"):
		gestor_vivero = get_parent()
	if gestor_vivero == null:
		queue_free()
		return

	estado_actual = Estado.ENTRANDO
	collision_mask = 0
	visible = false
	ultima_dir = "down"
	
	# 1. Ubicamos al cliente oculto tras la puerta y esperamos a que se abra por completo
	if puerta_npc:
		global_position = puerta_npc.global_position
		if puerta_npc.has_method("abrir_puerta_npc"):
			await puerta_npc.abrir_puerta_npc()
		
	# 2. Ahora sí aparece y camina hacia adentro mirando de frente
	anim.stop()
	reproducir_anim("walk_down")
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "global_position", punto_entrada, 0.7)
	await tween.finished
	
	# 3. Cerramos la puerta detrás de él mientras inicia su recorrido
	if puerta_npc and puerta_npc.has_method("cerrar_puerta_npc"):
		puerta_npc.cerrar_puerta_npc()
	
	collision_mask = 1
	destino_actual = gestor_vivero.reservar_puesto_exhibicion(self)
	estado_actual = Estado.YENDO_EXHIBICION

func _physics_process(_delta: float) -> void:
	if HudGlobal.esta_juego_pausado():
		velocity = Vector2.ZERO
		anim.play("idle_" + ultima_dir)
		return

	match estado_actual:
		Estado.ENTRANDO:
			anim.play("walk_down")
		Estado.CRUZANDO_PUERTA:
			anim.play("walk_up")
		Estado.YENDO_EXHIBICION:
			if mover_hacia(destino_actual):
				evaluar_exhibicion()
		Estado.YENDO_MOSTRADOR:
			if mover_hacia(destino_actual):
				estado_actual = Estado.ESPERANDO_ATENCION
				ultima_dir = "down"
				anim.play("idle_down")
		Estado.ESPERANDO_ATENCION:
			velocity = Vector2.ZERO
			ultima_dir = "down"
			anim.play("idle_down")
			var p = get_parent().get_node_or_null("Player")
			jugador_cerca = p != null and global_position.distance_to(p.global_position) < 34.0
			if jugador_cerca:
				set_mensaje("[E]")
			else:
				set_mensaje("$" if rol_actual == Rol.COMPRADOR else "!")
		Estado.SALIENDO:
			if mover_hacia(punto_entrada):
				completar_salida()

func mover_hacia(destino: Vector2) -> bool:
	var diff: Vector2 = destino - global_position
	if diff.length() < 4.0:
		velocity = Vector2.ZERO
		return true
		
	var dir: Vector2 = diff.normalized()
	velocity = dir * velocidad
	move_and_slide()
	
	# Evasión inteligente: si choca con una planta exhibida o esquina, la rodea suavemente
	if get_slide_collision_count() > 0:
		var normal: Vector2 = get_slide_collision(0).get_normal()
		var tangente_a := Vector2(-normal.y, normal.x)
		var tangente_b := Vector2(normal.y, -normal.x)
		var dir_evasion: Vector2 = tangente_a if tangente_a.dot(dir) >= tangente_b.dot(dir) else tangente_b
		velocity = (dir_evasion * 0.85 + dir * 0.15).normalized() * velocidad
		move_and_slide()
		dir = velocity.normalized()
	
	if abs(dir.x) > abs(dir.y):
		ultima_dir = "right" if dir.x > 0 else "left"
	else:
		ultima_dir = "down" if dir.y > 0 else "up"
	anim.play("walk_" + ultima_dir)
	return false

func evaluar_exhibicion() -> void:
	estado_actual = Estado.MIRANDO
	ultima_dir = "up"
	anim.play("idle_up")
	set_mensaje("...")
	await get_tree().create_timer(1.5).timeout
	
	gestor_vivero.liberar_puesto_exhibicion(self)
	
	var disponibles: Array[Dictionary] = []
	for slot_name in HudGlobal.exhibicion_guardada:
		var item: String = HudGlobal.exhibicion_guardada[slot_name]
		if item != "":
			disponibles.append({ "slot": slot_name, "item": item })
			
	if rol_actual == Rol.COMPRADOR and disponibles.size() > 0:
		var elegido: Dictionary = disponibles.pick_random()
		var item_elegido: String = str(elegido["item"])
		var precio: int = 25
		
		for clave in HudGlobal.CATALOGO_PLANTAS:
			if HudGlobal.CATALOGO_PLANTAS[clave]["cosecha"] == item_elegido:
				precio = HudGlobal.CATALOGO_PLANTAS[clave]["precio_venta"]
				break
				
		objetivo_venta = { "slot": elegido["slot"], "item": item_elegido, "precio": precio }
		set_mensaje("¡Me gusta!")
		destino_actual = gestor_vivero.reservar_puesto_mostrador(self)
		estado_actual = Estado.YENDO_MOSTRADOR
		
	elif rol_actual == Rol.PEDIDO or (rol_actual == Rol.COMPRADOR and disponibles.size() == 0):
		rol_actual = Rol.PEDIDO
		var semilla_key: String = HudGlobal.CATALOGO_PLANTAS.keys().pick_random()
		var info: Dictionary = HudGlobal.CATALOGO_PLANTAS[semilla_key]
		var item_pedido: String = info["cosecha"]
		var cantidad: int = randi_range(1, 2)
		var recompensa: int = int(info["precio_venta"] * cantidad * 1.25)
		
		objetivo_pedido = { "item": item_pedido, "cantidad": cantidad, "recompensa": recompensa }
		set_mensaje("Encargo")
		destino_actual = gestor_vivero.reservar_puesto_mostrador(self)
		estado_actual = Estado.YENDO_MOSTRADOR
		
	else: # Rol.CURIOSO
		set_mensaje("¡Lindas!")
		await get_tree().create_timer(2.0).timeout
		iniciar_retirada()

func _unhandled_input(event: InputEvent) -> void:
	if estado_actual == Estado.ESPERANDO_ATENCION and jugador_cerca and not HudGlobal.dialogo_npc_abierto:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
			ultima_dir = "down"
			anim.play("idle_down")
			abrir_interaccion()
			get_viewport().set_input_as_handled()

func abrir_interaccion() -> void:
	if rol_actual == Rol.COMPRADOR:
		var nombre_planta: String = NOMBRES_BONITOS.get(objetivo_venta["item"], objetivo_venta["item"])
		var msg := "¡Hola! Quiero comprar el %s de exhibición por $%d Eco-Monedas." % [nombre_planta, objetivo_venta["precio"]]
		HudGlobal.mostrar_dialogo_npc(msg, _aceptar_compra, _rechazar_interaccion)
	elif rol_actual == Rol.PEDIDO:
		var nombre_planta: String = NOMBRES_BONITOS.get(objetivo_pedido["item"], objetivo_pedido["item"])
		var msg := "No veo lo que busco. ¿Me consigues %dx %s por $%d Eco-Monedas?" % [objetivo_pedido["cantidad"], nombre_planta, objetivo_pedido["recompensa"]]
		HudGlobal.mostrar_dialogo_npc(msg, _aceptar_pedido, _rechazar_interaccion)

func _aceptar_compra() -> void:
	var slot_name: String = objetivo_venta["slot"]
	if HudGlobal.exhibicion_guardada.get(slot_name, "") == objetivo_venta["item"]:
		HudGlobal.agregar_monedas(objetivo_venta["precio"])
		var nodo_mesa = get_parent().get_node_or_null(slot_name)
		if nodo_mesa and nodo_mesa.has_method("vaciar_por_venta"):
			nodo_mesa.vaciar_por_venta()
		set_mensaje("¡Gracias!")
	else:
		set_mensaje("¡Ya no está!")
	iniciar_retirada()

func _aceptar_pedido() -> void:
	HudGlobal.pedidos_activos.append(objetivo_pedido.duplicate())
	set_mensaje("¡Volveré!")
	iniciar_retirada()

func _rechazar_interaccion() -> void:
	set_mensaje("¡Adiós!")
	iniciar_retirada()

func iniciar_retirada() -> void:
	gestor_vivero.liberar_puesto_exhibicion(self)
	gestor_vivero.liberar_puesto_mostrador(self)
	estado_actual = Estado.SALIENDO
	await get_tree().create_timer(1.0).timeout
	set_mensaje("")

func completar_salida() -> void:
	estado_actual = Estado.MIRANDO # Espera quieto mirando a la puerta mientras se abre
	ultima_dir = "up"
	anim.play("idle_up")
	collision_mask = 0
	
	# 1. Esperamos a que se abra la puerta antes de cruzar
	if puerta_npc and puerta_npc.has_method("abrir_puerta_npc"):
		await puerta_npc.abrir_puerta_npc()
		
	# 2. Camina hacia el umbral mirando hacia arriba (de espaldas)
	estado_actual = Estado.CRUZANDO_PUERTA
	var tween := create_tween()
	tween.tween_property(self, "global_position", puerta_npc.global_position, 0.4)
	await tween.finished
	visible = false
	
	# 3. Cierra la puerta y libera el nodo
	if puerta_npc and puerta_npc.has_method("cerrar_puerta_npc"):
		await puerta_npc.cerrar_puerta_npc()
	
	cliente_se_fue.emit(self)
	queue_free()

func set_mensaje(texto: String) -> void:
	if label_estado:
		label_estado.text = texto

func reproducir_anim(nombre: String) -> void:
	for anim_name in anim.get_animation_list():
		if anim_name.strip_edges() == nombre:
			anim.play(anim_name)
			return
	if anim.has_animation("idle_down"):
		anim.play("idle_down")

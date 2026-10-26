extends Area2D

@export_file("*.tscn") var escena_destino: String
@export var direccion_movimiento: Vector2 = Vector2(0, -40)

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer 

var jugador_cerca: Node2D = null
var viajando: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		jugador_cerca = body

func _on_body_exited(body: Node2D) -> void:
	if body == jugador_cerca:
		jugador_cerca = null

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A and jugador_cerca and not viajando:
			iniciar_transicion()

func iniciar_transicion() -> void:
	viajando = true
	jugador_cerca.set_physics_process(false) 
	
	# 1. Abrimos la puerta y ESPERAMOS a que termine
	if anim.has_animation("abrir"):
		anim.play("abrir")
		await anim.animation_finished # Esto evita que el gato traspase la puerta cerrada
	
	# 2. Hacemos que el gato mueva las patitas dependiendo de si va arriba o abajo
	var anim_gato = jugador_cerca.get_node("AnimationPlayer")
	if direccion_movimiento.y < 0:
		anim_gato.play("walk_up")
	else:
		anim_gato.play("walk_down")
	
	# 3. Movemos al gato
	var tween = create_tween()
	tween.tween_property(jugador_cerca, "global_position", jugador_cerca.global_position + direccion_movimiento, 0.5)
	await tween.finished
	
	# 4. Detenemos la animación del gato
	if direccion_movimiento.y < 0:
		anim_gato.play("idle_up")
	else:
		anim_gato.play("idle_down")
	
	# 5. Cambiamos de mapa
	if escena_destino != "":
		Transicion.cambiar_escena(escena_destino)

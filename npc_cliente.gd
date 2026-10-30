extends CharacterBody2D

@onready var anim = $AnimationPlayer

var direccion: Vector2 = Vector2.ZERO
var velocidad: float = 30.0 # Más lento que el jugador

func _ready() -> void:
	# Creamos un temporizador por código que cambia de dirección cada 2 segundos
	var timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.timeout.connect(_elegir_nueva_direccion)
	add_child(timer)
	
	_elegir_nueva_direccion() # Elegir la primera vez

func _physics_process(delta: float) -> void:
	velocity = direccion * velocidad
	move_and_slide()
	animar_movimiento()

func _elegir_nueva_direccion() -> void:
	# Elige un número al azar entre 0 y 4
	var opcion = randi() % 5
	
	match opcion:
		0: direccion = Vector2.UP
		1: direccion = Vector2.DOWN
		2: direccion = Vector2.LEFT
		3: direccion = Vector2.RIGHT
		4: direccion = Vector2.ZERO # Quedarse quieto

func animar_movimiento() -> void:
	if direccion == Vector2.ZERO:
		anim.play("idle_down") # Por ahora lo dejamos mirando abajo al parar
	elif direccion.y < 0:
		anim.play("walk_up")
	elif direccion.y > 0:
		anim.play("walk_down")
	elif direccion.x < 0:
		anim.play("walk_left")
	elif direccion.x > 0:
		anim.play("walk_right")

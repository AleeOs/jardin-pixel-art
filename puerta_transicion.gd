extends Area2D

@export_file("*.tscn") var escena_destino: String
@export var direccion_movimiento: Vector2 = Vector2(0, -40)
@export var es_puerta_npc: bool = false

@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer 

var jugador_cerca: Node2D = null
var viajando: bool = false

func _ready() -> void:
	if not es_puerta_npc:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		jugador_cerca = body
		HudGlobal.registrar_puerta_cercana(self)
		if direccion_movimiento.y > 0:
			HudGlobal.set_hotbar_transparente(true)

func _on_body_exited(body: Node2D) -> void:
	if body == jugador_cerca:
		jugador_cerca = null
		HudGlobal.registrar_puerta_cercana(null)
		if direccion_movimiento.y > 0:
			HudGlobal.set_hotbar_transparente(false)

func _exit_tree() -> void:
	if jugador_cerca != null:
		HudGlobal.registrar_puerta_cercana(null)
		if direccion_movimiento.y > 0:
			HudGlobal.set_hotbar_transparente(false)
		
func _unhandled_input(event: InputEvent) -> void:
	if es_puerta_npc: return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_A and jugador_cerca and not viajando:
			iniciar_transicion()

func iniciar_transicion() -> void:
	viajando = true
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	jugador_cerca.set_physics_process(false) 
	
	if anim.has_animation("abrir"):
		anim.play("abrir")
		await anim.animation_finished
	
	var anim_gato = jugador_cerca.get_node("AnimationPlayer")
	anim_gato.play("walk_up" if direccion_movimiento.y < 0 else "walk_down")
	
	var tween = create_tween()
	tween.tween_property(jugador_cerca, "global_position", jugador_cerca.global_position + direccion_movimiento, 0.5)
	await tween.finished
	
	anim_gato.play("idle_up" if direccion_movimiento.y < 0 else "idle_down")
	
	if direccion_movimiento.y > 0:
		HudGlobal.set_hotbar_transparente(false)
	if escena_destino != "":
		Transicion.cambiar_escena(escena_destino)

# --- ANIMACIÓN AUTOMÁTICA PARA ENTRADA/SALIDA DE NPCS ---
# --- CONTROL SINCRONIZADO PARA ENTRADA/SALIDA DE NPCS ---
var npcs_usando_puerta: int = 0

func abrir_puerta_npc() -> void:
	npcs_usando_puerta += 1
	$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
	if npcs_usando_puerta == 1 and anim.has_animation("abrir"):
		anim.play("abrir")
		await anim.animation_finished

func cerrar_puerta_npc() -> void:
	npcs_usando_puerta = max(0, npcs_usando_puerta - 1)
	if npcs_usando_puerta == 0:
		if anim.has_animation("abrir"):
			anim.play_backwards("abrir")
			await anim.animation_finished
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)
		

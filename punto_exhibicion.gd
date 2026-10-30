extends Area2D

@onready var sprite_planta = $Sprite2D

var jugador_cerca: Node2D = null
var ocupado: bool = false
var nombre_planta_exhibida: String = ""

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
		if event.keycode == KEY_P and jugador_cerca:
			interactuar_exhibicion()

func interactuar_exhibicion() -> void:
	var hud = HudGlobal 

	if ocupado:
		# QUITAR PLANTA
		hud.agregar_cosecha(nombre_planta_exhibida)
		sprite_planta.texture = null
		nombre_planta_exhibida = ""
		ocupado = false
		
	else:
		# PONER PLANTA
		var item_seleccionado = hud.hotbar_items[hud.slot_seleccionado]
		
		# Verifica que tengas una planta cosechada en la mano (no una semilla)
		if item_seleccionado != "" and item_seleccionado in hud.lista_cosechas:
			hud.gastar_semilla(item_seleccionado)
			nombre_planta_exhibida = item_seleccionado
			ocupado = true
			
			# Reutiliza tu brillante sistema de texturas
			sprite_planta.texture = hud.iconos_items[item_seleccionado]

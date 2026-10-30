extends CharacterBody2D

@export var speed: float = 50.0

# Exportamos las dos capas para que las plantas no borren la tierra arada
@export var cultivo_layer: TileMapLayer
@export var plantas_layer: TileMapLayer

# Escena de la espiga flotante de trigo
@export var trigo_item_scene: PackedScene

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer

var last_dir: String = "down"
var is_acting: bool = false # Bloquea el movimiento mientras realiza una acción
var menu_abierto: bool = false # Bloquea el movimiento cuando el inventario está visible

# DATOS DEL TILESET
const ID_TIERRA_SOURCE: int = 0  # ID de la fuente de la textura de tierra

# Variantes aleatorias de casillas para arar
const VARIANTES_TIERRA: Array[Vector2i] = [
	Vector2i(0, 0),
	Vector2i(1, 0),
	Vector2i(2, 0),
	Vector2i(0, 1),
	Vector2i(1, 1),
	Vector2i(2, 1)
]

const ID_PLANTAS: int = 1
const COORD_SEMILLA := Vector2i(1, 0)
const COORD_CRECIENDO := Vector2i(2, 0)
const COORD_MADURO := Vector2i(4, 0)

# Diccionario para controlar la etapa de cada planta
# 1 = Semilla, 2 = Brote mediano, 3 = Trigo maduro


# INVENTARIO Y EQUIPAMIENTO
var inventario_trigo: int = 0
var semilla_equipada: String = "" # Ahora empieza sin nada en las manos

func _ready() -> void:
	# Nos conectamos directamente al Autoload global
	if HudGlobal.has_signal("estado_inventario_cambiado"):
		HudGlobal.estado_inventario_cambiado.connect(_on_estado_inventario_cambiado)
		
	if HudGlobal.has_signal("semilla_equipada"):
		HudGlobal.semilla_equipada.connect(_on_semilla_equipada)
		
	# Forzamos a que el gato lea qué tiene en la mano al apenas arrancar
	if HudGlobal.hotbar_items.size() > 0:
		semilla_equipada = HudGlobal.hotbar_items[HudGlobal.slot_seleccionado]


# Esta función actualiza las manos del gato cuando haces clic en el HUD
func _on_semilla_equipada(tipo: String) -> void:
	semilla_equipada = tipo
	
func _on_estado_inventario_cambiado(abierto: bool) -> void:
	menu_abierto = abierto

func _physics_process(_delta: float) -> void:
	# Si está ejecutando animación de herramienta o con el inventario abierto, no se mueve
	if is_acting or menu_abierto:
		velocity = Vector2.ZERO
		
		# Solo reproducir "idle" si el menú está abierto y NO está usando una herramienta
		if menu_abierto and not is_acting:
			anim.play("idle_" + last_dir)
			
		move_and_slide()
		return
		
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if direction != Vector2.ZERO:
		velocity = direction * speed
		
		if abs(direction.x) > abs(direction.y):
			if direction.x > 0:
				anim.play("walk_right")
				last_dir = "right"
			else:
				anim.play("walk_left")
				last_dir = "left"
		else:
			if direction.y > 0:
				anim.play("walk_down")
				last_dir = "down"
			else:
				anim.play("walk_up")
				last_dir = "up"
	else:
		velocity = Vector2.ZERO
		anim.play("idle_" + last_dir)

	move_and_slide()

# Detectar teclas de interacción
func _unhandled_input(event: InputEvent) -> void:
	if is_acting or menu_abierto:
		return
		
	if event.is_action_pressed("ui_accept"): # ESPACIO para arar
		iniciar_accion("action_")
	elif event.is_action_pressed("plantar"): # E para sembrar
		plantar_semilla()
	elif event.is_action_pressed("regar"): # R para regar
		iniciar_accion("water_")
	elif event.is_action_pressed("cosechar"): # F para cosechar
		cosechar_planta()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		intentar_exhibir()

func iniciar_accion(prefix: String) -> void:
	is_acting = true
	var anim_name := prefix + last_dir
	anim.play(anim_name)
	
	if not anim.is_connected("animation_finished", _on_animation_finished):
		anim.connect("animation_finished", _on_animation_finished)

func _on_animation_finished(_anim_name: String) -> void:
	is_acting = false

# Calcular la coordenada de la casilla frente al personaje
func obtener_coordenada_frente(layer: TileMapLayer) -> Vector2i:
	var target_vector := Vector2.ZERO
	match last_dir:
		"down": target_vector = Vector2.DOWN
		"up": target_vector = Vector2.UP
		"left": target_vector = Vector2.LEFT
		"right": target_vector = Vector2.RIGHT
		
	var target_pos := global_position + (target_vector * 16.0)
	return layer.local_to_map(layer.to_local(target_pos))

# Función ejecutada por la Pista de Método de la animación de arar (Espacio)
func arar_tierra() -> void:
	if not cultivo_layer: return
	var tile_coord := obtener_coordenada_frente(cultivo_layer)
	var tile_elegido: Vector2i = VARIANTES_TIERRA.pick_random()
	cultivo_layer.set_cell(tile_coord, ID_TIERRA_SOURCE, tile_elegido)
	
	# NUEVO: Guardar en el cerebro global
	HudGlobal.tierra_guardada[tile_coord] = tile_elegido
	
# Función ejecutada al presionar la tecla E
func plantar_semilla() -> void:
	if semilla_equipada == "" or not cultivo_layer or not plantas_layer: return
	
	# NUEVA VALIDACIÓN: Si el ítem no está en la lista de semillas, no hacemos nada
	if not semilla_equipada in HudGlobal.lista_semillas:
		return
		
	var tile_coord := obtener_coordenada_frente(cultivo_layer)
	var source_id := cultivo_layer.get_cell_source_id(tile_coord)
	
	if source_id != -1 and not HudGlobal.plantas_guardadas.has(tile_coord):
		plantas_layer.set_cell(tile_coord, ID_PLANTAS, COORD_SEMILLA)
		HudGlobal.plantas_guardadas[tile_coord] = 1 # 1 = Semilla
		HudGlobal.gastar_semilla(semilla_equipada)

# Función ejecutada por la Pista de Método de la animación de regar (R)
func regar_tierra() -> void:
	if not plantas_layer: return
	var tile_coord := obtener_coordenada_frente(plantas_layer)
	
	if HudGlobal.plantas_guardadas.has(tile_coord):
		var estado_actual: int = HudGlobal.plantas_guardadas[tile_coord]
		if estado_actual == 1:
			iniciar_timer_crecimiento(tile_coord, 5.0, 2, COORD_CRECIENDO)
		elif estado_actual == 2:
			iniciar_timer_crecimiento(tile_coord, 5.0, 3, COORD_MADURO)
			
func iniciar_timer_crecimiento(coord: Vector2i, tiempo: float, nuevo_estado: int, nueva_coord_atlas: Vector2i) -> void:
	var timer := get_tree().create_timer(tiempo)
	await timer.timeout
	if HudGlobal.plantas_guardadas.has(coord):
		plantas_layer.set_cell(coord, ID_PLANTAS, nueva_coord_atlas)
		HudGlobal.plantas_guardadas[coord] = nuevo_estado
		
# Función ejecutada al presionar la tecla F
func cosechar_planta() -> void:
	if not plantas_layer: return
	var tile_coord := obtener_coordenada_frente(plantas_layer)
	
	if HudGlobal.plantas_guardadas.has(tile_coord) and HudGlobal.plantas_guardadas[tile_coord] == 3:
		plantas_layer.set_cell(tile_coord, -1, Vector2i(-1, -1))
		HudGlobal.plantas_guardadas.erase(tile_coord) # NUEVO: Borrar del global
		
		if trigo_item_scene:
			var trigo_instancia := trigo_item_scene.instantiate() as Node2D
			trigo_instancia.global_position = plantas_layer.to_global(plantas_layer.map_to_local(tile_coord))
			get_parent().add_child(trigo_instancia)
func intentar_exhibir() -> void:
	var target_vector := Vector2.ZERO
	match last_dir:
		"down": target_vector = Vector2.DOWN
		"up": target_vector = Vector2.UP
		"left": target_vector = Vector2.LEFT
		"right": target_vector = Vector2.RIGHT
		
	# Calculamos el pixel exacto que está un pasito frente al gato
	var target_pos := global_position + (target_vector * 16.0)
	
	# Buscamos en el grupo si hay un punto de exhibición cerca de esa posición
	var puntos = get_tree().get_nodes_in_group("punto_exhibicion")
	for punto in puntos:
		if punto.global_position.distance_to(target_pos) < 12.0:
			punto.interactuar_exhibicion()
			return

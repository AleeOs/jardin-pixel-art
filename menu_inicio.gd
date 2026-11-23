extends Control

@onready var velo_contraste: ColorRect = find_child("VeloContraste", true, false)
@onready var escena_jardin: Node2D = find_child("EscenaJardin", true, false)
@onready var escena_vivero: Node2D = find_child("EscenaVivero", true, false)
@onready var camara_diorama: Camera2D = find_child("CamaraDiorama", true, false)

@onready var label_titulo: Label = find_child("LabelTitulo", true, false)
@onready var btn_continuar: BaseButton = find_child("BotonContinuar", true, false)
@onready var btn_nueva: BaseButton = find_child("BotonNuevaPartida", true, false)
@onready var btn_cargar: BaseButton = find_child("BotonCargarPartida", true, false)
@onready var btn_salir: BaseButton = find_child("BotonSalir", true, false)
@onready var panel_slots: Control = find_child("PanelSlotsInicio", true, false)

# Ajusta estas coordenadas al centro visual de cada escenario en tu SubViewport
const POS_CAMARA_JARDIN := Vector2(225, 110)
const POS_CAMARA_VIVERO := Vector2(552, 470)

var ultimo_slot: int = 0
var mostrando_jardin: bool = true

func _ready() -> void:
	HudGlobal.set_hud_visible(false)
	HudGlobal.atenuar_musica(false)
	ultimo_slot = HudGlobal.obtener_ultimo_slot_jugado()
	
	if escena_jardin: escena_jardin.visible = true
	if escena_vivero: escena_vivero.visible = false
	if camara_diorama: camara_diorama.position = POS_CAMARA_JARDIN
	
	_animar_titulo()
	_iniciar_ciclo_diorama()
	
	if btn_continuar:
		btn_continuar.disabled = (ultimo_slot == 0)
		btn_continuar.modulate = Color(1, 1, 1) if ultimo_slot > 0 else Color(0.65, 0.65, 0.65, 0.75)
		btn_continuar.pressed.connect(_on_continuar)
		if ultimo_slot > 0:
			_configurar_hover_boton(btn_continuar)
			
	if btn_nueva:
		btn_nueva.pressed.connect(_on_nueva_partida)
		_configurar_hover_boton(btn_nueva)
		
	if btn_cargar:
		btn_cargar.pressed.connect(_on_abrir_cargar)
		_configurar_hover_boton(btn_cargar)
		
	if btn_salir:
		btn_salir.visible = not OS.has_feature("web")
		btn_salir.pressed.connect(func(): get_tree().quit())
		_configurar_hover_boton(btn_salir)
		
	if panel_slots:
		panel_slots.slot_seleccionado.connect(_on_slot_cargado)

func _iniciar_ciclo_diorama() -> void:
	if not escena_jardin or not escena_vivero or not velo_contraste:
		return
	while is_inside_tree():
		await get_tree().create_timer(8.0).timeout
		if not is_inside_tree():
			break
		# Fundido a oscuro suave
		var t_out := create_tween()
		t_out.tween_property(velo_contraste, "color:a", 0.95, 0.6)
		await t_out.finished
		
		mostrando_jardin = !mostrando_jardin
		escena_jardin.visible = mostrando_jardin
		escena_vivero.visible = !mostrando_jardin
		if camara_diorama:
			camara_diorama.position = POS_CAMARA_JARDIN if mostrando_jardin else POS_CAMARA_VIVERO
			
		# Fundido de regreso al velo normal (50/255 ≈ 0.20)
		var t_in := create_tween()
		t_in.tween_property(velo_contraste, "color:a", 0.20, 0.6)
		await t_in.finished

func _animar_titulo() -> void:
	if not label_titulo:
		return
	await get_tree().process_frame
	var y_base: float = label_titulo.position.y
	var tween := create_tween().set_loops()
	tween.tween_property(label_titulo, "position:y", y_base - 4.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(label_titulo, "position:y", y_base + 4.0, 1.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _configurar_hover_boton(boton: BaseButton) -> void:
	boton.resized.connect(func(): boton.pivot_offset = boton.size * 0.5)
	boton.pivot_offset = boton.size * 0.5
	boton.mouse_entered.connect(func():
		var t := create_tween()
		t.tween_property(boton, "scale", Vector2(1.05, 1.05), 0.1)
	)
	boton.mouse_exited.connect(func():
		var t := create_tween()
		t.tween_property(boton, "scale", Vector2(1.0, 1.0), 0.1)
	)

func _on_continuar() -> void:
	if ultimo_slot > 0:
		HudGlobal.cargar_desde_slot(ultimo_slot)

func _on_nueva_partida() -> void:
	HudGlobal.reiniciar_estado_partida()
	if has_node("/root/Transicion"):
		Transicion.viene_de_transicion = false
	HudGlobal.set_hud_visible(true)
	get_tree().change_scene_to_file("res://jardin.tscn")

func _on_abrir_cargar() -> void:
	if panel_slots:
		panel_slots.abrir(panel_slots.Modo.CARGAR)

func _on_slot_cargado(num_slot: int, _modo: int) -> void:
	HudGlobal.cargar_desde_slot(num_slot)

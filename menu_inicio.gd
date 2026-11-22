extends Control

@onready var btn_continuar: BaseButton = find_child("BotonContinuar", true, false)
@onready var btn_nueva: BaseButton = find_child("BotonNuevaPartida", true, false)
@onready var btn_cargar: BaseButton = find_child("BotonCargarPartida", true, false)
@onready var btn_salir: BaseButton = find_child("BotonSalir", true, false)
@onready var panel_slots: Control = find_child("PanelSlotsInicio", true, false)

var ultimo_slot: int = 0

func _ready() -> void:
	HudGlobal.set_hud_visible(false)
	ultimo_slot = HudGlobal.obtener_ultimo_slot_jugado()
	
	if btn_continuar:
		btn_continuar.disabled = (ultimo_slot == 0)
		btn_continuar.modulate = Color(1, 1, 1) if ultimo_slot > 0 else Color(0.6, 0.6, 0.6, 0.7)
		btn_continuar.pressed.connect(_on_continuar)
		
	if btn_nueva:
		btn_nueva.pressed.connect(_on_nueva_partida)
		
	if btn_cargar:
		btn_cargar.pressed.connect(_on_abrir_cargar)
		
	if btn_salir:
		btn_salir.visible = not OS.has_feature("web")
		btn_salir.pressed.connect(func(): get_tree().quit())
		
	if panel_slots:
		panel_slots.slot_seleccionado.connect(_on_slot_cargado)

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

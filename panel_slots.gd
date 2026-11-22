extends Control

enum Modo { CARGAR, GUARDAR }

signal slot_seleccionado(num_slot: int, modo: Modo)

@onready var label_titulo: Label = find_child("LabelTitulo", true, false)
@onready var boton_cerrar: BaseButton = find_child("BotonCerrar", true, false)

var modo_actual: Modo = Modo.CARGAR

func _ready() -> void:
	visible = false
	if boton_cerrar:
		boton_cerrar.pressed.connect(cerrar)
	for i in range(1, 4):
		var btn := find_child("Slot" + str(i), true, false) as BaseButton
		if btn:
			btn.pressed.connect(_on_slot_presionado.bind(i))

func abrir(modo: Modo) -> void:
	modo_actual = modo
	if label_titulo:
		label_titulo.text = "CARGAR PARTIDA" if modo == Modo.CARGAR else "GUARDAR PARTIDA"
		
	for i in range(1, 4):
		var btn := find_child("Slot" + str(i), true, false) as BaseButton
		if not btn: continue
		var lbl := btn.find_child("TextoSlot", true, false) as Label
		var info: Dictionary = HudGlobal.obtener_info_slot(i)
		
		if info.get("ocupado", false):
			btn.disabled = false
			btn.modulate = Color(1, 1, 1)
			if lbl:
				lbl.text = "Ranura %d: $%d (%s)" % [i, info["monedas"], str(info["fecha"]).substr(0, 16)]
		else:
			btn.disabled = (modo == Modo.CARGAR)
			btn.modulate = Color(0.6, 0.6, 0.6, 0.8) if modo == Modo.CARGAR else Color(1, 1, 1)
			if lbl:
				lbl.text = "Ranura %d: [ Vacia ]" % i
				
	visible = true

func cerrar() -> void:
	visible = false

func _on_slot_presionado(num_slot: int) -> void:
	cerrar()
	slot_seleccionado.emit(num_slot, modo_actual)

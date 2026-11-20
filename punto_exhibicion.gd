extends StaticBody2D

@onready var sprite_planta = $Sprite2D
@onready var colision = $CollisionShape2D

var ocupado: bool = false
var nombre_planta_exhibida: String = ""

func _ready() -> void:
	if HudGlobal.exhibicion_guardada.has(name) and HudGlobal.exhibicion_guardada[name] != "":
		nombre_planta_exhibida = HudGlobal.exhibicion_guardada[name]
		ocupado = true
		aplicar_visual_exhibicion(nombre_planta_exhibida)
		colision.disabled = false
	else:
		colision.disabled = true 

func aplicar_visual_exhibicion(tipo: String) -> void:
	sprite_planta.texture = HudGlobal.texturas_exhibicion[tipo]
	sprite_planta.offset.y = -8.0 if tipo == "arbol_cosechado" else 0.0

func interactuar_exhibicion() -> void:
	var hud = HudGlobal 

	if ocupado:
		hud.agregar_cosecha(nombre_planta_exhibida)
		if hud.hotbar_items[hud.slot_seleccionado] == "":
			hud.hotbar_items[hud.slot_seleccionado] = nombre_planta_exhibida
			hud.dibujar_items_hotbar()
			hud.semilla_equipada.emit(nombre_planta_exhibida)
			
		sprite_planta.texture = null
		sprite_planta.offset.y = 0.0
		nombre_planta_exhibida = ""
		ocupado = false
		colision.disabled = true 
		hud.exhibicion_guardada[name] = ""
	else:
		var item_seleccionado = hud.hotbar_items[hud.slot_seleccionado]
		if item_seleccionado != "" and item_seleccionado in hud.lista_cosechas:
			hud.gastar_semilla(item_seleccionado)
			nombre_planta_exhibida = item_seleccionado
			ocupado = true
			aplicar_visual_exhibicion(item_seleccionado)
			colision.disabled = false 
			hud.exhibicion_guardada[name] = item_seleccionado

extends StaticBody2D

@onready var sprite_planta = $Sprite2D
@onready var colision = $CollisionShape2D

var ocupado: bool = false
var nombre_planta_exhibida: String = ""

func _ready() -> void:
	# REVISAR MEMORIA: Preguntamos si esta mesa específica (usando su nombre) tiene algo guardado
	if HudGlobal.exhibicion_guardada.has(name) and HudGlobal.exhibicion_guardada[name] != "":
		nombre_planta_exhibida = HudGlobal.exhibicion_guardada[name]
		ocupado = true
		sprite_planta.texture = HudGlobal.texturas_exhibicion[nombre_planta_exhibida]
		colision.disabled = false # Volvemos a hacerla sólida
	else:
		colision.disabled = true 

func interactuar_exhibicion() -> void:
	var hud = HudGlobal 

	if ocupado:
		# QUITAR PLANTA Y DEVOLVERLA AL INVENTARIO
		hud.agregar_cosecha(nombre_planta_exhibida)
		
		# Equipar automáticamente en el hotbar si la casilla actual está vacía
		if hud.hotbar_items[hud.slot_seleccionado] == "":
			hud.hotbar_items[hud.slot_seleccionado] = nombre_planta_exhibida
			hud.dibujar_items_hotbar()
			hud.semilla_equipada.emit(nombre_planta_exhibida)
			
		sprite_planta.texture = null
		nombre_planta_exhibida = ""
		ocupado = false
		colision.disabled = true 
		
		# BORRAR DE LA MEMORIA GLOBAL
		hud.exhibicion_guardada[name] = ""
		
	else:
		# PONER PLANTA
		var item_seleccionado = hud.hotbar_items[hud.slot_seleccionado]
		
		if item_seleccionado != "" and item_seleccionado in hud.lista_cosechas:
			hud.gastar_semilla(item_seleccionado)
			nombre_planta_exhibida = item_seleccionado
			ocupado = true
			sprite_planta.texture = hud.texturas_exhibicion[item_seleccionado]
			colision.disabled = false 
			
			# GUARDAR EN LA MEMORIA GLOBAL (usando el nombre de este nodo)
			hud.exhibicion_guardada[name] = item_seleccionado

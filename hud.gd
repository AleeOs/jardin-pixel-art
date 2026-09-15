extends CanvasLayer

@onready var cantidad_label: Label = $InventarioUI/MarcoUI/CantidadText

func actualizar_trigo(cantidad: int) -> void:
	if cantidad_label:
		cantidad_label.text = "x" + str(cantidad)

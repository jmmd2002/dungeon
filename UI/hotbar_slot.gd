class_name HotbarSlot
extends PanelContainer

@onready var number_label: Label = $Margin/VBox/Number
@onready var name_label: Label = $Margin/VBox/ItemName


func show_slot(number: int, item: Item, selected: bool) -> void:
	number_label.text = str(number)
	name_label.text = item.display_name if item != null else ""
	modulate = Color.WHITE if selected else Color(1, 1, 1, 0.5)

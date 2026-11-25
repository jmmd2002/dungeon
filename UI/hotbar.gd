class_name Hotbar
extends HBoxContainer

const SLOT: PackedScene = preload(P.HOTBAR_SLOT)

var _inventory: Inventory

func watch(inventory: Inventory) -> void:
	_inventory = inventory # load inv
	for i: int in Inventory.SIZE:
		add_child(SLOT.instantiate()) #add slots
	# Repaint when inventory changes
	inventory.changed.connect(_refresh) 
	_refresh()

func _refresh() -> void:
	for slot: int in Inventory.SIZE:
		var item: Item = Game.items.get_item(_inventory.slots[slot])
		var box: HotbarSlot = get_child(slot)
		box.show_slot(slot + 1, item, slot == _inventory.selected_slot)

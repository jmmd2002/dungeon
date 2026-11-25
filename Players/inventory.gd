class_name Inventory
extends Node

signal changed

const SIZE: int = 4

# Item IDs stored in inv; 0 means empty
# Host sets each players inventory
var slots: PackedInt32Array = PackedInt32Array():
	set(value):
		slots = value
		changed.emit()
var selected_slot: int = 0:
	set(value):
		selected_slot = value
		changed.emit()

# Inventory owner
@onready var player: Player = get_parent() as Player


#############################
# Setup and logic loop
#############################

func _init() -> void:
	slots.resize(SIZE)

func _process(_delta: float) -> void:

	# Show selected item
	for slot: int in SIZE:
		var item: Item = Game.items.get_item(slots[slot]) # null for empty slots
		if item != null:
			item.follow_hand(player.hold_point.global_transform, slot == selected_slot)


##############################
# Getters
##############################

# null if the selected slot is empty or not spawned
func get_held_item() -> Item:
	return Game.items.get_item(slots[selected_slot])

#############################
# Setters
#############################

func try_pickup(item: Item) -> void:
	_pickup.rpc_id(1, item.name.to_int(), selected_slot)


#############################
# Player control
#############################

func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return # end early if not controlling

	if event.is_action_pressed("drop"):
		_drop_item()
	elif event.is_action_pressed("slot_next"):
		_select_slot(selected_slot + 1)
	elif event.is_action_pressed("slot_previous"):
		_select_slot(selected_slot - 1)
	else:
		var slot: int = _number_key_slot(event)
		if slot != -1:
			_select_slot(slot)
			
func _select_slot(slot: int) -> void:
	selected_slot = posmod(slot, SIZE) # wrap around

func _drop_item() -> void:
	if get_held_item() != null:
		_drop.rpc_id(1, selected_slot)

# Host controlls pickups
@rpc("any_peer", "call_local", "reliable")
func _pickup(item_id: int, slot: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return # Players can only ask for themselves
	if slot < 0 or slot >= SIZE:
		return # Bad request
	var item: Item = Game.items.get_item(item_id)
	if item == null:
		return # Bad request
	if slots[slot] != 0 or not player.interactor.can_reach(item.global_position):
		return # Slot is full or item is too far away
	if item.request_pickup(): # ask item to get picked up
		_set_slot(slot, item_id)


# Host controlls drops
@rpc("any_peer", "call_local", "reliable")
func _drop(slot: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return # Players can only ask for themselves
	if slot < 0 or slot >= SIZE:
		return # Bad request
	var item: Item = Game.items.get_item(slots[slot])
	if item == null:
		return # Slot is empty
	_set_slot(slot, 0)
	item.request_drop() #ask item to get dropped

##############################
# Internal helpers
##############################

func _number_key_slot(event: InputEvent) -> int:
	for slot: int in SIZE:
		if event.is_action_pressed("slot_%d" % (slot + 1)):
			return slot
	return -1

func _set_slot(slot: int, item_id: int) -> void:

	# New array for sync to see the change
	var new_slots: PackedInt32Array = slots.duplicate()
	new_slots[slot] = item_id
	slots = new_slots

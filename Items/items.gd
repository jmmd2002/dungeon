extends Node3D

const ITEM: PackedScene = preload(P.ITEM)

var _next_id: int = 1 # items id

func _ready() -> void:
	NW.server_started.connect(_on_server_started)

func _on_server_started() -> void:
	spawn_item(Vector3(0, 0.15, 0)) # Test item until the facility spawns them

# Host only
func spawn_item(spawn_position: Vector3) -> Item:
	var item: Item = ITEM.instantiate()
	item.name = str(_next_id)
	_next_id += 1
	item.position = spawn_position
	add_child(item, true)
	return item

# Returns null if there's no item with this ID, so it's safe to use with IDs from clients
func get_item(id: int) -> Item:
	return get_node_or_null(str(id)) as Item

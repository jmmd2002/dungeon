extends Node3D

const PLAYER: PackedScene = preload(P.PLAYER)

############################3
# Initialization
#############################

func _ready() -> void:
	NW.server_started.connect(_on_server_started)

func _on_server_started() -> void:
	multiplayer.peer_connected.connect(add_player)
	multiplayer.peer_disconnected.connect(remove_player)
	add_player(1) # The host is always peer 1

####################################
# API
####################################

func add_player(id: int) -> void:
	var player: Node3D = PLAYER.instantiate()
	player.name = str(id)
	player.position = Vector3(randf_range(-3, 3), 1, randf_range(-3, 3))
	add_child(player, true) # node name = id

func remove_player(id: int) -> void:
	var player: Player = get_player(id)
	var items: Node = get_tree().get_first_node_in_group("items")
	for item_id: int in player.inventory:
		var item: Item = items.get_item(item_id)
		if item != null:
			item.queue_free() # Items disappear with the player, and the spawner removes them everywhere
	player.queue_free()

func get_player(id: int) -> Player:
	return get_node(str(id)) as Player

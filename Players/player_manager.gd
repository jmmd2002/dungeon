class_name PlayerManager
extends Node3D

const PLAYER: PackedScene = preload(P.PLAYER)

#############################
# Initialization
#############################

func _enter_tree() -> void:
	Game.players = self

func _exit_tree() -> void:
	Game.players = null

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
	var player: Player = PLAYER.instantiate()
	player.name = str(id)
	player.position = Vector3(randf_range(-3, 3), 5, randf_range(-3, 3))
	
	add_child(player, true) # node name = id

func remove_player(id: int) -> void:
	var player: Player = get_player(id)
	for item_id: int in player.inventory.slots:
		var item: Item = Game.items.get_item(item_id)
		if item != null:
			item.queue_free() # Items disappear with the player, and the spawner removes them everywhere
	player.queue_free()

func get_player(id: int) -> Player:
	return get_node(str(id)) as Player

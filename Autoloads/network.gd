extends Node

signal server_started
signal connected_to_host
signal connection_failed
signal connection_lost

const PORT: int = 7777

func _ready() -> void:

	# Set signals
	multiplayer.connected_to_server.connect(connected_to_host.emit)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

###########################################
# API
###########################################

func host() -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_server(PORT)
	if error != OK: # warn if server could not be started
		push_warning("Could not start server: %s" % error_string(error))
		return error

	# Assign peer and emit signal
	multiplayer.multiplayer_peer = peer
	server_started.emit()
	return OK

func join(address: String) -> Error:
	var peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
	var error: Error = peer.create_client(address, PORT)
	if error != OK: # warn if client could not be started
		push_warning("Could not start client: %s" % error_string(error))
		return error
	multiplayer.multiplayer_peer = peer
	return OK

#####################################
# Internal helpers
#####################################

func _on_connection_failed() -> void:
	multiplayer.multiplayer_peer = null
	connection_failed.emit()

func _on_server_disconnected() -> void:
	multiplayer.multiplayer_peer = null
	connection_lost.emit()

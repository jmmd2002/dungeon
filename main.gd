extends Node

var started: bool = false

func _ready() -> void:
	NW.connection_failed.connect(_on_connection_ended.bind("Could not reach the host"))
	NW.connection_lost.connect(_on_connection_ended.bind("Lost connection to the host"))

func _unhandled_input(event: InputEvent) -> void:
	if started or not (event is InputEventKey and event.pressed):
		return
	if event.keycode == KEY_H:
		started = NW.host() == OK
	elif event.keycode == KEY_J:
		started = NW.join("127.0.0.1") == OK

func _on_connection_ended(message: String) -> void:
	print(message)
	started = false

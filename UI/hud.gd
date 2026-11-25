class_name HUD
extends CanvasLayer

@onready var hotbar: Hotbar = $Hotbar


func _enter_tree() -> void:
	Game.hud = self

func _exit_tree() -> void:
	Game.hud = null

func _ready() -> void:
	visible = false

func watch(player: Player) -> void:
	hotbar.watch(player.inventory)
	player.tree_exiting.connect(hide)
	visible = true

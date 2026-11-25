class_name Interactor
extends RayCast3D

const REACH: float = 2.0
const REACH_TOLERANCE: float = 1.0 # Positions lag on the host, so allow some slack

@onready var player: Player = owner as Player


func _ready() -> void:
	# Interact range
	target_position = Vector3(0, 0, -REACH)


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return # end early if not controlling

	if event.is_action_pressed("interact"):
		_interact()


func _interact() -> void:
	var target: Object = get_collider()

	# Items
	if target is Item:
		player.inventory.try_pickup(target)
	
	# Others
	

#############################3
# Getters
#############################3

func can_reach(point: Vector3) -> bool:
	return global_position.distance_to(point) <= REACH + REACH_TOLERANCE

class_name Item
extends StaticBody3D

@export var display_name: String = "Item"
@export var weight: float = 1.0
@export var value: int = 0
@export var half_height: float = 0.15 # Distance from the center to the bottom

const MAX_DROP_DISTANCE: float = 10.0

var is_held: bool = false #synched
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

##############################
# Initialization and checks
##############################

func _ready() -> void:
	collision_shape.disabled = is_held #check held status


################################
# Requests (host only)
################################

# Host only: an item that's already held can't be picked up
func request_pickup() -> bool:
	if is_held:
		return false
	_set_held.rpc(true)
	return true

# Host only: finds the floor below the item, then tells every machine
func request_drop() -> void:
	await get_tree().physics_frame # The physics world is only safe to query here
	var from: Vector3 = global_position
	var to: Vector3 = from + Vector3.DOWN * MAX_DROP_DISTANCE
	var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from, to, 1)
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var landing: Vector3 = from
	if not hit.is_empty():
		landing = hit.position + Vector3.UP * half_height
	_place_at.rpc(Transform3D(Basis.IDENTITY, landing))

################################
# Announcements (every machine)
################################

# The host tells every machine whether the item is held
@rpc("authority", "call_local", "reliable")
func _set_held(held: bool) -> void:
	is_held = held
	collision_shape.disabled = held

# The host tells every machine where the item is
@rpc("authority", "call_local", "reliable")
func _place_at(new_transform: Transform3D) -> void:
	_set_held(false)
	visible = true # from inventory
	set_pose(new_transform)

################################
# State
################################

func set_pose(new_transform: Transform3D) -> void:
	global_transform = new_transform

# Called every frame by the player whose inventory holds this item
func follow_hand(hand: Transform3D, shown: bool) -> void:
	if not is_held:
		return # Being dropped: the host's landing spot wins
	visible = shown
	if shown:
		set_pose(hand)

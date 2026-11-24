class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 4.0
const JUMP_VELOCITY: float = 4.5
const MAX_LOOK_ANGLE: float = 1.4
const REACH: float = 2.0
const REACH_TOLERANCE: float = 1.0 # Positions lag on the host, so allow some slack

const INVENTORY_SIZE: int = 4

var held_item: Item = null

# Item IDs stored in inv; 0 means empty
var inventory: PackedInt32Array = PackedInt32Array()
var selected_slot: int = 0

@onready var head: Node3D = $Head
@onready var view: Camera3D = $Head/View
@onready var interact_ray: RayCast3D = $Head/View/InteractRay
@onready var hold_point: Marker3D = $Head/View/HoldPoint
@onready var player_hud: CanvasLayer = $PlayerHud


#############################
# Setup
#############################

func _init() -> void:
	inventory.resize(INVENTORY_SIZE)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int()) # Player controller by the player
	$HostSync.set_multiplayer_authority(1) # Host controls

func _ready() -> void:
	view.current = is_multiplayer_authority() # set correct view
	if is_multiplayer_authority():
		position = Vector3(randf_range(-3, 3), 5, randf_range(-3, 3)) # Own spawn point
	if is_multiplayer_authority() and get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED #hide mouse
		
		
	if not is_multiplayer_authority(): 
		player_hud.queue_free() # We only want one crosshair per player machine
		
	# Interact range
	interact_ray.target_position = Vector3(0, 0, -REACH)




#############################
# Player control
#############################

func _physics_process(delta: float) -> void:

	if not is_multiplayer_authority():
		return # end early if not controlling

	# Move the player in the direction its facing
	var input: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = transform.basis * Vector3(input.x, 0, input.y) # rotate to player
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	move_and_slide()

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Gravity
	if not is_on_floor():
		velocity.y -= G.G * delta


func _unhandled_input(event: InputEvent) -> void:
	if not is_multiplayer_authority():
		return # end early if not controlling

	if event is InputEventMouseMotion:
		_look(event)
	elif event.is_action_pressed("interact"):
		_interact()
	elif event.is_action_pressed("drop"):
		_drop_item()
	elif event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE # Esc frees the mouse
	elif event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED # Clicking captures it again


# Turn the body left/right and tilt the head up/down
func _look(event: InputEventMouseMotion) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	rotate_y(-event.relative.x * G.mouse_sensitivity)
	head.rotate_x(-event.relative.y * G.mouse_sensitivity)
	head.rotation.x = clampf(head.rotation.x, -MAX_LOOK_ANGLE, MAX_LOOK_ANGLE)


func _interact() -> void:
	var target: Object = interact_ray.get_collider()
	if target is Item:
		_pickup.rpc_id(1, target.name.to_int())


func _drop_item() -> void:
	if held_item != null:
		_drop.rpc_id(1)



#############################
# Held item
#############################

# Runs on the host: checks the player's side, then asks the item
@rpc("any_peer", "call_local", "reliable")
func _pickup(item_id: int) -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return # Players can only ask for themselves
	var item: Item = _get_item(item_id)
	if item == null:
		return # Bad request
	if held_item != null or not can_reach(item.global_position):
		return
	if item.request_pickup():
		_hold_item.rpc(item_id)


# Runs on the host: checks the player's side, then asks the item
@rpc("any_peer", "call_local", "reliable")
func _drop() -> void:
	if not multiplayer.is_server():
		return
	if multiplayer.get_remote_sender_id() != get_multiplayer_authority():
		return # Players can only ask for themselves
	if held_item == null:
		return
	var item: Item = held_item
	_release_item.rpc()
	item.request_drop()


func _process(_delta: float) -> void:
	if held_item != null:
		held_item.set_pose(hold_point.global_transform)


# Used by the host to check a client's request
func can_reach(point: Vector3) -> bool:
	return view.global_position.distance_to(point) <= REACH + REACH_TOLERANCE


#############################
# Announcements (every machine)
#############################

# The host tells every machine
@rpc("any_peer", "call_local", "reliable")
func _hold_item(item_id: int) -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return # Only the host can announce this
	held_item = _get_item(item_id)


# The host tells every machine
@rpc("any_peer", "call_local", "reliable")
func _release_item() -> void:
	if multiplayer.get_remote_sender_id() != 1:
		return # Only the host can announce this
	held_item = null


func _get_item(id: int) -> Item:
	return get_tree().get_first_node_in_group("items").get_item(id)

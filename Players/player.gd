class_name Player
extends CharacterBody3D

const WALK_SPEED: float = 4.0
const JUMP_VELOCITY: float = 4.5
const MAX_LOOK_ANGLE: float = 1.4

@onready var head: Node3D = $Head
@onready var view: Camera3D = $Head/View
@onready var interactor: Interactor = $Head/View/InteractRay
@onready var hold_point: Marker3D = $Head/View/HoldPoint
@onready var inventory: Inventory = $Inventory


#############################
# Setup and logic loop
#############################

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int()) # Player controller by the player
	$HostSync.set_multiplayer_authority(1) # Host controls

func _ready() -> void:
	view.current = is_multiplayer_authority() # set correct view
	if is_multiplayer_authority() and get_window().has_focus():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED #hide mouse
	
	# Draw HUD
	if is_multiplayer_authority():
		Game.hud.watch(self)


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

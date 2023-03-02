extends KinematicBody

# controller variables, add export to the front to expose to editor
# like: export speed = 7
var speed = 7
var default_speed = speed
var mouse_sensitivity = 0.2
var gravity = 9.8
var jump = 5
var cam_accel = 40

# sprinting stuff, can export as well
var sprint_speed = 14
export var can_sprint = false # use sprinting at all
var toggle_sprint = false # toggle sprint on off instead of holding
var is_sprinting = false

# smooths out jumping acceleration
var snap
const ACCEL_DEFAULT = 7
const ACCEL_AIR = 1
onready var accel = ACCEL_DEFAULT

# member variables for tracking movement
var direction = Vector3()
var velocity = Vector3()
var movement = Vector3()
var gravity_vec = Vector3()

# loads references to player head and camera
onready var head = $Head
onready var camera = $Head/Camera

var suspend_movement = false

# runs once when scene opens
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	default_speed = speed

# processes input from mouse and keyboard
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		suspend_movement = !suspend_movement
		
	# to expose mouse on key press, need to add to input map
	if event.is_action_pressed("change_mouse_input"):
		match Input.get_mouse_mode():
			Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.MOUSE_MODE_VISIBLE:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event is InputEventMouseMotion and not suspend_movement:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-89), deg2rad(89))

func _process(delta):
	# camera physics interpolation
	if Engine.get_frames_per_second() > Engine.iterations_per_second:
		camera.set_as_toplevel(true)
		camera.global_transform.origin = camera.global_transform.origin.linear_interpolate(head.global_transform.origin, cam_accel * delta)
		camera.rotation.y = rotation.y
		camera.rotation.x = head.rotation.x
	else:
		camera.set_as_toplevel(false)
		camera.global_transform = head.global_transform
		
# updates scene physics every frame
func _physics_process(delta):
	
	# keyboard input
	direction = Vector3.ZERO
	var h_rot = global_transform.basis.get_euler().y
	var f_input = Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	var h_input = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	direction = Vector3(h_input, 0, f_input).rotated(Vector3.UP, h_rot).normalized()
	
	# sprinting stuff
	speed = default_speed
	if can_sprint:
		if toggle_sprint:
			if Input.is_action_just_pressed("sprint") and not is_sprinting:
				is_sprinting = true
			elif Input.is_action_just_pressed("sprint") and is_sprinting:
				is_sprinting = false
		else:
			is_sprinting = Input.is_action_pressed("sprint")
		
		if is_sprinting:
			speed = sprint_speed
	
	if is_on_floor():
		snap = -get_floor_normal()
		accel = ACCEL_DEFAULT
		gravity_vec = Vector3.ZERO
	else:
		snap = Vector3.DOWN
		accel = ACCEL_AIR
		gravity_vec += Vector3.DOWN * gravity * delta
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		snap = Vector3.ZERO
		gravity_vec = Vector3.UP * jump
		# $JumpSound.play()		
	
	velocity = velocity.linear_interpolate(direction * speed, accel * delta)
	movement = velocity + gravity_vec
	
	if not suspend_movement:
		move_and_slide_with_snap(movement, snap, Vector3.UP)

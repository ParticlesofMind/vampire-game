extends CharacterBody3D

@export var walk_speed: float = 5.5
@export var sprint_multiplier: float = 1.6
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.0022
@export var turn_speed: float = 10.0

@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D

var _pitch: float = 0.0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Third-person: yaw camera pivot, pitch camera pivot (clamped).
		camera_pivot.rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(_pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-85.0), deg_to_rad(85.0))
		camera_pivot.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Move
	var input_vec := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := camera_pivot.global_transform.basis
	var cam_forward := (-cam_basis.z).normalized()
	var cam_right := (cam_basis.x).normalized()
	cam_forward.y = 0.0
	cam_right.y = 0.0
	cam_forward = cam_forward.normalized()
	cam_right = cam_right.normalized()

	var dir := (cam_right * input_vec.x + cam_forward * input_vec.y).normalized()
	var speed := walk_speed * (sprint_multiplier if Input.is_action_pressed("sprint") else 1.0)

	if dir != Vector3.ZERO:
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		# Rotate the character toward movement direction.
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, min(1.0, turn_speed * delta))
	else:
		velocity.x = move_toward(velocity.x, 0.0, walk_speed)
		velocity.z = move_toward(velocity.z, 0.0, walk_speed)

	move_and_slide()



extends "res://scripts/parts/Part.gd"

@export var forward_speed: float = 7.0
@export var turn_rate: float = 1.7
@export var reverse_speed: float = 2.5

@export var bob_amplitude: float = 0.22
@export var bob_frequency: float = 1.1
@export var roll_degrees: float = 4.0

@export var mouse_sensitivity: float = 0.0022
@export var pitch_min_degrees: float = -40.0
@export var pitch_max_degrees: float = 25.0

@export var zoom_step: float = 0.9
@export var zoom_min: float = 4.0
@export var zoom_max: float = 14.0
@export var zoom_smoothing: float = 14.0

@onready var boat: Node3D = $Boat
@onready var camera_pivot: Node3D = $Boat/CameraPivot
@onready var spring_arm: SpringArm3D = $Boat/CameraPivot/SpringArm3D

var _base_boat_y: float = 0.0
var _pitch: float = deg_to_rad(-15.0)
var _target_spring_len: float = 0.0

func _ready() -> void:
	super._ready()
	_base_boat_y = boat.position.y
	camera_pivot.rotation.x = _pitch
	hud_label.text = "Part %d — The Crossing\nWASD: steer • Mouse: look • Wheel: zoom • Esc: pause\nPress P to complete (placeholder)" % part_index
	_target_spring_len = clamp(spring_arm.spring_length, zoom_min, zoom_max)

func _unhandled_input(event: InputEvent) -> void:
	super._unhandled_input(event)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_target_spring_len = clamp(_target_spring_len - zoom_step, zoom_min, zoom_max)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_target_spring_len = clamp(_target_spring_len + zoom_step, zoom_min, zoom_max)

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Yaw rotates the boat; pitch rotates the camera rig.
		boat.rotate_y(-event.relative.x * mouse_sensitivity)
		_pitch = clamp(
			_pitch - event.relative.y * mouse_sensitivity,
			deg_to_rad(pitch_min_degrees),
			deg_to_rad(pitch_max_degrees)
		)
		camera_pivot.rotation.x = _pitch

func _physics_process(delta: float) -> void:
	# Camera zoom smoothing (spring arm handles collision).
	if _target_spring_len == 0.0:
		_target_spring_len = clamp(spring_arm.spring_length, zoom_min, zoom_max)
	spring_arm.spring_length = lerp(spring_arm.spring_length, _target_spring_len, min(1.0, zoom_smoothing * delta))

	var steer: float = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	boat.rotate_y(steer * turn_rate * delta)

	var throttle: float = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var speed: float = forward_speed * maxf(throttle, 0.0) - reverse_speed * maxf(-throttle, 0.0)

	var forward := -boat.global_transform.basis.z
	boat.global_position += forward * speed * delta

	# Simple bob/roll so it feels like floating.
	var t := Time.get_ticks_msec() / 1000.0
	boat.position.y = _base_boat_y + sin(t * bob_frequency) * bob_amplitude
	var target_roll := sin(t * (bob_frequency * 0.9)) * deg_to_rad(roll_degrees)
	boat.rotation.z = lerp_angle(boat.rotation.z, target_roll, min(1.0, 4.0 * delta))

extends CharacterBody3D

@export var walk_speed: float = 1.6
@export var turn_speed: float = 6.0

@export var wander_retarget_min_sec: float = 1.4
@export var wander_retarget_max_sec: float = 3.2

var _mode: StringName = &"queue" # "queue" or "wander"
var _target: Vector3

var _wander_center: Vector3
var _wander_bounds_x: Vector2 = Vector2(-8, 8)
var _wander_bounds_z: Vector2 = Vector2(-8, 8)
var _retarget_at: float = 0.0

func _ready() -> void:
	_target = global_position
	_wander_center = global_position
	_schedule_retarget()

func set_queue_target(pos: Vector3) -> void:
	_mode = &"queue"
	_target = pos

func set_wander_bounds(center: Vector3, bounds_x: Vector2, bounds_z: Vector2) -> void:
	_mode = &"wander"
	_wander_center = center
	_wander_bounds_x = bounds_x
	_wander_bounds_z = bounds_z
	_pick_new_wander_target()

func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity += get_gravity() * delta

	if _mode == &"wander":
		if Time.get_ticks_msec() / 1000.0 >= _retarget_at or global_position.distance_to(_target) < 0.5:
			_pick_new_wander_target()

	var to := _target - global_position
	to.y = 0.0

	var dir := Vector3.ZERO
	if to.length() > 0.15:
		dir = to.normalized()

	velocity.x = dir.x * walk_speed
	velocity.z = dir.z * walk_speed

	if dir != Vector3.ZERO:
		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, min(1.0, turn_speed * delta))

	move_and_slide()

func _pick_new_wander_target() -> void:
	_target = _wander_center + Vector3(
		randf_range(_wander_bounds_x.x, _wander_bounds_x.y),
		0.0,
		randf_range(_wander_bounds_z.x, _wander_bounds_z.y)
	)
	_schedule_retarget()

func _schedule_retarget() -> void:
	_retarget_at = (Time.get_ticks_msec() / 1000.0) + randf_range(wander_retarget_min_sec, wander_retarget_max_sec)




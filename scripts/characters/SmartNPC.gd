extends CharacterBody3D

enum State { IDLE, WANDER, TRAVEL }

@export var move_speed: float = 2.0
@export var npc_type: String = "civilian"

var current_state: State = State.IDLE
var _target_position: Vector3

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D

func _ready() -> void:
	# Ensure the agent is set up
	nav_agent.path_desired_distance = 0.5
	nav_agent.target_desired_distance = 0.5

	# Initial random behavior
	set_state(State.WANDER)

func set_state(new_state: State) -> void:
	current_state = new_state
	if new_state == State.WANDER:
		pick_random_wander_target()
	elif new_state == State.IDLE:
		velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if current_state == State.IDLE:
		move_and_slide()
		return

	if nav_agent.is_navigation_finished():
		if current_state == State.WANDER:
			# Wait a bit then pick new target? For now just pick new one
			pick_random_wander_target()
		return

	var current_agent_position: Vector3 = global_position
	var next_path_position: Vector3 = nav_agent.get_next_path_position()

	var new_velocity: Vector3 = next_path_position - current_agent_position
	new_velocity = new_velocity.normalized() * move_speed

	# Setup avoidance if needed later
	# nav_agent.set_velocity(new_velocity)

	velocity = new_velocity

	# Look at direction
	if velocity.length() > 0.1:
		var look_target = global_position + velocity
		look_at(Vector3(look_target.x, global_position.y, look_target.z), Vector3.UP)

	move_and_slide()

func set_movement_target(movement_target: Vector3):
	nav_agent.target_position = movement_target

func pick_random_wander_target():
	var wander_radius = 10.0
	var random_offset = Vector3(randf_range(-wander_radius, wander_radius), 0, randf_range(-wander_radius, wander_radius))
	set_movement_target(global_position + random_offset)

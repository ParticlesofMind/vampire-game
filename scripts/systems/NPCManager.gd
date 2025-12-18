extends Node

@export var max_population: int = 50
@export var spawn_radius_min: float = 20.0
@export var spawn_radius_max: float = 60.0
@export var npc_scene_path: String = "res://scenes/characters/SmartNPC.tscn"

var active_npcs: Array = []
var npc_scene: PackedScene

# References to other managers (would be Autoloads in real project)
# For now, we assume they are children or siblings, or we find them.
# In a real setup, these would be singletons like TimeCycle, DistrictManager.
var time_cycle: Node
var district_manager: Node

func _ready() -> void:
	npc_scene = load(npc_scene_path)

	# Find dependencies if they exist in the tree, or assume they are siblings
	# This is a bit hacky for the test environment but works.
	time_cycle = get_node_or_null("/root/Main/TimeCycle")
	# If not found, try searching siblings
	if not time_cycle:
		time_cycle = get_parent().find_child("TimeCycle", false, false)

	district_manager = get_node_or_null("/root/Main/DistrictManager")
	if not district_manager:
		district_manager = get_parent().find_child("DistrictManager", false, false)

func _process(delta: float) -> void:
	# Cleanup invalid NPCs
	for i in range(active_npcs.size() - 1, -1, -1):
		if not is_instance_valid(active_npcs[i]):
			active_npcs.remove_at(i)

	_check_spawns()

func _check_spawns() -> void:
	if active_npcs.size() >= max_population:
		return

	# Determine desired population based on Time and District
	# For simplicity, we just use a global cap modified by time for now if DistrictManager is missing
	var multiplier = 1.0

	if time_cycle:
		# Reduce population at night (hours 22 to 6)
		var hour = time_cycle.get_hour()
		if hour >= 22 or hour < 6:
			multiplier = 0.3
		elif hour >= 6 and hour < 8:
			multiplier = 0.6
		else:
			multiplier = 1.0

	var current_cap = max_population * multiplier

	if active_npcs.size() < current_cap:
		# Spawn an NPC
		_spawn_npc_near_player()

func _spawn_npc_near_player() -> void:
	if not npc_scene:
		return

	# We need a player reference. In a real game, this is a global or group look up.
	# For now, assume a camera or a node named "Player" exists.
	var player = get_tree().get_first_node_in_group("player")
	var center = Vector3.ZERO
	if player:
		center = player.global_position

	# Random position in ring
	var angle = randf() * TAU
	var dist = randf_range(spawn_radius_min, spawn_radius_max)
	var offset = Vector3(cos(angle), 0, sin(angle)) * dist
	var raw_spawn_pos = center + offset

	# Snap to Navigation Mesh
	var map = get_world_3d().navigation_map
	var spawn_pos = NavigationServer3D.map_get_closest_point(map, raw_spawn_pos)

	# Determine type
	var type = "civilian"
	if district_manager:
		# Use current district logic
		var dist_name = district_manager.get_current_district()
		type = district_manager.get_npc_type_for_district(dist_name)
		if type == "": type = "civilian"

	var npc = npc_scene.instantiate()
	npc.position = spawn_pos
	npc.npc_type = type

	get_parent().add_child(npc)
	active_npcs.append(npc)

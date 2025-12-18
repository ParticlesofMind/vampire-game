extends "res://scripts/parts/Part.gd"

# Part3 (NYC) wrapper that keeps a persistent "WorldShell" and swaps between:
# - an exterior mission slice (2 blocks)
# - an interior (bodega template)

@export var world_shell_scene: PackedScene
@export var mission_scene: PackedScene

var _world_shell: Node3D
var _mission: Node3D
var _interior: Node3D

@onready var _player: Node3D = $Player

func _ready() -> void:
	super._ready()
	_build_world()
	_show_exterior()
	hud_label.text = "Part %d — New York City\nWASD move • Mouse look • Space jump • Shift sprint\nEnter the bodega door to test interiors • Esc: pause" % part_index

func _build_world() -> void:
	if world_shell_scene and _world_shell == null:
		_world_shell = world_shell_scene.instantiate() as Node3D
		add_child(_world_shell)
		_world_shell.owner = self

	if mission_scene and _mission == null:
		_mission = mission_scene.instantiate() as Node3D
		add_child(_mission)
		_mission.owner = self

	# If the mission provides a spawn marker, use it.
	var spawn := _find_node_in(_mission, "PlayerSpawn") as Marker3D
	if spawn:
		_player.global_transform = spawn.global_transform

func enter_interior(interior_scene: PackedScene) -> void:
	if interior_scene == null:
		push_warning("CityPart: enter_interior called with null scene")
		return

	if _interior:
		_interior.queue_free()
		_interior = null

	_interior = interior_scene.instantiate() as Node3D
	add_child(_interior)
	_interior.owner = self

	# Move player to interior spawn if present.
	var spawn := _find_node_in(_interior, "PlayerSpawn") as Marker3D
	if spawn:
		_player.global_transform = spawn.global_transform

	_show_interior()

func exit_interior() -> void:
	if _interior:
		_interior.queue_free()
		_interior = null

	# Move player back to exterior return point if present.
	var spawn := _find_node_in(_mission, "InteriorReturn") as Marker3D
	if spawn:
		_player.global_transform = spawn.global_transform

	_show_exterior()

func _show_exterior() -> void:
	if _mission:
		_mission.visible = true
	if _world_shell:
		_world_shell.visible = true
	if _interior:
		_interior.visible = false

func _show_interior() -> void:
	if _mission:
		_mission.visible = false
	# Keep the world shell off in interiors (cheap and avoids outdoor fog inside).
	if _world_shell:
		_world_shell.visible = false
	if _interior:
		_interior.visible = true

func _find_node_in(root: Node, node_name: String) -> Node:
	if root == null:
		return null
	# Search by name; missions/interiors are small so a simple DFS is fine.
	if root.name == node_name:
		return root
	for c in root.get_children():
		var found := _find_node_in(c, node_name)
		if found:
			return found
	return null






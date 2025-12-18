extends Node3D

@export var npc_scene: PackedScene
@export var queue_count: int = 10
@export var wander_count: int = 4

@export var advance_every_sec: float = 5.5
@export var wander_bounds_x: Vector2 = Vector2(-10, 10)
@export var wander_bounds_z: Vector2 = Vector2(-10, 10)

@onready var _markers_root: Node3D = null

var _queue_npcs: Array[Node] = []
var _wander_npcs: Array[Node] = []
var _timer: Timer

func _ready() -> void:
	randomize()
	if npc_scene == null:
		push_error("QueueController: npc_scene not assigned")
		return
	if has_node("../QueueMarkers"):
		_markers_root = $"../QueueMarkers"

	var markers := _get_markers()
	if markers.is_empty():
		push_error("QueueController: no queue markers found (create ../QueueMarkers with Marker3D children)")
		return

	_spawn_queue(markers)
	_spawn_wanderers()

	_timer = Timer.new()
	_timer.wait_time = maxf(1.0, advance_every_sec)
	_timer.autostart = true
	_timer.one_shot = false
	add_child(_timer)
	_timer.timeout.connect(func() -> void: _advance_queue(markers))

func _get_markers() -> Array[Marker3D]:
	if _markers_root == null:
		return []

	var markers: Array[Marker3D] = []
	for c in _markers_root.get_children():
		if c is Marker3D:
			markers.append(c)

	# Sort by name so P00, P01... is stable.
	markers.sort_custom(func(a: Marker3D, b: Marker3D) -> bool:
		return a.name.naturalnocasecmp_to(b.name) < 0
	)
	return markers

func _spawn_queue(markers: Array[Marker3D]) -> void:
	_queue_npcs.clear()
	var count: int = mini(queue_count, markers.size())
	for i in range(count):
		var npc := npc_scene.instantiate()
		npc.name = "QueueNPC_%02d" % i
		add_child(npc)

		var target_marker := markers[i]
		npc.global_position = target_marker.global_position + Vector3(randf_range(-0.25, 0.25), 0, randf_range(-0.25, 0.25))
		_queue_npcs.append(npc)

		if npc.has_method("set_queue_target"):
			npc.call("set_queue_target", target_marker.global_position)

func _spawn_wanderers() -> void:
	_wander_npcs.clear()
	for i in range(max(0, wander_count)):
		var npc := npc_scene.instantiate()
		npc.name = "WanderNPC_%02d" % i
		add_child(npc)
		npc.global_position = global_position + Vector3(randf_range(wander_bounds_x.x, wander_bounds_x.y), 0, randf_range(wander_bounds_z.x, wander_bounds_z.y))
		_wander_npcs.append(npc)

		if npc.has_method("set_wander_bounds"):
			npc.call("set_wander_bounds", global_position, wander_bounds_x, wander_bounds_z)

func _advance_queue(markers: Array[Marker3D]) -> void:
	if _queue_npcs.is_empty():
		return

	# Everyone targets the next marker toward the front (index-1).
	for i in range(_queue_npcs.size()):
		var npc := _queue_npcs[i]
		if npc == null or not is_instance_valid(npc):
			continue

		var marker_idx: int = maxi(0, i - 1)
		var target := markers[marker_idx].global_position

		# Front person "exits" then rejoins at the end (keeps motion in the scene).
		if i == 0:
			target = global_position + Vector3(6.0, 0, -8.0)  # toward the desk/exit area
		elif i == _queue_npcs.size() - 1:
			target = markers[i].global_position

		if npc.has_method("set_queue_target"):
			npc.call("set_queue_target", target)

	# Cycle the array: front goes to back (after a short delay, it will retarget to the last marker).
	var front: Node = _queue_npcs.pop_front() as Node
	_queue_npcs.append(front)

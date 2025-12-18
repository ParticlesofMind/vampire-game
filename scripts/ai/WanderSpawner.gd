extends Node3D

@export var npc_scene: PackedScene
@export var count: int = 8
@export var bounds_x: Vector2 = Vector2(-20, 20)
@export var bounds_z: Vector2 = Vector2(-20, 20)

func _ready() -> void:
	randomize()
	if npc_scene == null:
		push_error("WanderSpawner: npc_scene not assigned")
		return

	for i in range(max(0, count)):
		var npc := npc_scene.instantiate()
		npc.name = "CityNPC_%02d" % i
		add_child(npc)
		npc.global_position = global_position + Vector3(randf_range(bounds_x.x, bounds_x.y), 0, randf_range(bounds_z.x, bounds_z.y))
		if npc.has_method("set_wander_bounds"):
			npc.call("set_wander_bounds", global_position, bounds_x, bounds_z)



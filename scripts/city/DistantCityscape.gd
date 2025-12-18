extends Node3D

@export var radius: float = 200.0
@export var building_count: int = 50
@export var min_height: float = 20.0
@export var max_height: float = 80.0

func _ready():
	var multi_mesh = MultiMesh.new()
	multi_mesh.transform_format = MultiMesh.TRANSFORM_3D
	multi_mesh.mesh = BoxMesh.new()
	multi_mesh.mesh.size = Vector3(10, 1, 10) # Base size, we will scale it
	# Simple dark material for silhouette
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.05, 0.05, 0.07)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.fog_enabled = true # Let fog affect it
	multi_mesh.mesh.material = mat

	multi_mesh.instance_count = building_count

	var mm_instance = MultiMeshInstance3D.new()
	mm_instance.multimesh = multi_mesh
	add_child(mm_instance)

	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(building_count):
		var angle = rng.randf() * TAU
		var dist = radius + rng.randf() * 100.0
		var x = cos(angle) * dist
		var z = sin(angle) * dist
		var h = rng.randf_range(min_height, max_height)

		var basis = Basis()
		# Random rotation
		basis = basis.rotated(Vector3.UP, rng.randf() * TAU)
		# Scale height
		basis = basis.scaled(Vector3(1 + rng.randf(), h, 1 + rng.randf()))

		var pos = Vector3(x, h/2.0, z)

		multi_mesh.set_instance_transform(i, Transform3D(basis, pos))

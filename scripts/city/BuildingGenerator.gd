extends Node3D
class_name BuildingGenerator

@export var width: float = 10.0
@export var depth: float = 12.0
@export var floor_height: float = 3.5
@export var num_floors: int = 3
@export_enum("Tenement", "Brownstone", "Commercial") var building_type: String = "Tenement"
@export var seed_value: int = 0

var rng = RandomNumberGenerator.new()

func _ready():
	rng.seed = seed_value
	generate_building()

func generate_building():
	# Clear existing children if any (for tool usage)
	for child in get_children():
		child.queue_free()

	var combiner = CSGCombiner3D.new()
	combiner.name = "BuildingMesh"
	add_child(combiner)

	# Main structure
	var total_height = num_floors * floor_height
	var main_body = CSGBox3D.new()
	main_body.size = Vector3(width, total_height, depth)
	main_body.position = Vector3(0, total_height / 2.0, 0)
	main_body.material = _get_wall_material()
	combiner.add_child(main_body)

	# Cornice (Roof trim)
	var cornice = CSGBox3D.new()
	cornice.size = Vector3(width + 0.4, 0.5, depth + 0.4)
	cornice.position = Vector3(0, total_height, 0)
	cornice.material = _get_trim_material()
	combiner.add_child(cornice)

	# Windows
	var window_width = 1.2
	var window_height = 2.0
	var windows_per_floor_x = floor(width / 3.0)
	var windows_per_floor_z = floor(depth / 3.0)

	# Front and Back Windows
	for f in range(num_floors):
		var y_pos = (f * floor_height) + (floor_height / 2.0)

		# Ground floor might be different (shop or entrance)
		if f == 0 and building_type == "Tenement":
			# Add Entrance
			var entrance = CSGBox3D.new()
			entrance.operation = CSGShape3D.OPERATION_SUBTRACTION
			entrance.size = Vector3(2.0, 3.0, 1.0)
			entrance.position = Vector3(0, 1.5, depth / 2.0)
			combiner.add_child(entrance)
			continue # Skip windows on ground floor center for now

		for i in range(windows_per_floor_x):
			var x_pos = (i - (windows_per_floor_x - 1) / 2.0) * (width / windows_per_floor_x)

			# Front
			var win_front = CSGBox3D.new()
			win_front.operation = CSGShape3D.OPERATION_SUBTRACTION
			win_front.size = Vector3(window_width, window_height, 1.0)
			win_front.position = Vector3(x_pos, y_pos, depth / 2.0)
			combiner.add_child(win_front)

			# Back
			var win_back = CSGBox3D.new()
			win_back.operation = CSGShape3D.OPERATION_SUBTRACTION
			win_back.size = Vector3(window_width, window_height, 1.0)
			win_back.position = Vector3(x_pos, y_pos, -depth / 2.0)
			combiner.add_child(win_back)

	# Fire Escapes (Decoration) for Tenements
	if building_type == "Tenement":
		_add_fire_escapes(combiner, total_height)

func _get_wall_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	if building_type == "Tenement":
		mat.albedo_color = Color(0.6, 0.3, 0.2) # Brick red
	elif building_type == "Brownstone":
		mat.albedo_color = Color(0.4, 0.35, 0.3) # Brownstone
	else:
		mat.albedo_color = Color(0.5, 0.5, 0.55) # Concrete/Stone
	mat.roughness = 0.9
	return mat

func _get_trim_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.2)
	return mat

func _add_fire_escapes(parent: Node3D, building_height: float):
	# Simplified fire escape: platforms and railings
	# This adds to the geometry, not subtracts
	for f in range(1, num_floors):
		var y_pos = (f * floor_height) + 0.5 # Bottom of window level
		var platform = CSGBox3D.new()
		platform.size = Vector3(width * 0.6, 0.2, 1.0)
		platform.position = Vector3(0, y_pos, (depth / 2.0) + 0.5)
		platform.material = _get_trim_material()
		parent.add_child(platform)

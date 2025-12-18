extends Node3D

@export var block_width: int = 3
@export var block_depth: int = 3
@export var street_width: float = 12.0
@export var building_spacing: float = 14.0 # Average width of a building slot

var tenement_scene = preload("res://scenes/city/buildings/Procedural_Tenement.tscn")
var brownstone_scene = preload("res://scenes/city/buildings/Procedural_Brownstone.tscn")
var skyscraper_scene = preload("res://scenes/city/buildings/Procedural_Skyscraper.tscn")
var lamp_scene = preload("res://scenes/city/props/GasLamp.tscn")

func _ready():
	generate_block()

func generate_block():
	# Simple grid layout
	# We place buildings along the perimeter of blocks.
	# For simplicity, let's just make rows of buildings separated by streets.

	for x in range(block_width):
		for z in range(block_depth):
			_place_building_cluster(x * (building_spacing * 3 + street_width), z * (building_spacing * 3 + street_width))

func _place_building_cluster(offset_x: float, offset_z: float):
	# Create a mini block of 3x3 buildings? No, let's do linear streets.
	# Let's place a row of buildings.

	for i in range(3):
		# occasional skyscraper
		var b_type = randi() % 10
		var building
		if b_type == 0:
			building = skyscraper_scene.instantiate()
		elif b_type < 6:
			building = tenement_scene.instantiate()
		else:
			building = brownstone_scene.instantiate()

		# Add some random variation
		building.seed_value = randi()
		# Tenements and Brownstones have num_floors, Skyscraper might have different default range
		if "num_floors" in building:
			building.num_floors = randi() % 3 + 3 # 3 to 5 floors (will override default)

		building.position = Vector3(offset_x + (i * building_spacing), 0, offset_z)

		add_child(building)

		# Add a street lamp occasionally
		if i % 2 == 0:
			var lamp = lamp_scene.instantiate()
			add_child(lamp)
			lamp.position = Vector3(offset_x + (i * building_spacing), 0, offset_z + 8.0) # Near the street

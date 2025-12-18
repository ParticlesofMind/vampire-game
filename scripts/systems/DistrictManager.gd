extends Node

# Map of district name -> DistrictData resource
var districts: Dictionary = {}
var current_district_name: String = "default"

func register_district(data: Resource):
	if data and "district_name" in data:
		districts[data.district_name] = data
		print("District registered: ", data.district_name)

func get_district_data(name: String) -> Resource:
	return districts.get(name)

func get_npc_type_for_district(district_name: String) -> String:
	var data = get_district_data(district_name)
	if data and data.spawn_table:
		if data.spawn_table.has_method("get_random_type"):
			return data.spawn_table.get_random_type()
	return ""

func get_density_multiplier(district_name: String, hour: int) -> float:
	var data = get_district_data(district_name)
	if data:
		return data.get_density_at_hour(hour)
	return 1.0

func set_current_district(name: String) -> void:
	if districts.has(name):
		current_district_name = name
		print("Current district set to: ", name)

func get_current_district() -> String:
	return current_district_name

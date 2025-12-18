extends Resource
class_name DistrictData

@export var district_name: String
# Curve defining population density (0-1) over 24 hours (X axis 0-24)
@export var population_curve: Curve
@export var spawn_table: Resource # SpawnTable

func get_density_at_hour(hour: int) -> float:
	if population_curve:
		# Curve X is 0-1 usually, so map hour 0-24 to 0-1
		return population_curve.sample(float(hour) / 24.0)
	return 1.0

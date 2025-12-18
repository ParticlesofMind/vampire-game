extends Resource
class_name SpawnTable

# Dictionary mapping NPC type strings to weight integers
# e.g., {"worker": 10, "rich": 1}
@export var weights: Dictionary = {}

func get_random_type() -> String:
	var total_weight = 0
	for w in weights.values():
		total_weight += w

	if total_weight == 0:
		return ""

	var roll = randi() % total_weight
	var current = 0
	for type in weights:
		current += weights[type]
		if roll < current:
			return type
	return ""

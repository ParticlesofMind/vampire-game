extends Area3D

@export var district_data: Resource
var _district_manager: Node

func _ready() -> void:
	# Assume DistrictManager is at /root/Main/DistrictManager or similar global location
	# In a real game, use a unique name or group
	_district_manager = get_node_or_null("/root/Main/DistrictManager")
	if not _district_manager:
		_district_manager = get_tree().root.find_child("DistrictManager", true, false)

	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and _district_manager and district_data:
		_district_manager.call("set_current_district", district_data.district_name)

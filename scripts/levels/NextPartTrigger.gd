extends Area3D

@export var show_hint: bool = true
@export var hint_text: String = "Enter to continue"
@export var activator_group: StringName = &"progressor"

@onready var _label: Label3D = null

func _ready() -> void:
	# If the user adds this script but not the label, that's fine.
	if has_node("HintLabel3D"):
		_label = $HintLabel3D
	if _label:
		_label.visible = show_hint
		_label.text = hint_text

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
	if body == null:
		return
	if not body.is_in_group(activator_group):
		return

	# Find the nearest ancestor that implements complete_part().
	var n: Node = self
	while n != null:
		if n.has_method("complete_part"):
			n.call("complete_part")
			return
		n = n.get_parent()

func _on_area_entered(area: Area3D) -> void:
	if area == null:
		return
	if not area.is_in_group(activator_group):
		return
	_on_body_entered(area)



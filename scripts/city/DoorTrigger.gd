extends Area3D

@export_enum("EnterInterior", "ExitInterior") var mode: int = 0
@export var interior_scene: PackedScene
@export var activator_group: StringName = &"progressor"
@export var show_hint: bool = true
@export var hint_text: String = "Enter"

@onready var _label: Label3D = null

func _ready() -> void:
	if has_node("HintLabel3D"):
		_label = $HintLabel3D
	if _label:
		_label.visible = show_hint
		_label.text = hint_text

	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group(activator_group):
		return

	var n: Node = self
	while n != null:
		if mode == 0 and n.has_method("enter_interior"):
			n.call("enter_interior", interior_scene)
			return
		if mode == 1 and n.has_method("exit_interior"):
			n.call("exit_interior")
			return
		n = n.get_parent()

func _on_area_entered(area: Area3D) -> void:
	if area == null:
		return
	if area.is_in_group(activator_group):
		_on_body_entered(area)






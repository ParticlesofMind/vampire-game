extends Node3D

@export var part_index: int = 1

@onready var hud_label: Label = %HudLabel

func _ready() -> void:
	var title := _part_title(part_index)
	hud_label.text = "Part %d — %s\nWheel: zoom • Press P to continue (placeholder)\nEsc: pause" % [part_index, title]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		_complete_part()

func complete_part() -> void:
	# Public hook for triggers in the level to advance to the next part.
	_complete_part()

func _complete_part() -> void:
	var app := get_parent()
	if app and app.has_method("unlock_part"):
		app.call("unlock_part", part_index + 1)

	# Auto-advance to the next part if possible; otherwise return to menu.
	if app and app.has_method("start_part") and part_index < 3:
		app.call("start_part", part_index + 1)
	elif app and app.has_method("show_main_menu"):
		app.call("show_main_menu")

func _part_title(idx: int) -> String:
	match idx:
		1:
			return "The Crossing (Ocean)"
		2:
			return "Ellis Island"
		3:
			return "New York City"
		_:
			return "Unknown"



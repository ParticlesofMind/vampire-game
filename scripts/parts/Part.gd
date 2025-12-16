extends Node3D

@export var part_index: int = 1

@onready var hud_label: Label = %HudLabel

func _ready() -> void:
	hud_label.text = "Part %d — New York, 1918\nPress P to complete this part (placeholder)\nEsc: pause" % part_index

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_P:
		_complete_part()

func _complete_part() -> void:
	var app := get_parent()
	if app and app.has_method("unlock_part"):
		app.call("unlock_part", part_index + 1)
	if app and app.has_method("show_main_menu"):
		app.call("show_main_menu")



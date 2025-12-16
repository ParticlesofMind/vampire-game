extends Node3D

@onready var status_label: Label = %StatusLabel

func _ready() -> void:
	_ensure_input_actions()
	status_label.text = "Vampire Game (Godot 4.5.1, 3D)\nWASD move • Mouse look • Space jump • Shift sprint • Esc quit"
	print("Main ready")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()

func _ensure_input_actions() -> void:
	_ensure_key_action("move_forward", [KEY_W, KEY_UP])
	_ensure_key_action("move_back", [KEY_S, KEY_DOWN])
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("jump", [KEY_SPACE])
	_ensure_key_action("sprint", [KEY_SHIFT])

func _ensure_key_action(action_name: StringName, keycodes: Array[int]) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)

	# Only add missing keys (avoid duplicates if you later set these in the editor).
	var existing_keycodes: Dictionary = {}
	for ev in InputMap.action_get_events(action_name):
		if ev is InputEventKey:
			existing_keycodes[ev.keycode] = true

	for kc in keycodes:
		if existing_keycodes.has(kc):
			continue
		var e := InputEventKey.new()
		e.keycode = kc
		InputMap.action_add_event(action_name, e)



extends Node

const SAVE_PATH := "user://save.cfg"

@export var main_menu_scene: PackedScene
@export var part_1_scene: PackedScene
@export var part_2_scene: PackedScene
@export var part_3_scene: PackedScene
@export var pause_menu_scene: PackedScene

var _current_scene: Node = null
var _pause_menu: CanvasLayer = null
var _unlocked_part: int = 1

func _ready() -> void:
	_ensure_input_actions()
	_load_save()
	show_main_menu()

func show_main_menu() -> void:
	_set_paused(false)
	_set_scene(main_menu_scene)

	# Wire menu callbacks if present.
	var menu := _current_scene
	if menu and menu.has_signal("start_part"):
		menu.connect("start_part", Callable(self, "_on_start_part"))
	if menu and menu.has_signal("quit_game"):
		menu.connect("quit_game", Callable(self, "_on_quit_game"))
	if menu and menu.has_method("set_unlocked_part"):
		menu.call("set_unlocked_part", _unlocked_part)

func start_part(part: int) -> void:
	_set_paused(false)
	match part:
		1:
			_set_scene(part_1_scene)
		2:
			_set_scene(part_2_scene)
		3:
			_set_scene(part_3_scene)
		_:
			_set_scene(part_1_scene)

func _unhandled_input(event: InputEvent) -> void:
	# In-game: Esc toggles pause menu. In menus: it does nothing.
	if event.is_action_pressed("ui_cancel") and _current_scene and _current_scene.name.begins_with("Part"):
		_toggle_pause()

func _ensure_input_actions() -> void:
	# Movement/actions (created at runtime so the project runs even on a fresh clone).
	_ensure_key_action("move_forward", [KEY_W, KEY_UP])
	_ensure_key_action("move_back", [KEY_S, KEY_DOWN])
	_ensure_key_action("move_left", [KEY_A, KEY_LEFT])
	_ensure_key_action("move_right", [KEY_D, KEY_RIGHT])
	_ensure_key_action("jump", [KEY_SPACE])
	_ensure_key_action("sprint", [KEY_SHIFT])

func _toggle_pause() -> void:
	if _pause_menu == null:
		_pause_menu = pause_menu_scene.instantiate() as CanvasLayer
		add_child(_pause_menu)
		if _pause_menu.has_signal("resume"):
			_pause_menu.connect("resume", Callable(self, "_on_resume"))
		if _pause_menu.has_signal("back_to_menu"):
			_pause_menu.connect("back_to_menu", Callable(self, "_on_back_to_menu"))
		if _pause_menu.has_signal("quit_game"):
			_pause_menu.connect("quit_game", Callable(self, "_on_quit_game"))

	_pause_menu.visible = not _pause_menu.visible
	_set_paused(_pause_menu.visible)

func _set_paused(paused: bool) -> void:
	get_tree().paused = paused
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)

func unlock_part(part: int) -> void:
	if part > _unlocked_part:
		_unlocked_part = clamp(part, 1, 3)
		_save()

func _set_scene(scene: PackedScene) -> void:
	if scene == null:
		push_error("App: scene not assigned")
		return
	if _current_scene:
		_current_scene.queue_free()
	_current_scene = scene.instantiate()
	add_child(_current_scene)

func _on_start_part(part: int) -> void:
	start_part(part)

func _on_resume() -> void:
	if _pause_menu:
		_pause_menu.visible = false
	_set_paused(false)

func _on_back_to_menu() -> void:
	if _pause_menu:
		_pause_menu.visible = false
	show_main_menu()

func _on_quit_game() -> void:
	get_tree().quit()

func _load_save() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err == OK:
		_unlocked_part = int(cfg.get_value("progress", "unlocked_part", 1))
		_unlocked_part = clamp(_unlocked_part, 1, 3)

func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "unlocked_part", _unlocked_part)
	cfg.save(SAVE_PATH)



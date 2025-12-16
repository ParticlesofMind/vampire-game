extends Control

signal start_part(part: int)
signal quit_game()

@onready var btn_new: Button = %NewGameButton
@onready var btn_continue: Button = %ContinueButton
@onready var btn_part1: Button = %Part1Button
@onready var btn_part2: Button = %Part2Button
@onready var btn_part3: Button = %Part3Button
@onready var btn_quit: Button = %QuitButton

var _unlocked_part: int = 1

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	btn_new.pressed.connect(func() -> void: emit_signal("start_part", 1))
	btn_continue.pressed.connect(_on_continue)
	btn_part1.pressed.connect(func() -> void: emit_signal("start_part", 1))
	btn_part2.pressed.connect(func() -> void: emit_signal("start_part", 2))
	btn_part3.pressed.connect(func() -> void: emit_signal("start_part", 3))
	btn_quit.pressed.connect(func() -> void: emit_signal("quit_game"))

	_refresh()

func set_unlocked_part(part: int) -> void:
	_unlocked_part = clamp(part, 1, 3)
	_refresh()

func _refresh() -> void:
	btn_continue.disabled = (_unlocked_part <= 1)
	btn_part2.disabled = (_unlocked_part < 2)
	btn_part3.disabled = (_unlocked_part < 3)

func _on_continue() -> void:
	emit_signal("start_part", _unlocked_part)



extends CanvasLayer

signal resume()
signal back_to_menu()
signal quit_game()

@onready var btn_resume: Button = %ResumeButton
@onready var btn_menu: Button = %MenuButton
@onready var btn_quit: Button = %QuitButton

func _ready() -> void:
	btn_resume.pressed.connect(func() -> void: emit_signal("resume"))
	btn_menu.pressed.connect(func() -> void: emit_signal("back_to_menu"))
	btn_quit.pressed.connect(func() -> void: emit_signal("quit_game"))



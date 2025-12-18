extends Control

signal start_part(part: int)
signal quit_game()

@onready var btn_new: Button = %NewGameButton
@onready var btn_continue: Button = %ContinueButton
@onready var btn_part1: Button = %Part1Button
@onready var btn_part2: Button = %Part2Button
@onready var btn_part3: Button = %Part3Button
@onready var btn_quit: Button = %QuitButton

@onready var slide_heading: Label = %SlideHeading
@onready var slide_body: Label = %SlideBody
@onready var slide_index: Label = %SlideIndex
@onready var btn_prev_slide: Button = %PrevSlideButton
@onready var btn_next_slide: Button = %NextSlideButton

var _unlocked_part: int = 1
var _slide_idx: int = 0

const _SLIDES := [
	{
		"title": "A Bloodline Awakens",
		"body": "New York, 1918. Fog, gaslight, and whispers.\nExplore the night and uncover what hunts you back."
	},
	{
		"title": "Steel, Silk, and Shadow",
		"body": "A simple journey—movement, discovery, and story.\n(Replace this panel later with real screenshots.)"
	},
]

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	btn_new.pressed.connect(func() -> void: emit_signal("start_part", 1))
	btn_continue.pressed.connect(_on_continue)
	btn_part1.pressed.connect(func() -> void: emit_signal("start_part", 1))
	btn_part2.pressed.connect(func() -> void: emit_signal("start_part", 2))
	btn_part3.pressed.connect(func() -> void: emit_signal("start_part", 3))
	btn_quit.pressed.connect(func() -> void: emit_signal("quit_game"))

	btn_prev_slide.pressed.connect(func() -> void: _set_slide(_slide_idx - 1))
	btn_next_slide.pressed.connect(func() -> void: _set_slide(_slide_idx + 1))

	_apply_victorian_theme()
	_refresh()
	_set_slide(0)

func set_unlocked_part(part: int) -> void:
	_unlocked_part = clamp(part, 1, 3)
	_refresh()

func _refresh() -> void:
	btn_continue.disabled = (_unlocked_part <= 1)
	btn_part2.disabled = (_unlocked_part < 2)
	btn_part3.disabled = (_unlocked_part < 3)

func _on_continue() -> void:
	emit_signal("start_part", _unlocked_part)

func _set_slide(idx: int) -> void:
	if _SLIDES.is_empty():
		return
	_slide_idx = posmod(idx, _SLIDES.size())
	var s: Dictionary = _SLIDES[_slide_idx]
	slide_heading.text = str(s.get("title", ""))
	slide_body.text = str(s.get("body", ""))
	slide_index.text = "%d / %d" % [_slide_idx + 1, _SLIDES.size()]

func _apply_victorian_theme() -> void:
	# A simple built-in theme (no external assets) with a classy gothic palette.
	var t := Theme.new()

	# Global defaults.
	t.set_color("font_color", "Control", Color(0.92, 0.86, 0.78))
	t.set_color("font_outline_color", "Control", Color(0.0, 0.0, 0.0, 0.65))
	t.set_constant("outline_size", "Control", 1)
	t.set_color("font_color_disabled", "Control", Color(0.55, 0.52, 0.50))
	t.set_color("caret_color", "LineEdit", Color(0.95, 0.89, 0.82))

	# Panels.
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.08, 0.05, 0.07)
	panel.border_color = Color(0.35, 0.11, 0.18)
	panel.border_width_left = 2
	panel.border_width_top = 2
	panel.border_width_right = 2
	panel.border_width_bottom = 2
	panel.corner_radius_top_left = 10
	panel.corner_radius_top_right = 10
	panel.corner_radius_bottom_left = 10
	panel.corner_radius_bottom_right = 10
	panel.content_margin_left = 10
	panel.content_margin_right = 10
	panel.content_margin_top = 10
	panel.content_margin_bottom = 10
	t.set_stylebox("panel", "PanelContainer", panel)

	# Buttons.
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = Color(0.10, 0.06, 0.09)
	btn_normal.border_color = Color(0.42, 0.14, 0.22)
	btn_normal.border_width_left = 2
	btn_normal.border_width_top = 2
	btn_normal.border_width_right = 2
	btn_normal.border_width_bottom = 2
	btn_normal.corner_radius_top_left = 8
	btn_normal.corner_radius_top_right = 8
	btn_normal.corner_radius_bottom_left = 8
	btn_normal.corner_radius_bottom_right = 8
	btn_normal.content_margin_left = 14
	btn_normal.content_margin_right = 14
	btn_normal.content_margin_top = 10
	btn_normal.content_margin_bottom = 10

	var btn_hover := btn_normal.duplicate()
	btn_hover.bg_color = Color(0.13, 0.07, 0.10)
	btn_hover.border_color = Color(0.62, 0.21, 0.33)

	var btn_pressed := btn_normal.duplicate()
	btn_pressed.bg_color = Color(0.16, 0.08, 0.12)
	btn_pressed.border_color = Color(0.78, 0.28, 0.42)

	var btn_disabled := btn_normal.duplicate()
	btn_disabled.bg_color = Color(0.07, 0.05, 0.06)
	btn_disabled.border_color = Color(0.20, 0.10, 0.12)

	t.set_stylebox("normal", "Button", btn_normal)
	t.set_stylebox("hover", "Button", btn_hover)
	t.set_stylebox("pressed", "Button", btn_pressed)
	t.set_stylebox("disabled", "Button", btn_disabled)
	t.set_color("font_color", "Button", Color(0.95, 0.89, 0.82))
	t.set_color("font_hover_color", "Button", Color(1.0, 0.93, 0.88))
	t.set_color("font_pressed_color", "Button", Color(1.0, 0.93, 0.88))
	t.set_color("font_disabled_color", "Button", Color(0.55, 0.52, 0.50))
	t.set_constant("h_separation", "Button", 8)

	# Labels: give headings a little extra weight via spacing and color.
	t.set_color("font_color", "Label", Color(0.92, 0.86, 0.78))
	t.set_color("font_shadow_color", "Label", Color(0.0, 0.0, 0.0, 0.55))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)

	theme = t


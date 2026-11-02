extends RefCounted
## Styles of the interface. The pictures in res://assets/ui are saved at x2 and used at 1:1.

const TEXT_COLOR := Color("f4f2ea")
const BUTTON_MARGIN := 14
const CHOICE_MARGIN := 10
const PANEL_MARGIN := 16


static func box(file: String, margin: int) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/ui/%s.png" % file)
	style.set_texture_margin_all(margin)
	style.set_content_margin_all(margin)
	return style


static func _dress(target: Button, normal: StyleBox, hover: StyleBox, pressed: StyleBox, font_size: int) -> void:
	target.add_theme_stylebox_override("normal", normal)
	target.add_theme_stylebox_override("hover", hover)
	target.add_theme_stylebox_override("pressed", pressed)
	target.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	target.add_theme_font_size_override("font_size", font_size)
	target.add_theme_color_override("font_color", TEXT_COLOR)
	target.add_theme_color_override("font_hover_color", Color.WHITE)
	target.add_theme_color_override("font_pressed_color", TEXT_COLOR)
	target.add_theme_color_override("font_focus_color", Color.WHITE)
	# the keyboard has no hover, so a focused button takes the hover look
	target.focus_entered.connect(func(): target.add_theme_stylebox_override("normal", hover))
	target.focus_exited.connect(func(): target.add_theme_stylebox_override("normal", normal))


static func button(text: String, width: float) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(width, 64)
	_dress(result, box("button_normal", BUTTON_MARGIN), box("button_hover", BUTTON_MARGIN), box("button_pressed", BUTTON_MARGIN), 26)
	return result


static func choice(text: String, width: float) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(width, 48)
	result.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_dress(result, box("choice_normal", CHOICE_MARGIN), box("choice_hover", CHOICE_MARGIN), box("choice_hover", CHOICE_MARGIN), 22)
	return result

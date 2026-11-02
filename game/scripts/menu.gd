extends Control
## Start screen: a picture of the ander, the logo and two buttons.

const UiKit = preload("res://scripts/ui_kit.gd")
const GAME_SCENE := "res://scenes/main.tscn"
const SCREEN_WIDTH := 1280.0
const LOGO_TOP := 64.0
const BUTTONS_TOP := 440.0
const BUTTON_WIDTH := 320.0


func _ready() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/ui/menu_bg.png")
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(background)

	var logo := TextureRect.new()
	logo.texture = load("res://assets/ui/logo.png")
	logo.position = Vector2((SCREEN_WIDTH - logo.texture.get_width()) / 2.0, LOGO_TOP)
	add_child(logo)

	var buttons := VBoxContainer.new()
	buttons.position = Vector2((SCREEN_WIDTH - BUTTON_WIDTH) / 2.0, BUTTONS_TOP)
	buttons.add_theme_constant_override("separation", 16)
	add_child(buttons)

	var start := UiKit.button("Начать", BUTTON_WIDTH)
	start.name = "StartGame"
	start.pressed.connect(func(): get_tree().change_scene_to_file(GAME_SCENE))
	buttons.add_child(start)

	var leave := UiKit.button("Выход", BUTTON_WIDTH)
	leave.pressed.connect(func(): get_tree().quit())
	buttons.add_child(leave)

	start.grab_focus()


extends CanvasLayer
## Dialogue window: a portrait, a name plate, the text and optional answers.
## There is no story here, the game calls it line by line:
##     dialog.show_line("guard", "Пропуск покажите, пожалуйста.")
##     await dialog.line_finished
##     dialog.show_choices(["Вот он", "Я первокурсник"])
##     var answer: int = await dialog.choice_made
##     dialog.close()

signal line_finished
signal choice_made(index: int)

const UiKit = preload("res://scripts/ui_kit.gd")
const CHARS_PER_SECOND := 45.0
const PANEL_RECT := Rect2(24, 528, 1232, 176)
const FRAME_POS := Vector2(32, 420)
const PORTRAIT_POS := Vector2(40, 428)
const PORTRAIT_SIZE := Vector2(256, 256)
const NAME_POS := Vector2(320, 500)
const NAME_SIZE := Vector2(300, 56)
const TEXT_TOP := 568.0
const TEXT_LEFT := 332.0
const TEXT_LEFT_NO_PORTRAIT := 60.0
const TEXT_RIGHT := 1228.0
const TEXT_HEIGHT := 120.0
const ARROW_POS := Vector2(1212, 664)
const ARROW_FRAMES := 4
const ARROW_FPS := 6.0
const CHOICES_POS := Vector2(720, 300)
const CHOICE_WIDTH := 520.0

var people := {}
var root: Control
var frame: TextureRect
var portrait: TextureRect
var name_plate: PanelContainer
var name_label: Label
var text_label: Label
var arrow: Sprite2D
var choices: VBoxContainer
var waiting := false
var arrow_time := 0.0
var text_tween: Tween
var pending_pages: Array[String] = []


func _ready() -> void:
	layer = 10
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://maps/characters.json"))
	for person in data["people"]:
		people[person["id"]] = person

	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.box("dialog_panel", UiKit.PANEL_MARGIN))
	panel.position = PANEL_RECT.position
	panel.size = PANEL_RECT.size
	root.add_child(panel)

	frame = TextureRect.new()
	frame.texture = load("res://assets/ui/portrait_frame.png")
	frame.position = FRAME_POS
	root.add_child(frame)

	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.position = PORTRAIT_POS
	portrait.size = PORTRAIT_SIZE
	root.add_child(portrait)

	name_plate = PanelContainer.new()
	name_plate.add_theme_stylebox_override("panel", UiKit.box("name_plate", UiKit.BUTTON_MARGIN))
	name_plate.position = NAME_POS
	name_plate.custom_minimum_size = NAME_SIZE
	root.add_child(name_plate)

	name_label = Label.new()
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_plate.add_child(name_label)

	text_label = Label.new()
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_label.add_theme_font_size_override("font_size", 26)
	text_label.add_theme_color_override("font_color", UiKit.TEXT_COLOR)
	text_label.position = Vector2(TEXT_LEFT, TEXT_TOP)
	text_label.size = Vector2(TEXT_RIGHT - TEXT_LEFT, TEXT_HEIGHT)
	root.add_child(text_label)

	arrow = Sprite2D.new()
	arrow.texture = load("res://assets/ui/next_arrow.png")
	arrow.hframes = ARROW_FRAMES
	arrow.centered = false
	arrow.position = ARROW_POS
	root.add_child(arrow)

	choices = VBoxContainer.new()
	choices.position = CHOICES_POS
	choices.add_theme_constant_override("separation", 8)
	root.add_child(choices)

	root.visible = false


func _process(delta: float) -> void:
	arrow_time += delta
	arrow.frame = int(arrow_time * ARROW_FPS) % ARROW_FRAMES


func is_open() -> bool:
	return root.visible


## who is an id from characters.json, emotion is "normal" or "smile".
func show_line(who: String, line: String, emotion := "normal") -> void:
	choices.visible = false
	if text_tween != null:
		text_tween.kill()
	var person: Dictionary = people.get(who, {})
	var path: String = person.get("portrait_" + emotion, "")
	var has_portrait := path != ""
	if has_portrait:
		portrait.texture = load(path)
	frame.visible = has_portrait
	portrait.visible = has_portrait
	var left := TEXT_LEFT if has_portrait else TEXT_LEFT_NO_PORTRAIT
	text_label.position.x = left
	text_label.size.x = TEXT_RIGHT - left
	name_plate.position.x = left - 12.0
	name_label.text = String(person.get("name", who))
	text_label.size.y = TEXT_HEIGHT
	pending_pages.clear()
	var page := ""
	var font := text_label.get_theme_font("font")
	for word: String in line.split(" ", false):
		var candidate := word if page.is_empty() else page + " " + word
		if not page.is_empty() and font.get_multiline_string_size(candidate,HORIZONTAL_ALIGNMENT_LEFT,text_label.size.x,26).y > TEXT_HEIGHT:
			pending_pages.append(page)
			page = word
		else:
			page = candidate
	pending_pages.append(page)
	_show_page(pending_pages.pop_front())
	root.visible = true


func _show_page(line: String) -> void:
	if text_tween != null:
		text_tween.kill()
	text_label.text = line
	text_label.visible_ratio = 0.0
	text_tween = create_tween()
	text_tween.tween_property(text_label, "visible_ratio", 1.0, line.length() / CHARS_PER_SECOND)
	arrow.visible = true
	waiting = true


func show_choices(options: Array) -> void:
	choices.visible = true
	for old in choices.get_children():
		old.queue_free()
	arrow.visible = false
	waiting = false
	root.visible = true
	for i in options.size():
		var button := UiKit.choice(String(options[i]), CHOICE_WIDTH)
		button.pressed.connect(_on_choice.bind(i))
		choices.add_child(button)
		if i == 0:
			button.grab_focus()


func close() -> void:
	if text_tween != null:
		text_tween.kill()
	root.visible = false
	waiting = false
	choices.visible = false
	pending_pages.clear()


func _on_choice(index: int) -> void:
	choices.visible = false
	for old in choices.get_children():
		old.queue_free()
	choice_made.emit(index)


func _unhandled_input(event: InputEvent) -> void:
	if not waiting or not (event.is_action_pressed("ui_accept") or event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	if text_label.visible_ratio < 1.0:
		if text_tween != null:
			text_tween.kill()
		text_label.visible_ratio = 1.0
		return
	if not pending_pages.is_empty():
		_show_page(pending_pages.pop_front())
		return
	waiting = false
	line_finished.emit()

extends CanvasLayer
## Compact, passive task list. It stays visible while a conversation changes progress.
const UiKit = preload("res://scripts/ui_kit.gd")
var clock: Label
var wallet: Label
var lesson: Label
var rows: Array[RichTextLabel] = []
var last_text := ""


func _ready() -> void:
	layer = 2
	var panel := PanelContainer.new()
	panel.name = "TaskList"
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_left = -368
	panel.offset_right = -16
	panel.offset_top = 12
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiKit.box("dialog_panel", 12))
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 7)
	panel.add_child(content)
	var header := HBoxContainer.new()
	content.add_child(header)
	clock = Label.new()
	clock.add_theme_font_size_override("font_size", 27)
	clock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(clock)
	wallet = Label.new()
	wallet.add_theme_font_size_override("font_size", 18)
	wallet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(wallet)
	lesson = Label.new()
	lesson.add_theme_font_size_override("font_size", 14)
	lesson.add_theme_color_override("font_color", Color("b9c9dc"))
	content.add_child(lesson)
	var heading := Label.new()
	heading.text = "ЗАДАНИЯ"
	heading.add_theme_font_size_override("font_size", 12)
	heading.add_theme_color_override("font_color", Color("b9c9dc"))
	content.add_child(heading)
	for i in range(3):
		var row := RichTextLabel.new()
		row.bbcode_enabled = true
		row.fit_content = true
		row.scroll_active = false
		row.custom_minimum_size.x = 328
		row.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_theme_font_size_override("normal_font_size", 16)
		content.add_child(row)
		rows.append(row)


func refresh(day, map_id: String) -> void:
	var tasks: Array[Dictionary] = day.tasks(map_id)
	var signature: String = day.clock_text() + str(day.money) + str(tasks) + day.lesson_hint(map_id)
	if signature == last_text:
		return
	last_text = signature
	clock.text = day.clock_text()
	wallet.text = "%d ₽" % day.money
	lesson.text = day.lesson_hint(map_id)
	for i in tasks.size():
		var task: Dictionary = tasks[i]
		var color := "91d9aa" if task["done"] else ("ffc384" if task.get("late",false) else "f4f2ea")
		var mark := "✓" if task["done"] else "•"
		rows[i].text = "[color=#%s]%s %s[/color]\n[font_size=13][color=#b9c9dc]%s[/color][/font_size]" % [color,mark,task["title"],task["detail"]]

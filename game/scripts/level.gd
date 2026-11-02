extends Node2D
## Playable campus route built from map data, animated tiles and character sheets.

const RouteMap = preload("res://scripts/route_map.gd")
const WalkVisual = preload("res://scripts/character_visual.gd")
const People = preload("res://scripts/campus_people.gd")
const EnvironmentAnimation = preload("res://scripts/environment_animation.gd")
const DialogBox = preload("res://scripts/dialog_box.gd")
const UiKit = preload("res://scripts/ui_kit.gd")
const CampusDay = preload("res://scripts/campus_day.gd")
const CampusDialogue = preload("res://scripts/campus_dialogue.gd")
const QuestTracker = preload("res://scripts/quest_tracker.gd")
const FixtureVisual = preload("res://scripts/fixture_visual.gd")
const DoorVisual = preload("res://scripts/door_visual.gd")
const ArchVisual = preload("res://scripts/arch_visual.gd")
const ATMVisual = preload("res://scripts/atm_visual.gd")
const SPEED := 4.0
const UNDER_DEPTH := 72.0
const TITLES := {
	"entrance": "Главный вход · 1 этаж",
	"corridor_1": "Коридор · 1 этаж",
	"corridor_4": "Компьютерные классы · 4 этаж",
	"class_1421": "Аудитория 1421",
	"winter_garden": "Зимний сад · галерея",
	"winter_garden_lower": "Зимний сад · кафе и нижний уровень",
}

var model = RouteMap.new()
var tileset: TileSet = preload("res://tileset.tres")
var level_root: Node2D
var hero: Node2D
var hero_sprite: Node2D
var camera: Camera2D
var hero_pos := Vector2.ZERO
var origin := Vector2.ZERO
var paused := false
var exit_cooldown := 0.0
var location_label: Label
var route_label: Label
var portal_label: Label
var pause_label: Label
var zoom_value := 1.5
var return_targets: Dictionary = {}
var people = People.new()
var environment_animation = EnvironmentAnimation.new()
var dialog
var door_nodes: Array[Node2D] = []
var pause_panel: Control
var conversation: Dictionary = {}
var conversation_phase := ""
var npc_lines: Dictionary = {}
var hud: CanvasLayer
var day = CampusDay.new()
var dialogue_rules = CampusDialogue.new()
var quest_tracker: CanvasLayer
var conversation_options: Array[Dictionary] = []


func _ready() -> void:
	_install_controls()
	model.initialize()
	tileset = tileset.duplicate(true)
	var atlas_source := tileset.get_source(0) as TileSetAtlasSource
	for floor_id: String in ["floor_a", "floor_class"]:
		var coords := _atlas(floor_id)
		atlas_source.create_alternative_tile(coords, 1)
		atlas_source.get_tile_data(coords, 1).texture_origin = atlas_source.get_tile_data(coords, 0).texture_origin + Vector2i(0, 16)
	environment_animation.setup(tileset,model.read_json("res://maps/anim.json"))
	npc_lines = model.read_json("res://maps/npc_lines.json")
	dialogue_rules.lines = npc_lines
	_make_hero()
	_make_hud()
	quest_tracker = QuestTracker.new()
	add_child(quest_tracker)
	_make_pause_menu()
	dialog = DialogBox.new()
	add_child(dialog)
	dialog.people["atm"] = {"name": "Банкомат · оплата услуг"}
	dialog.line_finished.connect(_on_dialog_line_finished)
	dialog.choice_made.connect(_on_dialog_choice)
	change_map("entrance")


func _physics_process(delta: float) -> void:
	hud.visible = not paused and not dialog.is_open()
	quest_tracker.visible = not paused
	if paused or dialog.is_open() or model.data.is_empty():
		exit_cooldown = maxf(exit_cooldown,0.25)
		hero_sprite.stop()
		return
	day.advance(delta, str(model.data["id"]))
	quest_tracker.refresh(day, str(model.data["id"]))
	people.tick(delta,model,to_screen,hero_pos)
	environment_animation.tick(delta,hero_pos)
	for door: Node2D in door_nodes:
		door.set_open(door.position.distance_to(hero.position)<80.0)
	exit_cooldown = maxf(0.0, exit_cooldown - delta)
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Screen-relative joystick movement: up on the stick moves up on the screen.
	var grid_dir := Vector2(dir.x + 2.0 * dir.y, 2.0 * dir.y - dir.x)
	if not grid_dir.is_zero_approx():
		grid_dir = grid_dir.normalized() * dir.length()
	var step := grid_dir * SPEED * delta
	var previous_position := hero_pos
	if not model.blocked(hero_pos + Vector2(step.x, 0.0)) and not people.blocks_walker(hero_pos + Vector2(step.x, 0.0)):
		hero_pos.x += step.x
	if not model.blocked(hero_pos + Vector2(0.0, step.y)) and not people.blocks_walker(hero_pos + Vector2(0.0, step.y)):
		hero_pos.y += step.y
	_place_hero()
	hero_sprite.advance(delta, hero_pos.distance_to(previous_position), dir)
	_update_portal_hint()
	if Input.is_action_just_pressed("interact") and exit_cooldown <= 0.0:
		if not use_exit():
			var atm: Dictionary = _nearby_atm()
			if not atm.is_empty():
				begin_talk({"spec": {"who": "atm", "x": atm["x"], "y": atm["y"]}})
			else:
				var npc: Dictionary = people.nearest(hero_pos)
				if not npc.is_empty():
					begin_talk(npc)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_route"):
		if dialog.is_open():
			_close_dialog()
			return
		paused = not paused
		pause_panel.visible = paused
		if paused:
			pause_panel.find_child("Resume",true,false).grab_focus()
	if event.is_action_pressed("zoom_in"):
		_set_zoom(zoom_value + 0.25)
	if event.is_action_pressed("zoom_out"):
		_set_zoom(zoom_value - 0.25)


func change_map(id: String, spawn: Array = []) -> void:
	if not model.load_map(id):
		portal_label.text = "Не удалось загрузить локацию"
		return
	people.reset()
	environment_animation.reset()
	door_nodes.clear()
	for portal: Dictionary in model.data.get("exits", []):
		if bool(portal.get("contextual_return", false)) and return_targets.has(id):
			var target: Dictionary = return_targets[id]
			portal["to"] = target["to"]
			portal["spawn"] = target["spawn"]
			portal["label"] = "Вернуться: " + str(target["title"])
	if hero.get_parent() != null:
		hero.get_parent().remove_child(hero)
	if is_instance_valid(level_root):
		level_root.free()
	level_root = Node2D.new()
	level_root.name = "Location"
	add_child(level_root)
	var under := str(model.data.get("under", ""))
	if not under.is_empty():
		var lower := Node2D.new()
		lower.position.y = UNDER_DEPTH
		level_root.add_child(lower)
		var lower_data := model.read_json("res://maps/%s.json" % under)
		var lower_world := _add_tiles(lower,lower_data)
		people.populate(lower_world,lower_data,false,to_screen,model.legend)
	var world := _add_tiles(level_root, model.data)
	people.populate(world,model.data,true,to_screen,model.legend)
	world.add_child(hero)
	var start: Array = spawn if not spawn.is_empty() else model.data["spawn"]
	hero_pos = Vector2(float(start[0]) + 0.5, float(start[1]) + 0.5)
	day.check_attendance(id)
	quest_tracker.refresh(day, id)
	_place_hero()
	camera.reset_smoothing()
	location_label.text = TITLES.get(id, str(model.data.get("title", id)))
	var directions := {
		"entrance": "Проход слева от гардероба — 1 этаж; лестница справа — 4 этаж",
		"corridor_1": "E у дверей — войти; лестница №2 справа в конце ведёт в зимний сад",
		"corridor_4": "Средняя дверь — аудитория 1421; левый конец коридора — зимний сад",
		"class_1421": "Можно осмотреть класс и вернуться через входную дверь",
		"winter_garden": "Две лестницы у проёма ведут к кафе на нижнем уровне",
		"winter_garden_lower": "Осмотрите кафе; лестницы возвращают на галерею",
	}
	route_label.text = directions.get(id, "E у входной двери — вернуться в коридор")
	exit_cooldown = 0.35
	_update_portal_hint()


func use_exit() -> bool:
	var portal: Dictionary = model.exit_at(hero_pos)
	if portal.is_empty():
		return false
	if bool(portal.get("remember_return", false)):
		return_targets[str(portal["to"])] = {"to": str(model.data["id"]), "spawn": portal["return_spawn"], "title": location_label.text}
	change_map(str(portal["to"]), portal["spawn"])
	return true


func _make_hero() -> void:
	hero = Node2D.new()
	hero.name = "Player"
	hero_sprite = WalkVisual.new()
	hero.add_child(hero_sprite)
	camera = Camera2D.new()
	camera.zoom = Vector2.ONE * zoom_value
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.offset = Vector2(0.0, -90.0)
	hero.add_child(camera)


func _add_tiles(parent: Node2D, data: Dictionary) -> Node2D:
	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tileset
	parent.add_child(floor_layer)
	origin = floor_layer.map_to_local(Vector2i.ZERO)
	var data_rows: Array = data["rows"]
	for y in range(data_rows.size()):
		var row: String = data_rows[y]
		for x in range(row.length()):
			var kind: Dictionary = model.legend.get(row[x], {})
			if bool(kind.get("floor", false)):
				var floor_id := str(data["floor"])
				for region: Dictionary in data.get("floor_regions", []):
					var bounds: Array = region["rect"]
					if Rect2(float(bounds[0]), float(bounds[1]), float(bounds[2]), float(bounds[3])).has_point(Vector2(x,y)):
						floor_id = str(region["tile"])
				floor_layer.set_cell(Vector2i(x, y), 0, _atlas(floor_id))
	var world := Node2D.new()
	world.name = "SortedObjects"
	world.y_sort_enabled = true
	parent.add_child(world)
	# Raised floor belongs below actors, never in furniture Y-sorting.
	var surfaces := TileMapLayer.new()
	surfaces.name = "Surfaces"
	surfaces.tile_set = tileset
	parent.add_child(surfaces)
	parent.move_child(surfaces, world.get_index())
	for layer_name: String in ["walls", "props"]:
		var layer := TileMapLayer.new()
		layer.name = layer_name.capitalize()
		layer.tile_set = tileset
		layer.y_sort_enabled = true
		world.add_child(layer)
		for item: Dictionary in data[layer_name]:
			var id := str(item["tile"])
			# Cut away the near-side room walls so they do not hide the corridor.
			if bool(item.get("cutaway", false)) and id in ["wall_y", "door_y", "wall_x", "door_x"]:
				if id in ["wall_y", "wall_x"]:
					var edge := Line2D.new()
					edge.width = 6.0
					edge.default_color = Color("#8597a3")
					edge.add_point(to_screen(Vector2(float(item["x"]), float(item["y"]))))
					var end := Vector2(float(item["x"]), float(item["y"])) + (Vector2.RIGHT if id == "wall_x" else Vector2.DOWN)
					edge.add_point(to_screen(end))
					parent.add_child(edge)
				continue
			var cell := Vector2i(int(item["x"]), int(item["y"]))
			if id in ["platform", "coffee_floor"]:
				# Only the top face inside the platform: repeated front risers cause seams.
				surfaces.set_cell(cell, 0, _atlas("floor_a" if id == "platform" else "floor_class"), 1)
			elif id in ["blue_step_0", "blue_step_1"]:
				var step_layer := TileMapLayer.new()
				step_layer.tile_set = tileset
				surfaces.add_child(step_layer)
				step_layer.set_cell(cell, 0, _atlas(id))
			else:
				environment_animation.set_visual(layer,cell,id,_atlas(id),str(data["id"])==str(model.data["id"]))
	for arch_data: Dictionary in data.get("arches", []):
		var arch := ArchVisual.new()
		arch.name = "Archway"
		arch.axis = str(arch_data.get("axis", "y"))
		arch.position = floor_layer.map_to_local(Vector2i(int(arch_data["x"]),int(arch_data["y"])))
		world.add_child(arch)
	for atm_data: Dictionary in data.get("atms", []):
		var atm := ATMVisual.new()
		atm.name = "ATM"
		atm.position = floor_layer.map_to_local(Vector2i(int(atm_data["x"]),int(atm_data["y"])))
		world.add_child(atm)
	for door: Dictionary in data.get("doors", []):
		var leaf := DoorVisual.new()
		leaf.name = "DoorLeaf"
		leaf.axis = str(door.get("axis", "y"))
		leaf.glass = bool(door.get("glass", false))
		leaf.position = floor_layer.map_to_local(Vector2i(int(door["x"]), int(door["y"])))
		world.add_child(leaf)
		if str(data["id"])==str(model.data["id"]):
			door_nodes.append(leaf)
	for fixture: Dictionary in data.get("fixtures", []):
		var visual := FixtureVisual.new()
		visual.fixture_type = str(fixture["type"])
		visual.position = to_screen(Vector2(float(fixture["x"]) + 0.5, float(fixture["y"]) + 0.5))
		world.add_child(visual)
	for marker: Dictionary in data.get("portal_markers", []):
		var marker_pos: Array = marker["pos"]
		var point := to_screen(Vector2(float(marker_pos[0]), float(marker_pos[1])))
		var threshold := Line2D.new()
		threshold.points = PackedVector2Array([point+Vector2(-16,0),point+Vector2(0,8),point+Vector2(16,0)])
		threshold.default_color = Color("#e5b65a")
		threshold.width = 3.0
		parent.add_child(threshold)
		var sign := Label.new()
		sign.text = str(marker["text"])
		var offset: Array = marker.get("offset", [-50,-80])
		sign.position = point + Vector2(float(offset[0]), float(offset[1]))
		sign.add_theme_font_size_override("font_size", 14)
		sign.add_theme_color_override("font_color", Color("#ffe5aa"))
		sign.add_theme_color_override("font_outline_color", Color("#182131"))
		sign.add_theme_constant_override("outline_size", 5)
		parent.add_child(sign)
	for marker: Dictionary in data.get("labels", []):
		_add_map_sign(parent,marker)
	return world


func _add_map_sign(parent: Node2D, marker: Dictionary) -> void:
	var sign := PanelContainer.new()
	sign.name = "MapSign"
	sign.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sign.z_index = 20
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color("#203b58")
	plate.border_color = Color("#8ba9bf")
	plate.set_border_width_all(1)
	plate.content_margin_left = 7
	plate.content_margin_right = 7
	plate.content_margin_top = 3
	plate.content_margin_bottom = 3
	sign.add_theme_stylebox_override("panel",plate)
	var label := Label.new()
	label.text = str(marker["text"])
	label.add_theme_font_size_override("font_size",14)
	label.add_theme_color_override("font_color",Color("#f4f2ea"))
	sign.add_child(label)
	parent.add_child(sign)
	sign.size = sign.get_combined_minimum_size()
	var offset: Array = marker.get("offset",[0,-100])
	sign.position = to_screen(Vector2(float(marker["x"]),float(marker["y"]))) + Vector2(float(offset[0]),float(offset[1])) - Vector2(sign.size.x/2.0,0)


func _atlas(id: String) -> Vector2i:
	var coordinates: Array = model.tiles[id]["atlas"]
	return Vector2i(int(coordinates[0]), int(coordinates[1]))


func to_screen(pos: Vector2) -> Vector2:
	return origin + Vector2((pos.x - pos.y) * 32.0, (pos.x + pos.y - 1.0) * 16.0)


func _place_hero() -> void:
	hero.position = to_screen(hero_pos)
	var kind: Dictionary = model.kind_at(hero_pos)
	hero_sprite.position.y = -float(kind.get("elevation", 0))


func _update_portal_hint() -> void:
	var portal: Dictionary = model.exit_at(hero_pos)
	portal_label.visible = not portal.is_empty()
	if not portal.is_empty():
		portal_label.text = "E / Enter / кнопка 1 — " + str(portal.get("label", TITLES.get(portal["to"], "Перейти")))
	else:
		if not _nearby_atm().is_empty():
			portal_label.visible = true
			portal_label.text = "E / кнопка 1 — банкомат: оплата бейджика"
			return
		var npc: Dictionary = people.nearest(hero_pos)
		if not npc.is_empty():
			portal_label.visible = true
			var who := str(npc["spec"]["who"])
			portal_label.text = "E / кнопка 1 — поговорить: " + str(dialog.people.get(who,{}).get("name",who))


func _set_zoom(value: float) -> void:
	zoom_value = clampf(value, 0.75, 2.0)
	if camera != null:
		camera.zoom = Vector2.ONE * zoom_value


func begin_talk(npc: Dictionary) -> void:
	hud.visible = false
	conversation = npc
	conversation_phase = "greeting"
	var who := str(npc["spec"]["who"])
	var spec: Dictionary = npc["spec"]
	var key := "%s/%s/%s/%s" % [model.data["id"],who,spec.get("x",0),spec.get("y",0)]
	dialog.show_line(who,dialogue_rules.greeting(who,key,day,str(model.data["id"])))
	quest_tracker.refresh(day,str(model.data["id"]))
	hero_sprite.stop()


func _on_dialog_line_finished() -> void:
	if conversation_phase == "greeting":
		conversation_phase = "choices"
		var who := str(conversation["spec"]["who"])
		conversation_options = dialogue_rules.options(who,day,str(model.data["id"]))
		var labels: Array[String] = []
		for option: Dictionary in conversation_options:
			labels.append(str(option["label"]))
		dialog.show_choices(labels)
	else:
		_close_dialog()


func _on_dialog_choice(index: int) -> void:
	if conversation_phase != "choices" or index < 0 or index >= conversation_options.size():
		return
	var action := str(conversation_options[index]["action"])
	if action == "close":
		_close_dialog()
		return
	var who := str(conversation["spec"]["who"])
	conversation_phase = "answer"
	var directions := {
		"entrance":"Боковая арка слева от гардероба ведёт в коридор первого этажа. Лестница справа — на четвёртый этаж.",
		"corridor_1":"У подписанной двери нажмите E. Лестница №2 справа в конце коридора ведёт в зимний сад.",
		"corridor_4":"Средняя дверь ведёт в класс 1421. В левом конце коридора — лестница к зимнему саду.",
		"winter_garden":"Две лестницы у проёма ведут на нижний уровень, к кафе. Вернуться в коридор можно через вход в галерею.",
		"winter_garden_lower":"Обе лестницы ведут обратно на галерею. У лестницы нажмите E.",
	}
	var answer: String = str(directions.get(str(model.data["id"]),"У входной двери нажмите E, чтобы вернуться в коридор.")) if action == "directions" else dialogue_rules.answer(action,who,day,str(model.data["id"]))
	dialog.show_line(who,answer,"smile")
	quest_tracker.refresh(day,str(model.data["id"]))


func _close_dialog() -> void:
	dialog.close()
	conversation_phase = ""
	conversation_options.clear()
	exit_cooldown = 0.3
	quest_tracker.refresh(day,str(model.data["id"]))


func _nearby_atm() -> Dictionary:
	for atm: Dictionary in model.data.get("atms", []):
		var position := Vector2(float(atm["x"])+0.5,float(atm["y"])+0.5)
		# Interact from the floor in front of the solid machine, not through the wall.
		if hero_pos.distance_to(position) < 2.0 and hero_pos.y >= float(atm["y"])+0.75:
			return atm
	return {}


func _make_pause_menu() -> void:
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	pause_panel = Control.new()
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(pause_panel)
	var shade := ColorRect.new()
	shade.color = Color(0.03,0.05,0.09,0.8)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(shade)
	var title := Label.new()
	title.text = "Пауза"
	title.position = Vector2(480,180)
	title.size = Vector2(320,60)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size",36)
	pause_panel.add_child(title)
	var buttons := VBoxContainer.new()
	buttons.position = Vector2(480,280)
	buttons.add_theme_constant_override("separation",16)
	pause_panel.add_child(buttons)
	var resume := UiKit.button("Продолжить",320)
	resume.name = "Resume"
	resume.pressed.connect(func(): paused=false;pause_panel.hide())
	buttons.add_child(resume)
	var menu := UiKit.button("В главное меню",320)
	menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	buttons.add_child(menu)
	var leave := UiKit.button("Выход",320)
	leave.pressed.connect(func(): get_tree().quit())
	buttons.add_child(leave)
	pause_panel.hide()


func _make_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)
	var top := ColorRect.new()
	top.color = Color(0.05, 0.08, 0.13, 0.88)
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_bottom = 78.0
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(top)
	location_label = Label.new()
	location_label.position = Vector2(24, 12)
	location_label.add_theme_font_size_override("font_size", 23)
	location_label.size.x = 875
	location_label.clip_text = true
	hud.add_child(location_label)
	route_label = Label.new()
	route_label.position = Vector2(24, 43)
	route_label.add_theme_font_size_override("font_size", 15)
	route_label.size.x = 875
	route_label.clip_text = true
	route_label.add_theme_color_override("font_color", Color("#b9c9dc"))
	hud.add_child(route_label)
	var help := Label.new()
	help.text = "WASD / стрелки / джойстик — ходить     E / кнопка 1 — переход / разговор     Колесо / + − — масштаб     Esc / Start — пауза"
	help.add_theme_font_size_override("font_size", 15)
	help.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	help.position = Vector2(24, -34)
	help.add_theme_color_override("font_shadow_color", Color.BLACK)
	help.add_theme_constant_override("shadow_offset_x", 2)
	help.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(help)
	portal_label = Label.new()
	portal_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	portal_label.offset_top = -90.0
	portal_label.offset_bottom = -52.0
	portal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portal_label.add_theme_font_size_override("font_size", 21)
	portal_label.add_theme_color_override("font_color", Color("#ffe6a1"))
	portal_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	portal_label.add_theme_constant_override("shadow_offset_x", 2)
	portal_label.add_theme_constant_override("shadow_offset_y", 2)
	hud.add_child(portal_label)
	pause_label = Label.new()
	pause_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_label.offset_left = -240.0
	pause_label.offset_right = 240.0
	pause_label.offset_top = -30.0
	pause_label.text = "Пауза · Esc / Start — продолжить"
	pause_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_label.add_theme_font_size_override("font_size", 25)
	pause_label.visible = false
	hud.add_child(pause_label)


func _install_controls() -> void:
	var accept_key := InputEventKey.new()
	accept_key.physical_keycode = KEY_E
	_bind_control("ui_accept", accept_key)
	for action: String in ["move_left", "move_right", "move_up", "move_down", "interact", "pause_route", "zoom_in", "zoom_out"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action, 0.22)
	var keys := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_ENTER], "pause_route": [KEY_ESCAPE],
		"zoom_in": [KEY_EQUAL, KEY_KP_ADD], "zoom_out": [KEY_MINUS, KEY_KP_SUBTRACT],
	}
	for action: String in keys:
		for code: int in keys[action]:
			var key := InputEventKey.new()
			key.physical_keycode = code
			_bind_control(action, key)
	var buttons := {"move_left": JOY_BUTTON_DPAD_LEFT, "move_right": JOY_BUTTON_DPAD_RIGHT, "move_up": JOY_BUTTON_DPAD_UP, "move_down": JOY_BUTTON_DPAD_DOWN, "interact": JOY_BUTTON_A, "pause_route": JOY_BUTTON_START}
	for action: String in buttons:
		var button := InputEventJoypadButton.new()
		button.button_index = buttons[action]
		_bind_control(action, button)
	var axes := {"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0], "move_up": [JOY_AXIS_LEFT_Y, -1.0], "move_down": [JOY_AXIS_LEFT_Y, 1.0]}
	for action: String in axes:
		var axis := InputEventJoypadMotion.new()
		axis.axis = axes[action][0]
		axis.axis_value = axes[action][1]
		_bind_control(action, axis)
	for action: String in ["zoom_in", "zoom_out"]:
		var wheel := InputEventMouseButton.new()
		wheel.button_index = MOUSE_BUTTON_WHEEL_UP if action == "zoom_in" else MOUSE_BUTTON_WHEEL_DOWN
		_bind_control(action, wheel)


func _bind_control(action: String, event: InputEvent) -> void:
	if not InputMap.action_has_event(action,event):
		InputMap.action_add_event(action,event)

extends SceneTree
var failures: Array[String] = []

func _initialize():
	call_deferred("run_checks")

func check(value: bool, message: String):
	if not value:
		failures.append(message)

func labels_in(node: Node) -> Array[String]:
	var texts: Array[String] = []
	if node is Label:
		texts.append(node.text)
	for child: Node in node.get_children():
		texts.append_array(labels_in(child))
	return texts

func run_checks():
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.paused = true
	await process_frame
	game.change_map("corridor_4")
	var texts := labels_in(game.level_root)
	for number: String in ["1413","1417","1421","1425","1429"]:
		check(texts.any(func(text): return number in text), "Fourth-floor door sign missing: " + number)
	game.change_map("corridor_1")
	texts = labels_in(game.level_root)
	for room: String in ["Аудитория 1101","Аудитория 1102","Аудитория 1103"]:
		check(room in texts, "First-floor sign lost: " + room)
	var old_name := RegEx.new()
	old_name.compile("(?i)андер")
	for map_id: String in game.model.MAP_IDS:
		game.change_map(map_id)
		var content := FileAccess.get_file_as_string("res://maps/%s.json" % map_id)
		check(old_name.search(content) == null, "Old location name in map: " + map_id)
		check(old_name.search(game.location_label.text) == null, "Old HUD title: " + map_id)
		for spec: Dictionary in game.model.data.get("labels", []):
			check(str(spec["text"]) in labels_in(game.level_root), "Map label not rendered: " + str(spec["text"]))
	for path: String in ["res://scripts/level.gd","res://scripts/campus_day.gd","res://scripts/campus_dialogue.gd","res://maps/npc_lines.json"]:
		check(old_name.search(FileAccess.get_file_as_string(path)) == null, "Old name in active UI/dialogue source: " + path)
	if failures.is_empty():
		print("PASS navigation: all map labels, classroom signs on both floors, winter garden name in HUD/dialogue/data")
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)

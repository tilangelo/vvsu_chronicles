extends SceneTree
## Run: godot --headless --path game --script res://tools/check_route.gd

const RouteMap = preload("res://scripts/route_map.gd")
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var model = RouteMap.new()
	model.initialize()
	var all_data: Dictionary = {}
	for id: String in RouteMap.MAP_IDS:
		all_data[id] = model.read_json("res://maps/%s.json" % id)
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	var initial_position: Vector2 = scene.hero_pos
	Input.action_press("move_up")
	for frame in range(20):
		await physics_frame
	Input.action_release("move_up")
	_check(scene.hero_pos.distance_to(initial_position) > 0.1, "Keyboard action did not move the hero")
	_check(not scene.model.blocked(scene.hero_pos), "Movement ended in an obstacle")
	scene.paused = true
	var paused_position: Vector2 = scene.hero_pos
	Input.action_press("move_up")
	for frame in range(3):
		await physics_frame
	Input.action_release("move_up")
	_check(scene.hero_pos.is_equal_approx(paused_position), "Pause did not stop movement")
	print("PASS input movement and pause")
	var tested_exits := 0
	for id: String in RouteMap.MAP_IDS:
		model.load_map(id)
		var spawn: Array = model.data["spawn"]
		var start := Vector2(float(spawn[0]) + 0.5, float(spawn[1]) + 0.5)
		_check(not model.blocked(start), id + ": default spawn is blocked")
		var reachable := _reachable(model, start)
		# Quest contacts must be usable from the connected walkable area.
		scene.change_map(id)
		var contacts: Array[String] = []
		if id == "entrance": contacts = ["wardrobe"]
		if id in ["corridor_1", "ander"]: contacts.append("mentor")
		if id == "class_1421": contacts.append("teacher_m")
		for who: String in contacts:
			var accessible := false
			for node: Vector2i in reachable:
				var npc: Dictionary = scene.people.nearest(Vector2(node) * 0.5)
				if not npc.is_empty() and str(npc["spec"]["who"]) == who:
					accessible = true
					break
			_check(accessible, id + ": unreachable quest contact " + who)
		if not model.data.get("atms", []).is_empty():
			var accessible := false
			for node: Vector2i in reachable:
				scene.hero_pos = Vector2(node) * 0.5
				if not scene._nearby_atm().is_empty():
					accessible = true
					break
			_check(accessible, id + ": unreachable ATM interaction")
		for layer_name: String in ["walls", "props"]:
			for item: Dictionary in model.data[layer_name]:
				_check(model.tiles.has(str(item["tile"])), id + ": unknown tile")
		for from_id: String in all_data:
			for portal: Dictionary in all_data[from_id]["exits"]:
				if str(portal["to"]) == id:
					var landing: Array = portal["spawn"]
					var point := Vector2(float(landing[0]) + 0.5, float(landing[1]) + 0.5)
					_check(not model.blocked(point), from_id + " -> " + id + ": blocked landing")
					_check(reachable.has(Vector2i(roundi(point.x * 2.0), roundi(point.y * 2.0))), id + ": disconnected landing")
		for portal: Dictionary in model.data["exits"]:
			var found := false
			var trigger_point := Vector2.ZERO
			var r: Array = portal["rect"]
			var rect := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).grow(0.18)
			for node: Vector2i in reachable:
				var point := Vector2(node) * 0.5
				if rect.has_point(point):
					found = true
					trigger_point = point
					break
			_check(found, id + " -> " + str(portal["to"]) + ": unreachable exit")
			if found:
				scene.return_targets.clear()
				scene.change_map(id)
				scene.hero_pos = trigger_point
				_check(scene.use_exit(), id + ": interaction failed")
				_check(str(scene.model.data["id"]) == str(portal["to"]), id + ": wrong destination")
				tested_exits += 1
		print("PASS map ", id, " | reachable samples: ", reachable.size())
	scene.free()
	if failures.is_empty():
		print("PASS route: ", RouteMap.MAP_IDS.size(), " maps, ", tested_exits, " transitions, all landing points reachable")
		quit(0)
	else:
		for failure: String in failures:
			push_error(failure)
		quit(1)


func _reachable(model, start: Vector2) -> Dictionary:
	var key := Vector2i(roundi(start.x * 2.0), roundi(start.y * 2.0))
	var visited := {key: true}
	var queue: Array[Vector2i] = [key]
	var index := 0
	while index < queue.size():
		var point: Vector2i = queue[index]
		index += 1
		for delta: Vector2i in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next := point + delta
			if not visited.has(next) and not model.blocked(Vector2(next) * 0.5):
				visited[next] = true
				queue.append(next)
	return visited


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)

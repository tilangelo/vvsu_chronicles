extends RefCounted
const Person = preload("res://scripts/person.gd")
var active: Array[Dictionary] = []

func reset() -> void:
	active.clear()

func populate(world: Node2D, data: Dictionary, is_active: bool, project: Callable, legend: Dictionary) -> void:
	for spec: Dictionary in data.get("npcs", []):
		var person := Person.new()
		person.name = "Person_" + str(spec["who"])
		person.setup(str(spec["who"]))
		person.set_pose(str(spec.get("pose","idle")), str(spec.get("facing","s")))
		var pos := Vector2(float(spec["x"])+0.5,float(spec["y"])+0.5)
		var row: String = data["rows"][int(spec["y"])]
		var kind: Dictionary = legend.get(row[int(spec["x"])], {})
		var lift := float(spec.get("lift",kind.get("elevation",0)))
		person.place(project.call(pos),lift)
		world.add_child(person)
		if is_active:
			var points: Array[Vector2] = [pos]
			for point: Array in spec.get("path", []):
				points.append(Vector2(float(point[0])+0.5,float(point[1])+0.5))
			active.append({"person":person,"spec":spec,"pos":pos,"lift":lift,"points":points,"next":1})

func tick(delta: float, model, project: Callable, player_pos: Vector2) -> void:
	for npc: Dictionary in active:
		var points: Array = npc["points"]
		if points.size()<2:
			continue
		var pos: Vector2 = npc["pos"]
		var target: Vector2 = points[int(npc["next"])]
		var next := pos.move_toward(target,1.5*delta)
		if next.distance_to(player_pos)<0.65 or model.blocked(next):
			npc["person"].stop()
			continue
		var screen_step: Vector2 = project.call(next)-project.call(pos)
		npc["pos"] = next
		npc["person"].walk(screen_step,delta)
		npc["person"].place(project.call(next),float(model.kind_at(next).get("elevation",npc["lift"])))
		if next.distance_to(target)<0.03:
			npc["next"] = (int(npc["next"])+1)%points.size()

func nearest(pos: Vector2) -> Dictionary:
	var result: Dictionary = {}
	var best := INF
	for npc: Dictionary in active:
		var distance := pos.distance_to(npc["pos"])
		var who := str(npc["spec"]["who"])
		var service := who in ["wardrobe","barista","cook"] or (who.begins_with("teacher") and str(npc["spec"].get("pose",""))=="type")
		var score := distance - (1.5 if service else 0.0)
		if distance < (2.8 if service else 1.8) and score<best:
			result = npc
			best = score
	return result

func blocks_walker(pos: Vector2) -> bool:
	for npc: Dictionary in active:
		if npc["points"].size()>1 and pos.distance_to(npc["pos"])<0.42:
			return true
	return false

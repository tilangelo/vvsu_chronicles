extends RefCounted
## Route data and collision rules shared by the playable scene and route checks.

const MAP_IDS := ["entrance", "corridor_1", "corridor_4", "class_1421", "winter_garden", "winter_garden_lower", "class_1_a", "class_1_b", "class_1_c", "toilet_m", "toilet_f", "lounge_1"]
const WALL_MARGIN := 0.30
const FOOT_RADIUS := 0.13

var tiles: Dictionary = {}
var legend: Dictionary = {}
var data: Dictionary = {}
var rows: Array = []
var solid_edges: Dictionary = {}
var npc_cells: Dictionary = {}


func initialize() -> void:
	var catalogue := read_json("res://maps/tiles.json")
	for entry: Dictionary in catalogue.get("tiles", []):
		tiles[str(entry["id"])] = entry
	legend = read_json("res://maps/legend.json")


func load_map(id: String) -> bool:
	if id not in MAP_IDS:
		push_error("Unknown route map: " + id)
		return false
	var next_data := read_json("res://maps/%s.json" % id)
	if not next_data.has("rows"):
		return false
	data = next_data
	rows = data["rows"]
	npc_cells.clear()
	for npc: Dictionary in data.get("npcs", []):
		if npc.get("path", []).is_empty() and bool(npc.get("solid", true)):
			npc_cells[Vector2i(int(npc["x"]),int(npc["y"]))] = true
	solid_edges.clear()
	for layer_name: String in ["walls", "props"]:
		for item: Dictionary in data[layer_name]:
			var edge := str(tiles[str(item["tile"])]["solid_edge"])
			if edge.is_empty():
				continue
			var cell := Vector2i(int(item["x"]), int(item["y"]))
			var edges: Array = solid_edges.get(cell, [])
			edges.append(edge)
			solid_edges[cell] = edges
	return true


func kind_at(pos: Vector2) -> Dictionary:
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	if cell.y < 0 or cell.y >= rows.size():
		return {}
	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return {}
	return legend.get(row[cell.x], {})


func blocked(pos: Vector2) -> bool:
	# Test the feet, not the full visible sprite. This leaves narrow doors usable.
	for offset: Vector2 in [Vector2.ZERO, Vector2(FOOT_RADIUS, 0), Vector2(-FOOT_RADIUS, 0), Vector2(0, FOOT_RADIUS), Vector2(0, -FOOT_RADIUS)]:
		if _point_blocked(pos + offset):
			return true
	return false


func _point_blocked(pos: Vector2) -> bool:
	var kind := kind_at(pos)
	if kind.is_empty() or not bool(kind.get("walkable", false)):
		return true
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	var inside := pos - Vector2(cell)
	if npc_cells.has(cell):
		return true
	for edge: String in solid_edges.get(cell, []):
		if edge in ["north", "both"] and inside.y < WALL_MARGIN:
			return true
		if edge in ["west", "both"] and inside.x < WALL_MARGIN:
			return true
	return false


func exit_at(pos: Vector2) -> Dictionary:
	for portal: Dictionary in data.get("exits", []):
		var r: Array = portal["rect"]
		if Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3])).grow(0.18).has_point(pos):
			return portal
	return {}


func read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Cannot open route data: " + path)
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		push_error("Invalid route JSON: " + path)
		return {}
	return json.data

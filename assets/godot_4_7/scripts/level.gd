extends Node2D
## Builds a location from res://maps/<id>.json and walks the temporary hero through it.
## Arrow keys move the hero. Everything on a map is a tile: floor, walls and props.

const START_MAP := "entrance"
const SPEED := 4.0  # tiles per second
const SOURCE_ID := 0
const WALL_MARGIN := 0.3  # part of a cell taken by a wall standing at its far edge
const UNDER_DEPTH := 72.0  # a lower level is drawn this far below the floor that opens onto it

var tileset: TileSet = preload("res://tileset.tres")
var tile_info := {}
var legend := {}
var map_data := {}
var rows: Array = []
var solid := {}
var origin := Vector2.ZERO
var hero_pos := Vector2.ZERO
var level_root: Node2D
var hero: Node2D
var hero_sprite: Sprite2D


func _ready() -> void:
	var tiles: Dictionary = _read_json("res://maps/tiles.json")
	for info in tiles["tiles"]:
		tile_info[info["id"]] = info
	legend = _read_json("res://maps/legend.json")
	_make_hero()
	_load_map(START_MAP, [])


func _process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO:
		return
	# screen right is +x -y on the grid, screen down is +x +y
	var step := Vector2(dir.x + dir.y, dir.y - dir.x).normalized() * SPEED * delta
	if not _blocked(hero_pos + Vector2(step.x, 0.0)):
		hero_pos.x += step.x
	if not _blocked(hero_pos + Vector2(0.0, step.y)):
		hero_pos.y += step.y
	_place_hero()
	_check_exits()


func _read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


func _make_hero() -> void:
	hero = Node2D.new()
	hero_sprite = Sprite2D.new()
	hero_sprite.texture = load("res://assets/hero_temp.png")
	hero_sprite.centered = false
	hero_sprite.offset = Vector2(-32, -88)
	hero.add_child(hero_sprite)
	var camera := Camera2D.new()
	camera.zoom = Vector2(2, 2)
	hero.add_child(camera)


func _load_map(id: String, spawn: Array) -> void:
	if level_root != null:
		hero.get_parent().remove_child(hero)
		level_root.free()
	map_data = _read_json("res://maps/%s.json" % id)
	rows = map_data["rows"]
	solid.clear()
	_build_level()
	var start: Array = spawn if not spawn.is_empty() else map_data["spawn"]
	hero_pos = Vector2(start[0] + 0.5, start[1] + 0.5)
	_place_hero()


func _build_level() -> void:
	level_root = Node2D.new()
	add_child(level_root)
	var under: String = map_data["under"]
	if under != "":
		var lower := Node2D.new()
		lower.position = Vector2(0, UNDER_DEPTH)
		level_root.add_child(lower)
		_add_tiles(lower, _read_json("res://maps/%s.json" % under))
	var world := _add_tiles(level_root, map_data)
	for layer_name in ["walls", "props"]:
		for item in map_data[layer_name]:
			var edge: String = tile_info[item["tile"]]["solid_edge"]
			if edge != "":
				solid[Vector2i(int(item["x"]), int(item["y"]))] = edge
	for label_data in map_data["labels"]:
		var label := Label.new()
		label.text = label_data["text"]
		label.z_index = 100
		label.position = _to_screen(label_data["x"] + 0.5, label_data["y"] + 0.5)
		level_root.add_child(label)
	world.add_child(hero)


## Adds the floor and the sorted layers of one map and returns the node the hero belongs to.
func _add_tiles(parent: Node2D, data: Dictionary) -> Node2D:
	var floor_layer := TileMapLayer.new()
	floor_layer.tile_set = tileset
	parent.add_child(floor_layer)
	origin = floor_layer.map_to_local(Vector2i.ZERO)
	if floor_layer.map_to_local(Vector2i(1, 0)).x <= origin.x:
		push_warning("TileSet layout is not diamond down, the map will look wrong")
	var floor_atlas := _atlas(data["floor"])
	var data_rows: Array = data["rows"]
	for y in data_rows.size():
		var row: String = data_rows[y]
		for x in row.length():
			var kind = legend.get(row[x])
			if kind != null and kind["floor"]:
				floor_layer.set_cell(Vector2i(x, y), SOURCE_ID, floor_atlas)
	var world := Node2D.new()
	world.y_sort_enabled = true
	parent.add_child(world)
	for layer_name in ["walls", "props"]:
		var layer := TileMapLayer.new()
		layer.tile_set = tileset
		layer.y_sort_enabled = true
		world.add_child(layer)
		for item in data[layer_name]:
			layer.set_cell(Vector2i(int(item["x"]), int(item["y"])), SOURCE_ID, _atlas(item["tile"]))
	return world


func _atlas(id: String) -> Vector2i:
	var coords: Array = tile_info[id]["atlas"]
	return Vector2i(int(coords[0]), int(coords[1]))


func _to_screen(u: float, v: float) -> Vector2:
	return origin + Vector2((u - v) * 32.0, (u + v - 1.0) * 16.0)


func _cell_kind(pos: Vector2):
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	if cell.y < 0 or cell.y >= rows.size():
		return null
	var row: String = rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return null
	return legend.get(row[cell.x])


func _place_hero() -> void:
	hero.position = _to_screen(hero_pos.x, hero_pos.y)
	var kind = _cell_kind(hero_pos)
	hero_sprite.position.y = 0.0 if kind == null else -float(kind["elevation"])


func _blocked(pos: Vector2) -> bool:
	var kind = _cell_kind(pos)
	if kind == null or not kind["walkable"]:
		return true
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	var edge: String = solid.get(cell, "")
	var inside := pos - Vector2(cell)
	if (edge == "north" or edge == "both") and inside.y < WALL_MARGIN:
		return true
	if (edge == "west" or edge == "both") and inside.x < WALL_MARGIN:
		return true
	return false


func _check_exits() -> void:
	for map_exit in map_data["exits"]:
		var r: Array = map_exit["rect"]
		if Rect2(r[0], r[1], r[2], r[3]).has_point(hero_pos):
			_load_map(map_exit["to"], map_exit["spawn"])
			return

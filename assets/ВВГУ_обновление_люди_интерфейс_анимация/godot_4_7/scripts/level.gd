extends Node2D
## Builds a location from res://maps/<id>.json and walks the hero through it.
## Arrow keys move the hero. Everything on a map is a tile: floor, walls and props.
## People come from the npcs list of a map, see ИНТЕГРАЦИЯ.md.

const Person = preload("res://scripts/person.gd")
const DialogBox = preload("res://scripts/dialog_box.gd")

const START_MAP := "entrance"
const HERO_ID := "hero"
const SPEED := 4.0  # tiles per second
const NPC_SPEED := 2.0
const SOURCE_ID := 0
const ANIM_SOURCE_ID := 1
const CELL_SIZE := Vector2i(64, 160)
const TEXTURE_ORIGIN := Vector2i(0, 64)
const WALL_MARGIN := 0.3  # part of a cell taken by a wall standing at its far edge
const UNDER_DEPTH := 72.0  # a lower level is drawn this far below the floor that opens onto it

var tileset: TileSet = preload("res://tileset.tres")
var tile_info := {}
var anim_info := {}
var legend := {}
var map_data := {}
var rows: Array = []
var solid := {}
var npc_cells := {}
var walkers: Array = []
var layers := {}
var origin := Vector2.ZERO
var hero_pos := Vector2.ZERO
var level_root: Node2D
var hero: Person
var dialog: DialogBox


func _ready() -> void:
	var tiles: Dictionary = _read_json("res://maps/tiles.json")
	for info in tiles["tiles"]:
		tile_info[info["id"]] = info
	legend = _read_json("res://maps/legend.json")
	_make_anim_source()
	_make_hero()
	dialog = DialogBox.new()
	add_child(dialog)
	_load_map(START_MAP, [])


func _process(delta: float) -> void:
	_move_walkers(delta)
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if dir == Vector2.ZERO or dialog.is_open():
		hero.stop()
		return
	# screen right is +x -y on the grid, screen down is +x +y
	var step := Vector2(dir.x + dir.y, dir.y - dir.x).normalized() * SPEED * delta
	if not _blocked(hero_pos + Vector2(step.x, 0.0)):
		hero_pos.x += step.x
	if not _blocked(hero_pos + Vector2(0.0, step.y)):
		hero_pos.y += step.y
	hero.walk(dir, delta)
	_place_hero()
	_check_exits()


func _read_json(path: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


## Loops play by themselves. A strip is one tile per frame, play_strip() swaps them.
func _make_anim_source() -> void:
	var data: Dictionary = _read_json("res://maps/anim.json")
	for item in data["strips"]:
		anim_info[item["id"]] = item
	if tileset.has_source(ANIM_SOURCE_ID):
		return
	var source := TileSetAtlasSource.new()
	source.texture = load(data["texture"])
	source.texture_region_size = CELL_SIZE
	for item in data["loops"]:
		var coords := Vector2i(0, int(item["row"]))
		source.create_tile(coords)
		source.set_tile_animation_columns(coords, int(item["frames"]))
		source.set_tile_animation_frames_count(coords, int(item["frames"]))
		source.set_tile_animation_speed(coords, float(item["fps"]))
		_set_up_cell(source, coords, int(item["sort"]))
	for item in data["strips"]:
		for frame in int(item["frames"]):
			var coords := Vector2i(frame, int(item["row"]))
			source.create_tile(coords)
			_set_up_cell(source, coords, int(item["sort"]))
	tileset.add_source(source, ANIM_SOURCE_ID)


func _set_up_cell(source: TileSetAtlasSource, coords: Vector2i, sort: int) -> void:
	var tile: TileData = source.get_tile_data(coords, 0)
	tile.texture_origin = TEXTURE_ORIGIN
	tile.y_sort_origin = sort


func _make_hero() -> void:
	hero = Person.new()
	hero.setup(HERO_ID)
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
	npc_cells.clear()
	walkers.clear()
	layers.clear()
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
		var lower_data: Dictionary = _read_json("res://maps/%s.json" % under)
		_add_people(_add_tiles(lower, lower_data), lower_data, false)
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
	_add_people(world, map_data, true)
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
		layers[layer_name] = layer
		for item in data[layer_name]:
			var id: String = item["tile"]
			layer.set_cell(Vector2i(int(item["x"]), int(item["y"])), _source(id), _atlas(id))
	return world


## active is false for the level seen through an opening: its people stand still and block nothing.
func _add_people(world: Node2D, data: Dictionary, active: bool) -> void:
	for item in data.get("npcs", []):
		var person := Person.new()
		person.setup(item["who"])
		person.set_pose(item.get("pose", "idle"), item.get("facing", "s"))
		var pos := Vector2(item["x"] + 0.5, item["y"] + 0.5)
		var lift := float(item.get("lift", _elevation(data, pos)))
		person.place(_to_screen(pos.x, pos.y), lift)
		world.add_child(person)
		var path: Array = item.get("path", [])
		if active and not path.is_empty():
			var points: Array = [pos]
			for point in path:
				points.append(Vector2(point[0] + 0.5, point[1] + 0.5))
			walkers.append({"person": person, "pos": pos, "points": points, "next": 1, "lift": lift})
		elif active:
			npc_cells[Vector2i(int(item["x"]), int(item["y"]))] = true


## People with a path walk it in a loop, back to their first cell.
func _move_walkers(delta: float) -> void:
	for walker in walkers:
		var target: Vector2 = walker["points"][walker["next"]]
		var pos: Vector2 = walker["pos"]
		var to_target := target - pos
		if to_target.length() < 0.05:
			walker["next"] = (walker["next"] + 1) % walker["points"].size()
			continue
		var step := to_target.normalized() * minf(NPC_SPEED * delta, to_target.length())
		pos += step
		walker["pos"] = pos
		walker["person"].walk(Vector2(step.x - step.y, step.x + step.y), delta)
		walker["person"].place(_to_screen(pos.x, pos.y), walker["lift"])


## Opens or closes a door or a turnstile: strip is an id from the strips list of anim.json.
## The last frame stays on the map.
func play_strip(layer_name: String, cell: Vector2i, strip: String, reverse := false) -> void:
	var info: Dictionary = anim_info[strip]
	var layer: TileMapLayer = layers[layer_name]
	var frames := range(int(info["frames"]))
	if reverse:
		frames.reverse()
	for frame in frames:
		layer.set_cell(cell, ANIM_SOURCE_ID, Vector2i(frame, int(info["row"])))
		await get_tree().create_timer(1.0 / float(info["fps"])).timeout


func _source(id: String) -> int:
	return int(tile_info[id].get("source", SOURCE_ID))


func _atlas(id: String) -> Vector2i:
	var coords: Array = tile_info[id]["atlas"]
	return Vector2i(int(coords[0]), int(coords[1]))


func _to_screen(u: float, v: float) -> Vector2:
	return origin + Vector2((u - v) * 32.0, (u + v - 1.0) * 16.0)


func _cell_kind(data_rows: Array, pos: Vector2):
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	if cell.y < 0 or cell.y >= data_rows.size():
		return null
	var row: String = data_rows[cell.y]
	if cell.x < 0 or cell.x >= row.length():
		return null
	return legend.get(row[cell.x])


func _elevation(data: Dictionary, pos: Vector2) -> float:
	var kind = _cell_kind(data["rows"], pos)
	return 0.0 if kind == null else float(kind["elevation"])


func _place_hero() -> void:
	hero.place(_to_screen(hero_pos.x, hero_pos.y), _elevation(map_data, hero_pos))


func _blocked(pos: Vector2) -> bool:
	var kind = _cell_kind(rows, pos)
	if kind == null or not kind["walkable"]:
		return true
	var cell := Vector2i(floori(pos.x), floori(pos.y))
	if npc_cells.has(cell):
		return true
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

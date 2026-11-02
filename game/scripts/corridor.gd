extends Node2D

const TILE_WIDTH := 64.0
const TILE_HEIGHT := 32.0
const WALL_THICKNESS := 8.0

const REGION_COLORS := {
	"vestibule": Color("#c8c1aa"),
	"main_hall": Color("#b8b29e"),
	"continuation": Color("#b2ad99"),
	"class_4": Color("#d4c9a7"),
	"class_5": Color("#cbbf9d"),
	"class_2": Color("#d4c9a7"),
	"men_toilet": Color("#aebdc1"),
	"women_toilet": Color("#b6c4c8"),
	"lounge": Color("#b8c9b1"),
	"sofas": Color("#bcc9b5"),
	"stair_2": Color("#b9afa0"),
}

const GRID_LINE := Color("#a69f89")
const WALL_COLOR := Color("#52565c")
const WALL_EDGE := Color("#383c42")
const MAP_ORIGIN := Vector2.ZERO

var floor_cells: Dictionary = {}
var wall_edges_seen: Dictionary = {}
var lobby_boxes: Array[Dictionary] = []
var lobby_circles: Array[Dictionary] = []


func _ready() -> void:
	_build_floor_plan()
	_build_boundaries()
	_build_lobby_obstacles()
	$Player.position = _grid_to_screen(Vector2(6.5, 10.0))
	queue_redraw()


func _build_floor_plan() -> void:
	# Approximate footprints read from the user's top-down sketches.
	_add_region(Rect2i(0, 0, 14, 12), "vestibule")
	_add_region(Rect2i(4, -14, 5, 14), "main_hall")
	_add_region(Rect2i(0, -14, 4, 4), "class_5")
	_add_region(Rect2i(0, -10, 4, 4), "class_4")
	_add_region(Rect2i(9, -14, 4, 4), "men_toilet")
	_add_region(Rect2i(9, -10, 4, 4), "women_toilet")
	_add_region(Rect2i(9, -6, 6, 6), "lounge")
	_add_region(Rect2i(4, -23, 5, 9), "continuation")
	_add_region(Rect2i(4, -23, 14, 4), "continuation")
	_add_region(Rect2i(0, -23, 4, 3), "sofas")
	_add_region(Rect2i(0, -18, 4, 4), "class_2")
	_add_region(Rect2i(18, -23, 4, 7), "stair_2")


func _add_region(rect: Rect2i, region_name: String) -> void:
	for x in range(rect.position.x, rect.position.x + rect.size.x):
		for y in range(rect.position.y, rect.position.y + rect.size.y):
			floor_cells[Vector2i(x, y)] = region_name


func _build_boundaries() -> void:
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for cell: Vector2i in floor_cells.keys():
		for direction: Vector2i in directions:
			var neighbor: Vector2i = cell + direction
			if not _has_wall(cell, neighbor, direction):
				continue
			var edge_key := _edge_key(cell, neighbor)
			if wall_edges_seen.has(edge_key):
				continue
			wall_edges_seen[edge_key] = true
			_add_wall_collision(cell, direction)


func _has_wall(cell: Vector2i, neighbor: Vector2i, direction: Vector2i) -> bool:
	if not floor_cells.has(neighbor):
		# Leave a broad entrance opening at the south edge of the vestibule.
		return not (str(floor_cells[cell]) == "vestibule" and direction == Vector2i.DOWN and cell.y == 11 and cell.x >= 5 and cell.x <= 8)

	var region_a := str(floor_cells[cell])
	var region_b := str(floor_cells[neighbor])
	if region_a == region_b:
		return false
	if _is_open_connection(region_a, region_b):
		return false
	return not _is_doorway(cell, neighbor, region_a, region_b)


func _is_open_connection(region_a: String, region_b: String) -> bool:
	var pair := [region_a, region_b]
	return pair.has("vestibule") and pair.has("main_hall") \
		or pair.has("main_hall") and pair.has("continuation") \
		or pair.has("continuation") and pair.has("stair_2")


func _is_doorway(cell: Vector2i, neighbor: Vector2i, region_a: String, region_b: String) -> bool:
	var room_name := region_a if region_a not in ["main_hall", "continuation"] else region_b
	var corridor_name := region_a if region_a in ["main_hall", "continuation"] else region_b
	if corridor_name == "main_hall":
		var door_rows := {
			"class_5": [-13],
			"class_4": [-9],
			"men_toilet": [-13],
			"women_toilet": [-9],
			"lounge": [-4],
		}
		return room_name in door_rows and cell.y in door_rows[room_name]
	if corridor_name == "continuation":
		var door_rows := {"sofas": [-22], "class_2": [-16]}
		return room_name in door_rows and cell.y in door_rows[room_name]
	return false


func _edge_key(cell: Vector2i, neighbor: Vector2i) -> String:
	var first := cell
	var second := neighbor
	if first.x > second.x or (first.x == second.x and first.y > second.y):
		first = neighbor
		second = cell
	return "%d,%d:%d,%d" % [first.x, first.y, second.x, second.y]


func _add_wall_collision(cell: Vector2i, direction: Vector2i) -> void:
	var points := _edge_points(cell, direction)
	var midpoint := (points[0] + points[1]) * 0.5
	var center := _grid_to_screen(Vector2(cell) + Vector2(0.5, 0.5))
	var outward := (midpoint - center).normalized() * WALL_THICKNESS
	var wall := StaticBody2D.new()
	var polygon := CollisionPolygon2D.new()
	polygon.polygon = PackedVector2Array([points[0], points[1], points[1] + outward, points[0] + outward])
	wall.add_child(polygon)
	add_child(wall)


func _build_lobby_obstacles() -> void:
	# Desk, turnstiles and columns from the vestibule sketch. The shapes are provisional.
	_add_box_obstacle(_grid_to_screen(Vector2(1.8, 8.8)), Vector2(58.0, 22.0), Color("#76766e"))
	for cell in [Vector2(3.0, 10.3), Vector2(4.0, 10.3), Vector2(5.0, 10.3), Vector2(6.0, 10.3)]:
		_add_circle_obstacle(_grid_to_screen(cell + Vector2(0.5, 0.5)), 7.0, Color("#686b70"))
	for cell in [Vector2(5.0, 3.0), Vector2(9.0, 3.0), Vector2(5.0, 7.0), Vector2(9.0, 7.0)]:
		_add_circle_obstacle(_grid_to_screen(cell + Vector2(0.5, 0.5)), 10.0, Color("#777a7d"))


func _add_box_obstacle(center: Vector2, size: Vector2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	lobby_boxes.append({"center": center, "size": size, "color": color})


func _add_circle_obstacle(center: Vector2, radius: float, color: Color) -> void:
	var body := StaticBody2D.new()
	body.position = center
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	lobby_circles.append({"center": center, "radius": radius, "color": color})


func _draw() -> void:
	var cells: Array = floor_cells.keys()
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.x + a.y < b.x + b.y
	)
	for cell: Vector2i in cells:
		var center := _grid_to_screen(Vector2(cell) + Vector2(0.5, 0.5))
		var diamond := PackedVector2Array([
			center + Vector2(0.0, -TILE_HEIGHT * 0.5),
			center + Vector2(TILE_WIDTH * 0.5, 0.0),
			center + Vector2(0.0, TILE_HEIGHT * 0.5),
			center + Vector2(-TILE_WIDTH * 0.5, 0.0),
		])
		draw_colored_polygon(diamond, REGION_COLORS[str(floor_cells[cell])])
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), GRID_LINE, 1.0, true)

	_draw_wall_lines()
	_draw_lobby_objects()
	_draw_map_labels()


func _draw_lobby_objects() -> void:
	for box: Dictionary in lobby_boxes:
		var rect := Rect2(box["center"] - box["size"] * 0.5, box["size"])
		draw_rect(rect, box["color"])
		draw_rect(rect, WALL_EDGE, false, 2.0)
	for circle: Dictionary in lobby_circles:
		draw_circle(circle["center"], circle["radius"], circle["color"])
		draw_arc(circle["center"], circle["radius"], 0.0, TAU, 24, WALL_EDGE, 2.0)


func _draw_wall_lines() -> void:
	var directions: Array[Vector2i] = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.DOWN, Vector2i.UP]
	for cell: Vector2i in floor_cells.keys():
		for direction: Vector2i in directions:
			var neighbor: Vector2i = cell + direction
			if _has_wall(cell, neighbor, direction):
				var points := _edge_points(cell, direction)
				draw_line(points[0], points[1], WALL_COLOR, 5.0, true)
				draw_line(points[0] + Vector2(0.0, -16.0), points[1] + Vector2(0.0, -16.0), WALL_EDGE, 2.0, true)


func _draw_map_labels() -> void:
	var labels := [
		{"cell": Vector2(6.5, 0.4), "text": "ПРОХОД В КОРИДОР"},
		{"cell": Vector2(6.5, 6.0), "text": "ВЕСТИБЮЛЬ"},
		{"cell": Vector2(6.5, 10.7), "text": "ТУРНИКЕТЫ"},
		{"cell": Vector2(2.0, 7.0), "text": "СТОЛ ОХРАНЫ"},
		{"cell": Vector2(11.0, 8.0), "text": "ЛЕСТНИЦА 1"},
		{"cell": Vector2(2.0, -12.0), "text": "АУДИТОРИЯ 5"},
		{"cell": Vector2(2.0, -8.0), "text": "АУДИТОРИЯ 4"},
		{"cell": Vector2(11.0, -12.0), "text": "МУЖСКОЙ ТУАЛЕТ"},
		{"cell": Vector2(11.0, -8.0), "text": "ЖЕНСКИЙ ТУАЛЕТ"},
		{"cell": Vector2(11.5, -3.0), "text": "ЗОНА ОТДЫХА"},
		{"cell": Vector2(2.0, -22.0), "text": "ДИВАНЫ"},
		{"cell": Vector2(2.0, -16.0), "text": "АУДИТОРИЯ 2"},
		{"cell": Vector2(20.0, -20.0), "text": "ЛЕСТНИЦА 2"},
	]
	for marker: Dictionary in labels:
		var point := _grid_to_screen(marker["cell"])
		draw_string(ThemeDB.fallback_font, point + Vector2(-50.0, 4.0), marker["text"], HORIZONTAL_ALIGNMENT_LEFT, 150.0, 12, WALL_EDGE)


func _edge_points(cell: Vector2i, direction: Vector2i) -> PackedVector2Array:
	var center := _grid_to_screen(Vector2(cell) + Vector2(0.5, 0.5))
	if direction == Vector2i.RIGHT:
		return PackedVector2Array([center + Vector2(TILE_WIDTH * 0.5, 0.0), center + Vector2(0.0, TILE_HEIGHT * 0.5)])
	if direction == Vector2i.LEFT:
		return PackedVector2Array([center + Vector2(-TILE_WIDTH * 0.5, 0.0), center + Vector2(0.0, -TILE_HEIGHT * 0.5)])
	if direction == Vector2i.DOWN:
		return PackedVector2Array([center + Vector2(0.0, TILE_HEIGHT * 0.5), center + Vector2(-TILE_WIDTH * 0.5, 0.0)])
	return PackedVector2Array([center + Vector2(0.0, -TILE_HEIGHT * 0.5), center + Vector2(TILE_WIDTH * 0.5, 0.0)])


func _grid_to_screen(grid_position: Vector2) -> Vector2:
	return MAP_ORIGIN + Vector2(
		(grid_position.x - grid_position.y) * TILE_WIDTH * 0.5,
		(grid_position.x + grid_position.y) * TILE_HEIGHT * 0.5
	)

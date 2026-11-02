extends Node2D
## One person on a map: a sheet from res://assets/characters, a direction and a pose.
## The node stands at the feet of the person, so Y-sorting works the same way as for tiles.

const DIRS := ["s", "se", "e", "ne", "n", "nw", "w", "sw"]
const SIT_COLUMNS := {"se": 0, "sw": 1, "ne": 2, "nw": 3}
const FEET := Vector2(32, 88)
const WALK_FPS := 8.0
const IDLE_COLUMN := 0
const WALK_FIRST_COLUMN := 1
const WALK_FRAMES := 4
const SIT_ROW := 8
const TYPE_ROW := 9
const SIT_SORT := 8.0  # a person facing the camera sorts in front of the chair

var sprite: Sprite2D
var facing := "s"
var pose := "idle"  # idle, walk, sit or type
var walk_time := 0.0


func setup(id: String) -> void:
	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/%s.png" % id)
	sprite.hframes = 5
	sprite.vframes = 10
	sprite.centered = false
	sprite.offset = -FEET
	add_child(sprite)
	_show_frame()


func set_pose(new_pose: String, new_facing: String) -> void:
	pose = new_pose
	facing = new_facing
	_show_frame()


## Takes a direction in screen terms: right is (1, 0), down is (0, 1).
func walk(direction: Vector2, delta: float) -> void:
	facing = DIRS[posmod(roundi((PI / 2.0 - direction.angle()) / (PI / 4.0)), 8)]
	pose = "walk"
	walk_time += delta
	_show_frame()


func stop() -> void:
	if pose == "walk":
		pose = "idle"
		walk_time = 0.0
		_show_frame()


## Puts the feet on a screen point. lift raises the picture without changing the sort order.
func place(screen_pos: Vector2, lift: float) -> void:
	var seated := pose == "sit" or pose == "type"
	var bias := SIT_SORT if seated and (facing == "se" or facing == "sw") else 0.0
	position = screen_pos + Vector2(0.0, bias)
	sprite.position.y = -bias - lift


func _show_frame() -> void:
	if pose == "sit" or pose == "type":
		var row := SIT_ROW if pose == "sit" else TYPE_ROW
		sprite.frame_coords = Vector2i(int(SIT_COLUMNS.get(facing, 0)), row)
		return
	var column := IDLE_COLUMN
	if pose == "walk":
		column = WALK_FIRST_COLUMN + int(walk_time * WALK_FPS) % WALK_FRAMES
	sprite.frame_coords = Vector2i(column, DIRS.find(facing))

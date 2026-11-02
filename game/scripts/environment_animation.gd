extends RefCounted
var loops: Dictionary = {}
var gates: Array[Dictionary] = []
var strips: Dictionary = {}

func setup(tileset: TileSet, config: Dictionary) -> void:
	var source := TileSetAtlasSource.new()
	source.texture = load(str(config["texture"]))
	source.texture_region_size = Vector2i(64,160)
	for item: Dictionary in config["loops"]:
		var coords := Vector2i(0,int(item["row"]))
		source.create_tile(coords)
		source.set_tile_animation_columns(coords,int(item["frames"]))
		source.set_tile_animation_frames_count(coords,int(item["frames"]))
		source.set_tile_animation_speed(coords,float(item["fps"]))
		var tile := source.get_tile_data(coords,0)
		tile.texture_origin = Vector2i(0,64)
		tile.y_sort_origin = int(item["sort"])
		if not loops.has(str(item["replaces"])):
			loops[str(item["replaces"])] = []
		loops[str(item["replaces"])].append(coords)
	for strip: Dictionary in config["strips"]:
		strips[str(strip["id"])] = strip
		for frame in range(int(strip["frames"])):
			var coords := Vector2i(frame,int(strip["row"]))
			source.create_tile(coords)
			source.get_tile_data(coords,0).texture_origin = Vector2i(0,64)
			source.get_tile_data(coords,0).y_sort_origin = int(strip["sort"])
	tileset.add_source(source,1)

func reset() -> void:
	gates.clear()

func set_visual(layer: TileMapLayer, cell: Vector2i, id: String, fallback: Vector2i, active: bool) -> void:
	if id=="turnstile_gate_y" and active:
		layer.set_cell(cell,1,Vector2i(3,10))
		gates.append({"layer":layer,"cell":cell,"frame":3.0})
	elif loops.has(id):
		var options: Array = loops[id]
		layer.set_cell(cell,1,options[posmod(cell.x,options.size())])
	else:
		layer.set_cell(cell,0,fallback)

func tick(delta: float, player_pos: Vector2) -> void:
	for gate: Dictionary in gates:
		var cell: Vector2i = gate["cell"]
		var target := 3.0 if player_pos.distance_to(Vector2(cell)+Vector2(0.5,0.5))<2.1 else 0.0
		gate["frame"] = move_toward(float(gate["frame"]),target,10.0*delta)
		gate["layer"].set_cell(cell,1,Vector2i(roundi(gate["frame"]),10))

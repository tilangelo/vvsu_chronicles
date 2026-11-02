extends "res://scripts/person.gd"
## Adapter retaining the player's movement interface while using the supplied eight-way sheet.
var walking := false
var phase := 0.0

func _init() -> void:
	setup("hero")

func stop() -> void:
	walking = false
	phase = 0.0
	super.stop()

func advance(delta: float, distance: float, direction: Vector2) -> void:
	walking = distance > 0.0001
	if walking:
		phase += distance
		walk(direction, delta)
	else:
		phase = 0.0
		if not direction.is_zero_approx():
			var look: String = DIRS[posmod(roundi((PI/2.0-direction.angle())/(PI/4.0)),8)]
			set_pose("idle",look)
		else:
			stop()

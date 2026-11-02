extends Node2D
## Temporary cutout walk cycle from the supplied hero. No new bitmap is required.

const TEXTURE := preload("res://assets/hero_temp.png")
var phase := 0.0
var walking := false
var facing_left := false


func advance(_delta: float, distance: float, direction: Vector2) -> void:
	walking = distance > 0.0001
	if walking:
		phase += distance * 9.0
		if absf(direction.x) > 0.1:
			facing_left = direction.x < 0.0
	else:
		phase = 0.0
	queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-1.0 if facing_left else 1.0, 1.0))
	if not walking:
		draw_texture(TEXTURE, Vector2(-32, -88))
		return
	var stride := sin(phase)
	var lift_left := -maxf(0.0, stride) * 3.0
	var lift_right := -maxf(0.0, -stride) * 3.0
	# Keep hips attached; the planted and lifted legs alternate on actual travel.
	draw_texture_rect_region(TEXTURE, Rect2(-12, -24 + lift_left, 13, 25), Rect2(20, 64, 13, 25))
	draw_texture_rect_region(TEXTURE, Rect2(1, -24 + lift_right, 13, 25), Rect2(33, 64, 13, 25))
	var bob := -absf(sin(phase * 2.0))
	draw_texture_rect_region(TEXTURE, Rect2(-12, -67 + bob, 26, 44), Rect2(20, 21, 26, 44))

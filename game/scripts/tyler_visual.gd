extends Node2D
## Pixel-art character drawn in the same low-resolution coordinate space as the cast.
var time := 0.0

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	var ink := Color("#29252b")
	var skin := Color("#e8ac7c")
	var jacket := Color("#9d302b")
	var shadow := Color("#602427")
	var blond := Color("#d4ad6c")
	var bob := -1.0 if fmod(time,2.2) < 0.18 else 0.0
	draw_rect(Rect2(-11,-7,22,7),Color(0,0,0,0.18))
	draw_rect(Rect2(-10,-29+bob,8,23),ink)
	draw_rect(Rect2(2,-29+bob,8,23),ink)
	draw_rect(Rect2(-9,-27+bob,6,20),Color("#35343a"))
	draw_rect(Rect2(3,-27+bob,6,20),Color("#35343a"))
	draw_rect(Rect2(-11,-7+bob,9,5),Color("#625350"))
	draw_rect(Rect2(2,-7+bob,9,5),Color("#625350"))
	draw_rect(Rect2(-15,-55+bob,30,28),ink)
	draw_rect(Rect2(-13,-53+bob,26,24),jacket)
	draw_rect(Rect2(-15,-50+bob,5,20),shadow)
	draw_rect(Rect2(10,-50+bob,5,20),shadow)
	draw_rect(Rect2(-3,-51+bob,6,21),Color("#d2b18b"))
	draw_rect(Rect2(-3,-48+bob,6,15),Color("#2b292a"))
	draw_rect(Rect2(-14,-31+bob,4,5),skin)
	draw_rect(Rect2(10,-31+bob,4,5),skin)
	draw_rect(Rect2(-8,-72+bob,16,19),ink)
	draw_rect(Rect2(-7,-70+bob,14,16),skin)
	draw_rect(Rect2(-10,-75+bob,20,8),ink)
	draw_rect(Rect2(-9,-74+bob,18,7),blond)
	draw_rect(Rect2(-11,-71+bob,4,7),blond)
	draw_rect(Rect2(7,-71+bob,3,6),blond.darkened(0.2))
	draw_rect(Rect2(-7,-66+bob,6,4),Color("#a64133"))
	draw_rect(Rect2(1,-66+bob,6,4),Color("#a64133"))
	draw_rect(Rect2(-1,-65+bob,2,1),ink)

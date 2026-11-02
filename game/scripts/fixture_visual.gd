extends Node2D
## Simple ceramic fixtures for prototype toilet interiors.
var fixture_type := "toilet"

func _draw() -> void:
	var porcelain := Color("#f1f2eb")
	var shade := Color("#a2b7bc")
	var edge := Color("#586f7c")
	if fixture_type == "sink":
		draw_colored_polygon(PackedVector2Array([Vector2(-19,-20),Vector2(0,-29),Vector2(19,-20),Vector2(0,-10)]), porcelain)
		draw_colored_polygon(PackedVector2Array([Vector2(-19,-20),Vector2(0,-10),Vector2(0,2),Vector2(-19,-8)]), shade)
		draw_line(Vector2(0,-26),Vector2(0,-36),edge,3)
		draw_line(Vector2(0,-36),Vector2(7,-33),edge,3)
		draw_set_transform(Vector2(0,-20),0,Vector2(1,0.45))
		draw_circle(Vector2.ZERO,10,shade)
		draw_circle(Vector2.ZERO,6,Color("#d7e4e5"))
	else:
		draw_rect(Rect2(-11,-36,22,19),porcelain)
		draw_rect(Rect2(-11,-36,22,19),edge,false,1)
		draw_rect(Rect2(-5,-17,10,19),shade)
		draw_set_transform(Vector2(0,-14),0,Vector2(1,0.6))
		draw_circle(Vector2.ZERO,14,porcelain)
		draw_circle(Vector2.ZERO,9,edge)
		draw_circle(Vector2.ZERO,6,Color("#c6dfe2"))

extends Node2D
## Unbranded green-and-white ATM. Decorative for now, with a solid map footprint.

func _front(u: float, h: float) -> Vector2:
	return Vector2(-16.0+26.0*u,-10.0+13.0*u-h)

func _panel(a: float,b: float,bottom: float,top: float,color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([_front(a,bottom),_front(b,bottom),_front(b,top),_front(a,top)]),color)

func _draw() -> void:
	draw_colored_polygon(PackedVector2Array([_front(1,0),Vector2(22,-3),Vector2(22,-73),_front(1,70)]),Color("#117447"))
	draw_colored_polygon(PackedVector2Array([_front(0,70),_front(1,70),Vector2(22,-73),Vector2(-4,-86)]),Color("#3cac6c"))
	_panel(0,1,0,70,Color("#e4ebe5"))
	_panel(0,1,60,70,Color("#21a45c"))
	_panel(0.1,0.9,31,57,Color("#59746e"))
	_panel(0.17,0.83,35,53,Color("#153e48"))
	_panel(0.24,0.76,46,48,Color("#86d9ad"))
	_panel(0.24,0.65,40,42,Color("#c3d6d2"))
	_panel(0.15,0.55,23,29,Color("#b2c0ba"))
	for row in range(3):
		for col in range(3):
			_panel(0.20+col*0.09,0.25+col*0.09,24+row*1.4,25+row*1.4,Color("#455b55"))
	_panel(0.68,0.91,24,27,Color("#2d5242"))
	_panel(0.68,0.91,27,28,Color("#29b961"))
	_panel(0.13,0.87,10,18,Color("#3d554b"))
	_panel(0.18,0.82,12,14,Color("#192d26"))
	_panel(0,1,0,7,Color("#15894f"))
	draw_line(_front(0,0),_front(0,70),Color("#a3b8aa"),1)
	draw_line(_front(1,0),_front(1,70),Color("#126a42"),1)

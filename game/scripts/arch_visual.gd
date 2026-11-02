extends Node2D
## Open stone arch, fitted to the same wall plane as the existing doorway.
var axis := "y"

func _point(u: float, height: float) -> Vector2:
	if axis == "x":
		return Vector2(32.0*u, -16.0 + 16.0*u - height)
	return Vector2(-32.0 + 32.0*u, -16.0*u - height)

func _quad(u0: float, u1: float, h0: float, h1: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([_point(u0,h0),_point(u1,h0),_point(u1,h1),_point(u0,h1)]), color)

func _draw() -> void:
	_quad(0,1,0,96,Color("#c7d6df"))
	var inner := PackedVector2Array([_point(0.12,0),_point(0.88,0)])
	for i in range(15):
		var t := float(i)/14.0
		inner.append(_point(0.88-0.76*t,55.0+25.0*sqrt(maxf(0.0,1.0-pow(1.0-2.0*t,2)))))
	draw_colored_polygon(inner,Color("#344553"))
	_quad(0.0,0.12,0,55,Color("#e8e6d8"))
	_quad(0.88,1.0,0,55,Color("#b7c7cb"))
	for i in range(14):
		var a := float(i)/14.0
		var b := float(i+1)/14.0
		var ha := sqrt(maxf(0.0,1.0-pow(2.0*a-1.0,2)))
		var hb := sqrt(maxf(0.0,1.0-pow(2.0*b-1.0,2)))
		var stone := PackedVector2Array([_point(a,55+33*ha),_point(b,55+33*hb),_point(0.12+0.76*b,55+25*hb),_point(0.12+0.76*a,55+25*ha)])
		draw_colored_polygon(stone,Color("#e8e6d8") if i%2==0 else Color("#d9ddd4"))
		draw_line(stone[0],stone[3],Color("#a4b7b6"),1.0)
	_quad(0.14,0.86,0,4,Color("#92a6af"))
	draw_line(_point(0,0),_point(1,0),Color("#e2e7e2"),2)

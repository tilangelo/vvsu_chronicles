extends Node2D
## Prepared door strip from the update. The arch uses its own independent visual.
const ATLAS := preload("res://assets/tileset_anim_64x32.png")
var axis := "y"
var glass := false
var frame_position := 0.0
var target := 0.0
func set_open(open: bool) -> void:
    target=3.0 if open else 0.0
func _process(delta: float) -> void:
    var next=move_toward(frame_position,target,delta*10.0)
    if next!=frame_position:
        frame_position=next
        queue_redraw()
func _draw() -> void:
    var row=(13 if axis=='x' else 14) if glass else (11 if axis=='x' else 12)
    draw_texture_rect_region(ATLAS,Rect2(-32,-144,64,160),Rect2(roundi(frame_position)*64,row*160,64,160))

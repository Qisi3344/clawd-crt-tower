extends Control
var health:=3:
	set(v): health=v;queue_redraw()
func _ready() -> void: custom_minimum_size=Vector2(92,28);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	for i in range(3):
		var o:=Vector2(i*30,4)
		var points:=PackedVector2Array([Vector2(2,2),Vector2(8,2),Vector2(11,5),Vector2(14,2),Vector2(20,2),Vector2(23,5),Vector2(23,11),Vector2(11,22),Vector2(0,11),Vector2(0,5)])
		for k in range(points.size()): points[k]+=o
		draw_colored_polygon(points,Color("e89aaa") if i<health else Color("41334d"))

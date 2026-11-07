extends Control
var host: TouchControls
func _draw() -> void:
	var points:=host.centers()
	var font:=preload("res://assets/fonts/fusion-pixel.otf")
	draw_rect(Rect2(0,size.y-160,size.x,160),Color("17121fb8"))
	draw_line(Vector2(24,size.y-160),Vector2(size.x-24,size.y-160),Color("68516d"),2)
	draw_circle(points.stick,63,Color("292033ee"));draw_circle(points.stick,63,Color("a88496"),false,3)
	draw_line(points.stick-Vector2(42,0),points.stick+Vector2(42,0),Color("68516d"),1)
	draw_line(points.stick-Vector2(0,42),points.stick+Vector2(0,42),Color("68516d"),1)
	draw_circle(points.stick+host.joystick*42,25,Color("8dcabb"))
	for action in ["jump","attack","interact"]:
		var down:bool=host.owners.values().has(action)
		var p:Vector2=points[action]+Vector2(0,3 if down else 0)
		draw_circle(p+Vector2(3,5),41,Color("100f19"));draw_circle(p,41,Color("68516d") if down else Color("292033"));draw_circle(p,41,Color("8dcabb") if down else Color("a88496"),false,3)
		draw_string(font,p+Vector2(-26,7),{"jump":"跳跃","attack":"螯击","interact":"互动"}[action],HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("f4e7cf"))

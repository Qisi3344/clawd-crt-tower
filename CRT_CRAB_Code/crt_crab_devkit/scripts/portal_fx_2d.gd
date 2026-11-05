class_name PortalFX2D
extends Node2D

var progress := 0.0:
	set(value): progress=value;queue_redraw()
var entering := false
var pixels: Array[Dictionary] = []

func configure(sprite: Sprite2D) -> void:
	var frame := sprite.texture as AtlasTexture
	var image := frame.atlas.get_image().get_region(frame.region)
	for y in range(0,32,2):
		for x in range(0,32,2):
			var color := image.get_pixel(x,y)
			if color.a>0.5: pixels.append({"p":Vector2(x-16,y-16),"color":color})

func _draw() -> void:
	var t := 1-progress if entering else progress
	for i in range(pixels.size()):
		var pixel: Dictionary = pixels[i]
		var end := Vector2(22,-8)+Vector2(sin(i*2.3),cos(i*1.7))*10
		var p: Vector2 = pixel.p.lerp(end,t)
		var color: Color = pixel.color.lerp(Color("54cfc3"),t*0.6)
		color.a = 1-t
		draw_rect(Rect2(p,Vector2(2,2)),color)
	if entering:
		draw_arc(Vector2(0,14),3+progress*20,0,TAU,24,Color(0.33,0.81,0.76,(1-progress)*0.45),1)

class_name ArchiveTerrain
extends Node2D

var definition:Dictionary
var surfaces:Array[Rect2]=[]
var walkway:Texture2D
var foundation:Texture2D
var shallow_foundation:Texture2D
var art_root:="res://assets/pixel/archive/game/"
var lip:=Color("b3917d")

func _ready() -> void:
	name="ArchiveTerrain";texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	walkway=load(art_root+"walkway.png")
	foundation=load(art_root+"foundation.png")
	shallow_foundation=load(art_root+"foundation-32.png")
	var groups:Dictionary={}
	for p in definition.platforms:
		var key:="%d:%d"%[p[1],p[3]]
		if not groups.has(key): groups[key]=[]
		groups[key].append(Rect2(p[0],p[1],p[2],p[3]))
	for group in groups.values():
		group.sort_custom(func(a:Rect2,b:Rect2):return a.position.x<b.position.x)
		var merged:Rect2=group[0]
		for i in range(1,group.size()):
			var next:Rect2=group[i]
			if is_equal_approx(merged.end.x,next.position.x): merged.size.x+=next.size.x
			else: surfaces.append(merged);merged=next
		surfaces.append(merged)

func _draw() -> void:
	for rect in surfaces:
		var texture:Texture2D=walkway if rect.size.y<=16 else foundation
		if rect.size.y==32: texture=shallow_foundation
		# World-X sampling keeps adjacent collision pieces visually continuous.
		draw_texture_rect_region(texture,rect,Rect2(rect.position.x,0,rect.size.x,rect.size.y))
		draw_line(rect.position,Vector2(rect.end.x,rect.position.y),lip,1)
		draw_line(Vector2(rect.position.x,rect.end.y-1),rect.end-Vector2(0,1),Color("291f35"),1)
		for x in [rect.position.x,rect.end.x-1]: draw_line(Vector2(x,rect.position.y+1),Vector2(x,rect.end.y-1),Color("655164"),1)

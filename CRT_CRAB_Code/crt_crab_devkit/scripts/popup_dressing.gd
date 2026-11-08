class_name PopupDressing
extends Node2D
var world:SideWorld

func _ready() -> void:
	name="PopupArt";z_index=-4;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas:Texture2D=load("res://assets/pixel/popup/game/props.png")
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/popup/game/manifest.json"))
	var placements:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/popup_dressing.json"))
	for entry in placements:
		var r:Array=catalog.props[int(entry.id)-1].rect
		var part:=AtlasTexture.new();part.atlas=atlas;part.region=Rect2(r[0],r[1],r[2],r[3])
		var sprite:=Sprite2D.new();sprite.texture=part;sprite.position=Vector2(entry.x,entry.y)
		if int(entry.id)==11: sprite.texture=load("res://assets/pixel/popup/game/capsule.png")
		var height:float=sprite.texture.get_height()
		sprite.offset=Vector2(0,height/2.0 if entry.get("hang",false) else -height/2.0)
		if entry.get("rotate",false): sprite.offset=Vector2.ZERO;sprite.rotation=PI/2
		if int(entry.id) in [5,10]:
			var mount:=Node2D.new();mount.position=sprite.position
			mount.draw.connect(func():
				var rect:=Rect2(-18,-40,36,44) if int(entry.id)==5 else Rect2(-22,-27,44,54)
				mount.draw_rect(rect,Color("40334c"));mount.draw_rect(rect,Color("715c7c"),false,1)
			);add_child(mount)
		add_child(sprite)
		if entry.get("hang",false):
			var ceiling:=0.0
			for p in world.definition.platforms:
				if entry.x>=p[0] and entry.x<=p[0]+p[2] and p[1]+p[3]<=entry.y: ceiling=maxf(ceiling,p[1]+p[3])
			var wire:=Line2D.new();wire.width=1;wire.default_color=Color("735779");wire.points=PackedVector2Array([Vector2(entry.x,ceiling),Vector2(entry.x,entry.y)]);add_child(wire)

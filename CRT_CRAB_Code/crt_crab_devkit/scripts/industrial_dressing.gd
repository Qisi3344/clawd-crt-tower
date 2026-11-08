class_name IndustrialDressing
extends Node2D
var world:SideWorld

func _ready() -> void:
	var key:=world.screen_id.to_lower()
	name="RecycleArt" if key=="recycle" else "SignalArt"
	z_index=-4;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas:Texture2D=load("res://assets/pixel/%s/game/props.png"%key)
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/%s/game/manifest.json"%key))
	var placements:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/%s_dressing.json"%key))
	for entry in placements:
		var r:Array=catalog.props[int(entry.id)-1].rect
		var part:=AtlasTexture.new();part.atlas=atlas;part.region=Rect2(r[0],r[1],r[2],r[3])
		var sprite:=Sprite2D.new();sprite.texture=part;sprite.position=Vector2(entry.x,entry.y)
		sprite.offset=Vector2(0,r[3]/2.0 if entry.get("hang",false) else -r[3]/2.0);add_child(sprite)
		if entry.get("hang",false):
			var ceiling:=0.0
			for p in world.definition.platforms:
				if entry.x>=p[0] and entry.x<=p[0]+p[2] and p[1]+p[3]<=entry.y: ceiling=maxf(ceiling,p[1]+p[3])
			var wire:=Line2D.new();wire.width=1;wire.default_color=Color("697277");wire.points=PackedVector2Array([Vector2(entry.x,ceiling),Vector2(entry.x,entry.y)]);add_child(wire)

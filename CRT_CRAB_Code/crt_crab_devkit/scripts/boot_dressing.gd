class_name BootDressing
extends Node2D

func _ready() -> void:
	name="BootArt";z_index=-4;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas:Texture2D=load("res://assets/pixel/boot/game/props.png")
	var catalog:Array=JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/boot/game/props_manifest.json"))
	var placements:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/boot_dressing.json"))
	for entry in placements:
		var r:Array=catalog[int(entry.id)-1].atlas_rect
		var part:=AtlasTexture.new();part.atlas=atlas;part.region=Rect2(r[0],r[1],r[2],r[3])
		var sprite:=Sprite2D.new();sprite.texture=part;sprite.position=Vector2(entry.x,entry.y)
		sprite.offset=Vector2(0,r[3]/2.0 if entry.get("hang",false) else -r[3]/2.0);add_child(sprite)
		if entry.get("hang",false):
			var wire:=Line2D.new();wire.width=1;wire.default_color=Color("536d73");wire.points=PackedVector2Array([Vector2(entry.x,80),Vector2(entry.x,entry.y)]);add_child(wire)

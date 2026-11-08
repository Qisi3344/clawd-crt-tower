class_name ArchiveDressing
extends Node2D

var world: SideWorld
var lamps:Array[Sprite2D]=[]
var clock:=0.0
const ROOT="res://assets/pixel/archive/game/"

func _ready() -> void:
	name="ArchiveArt";z_index=-4;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var catalog:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ROOT+"manifest.json"))
	var atlas:Texture2D=load(ROOT+"props.png")
	# Fixed placements use existing floors; fragile gameplay lanes stay clear.
	var placements:Array=JSON.parse_string(FileAccess.get_file_as_string("res://data/archive_dressing.json"))
	for entry in placements:
		if entry.get("hang",false) and int(entry.id) in [7,11]:
			var ceiling:=0.0
			for platform in world.definition.platforms:
				if entry.position[0]>=platform[0] and entry.position[0]<=platform[0]+platform[2] and platform[1]+platform[3]<=entry.position[1]: ceiling=maxf(ceiling,platform[1]+platform[3])
			var wire:=Line2D.new();wire.width=1;wire.default_color=Color("61516b");wire.points=PackedVector2Array([Vector2(entry.position[0],ceiling),Vector2(entry.position[0],entry.position[1])]);add_child(wire)
		var region:Array=catalog.props[int(entry.id)-1].rect
		var texture:Texture2D
		if int(entry.id)==6: texture=load(ROOT+"column.png")
		else:
			var part:=AtlasTexture.new();part.atlas=atlas;part.region=Rect2(region[0],region[1],region[2],region[3]);texture=part
		var sprite:=Sprite2D.new();sprite.texture=texture;sprite.position=Vector2(entry.position[0],entry.position[1])
		sprite.offset=Vector2(0,texture.get_height()/2.0 if entry.get("hang",false) else -texture.get_height()/2.0)
		sprite.modulate=Color.WHITE if entry.get("area","")!="lower" else Color(.9,.85,.95)
		if entry.get("stowed",false): sprite.rotation=-.45
		add_child(sprite)
		if entry.get("stowed",false):
			var cage:=Node2D.new();cage.position=sprite.position;cage.draw.connect(func():
				cage.draw_rect(Rect2(-34,-50,50,60),Color("79677e"),false,2)
				for x in [-24,-8,8]: cage.draw_line(Vector2(x,-48),Vector2(x,8),Color("4e415c"),1)
				cage.draw_line(Vector2(-30,-16),Vector2(12,-44),Color("a99ab3"),1)
			);add_child(cage)
		if int(entry.id)==11: lamps.append(sprite)

func _process(delta: float) -> void:
	if not world.get_parent().get_parent().audio.reduced_motion: clock+=delta
	for i in range(lamps.size()):
		var intensity:=.94+sin(clock*.65+i)*.04
		lamps[i].self_modulate=Color(intensity,intensity,intensity)

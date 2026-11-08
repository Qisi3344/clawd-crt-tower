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
		var texture:=AtlasTexture.new();texture.atlas=atlas;texture.region=Rect2(region[0],region[1],region[2],region[3])
		var sprite:=Sprite2D.new();sprite.texture=texture;sprite.position=Vector2(entry.position[0],entry.position[1])
		sprite.offset=Vector2(0,region[3]/2.0 if entry.get("hang",false) else -region[3]/2.0)
		sprite.modulate=Color("aaa0bf") if entry.get("area","")!="lower" else Color("7b718f")
		if entry.get("stowed",false): sprite.rotation=-PI/2;sprite.modulate=Color("726580")
		add_child(sprite)
		if int(entry.id)==11: lamps.append(sprite)

func _process(delta: float) -> void:
	if not world.get_parent().get_parent().audio.reduced_motion: clock+=delta
	for i in range(lamps.size()):
		var intensity:=.94+sin(clock*.65+i)*.04
		lamps[i].self_modulate=Color(intensity,intensity,intensity)

class_name SkinDrafts
extends RefCounted

const IDS=["classic_orange","chef_crab","academy_crab","mecha_crab","lightning_crab","pirate_crab","music_crab","player_one_crab","heavenly_crab"]
static var manifest:Dictionary={}
static var body_atlas:Texture2D

static func entry(id:String) -> Dictionary:
	if manifest.is_empty(): manifest=JSON.parse_string(FileAccess.get_file_as_string("res://data/skin_drafts.json"))
	for skin in manifest.skins:
		if skin.id==id and id in IDS: return skin
	return {"id":"classic_orange","name":"默认小橘蟹","rarity":"default","appearance":{"weapon_name":"原版钳击"},"combat":{"pattern":"melee","enemy_damage":1,"enemy_reach_px":31,"enemy_hit_height_px":23,"cooldown_s":.32,"max_enemy_targets":1}}

static func body(row:int,index:int=0) -> AtlasTexture:
	if body_atlas==null:
		var image:Image=load("res://assets/pixel/skins/classic_orange.png").get_image()
		image.convert(Image.FORMAT_RGBA8)
		# Separate only the original attack-arc ink; every body/eye/claw/leg pixel stays.
		for y in range(96,128):
			for x in range(256):
				if image.get_pixel(x,y)==Color("f7e6aa"): image.set_pixel(x,y,Color.TRANSPARENT)
		body_atlas=ImageTexture.create_from_image(image)
	var part:=AtlasTexture.new();part.atlas=body_atlas;part.region=Rect2((index%8)*32,row*32,32,32);return part

static func px(canvas:CanvasItem,x:float,y:float,w:float,h:float,color:Color) -> void:
	canvas.draw_rect(Rect2(x-16,y-16,w,h),color)

static func polygon(canvas:CanvasItem,points:Array,anchor:Vector2,angle:float,color:Color) -> void:
	var vertices:=PackedVector2Array()
	for p in points: vertices.append((Vector2(p[0],p[1]).rotated(angle)+anchor-Vector2(16,16)).round())
	canvas.draw_colored_polygon(vertices,color)

static func paint(canvas:CanvasItem,id:String,row:int,index:int,attack:float=0.0,back:bool=false) -> void:
	if id=="classic_orange": return
	var bob:=1 if row in [1,4] and index%4 in [1,3] else 0
	var y:=10-bob
	var ink:=Color("263044");var ivory:=Color("f4f1e9");var cyan:=Color("68cfe6")
	if back:
		if id=="pirate_crab":
			polygon(canvas,[[0,0],[-6,3],[-2,4],[-5,7],[2,5]],Vector2(8,y-1),0,Color("b88c5b"))
		if id=="heavenly_crab":
			polygon(canvas,[[0,0],[-5,0],[-7,5],[-3,4]],Vector2(8,y+9),0,Color("bb423b"))
		if id=="mecha_crab":
			px(canvas,20,y-2,8,10,ink);px(canvas,22,y,5,6,Color("63727d"));px(canvas,25,y+1,2,3,cyan)
		if id=="lightning_crab":
			px(canvas,22,y+2,4,7,Color("27364d"));px(canvas,24,y+3,2,3,cyan)
		return
	match id:
		"pirate_crab":
			px(canvas,8,y-3,16,4,ink);px(canvas,9,y-2,14,3,Color("263a49"))
			px(canvas,10,y-2,12,1,Color("b88c5b"));px(canvas,16,y-1,2,2,ivory)
			px(canvas,9,y+10,14,2,Color("b88c5b"));px(canvas,18,y+10,2,2,Color("dccdba"))
		"music_crab":
			px(canvas,10,y-7,12,6,ink);px(canvas,11,y-6,10,5,Color("563957"))
			px(canvas,11,y-2,10,1,Color("d89aab"));px(canvas,7,y-1,18,2,ink)
			polygon(canvas,[[0,0],[3,1],[6,0],[6,3],[3,2],[0,3]],Vector2(13,y+10),0,Color("d89aab"))
		"player_one_crab":
			px(canvas,9,y-2,15,5,ink);px(canvas,10,y-1,13,3,Color("433b71"))
			px(canvas,11,y,10,1,Color("66cdc7"))
			for x in [5,24]:
				px(canvas,x,y+1,3,7,ink);px(canvas,x,y+2,2,5,Color("9b85c6"))
		"heavenly_crab":
			px(canvas,8,y-2,16,3,Color("bb423b"));px(canvas,9,y-2,14,1,Color("d3a348"))
			px(canvas,15,y-3,3,3,Color("d3a348"));px(canvas,16,y-2,1,1,ivory)
			px(canvas,10,y+10,12,2,Color("bb423b"));px(canvas,15,y+10,2,2,Color("d3a348"))
		"chef_crab":
			px(canvas,9,y-8,14,7,ink);px(canvas,10,y-9,5,7,ivory);px(canvas,15,y-10,6,8,ivory);px(canvas,21,y-8,3,5,ivory)
			px(canvas,10,y-2,14,2,Color("cbd2d3"));px(canvas,11,y+10,10,3,ivory);px(canvas,15,y+10,2,2,Color("f2b2a3"))
		"academy_crab":
			polygon(canvas,[[0,0],[9,-10],[15,0]],Vector2(9,y-1),0,ink)
			polygon(canvas,[[0,0],[6,-8],[10,0]],Vector2(12,y-2),0,Color("65577c"))
			px(canvas,7,y-2,18,2,Color("494064"));px(canvas,18,y-7,2,2,Color("a6a8c9"));px(canvas,10,y+10,12,2,Color("72b8a3"))
		"mecha_crab":
			for x in [4,23]:
				px(canvas,x,y,6,5,ink);px(canvas,x+1,y+1,5,3,Color("8e9da4"));px(canvas,x+1,y+1,2,1,cyan)
		"lightning_crab":
			for x in [7,23]:
				polygon(canvas,[[0,0],[3,-4],[2,-1],[4,-1],[0,3]],Vector2(x,y-2),0,cyan)
			px(canvas,14,y+10,2,1,cyan);px(canvas,16,y+11,2,1,Color("b99ad8"))
	var swinging:=row==3
	var progress:float=attack if swinging else 0.0
	var anchor:=Vector2(28,y+7)
	match id:
		"pirate_crab":
			var angle:float=lerpf(-1.0,.9,progress) if swinging else -.5
			polygon(canvas,[[0,-1],[5,-1],[5,2],[0,2]],anchor,angle,Color("b88c5b"))
			polygon(canvas,[[4,-3],[6,-3],[6,4],[4,4]],anchor,angle,Color("b88c5b"))
			polygon(canvas,[[6,-1],[14,-1],[18,-4],[17,1],[13,3],[6,2]],anchor,angle,ink)
			polygon(canvas,[[6,0],[14,0],[17,-2],[15,1],[12,2],[6,1]],anchor,angle,Color("dccdba"))
		"music_crab":
			px(canvas,28,y+5,7,3,Color("e4c89f"));px(canvas,31,y+7,4,3,Color("b88c5b"))
			polygon(canvas,[[0,-2],[5,-4],[5,4],[0,2]],Vector2(35,y+6),0,Color("e4c89f"))
			if swinging:
				var drift:=roundi(progress*5)
				px(canvas,41+drift,y+2,1,6,Color("d89aab"));px(canvas,39+drift,y+7,3,2,Color("d89aab"));px(canvas,42+drift,y+2,2,1,Color("d89aab"))
		"player_one_crab":
			px(canvas,27,y+4,9,7,ink);px(canvas,28,y+5,7,5,Color("433b71"))
			px(canvas,33,y+6,3,3,Color("66cdc7"));px(canvas,29,y+5,2,1,Color("9b85c6"))
			if swinging:
				px(canvas,39+roundi(progress*5),y+6,3,3,Color("66cdc7"))
		"heavenly_crab":
			var angle:float=lerpf(-1.3,.65,progress) if swinging else -.9
			polygon(canvas,[[-3,-1],[16,-1],[16,2],[-3,2]],anchor,angle,ink)
			polygon(canvas,[[-2,0],[15,0],[15,1],[-2,1]],anchor,angle,Color("2f6a65"))
			for tip in [-2,12]: polygon(canvas,[[tip,-1],[tip+3,-1],[tip+3,2],[tip,2]],anchor,angle,Color("d3a348"))
		"chef_crab":
			var angle:float=lerpf(-1.1,.7,progress) if swinging else -.6
			polygon(canvas,[[0,-1],[12,-1],[12,2],[0,2]],anchor,angle,ink)
			polygon(canvas,[[7,-4],[15,-4],[15,5],[7,5]],anchor,angle,ink)
			polygon(canvas,[[8,-3],[14,-3],[14,4],[8,4]],anchor,angle,Color("b7c5cb"))
			polygon(canvas,[[10,-2],[11,-2],[11,3],[10,3]],anchor,angle,Color("667982"))
		"academy_crab":
			var angle:float=-.25+sin(progress*PI)*.25 if swinging else -.7
			polygon(canvas,[[0,-1],[12,-1],[12,1],[0,1]],anchor,angle,Color("d0b489"))
			polygon(canvas,[[11,-3],[14,0],[11,3],[9,0]],anchor,angle,cyan)
		"mecha_crab":
			var reach:=roundi(sin(progress*PI)*5) if swinging else 0
			px(canvas,26+reach,y+5,8,7,ink);px(canvas,27+reach,y+6,6,5,Color("8e9da4"));px(canvas,31+reach,y+7,2,3,cyan)
		"lightning_crab":
			px(canvas,27,y+5,3,1,cyan);px(canvas,29,y+7,2,3,Color("b99ad8"))
			if swinging:
				var end:=Vector2(42,y+6)
				canvas.draw_polyline(PackedVector2Array([Vector2(29,y+6)-Vector2(16,16),Vector2(34,y+3)-Vector2(16,16),Vector2(35,y+8)-Vector2(16,16),end-Vector2(16,16)]),cyan,1)
	if swinging and id in ["chef_crab","mecha_crab","pirate_crab","heavenly_crab"]:
		canvas.draw_arc(Vector2(23,y+7)-Vector2(16,16),9,-.8,1.1,8,ivory if id=="chef_crab" else cyan,1)

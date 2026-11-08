extends Node2D

# One culled background for the whole continuous world, never another viewport.
var world: SideWorld
var last_view := Vector2(-999,-999)
var archive_far:Texture2D
var archive_mid:Texture2D
var boot_far:Texture2D
var boot_mid:Texture2D
func _ready() -> void:
	if world.screen_id=="ARCHIVE":
		archive_far=load("res://assets/pixel/archive/game/far.png")
		archive_mid=load("res://assets/pixel/archive/game/mid-continuous.png")
	if world.screen_id=="BOOT":
		boot_far=load("res://assets/pixel/boot/game/far.png")
		boot_mid=load("res://assets/pixel/boot/game/mid-continuous.png")
func _process(_delta: float) -> void:
	if not is_instance_valid(world.camera): return
	if world.camera.position!=last_view:
		last_view=world.camera.position;queue_redraw()

func _draw() -> void:
	if not is_instance_valid(world): return
	var view:=Rect2(last_view-Vector2(176,136),Vector2(352,272)).intersection(Rect2(Vector2.ZERO,world.world_size))
	var palettes={"BOOT":["222c32","536e66"],"ARCHIVE":["282936","756985"],"POP-UP":["282338","69516d"],"RECYCLE":["242d32","6a7d6c"],"SIGNAL":["192e38","527d85"],"ERROR":["242337","655c8a"]}
	var colors:Array=palettes.get(world.screen_id,palettes.BOOT)
	draw_rect(view,Color(colors[0]))
	if world.screen_id=="BOOT":
		draw_texture_rect_region(boot_far,view,Rect2(view.position*.15,view.size))
		draw_texture_rect_region(boot_mid,view,view)
		return
	if world.screen_id=="ARCHIVE":
		_draw_archive(view)
		return
	for x in range(int(view.position.x/64)*64,int(view.end.x)+64,64):
		for y in range(int(view.position.y/96)*96,int(view.end.y)+96,96):
			draw_rect(Rect2(x+12,y+12,42,72),Color(colors[1]).darkened(.48),false,1)
			for n in range(3): draw_line(Vector2(x+19,y+27+n*16),Vector2(x+46,y+27+n*16),Color(colors[1]).darkened(.58),1)
	for area in world.definition.get("areas",[]):
		var r:Array=area.rect
		var centre:=Vector2(r[0]+r[2]*.5,r[1]+r[3]*.4)
		if area.has("landmark_position"): centre=SideWorld.point(area.landmark_position)
		if not view.grow(60).has_point(centre): continue
		var accent:=Color(colors[1]);accent.a=.7
		match str(area.get("landmark","ring")):
			"ring":
				for radius in [36,42,47]: draw_circle(centre,radius,accent,false,2)
				draw_line(centre-Vector2(0,54),centre+Vector2(0,54),accent,2)
			"shelves":
				for i in range(5):
					draw_rect(Rect2(centre+Vector2(-58,-55+i*22),Vector2(116,18)),accent,false,2)
					for j in range(8): draw_line(centre+Vector2(-50+j*14,-53+i*22),centre+Vector2(-50+j*14,-39+i*22),accent,1)
			"crane":
				draw_line(centre-Vector2(64,45),centre+Vector2(64,-45),accent,5)
				draw_line(centre,centre+Vector2(0,70),accent,3)
				draw_arc(centre+Vector2(0,70),16,0,PI,12,accent,4)
			"window":
				for i in range(3):
					var rect:=Rect2(centre+Vector2(-60+i*15,-40+i*15),Vector2(104,65))
					draw_rect(rect,accent,false,2);draw_line(rect.position+Vector2(0,10),rect.position+Vector2(104,10),accent,2)
			"tower":
				for i in range(3):
					var p:=centre+Vector2(-40+i*40,0)
					draw_rect(Rect2(p-Vector2(9,64),Vector2(18,120)),accent,false,2)
					draw_circle(p-Vector2(0,68),9,accent,false,2)
			"core":
				for i in range(6):
					var angle:=i*TAU/6;var p:=centre+Vector2.from_angle(angle)*46
					draw_line(centre,p,accent,4);draw_rect(Rect2(p-Vector2(9,9),Vector2(18,18)),accent,false,2)
				draw_circle(centre,25,accent,false,4)

func _draw_archive(view: Rect2) -> void:
	if archive_far!=null:
		var source:=Rect2(view.position*.15,view.size)
		draw_texture_rect_region(archive_far,view,source,Color(.6,.56,.74))
	if archive_mid!=null: draw_texture_rect_region(archive_mid,view,view)

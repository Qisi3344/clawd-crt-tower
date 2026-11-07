class_name LocalMapView
extends Control
var world: SideWorld
func _ready() -> void: custom_minimum_size=Vector2(500,260);mouse_filter=Control.MOUSE_FILTER_IGNORE
func _draw() -> void:
	if not is_instance_valid(world): return
	var scale_factor:=minf((size.x-36)/world.world_size.x,(size.y-36)/world.world_size.y)
	var offset:=(size-world.world_size*scale_factor)/2
	draw_rect(Rect2(offset,world.world_size*scale_factor),Color("11131e"))
	var cells:Array=world.state.get("explored_cells",[])
	for cell in cells:
		var bits:=str(cell).split(":");if bits.size()!=2: continue
		var observed:=Rect2(int(bits[0])*80,int(bits[1])*80,80,80).intersection(Rect2(Vector2.ZERO,world.world_size))
		draw_rect(Rect2(offset+observed.position*scale_factor,observed.size*scale_factor),Color("383348"))
		for platform in world.definition.platforms:
			var piece:=Rect2(platform[0],platform[1],platform[2],platform[3]).intersection(observed)
			if piece.has_area(): draw_rect(Rect2(offset+piece.position*scale_factor,piece.size*scale_factor),Color("8b999d"))
	var font:=preload("res://assets/fonts/fusion-pixel.otf")
	for area in world.definition.get("areas",[]):
		if not world.state.get("visited_areas",[]).has(area.id): continue
		if world.current_area==str(area.id):
			var r:Array=area.rect
			draw_rect(Rect2(offset+Vector2(r[0],r[1])*scale_factor,Vector2(r[2],r[3])*scale_factor),Color("e89aaa"),false,2)
		var p:=offset+Vector2(area.rect[0]+10,area.rect[1]+22)*scale_factor
		draw_string(font,p,str(area.name),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("efcd9c"))
	for chest in world.chests:
		if world.session.collected.has(chest.id):
			var p:=offset+SideWorld.point(chest.position)*scale_factor
			draw_rect(Rect2(p-Vector2(3,3),Vector2(6,6)),Color("8dcabb"))
	for connection in world.definition.get("connections",[]):
		if not world.state.get("discovered_connections",[]).has(connection.id): continue
		var p:=offset+SideWorld.point(connection.position)*scale_factor
		var open:bool=str(connection.get("requires","")).is_empty() or world.flags.get(connection.requires,false)
		draw_circle(p,3,Color("8dcabb") if open else Color("efcd9c"))
	var player:=offset+world.player.position*scale_factor
	draw_circle(player,5,Color("e89aaa"));draw_circle(player,8,Color("f4e7cf"),false,1)

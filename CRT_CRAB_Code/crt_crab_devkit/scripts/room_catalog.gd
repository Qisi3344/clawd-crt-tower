class_name RoomCatalog
extends RefCounted

static func room(definition: Dictionary, id: String) -> Dictionary:
	var rooms = definition.get("rooms",{})
	return rooms.get(id,{}) if rooms is Dictionary else {}

static func valid_room(definition: Dictionary) -> bool:
	if not definition.get("spawns") is Dictionary or not definition.spawns.has("entrance"): return false
	for field in ["platforms","ladders","blocks","plates","doors","chests","crystals","breakables","enemies","terminals"]:
		if not definition.get(field) is Array: return false
	var size = definition.get("size",[768,240])
	if not (size is Array and size.size()==2 and size.all(func(v):return (v is float or v is int) and is_finite(float(v))) and size[0]>=320 and size[0]<=4096 and size[1]>=240 and size[1]<=2048): return false
	var bounds:=Vector2(size[0],size[1])
	for p in definition.spawns.values():
		if not inside(p,bounds): return false
	for field in ["blocks","plates","doors","chests","crystals","breakables","enemies","terminals","mechanisms","animals"]:
		for entry in definition.get(field,[]):
			for key in ["position","control","target","emitter"]:
				if entry.has(key) and not inside(entry[key],bounds): return false
	for platform in definition.platforms:
		if platform.size()<4 or platform[2]<=0 or platform[3]<=0 or not inside([platform[0],platform[1]],bounds) or not inside([platform[0]+platform[2],platform[1]+platform[3]],bounds): return false
	for ladder in definition.ladders:
		if not inside([ladder.x,ladder.top],bounds) or not inside([ladder.x,ladder.bottom],bounds) or ladder.top>=ladder.bottom: return false
	var area_ids:Array=[]
	for area in definition.get("areas",[]):
		if area_ids.has(area.id) or not inside(area.checkpoint,bounds): return false
		var r=area.get("rect")
		if not r is Array or r.size()!=4 or r[2]<=0 or r[3]<=0 or not inside([r[0],r[1]],bounds) or not inside([r[0]+r[2],r[1]+r[3]],bounds): return false
		area_ids.append(area.id)
	var connection_ids:Array=[]
	for connection in definition.get("connections",[]):
		if connection_ids.has(connection.id) or not area_ids.has(connection.from) or not area_ids.has(connection.to) or not inside(connection.position,bounds): return false
		connection_ids.append(connection.id)
	return true

static func inside(value, bounds: Vector2) -> bool:
	return value is Array and value.size()==2 and value.all(func(v):return (v is int or v is float) and is_finite(float(v))) and value[0]>=0 and value[1]>=0 and value[0]<=bounds.x and value[1]<=bounds.y

static func valid(definition: Dictionary) -> bool:
	if not definition.has("rooms"): return valid_room(definition)
	if not definition.rooms is Dictionary or not definition.rooms.has(definition.get("entry_room","")): return false
	for id in definition.rooms:
		if not valid_room(definition.rooms[id]): return false
		for portal in definition.rooms[id].get("room_portals",[]):
			if not definition.rooms.has(portal.get("to","")): return false
			if not definition.rooms[portal.to].spawns.has(portal.get("spawn","entrance")): return false
	return true

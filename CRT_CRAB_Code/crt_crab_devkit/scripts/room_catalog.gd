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
	return size is Array and size.size()==2 and size.all(func(v):return (v is float or v is int) and is_finite(float(v))) and size[0]>=320 and size[0]<=768 and size[1]>=240 and size[1]<=256

static func valid(definition: Dictionary) -> bool:
	if not definition.has("rooms"): return valid_room(definition)
	if not definition.rooms is Dictionary or not definition.rooms.has(definition.get("entry_room","")): return false
	for id in definition.rooms:
		if not valid_room(definition.rooms[id]): return false
		for portal in definition.rooms[id].get("room_portals",[]):
			if not definition.rooms.has(portal.get("to","")): return false
			if not definition.rooms[portal.to].spawns.has(portal.get("spawn","entrance")): return false
	return true

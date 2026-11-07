class_name LayoutMigration
extends RefCounted

const IDS := ["boot","archive","popup","recycle","signal","error"]

static func apply(session: Dictionary) -> void:
	for id in IDS:
		var key:String=id+"_01"
		if not session.worlds.has(key) or not session.worlds[key] is Dictionary: continue
		var definition=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/"+key+".json"))
		if not definition is Dictionary or int(definition.get("layout_version",1))<2: continue
		var old:Dictionary=session.worlds[key]
		if int(old.get("layout_version",1))>=2: continue
		var merged:Dictionary={"layout_version":2,"blocks":{},"broken":[],"defeated":[],"mechanisms":{},"visited_areas":[],"discovered_connections":[],"explored_cells":[]}
		var rooms:Dictionary=old.get("rooms",{}) if old.get("rooms",{}) is Dictionary else {}
		var active:String=str(old.get("room_id",definition.legacy_entry))
		if rooms.is_empty(): rooms={"main":old};active="main"
		for room in rooms:
			if not definition.legacy_offsets.has(room) or not rooms[room] is Dictionary: continue
			var source:Dictionary=rooms[room]
			var offset:=SideWorld.point(definition.legacy_offsets[room])
			for field in ["broken","defeated"]:
				if source.get(field) is Array:
					for value in source[field]:
						if value is String and not merged[field].has(value): merged[field].append(value)
			if source.get("mechanisms") is Dictionary: merged.mechanisms.merge(source.mechanisms,true)
			if source.get("boss") is Dictionary: merged.boss=source.boss.duplicate(true)
			if source.get("blocks") is Dictionary:
				for block in source.blocks:
					var target:=SideWorld.point(source.blocks[block],Vector2(-9999,-9999))+offset
					if RoomCatalog.inside([target.x,target.y],SideWorld.point(definition.size)): merged.blocks[block]=[target.x,target.y]
			if str(room)==active:
				var fallback:=SideWorld.point(definition.spawns.get(str(room)+":entrance",definition.spawns.entrance))
				var p:=SideWorld.point(source.get("position"),Vector2(-9999,-9999))+offset
				if not RoomCatalog.inside([p.x,p.y],SideWorld.point(definition.size)): p=fallback
				merged.position=[p.x,p.y]
				merged.last_entry="v4:"+str(room)
		if not merged.has("position"): merged.position=definition.spawns.entrance.duplicate()
		session.worlds[key]=merged
	# These are derived shortcut permissions from already completed boss nodes.
	var core:Dictionary={}
	var final_world=session.worlds.get("error_01",{})
	if final_world is Dictionary and final_world.get("boss") is Dictionary: core=final_world.boss
	for i in range(3):
		if int(core.get("stage",0))>i or session.flags.get("error_core_disabled",false): session.flags["error_node_"+["a","b","c"][i]]=true

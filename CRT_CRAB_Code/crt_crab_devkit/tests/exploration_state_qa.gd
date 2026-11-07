extends SceneTree

var checks:Array=[]
func _initialize() -> void: run.call_deferred()
func check(label: String, condition: bool) -> void:
	checks.append({"test":label,"passed":condition});print(("PASS " if condition else "FAIL ")+label)

func run() -> void:
	for id in LayoutMigration.IDS:
		var definition:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/"+id+"_01.json"))
		check(id+" has one validated continuous multi-floor world",RoomCatalog.valid(definition) and not definition.has("rooms") and definition.room_portals.is_empty() and definition.size[1]>=640 and definition.areas.size()>=3 and definition.connections.size()>=4)
		var before:Dictionary=definition.duplicate(true)
		before.chests[0].position=[99999,99999] if not before.chests.is_empty() else [0,0]
		if not definition.chests.is_empty(): check(id+" rejects a real entity beyond world bounds",not RoomCatalog.valid(before))
		for room in definition.legacy_offsets:
			var offset:=SideWorld.point(definition.legacy_offsets[room])
			var legacy:=SaveStore.fresh();legacy.version=4
			legacy.crystals=13;legacy.collected=["boot_access","archive_hidden"];legacy.wardrobe={"owned":["classic_orange","silver_shell"],"equipped":"silver_shell"}
			var source:={"position":[40,208],"blocks":{},"broken":["old_crack"],"defeated":["old_bug"],"mechanisms":{"old_switch":2}}
			for block in definition.blocks:
				if str(block.get("legacy_room","main"))==str(room):
					var p:=SideWorld.point(block.position)-offset
					source.blocks[block.id]=[p.x,p.y]
			legacy.worlds[id+"_01"]=source if room=="main" else {"room_id":room,"rooms":{room:source}}
			var translated:=SaveStore.migrate(legacy)
			var target:Dictionary=translated.worlds[id+"_01"]
			check(id+" / "+str(room)+" preserves each room's offset and object records",SideWorld.point(target.position)==Vector2(40,208)+offset and target.broken==source.broken and target.defeated==source.defeated and target.mechanisms==source.mechanisms and target.layout_version==2)
			check(id+" / "+str(room)+" migration is idempotent without fabricated puzzle flags",SaveStore.migrate(translated)==translated and not translated.flags.get("message_packet_restored",false) and translated.collected==legacy.collected and translated.crystals==13 and translated.wardrobe.equipped=="silver_shell")
	var payload:=SaveStore.fresh();payload.version=4
	payload.worlds.recycle_01={"room_id":"well","rooms":{"well":{"position":[-6000,99999],"blocks":{"recycle_metal":[99999,0]}}}}
	var migrated:=SaveStore.migrate(payload)
	check("unsafe v4 coordinates fall back without inventing a supported plate",SideWorld.point(migrated.worlds.recycle_01.position)==Vector2(544,688) and not migrated.worlds.recycle_01.blocks.has("recycle_metal") and not migrated.flags.get("recycle_heavy_supported",false))
	var disk:=SaveStore.new();disk.path="user://qa-layout-%d.json"%OS.get_process_id()
	var original:=JSON.stringify(payload)
	var file:=FileAccess.open(disk.path,FileAccess.WRITE);file.store_string(original);file.close();disk.load_progress()
	check("v4 original receives a byte-identical rollback copy before migration",disk.writable and FileAccess.get_file_as_string(disk.path+".v4-backup")==original and FileAccess.get_file_as_string(disk.path)==original)
	check("explicit migrated commit writes schema 5 while keeping layout 2",disk.write() and SaveStore.version_of(JSON.parse_string(FileAccess.get_file_as_string(disk.path)))==5 and disk.data.worlds.recycle_01.layout_version==2)
	payload.version=5;file=FileAccess.open(disk.path,FileAccess.WRITE);file.store_string(JSON.stringify(payload));file.close();disk.load_progress()
	check("schema 5 layout 1 also receives a separate layout rollback copy",disk.writable and FileAccess.file_exists(disk.path+".layout-v1-backup") and disk.data.worlds.recycle_01.layout_version==2)
	check("an identical existing backup is safely reused",disk.backup(".layout-v1-backup"))
	check("a different existing backup is retained while the new source is copied",disk.backup(".v4-backup") and FileAccess.get_file_as_string(disk.path+".v4-backup")==original)
	var extra:=false
	for name in DirAccess.get_files_at("user://"):
		if name.begins_with(disk.path.get_file()+".v4-backup-") and FileAccess.get_file_as_string("user://"+name)==FileAccess.get_file_as_string(disk.path): extra=true
	check("the additional rollback copy matches the newer source byte for byte",extra)
	for name in DirAccess.get_files_at("user://"):
		if name.begins_with(disk.path.get_file()): DirAccess.remove_absolute("user://"+name)
	var report:={"passed":checks.all(func(c):return c.passed),"tests":checks}
	file=FileAccess.open("res://artifacts/exploration-state-qa.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();quit(0 if report.passed else 1)

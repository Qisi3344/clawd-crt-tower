extends SceneTree

var checks: Array = []
var prefix := "user://qa-six-link-state-%d"%OS.get_process_id()
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"test":label,"passed":passed})
	print(("PASS " if passed else "FAIL ")+label)

func run() -> void:
	var old := SaveStore.fresh()
	old.version = 3
	old.erase("story");old.erase("screen_unlocked");old.erase("screen_unlock_seen");old.erase("screen_repaired")
	old.started = true;old.active = "ARCHIVE";old.computer_id="crt_archive_05";old.level_id="archive_01"
	old.crystals=11;old.collected=["boot_access","boot_remote","archive_key","archive_hidden"]
	old.flags={"boot_access":true,"archive_key":true,"signal_archive_gate":true}
	old.worlds={"archive_01":{"position":[560,208],"blocks":{"heavy_boulder":[392,200]}}}
	old.wardrobe={"owned":["classic_orange","silver_shell"],"equipped":"silver_shell"}
	var disk := SaveStore.new();disk.path=prefix+".json"
	var original_text := JSON.stringify(old)
	var roundtrip: Dictionary = JSON.parse_string(original_text)
	var file := FileAccess.open(disk.path,FileAccess.WRITE);file.store_string(original_text);file.close()
	disk.load_progress()
	check("v3 is accepted and backed up byte for byte",disk.writable and disk.data.version==4 and FileAccess.file_exists(disk.path+".v3-backup") and FileAccess.get_file_as_string(disk.path+".v3-backup")==original_text)
	check("v3 inventory worlds and wardrobe survive",disk.data.collected==roundtrip.collected and disk.data.worlds==roundtrip.worlds and disk.data.crystals==11 and disk.data.wardrobe.equipped=="silver_shell")
	check("old adventure continues without forcing an intro",disk.data.story.intro_seen and disk.data.story.message_state=="failed" and disk.data.active=="ARCHIVE")
	check("old entered ARCHIVE will not replay unlock",disk.data.screen_unlocked.get("ARCHIVE",false) and disk.data.screen_unlock_seen.get("ARCHIVE",false))
	for id in ["BOOT","ARCHIVE","POP-UP","RECYCLE","SIGNAL","ERROR"]:
		var payload := SaveStore.fresh();payload.active=id
		check("v4 keeps active screen "+id,SaveStore.migrate(payload).active==id)
	var invalid := SaveStore.fresh();invalid.story={"intro_seen":"no","outro_seen":false,"message_state":"delivered"};invalid.screen_unlocked={"ERROR":"yes","unknown":true}
	var clean := SaveStore.migrate(invalid)
	check("invalid story and unearned delivery are normalized",not clean.story.intro_seen and clean.story.message_state!="delivered" and not clean.screen_unlocked.has("unknown") and not clean.screen_unlocked.get("ERROR",false))
	check("new adventure uses a fresh intro and keeps wardrobe",disk.new_adventure() and not disk.data.story.intro_seen and disk.data.wardrobe.equipped=="silver_shell" and disk.data.collected.is_empty())
	var broken := SaveStore.new();broken.path=prefix+"-missing/fail.json"
	var before := broken.data.duplicate(true);var next := before.duplicate(true);next.story.intro_seen=true
	check("failed story commit leaves state unchanged",not broken.commit(next) and broken.data==before)
	for suffix in [".json",".json.v3-backup"]:
		if FileAccess.file_exists(prefix+suffix): DirAccess.remove_absolute(prefix+suffix)
	var dir := DirAccess.open("user://")
	for name in dir.get_files():
		if name.begins_with(prefix.get_file()+".json.before-new-"): dir.remove(name)
	var report := {"passed":checks.all(func(c):return c.passed),"tests":checks}
	file=FileAccess.open("res://artifacts/six-link-state-qa.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	quit(0 if report.passed else 1)

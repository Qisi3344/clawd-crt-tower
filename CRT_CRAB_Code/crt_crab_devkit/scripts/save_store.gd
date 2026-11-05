class_name SaveStore
extends RefCounted

const PATH := "user://progress.json"
var path := PATH
var data: Dictionary = fresh()
var enabled := true

static func fresh() -> Dictionary:
	return {"version":2,"active":"BOOT","computer_id":"crt_boot_00","level_id":"boot_01","health":3,"crystals":0,"collected":[],"pickups":[],"flags":{},"worlds":{}}

static func migrate(parsed: Dictionary) -> Dictionary:
	var result := fresh()
	if parsed.get("version")==1:
		# Coordinates and puzzle rewards belong to different rulesets; keep the old
		# record intact, but enter the new map at a safe checkpoint.
		result.legacy_progress = parsed.duplicate(true)
		result.health = clampi(int(parsed.get("health",3)),1,3)
		return result
	if parsed.get("version")!=2: return result
	for field in result:
		if parsed.has(field) and typeof(parsed[field])==typeof(result[field]): result[field] = parsed[field]
	if parsed.has("legacy_progress"): result.legacy_progress = parsed.legacy_progress
	if result.active not in ["BOOT","ARCHIVE"]: result.active = "BOOT"
	result.health = clampi(int(parsed.get("health",3)),1,3) if parsed.get("health") is float or parsed.get("health") is int else 3
	result.crystals = maxi(0,int(parsed.get("crystals",0))) if parsed.get("crystals") is float or parsed.get("crystals") is int else 0
	# JSON numbers are floats; retain validated numeric values explicitly.
	result.version = 2
	return result

func load_progress() -> void:
	if not enabled or not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return
	var parsed = parser.data
	if parsed is Dictionary:
		if parsed.get("version")==1 and not FileAccess.file_exists(path+".v1-backup"):
			DirAccess.copy_absolute(path,path+".v1-backup")
		data = migrate(parsed)

func write() -> bool:
	if not enabled:
		return true
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data,"\t",true,true))
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path) == OK

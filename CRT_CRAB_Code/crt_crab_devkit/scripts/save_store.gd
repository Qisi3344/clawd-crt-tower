class_name SaveStore
extends RefCounted

const PATH := "user://progress.json"
var path := PATH
var data: Dictionary = {"version":1,"active":"BOOT","health":3,"flags":{},"worlds":{}}
var enabled := true

func load_progress() -> void:
	if not enabled or not FileAccess.file_exists(path):
		return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return
	var parsed = parser.data
	if parsed is Dictionary and parsed.get("version") == 1 and parsed.get("flags") is Dictionary and parsed.get("worlds") is Dictionary and parsed.get("active") in ["BOOT","ARCHIVE"]:
		data = parsed

func write() -> bool:
	if not enabled:
		return true
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data,"\t"))
	file.close()
	return DirAccess.rename_absolute(path+".tmp",path) == OK

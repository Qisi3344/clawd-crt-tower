class_name SaveStore
extends RefCounted

const PATH := "user://progress.json"
var path := PATH
var data: Dictionary = fresh()
var enabled := true
var status := "missing"
var writable := true

static func fresh() -> Dictionary:
	return {"version":3,"started":false,"active":"BOOT","computer_id":"crt_boot_00","level_id":"boot_01","health":3,"crystals":0,"collected":[],"pickups":[],"flags":{},"worlds":{},"wardrobe":{"owned":["classic_orange"],"equipped":"classic_orange"}}

static func version_of(parsed: Dictionary) -> int:
	var value = parsed.get("version",0)
	return int(value) if (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) else 0

static func migrate(parsed: Dictionary) -> Dictionary:
	var version := version_of(parsed)
	var result := fresh()
	if version==1:
		result.legacy_progress = parsed.duplicate(true)
		result.health = clampi(int(parsed.get("health",3)),1,3)
		result.started = true
		return result
	if version not in [2,3]: return result
	for field in result:
		if parsed.has(field) and typeof(parsed[field])==typeof(result[field]): result[field] = parsed[field].duplicate(true) if parsed[field] is Dictionary or parsed[field] is Array else parsed[field]
	if parsed.has("legacy_progress"): result.legacy_progress = parsed.legacy_progress
	result.started = parsed.get("started",true)==true
	if result.active not in ["BOOT","ARCHIVE"]: result.active = "BOOT"
	for field in ["health","crystals"]:
		var value = parsed.get(field,3 if field=="health" else 0)
		result[field] = int(value) if (value is float or value is int) and is_finite(float(value)) else (3 if field=="health" else 0)
	result.health = clampi(result.health,1,3)
	result.crystals = maxi(0,result.crystals)
	for field in ["collected","pickups"]: result[field] = result[field].filter(func(v): return v is String)
	for key in result.flags.keys():
		if not key is String or not result.flags[key] is bool: result.flags.erase(key)
	var owned: Array = ["classic_orange"]
	var raw = result.wardrobe.get("owned",[])
	if raw is Array:
		for id in raw:
			if id is String and Cosmetics.valid(id) and not owned.has(id): owned.append(id)
	if result.collected.has("archive_hidden") and not owned.has("glitch_crab"): owned.append("glitch_crab")
	var equipped = result.wardrobe.get("equipped","classic_orange")
	result.wardrobe = {"owned":owned,"equipped":equipped if owned.has(equipped) else "classic_orange"}
	result.version = 3
	return result

func load_progress() -> void:
	if not enabled or not FileAccess.file_exists(path): return
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path))!=OK or not parser.data is Dictionary:
		status = "damaged"
		writable = false
		return
	var parsed: Dictionary = parser.data
	var version := version_of(parsed)
	if version not in [1,2,3]:
		status = "unsupported"
		writable = false
		return
	if version in [2,3]:
		for key in ["active","collected","pickups","flags","worlds"]:
			if not parsed.has(key) or typeof(parsed[key])!=typeof(fresh()[key]):
				status = "damaged"
				writable = false
				return
	if version in [1,2] and not backup(".v%d-backup"%int(parsed.version)):
		status = "backup_failed"
		writable = false
		return
	data = migrate(parsed)
	status = "valid"

func backup(suffix: String) -> bool:
	if not enabled or not FileAccess.file_exists(path) or FileAccess.file_exists(path+suffix): return true
	return DirAccess.copy_absolute(path,path+suffix)==OK

func _write(candidate: Dictionary) -> bool:
	if not enabled: return true
	var file := FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: return false
	file.store_string(JSON.stringify(candidate,"\t",true,true))
	file.flush()
	var error := file.get_error()
	file.close()
	if error!=OK: return false
	return DirAccess.rename_absolute(path+".tmp",path)==OK

func write() -> bool:
	return writable and _write(data)

func commit(candidate: Dictionary) -> bool:
	if not writable or not _write(candidate): return false
	data.clear()
	data.merge(candidate,true)
	status = "valid"
	return true

func purchase(id: String) -> String:
	if data.wardrobe.owned.has(id): return "已经拥有，无需重复购买。"
	var entries := Cosmetics.catalog().filter(func(item): return item.id==id)
	if entries.is_empty() or entries[0].condition!="purchase": return "隐藏数据尚未找到。"
	var price := int(entries[0].price)
	if data.crystals<price: return "晶体不足，需要 %d，当前 %d。"%[price,data.crystals]
	var candidate := data.duplicate(true)
	candidate.crystals -= price
	candidate.wardrobe.owned.append(id)
	return "解锁成功，选择装备后生效。" if commit(candidate) else "保存失败，晶体未扣除，请重试。"

func equip(id: String) -> bool:
	if not data.wardrobe.owned.has(id): return false
	var candidate := data.duplicate(true)
	candidate.wardrobe.equipped = id
	return commit(candidate)

func new_adventure() -> bool:
	if not backup(".before-new-"+str(Time.get_unix_time_from_system()).replace(".","-")): return false
	var candidate := fresh()
	candidate.wardrobe = data.wardrobe.duplicate(true)
	candidate.started = true
	var previous := writable
	writable = true
	if commit(candidate): return true
	writable = previous
	return false

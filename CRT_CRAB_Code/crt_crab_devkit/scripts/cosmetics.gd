class_name Cosmetics
extends RefCounted

static var entries: Array = []

static func catalog() -> Array:
	if entries.is_empty(): entries = JSON.parse_string(FileAccess.get_file_as_string("res://data/cosmetics.json"))
	return entries

static func valid(id: String) -> bool:
	return catalog().any(func(item): return item.id==id)

static func frame(id: String, row: int, index: int = 0) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = load("res://assets/pixel/skins/"+(id if valid(id) else "classic_orange")+".png")
	result.region = Rect2(index%8*32,row*32,32,32)
	return result

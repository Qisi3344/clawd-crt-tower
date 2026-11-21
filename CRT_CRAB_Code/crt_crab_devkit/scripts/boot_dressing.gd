class_name BootDressing
extends Node2D

# BOOT 启动机房的装饰层。
# 原本 12 件道具统一贴在角色后方（z_index=-4），看起来像"画在墙上"。
# 这里改为按机身/锚点分组：墙挂与吊挂道具保持后景；能落地的道具按 Y 深度
# 与螃蟹做前后排序——道具脚底比螃蟹更低时压到螃蟹前面，形成真实空间层次。
# 用途、摆放坐标与数量都不变（仍为 12 个 Sprite2D，且无碰撞体）。

var _sortable: Array[Dictionary] = []

func _ready() -> void:
	name = "BootArt"
	z_index = -4
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var atlas: Texture2D = load("res://assets/pixel/boot/game/props.png")
	var catalog: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/pixel/boot/game/props_manifest.json"))
	var placements: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/boot_dressing.json"))
	for entry in placements:
		var r: Array = catalog[int(entry.id) - 1].atlas_rect
		var part := AtlasTexture.new()
		part.atlas = atlas
		part.region = Rect2(r[0], r[1], r[2], r[3])
		var sprite := Sprite2D.new()
		sprite.texture = part
		sprite.position = Vector2(entry.x, entry.y)
		sprite.offset = Vector2(0, r[3] / 2.0 if entry.get("hang", false) else -r[3] / 2.0)
		add_child(sprite)
		if entry.get("hang", false):
			var wire := Line2D.new()
			wire.width = 1
			wire.default_color = Color("536d73")
			wire.points = PackedVector2Array([Vector2(entry.x, 80), Vector2(entry.x, entry.y)])
			add_child(wire)
		# 墙挂 / 吊挂始终在后；其余按脚底 Y 与角色排序。
		var behind: bool = bool(entry.get("wall", false) or entry.get("hang", false))
		sprite.z_as_relative = false
		sprite.z_index = -4 if behind else 0
		if not behind:
			_sortable.append({"sprite": sprite, "base_y": float(entry.y)})

func _process(_delta: float) -> void:
	if _sortable.is_empty():
		return
	var world := get_parent() as SideWorld
	if world == null or not is_instance_valid(world.player):
		return
	# 螃蟹碰撞体是 12x18、中心偏移 -9，脚底 = position.y + 9。
	var feet := world.player.position.y + 9.0
	for item in _sortable:
		var sprite: Sprite2D = item["sprite"]
		var base_y: float = item["base_y"]
		sprite.z_index = 9 if base_y > feet else 0
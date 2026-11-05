class_name PixelArt
extends RefCounted

static var atlas: Texture2D
static var tiles: Texture2D

static func frame(row: int, index: int = 0) -> AtlasTexture:
	if atlas == null: atlas = load("res://assets/pixel/sprites.png")
	var texture := AtlasTexture.new()
	texture.atlas = atlas
	texture.region = Rect2(index%8*32,row*32,32,32)
	return texture

static func sprite(parent: Node2D, row: int, pos: Vector2 = Vector2.ZERO, index: int = 0) -> Sprite2D:
	var node := Sprite2D.new()
	node.texture = frame(row,index)
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	node.position = pos
	parent.add_child(node)
	return node

static func tile(parent: Node2D, pos: Vector2, archive: bool, index: int = 0) -> void:
	if tiles == null: tiles = load("res://assets/pixel/tiles.png")
	var texture := AtlasTexture.new()
	texture.atlas = tiles
	texture.region = Rect2(index%8*16,16 if archive else 0,16,16)
	var node := Sprite2D.new()
	node.texture = texture
	node.position = pos+Vector2(8,8)
	parent.add_child(node)

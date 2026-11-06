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

static var key_icon: Texture2D
static func icon(row: int) -> Texture2D:
	if row!=8: return frame(row)
	if key_icon==null:
		var image := Image.create(32,32,false,Image.FORMAT_RGBA8); image.fill(Color.TRANSPARENT)
		image.fill_rect(Rect2i(6,7,12,12),Color("ffc478")); image.fill_rect(Rect2i(9,10,6,6),Color("292033"))
		image.fill_rect(Rect2i(16,12,11,4),Color("ffc478")); image.fill_rect(Rect2i(22,15,3,6),Color("ffc478")); image.fill_rect(Rect2i(26,15,3,4),Color("ffc478"))
		key_icon = ImageTexture.create_from_image(image)
	return key_icon

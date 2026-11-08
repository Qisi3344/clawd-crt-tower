extends SceneTree
func _initialize() -> void:
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/archive_01.json"))
	var img:=Image.create(1024,640,false,Image.FORMAT_RGB8);img.fill(Color("302338"))
	img.fill_rect(Rect2i(0,0,1024,64),Color("60516e"))
	img.fill_rect(Rect2i(0,64,1024,144),Color("49354e"))
	img.fill_rect(Rect2i(0,256,1024,192),Color("36293f"))
	for p in d.platforms: img.fill_rect(Rect2i(p[0],p[1],p[2],p[3]),Color("26c7c9"))
	for ladder in d.ladders:
		img.fill_rect(Rect2i(ladder.x-2,ladder.top,4,ladder.bottom-ladder.top),Color("f097d0"))
	for p in [Vector2i(192,200),Vector2i(344,136),Vector2i(392,208),Vector2i(560,208),Vector2i(672,160),Vector2i(864,208),Vector2i(864,64)]: img.fill_rect(Rect2i(p-Vector2i(16,24),Vector2i(32,24)),Color("e6ad46"))
	for r in [Rect2i(110,82,120,48),Rect2i(740,82,120,48),Rect2i(120,280,140,80),Rect2i(730,280,140,80)]: img.fill_rect(r,Color("151b45"))
	img.save_png("res://assets/pixel/archive/source/layout-guide-v2.png")
	quit()

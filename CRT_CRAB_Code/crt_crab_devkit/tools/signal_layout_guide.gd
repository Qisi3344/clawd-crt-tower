extends SceneTree
func _initialize() -> void:
	var d:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/signal_01.json"))
	var img:=Image.create(1024,768,false,Image.FORMAT_RGB8);img.fill(Color("302338"))
	img.fill_rect(Rect2i(0,0,1024,64),Color("60516e"))
	img.fill_rect(Rect2i(0,64,1024,144),Color("49354e"))
	img.fill_rect(Rect2i(0,256,1024,192),Color("36293f"))
	for p in d.platforms: img.fill_rect(Rect2i(p[0],p[1],p[2],p[3]),Color("26c7c9"))
	for ladder in d.ladders:
		img.fill_rect(Rect2i(ladder.x-2,ladder.top,4,ladder.bottom-ladder.top),Color("f097d0"))
	img.save_png("res://assets/pixel/signal/source/layout-guide.png")
	quit()

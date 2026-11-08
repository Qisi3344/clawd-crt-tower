extends SceneTree

const ROOT="res://assets/pixel/archive/"
const SOURCE=ROOT+"source/"
const FILES=["01_archive_cart_档案推车.png","02_archive_boxes_档案纸箱.png","03_open_drawer_开启的档案抽屉柜.png","04_closed_cabinet_封闭抽屉柜.png","05_rolling_ladder_带轮检索梯.png","06_bridge_support_桥梁支撑柱.png","07_hanging_folders_吊挂档案组.png","08_paper_tape_reel_打孔纸带卷轴.png","09_broken_terminal_破损CRT检索终端.png","10_spilled_records_倾倒记录箱.png","11_hanging_lamp_吊灯.png","12_sealed_case_封存保管箱.png"]
const WIDTHS=[40,24,32,32,24,12,32,32,40,32,20,32]

func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT+"game")
	var atlas:=Image.create(512,128,false,Image.FORMAT_RGBA8);atlas.fill(Color.TRANSPARENT)
	var regions:Array=[]
	for i in range(FILES.size()):
		var source:=Image.load_from_file(SOURCE+FILES[i]);source.convert(Image.FORMAT_RGBA8)
		var image:=source.get_region(Rect2i(128,78,64,160)) if i==5 else source.get_region(source.get_used_rect())
		var height:=roundi(image.get_height()*float(WIDTHS[i])/image.get_width())
		image.resize(WIDTHS[i],height,Image.INTERPOLATE_LANCZOS)
		for y in range(height):
			for x in range(WIDTHS[i]):
				var c:=image.get_pixel(x,y)
				if c.a<.25: c=Color.TRANSPARENT
				else: c.a=1
				image.set_pixel(x,y,c)
		var pos:=Vector2i((i%8)*64+8,(i/8)*64+8)
		atlas.blit_rect(image,Rect2i(0,0,WIDTHS[i],height),pos)
		regions.append({"id":i+1,"rect":[pos.x,pos.y,WIDTHS[i],height],"source":FILES[i]})
	atlas.save_png(ROOT+"game/props.png")
	var mid:=Image.load_from_file(SOURCE+"ARCHIVE_mid_source_中景.png")
	# Upright cabinet facades only; all painted walkways and stairs are excluded.
	var panels:=[Rect2i(365,270,185,280),Rect2i(600,275,180,250),Rect2i(1515,270,190,280)]
	for i in range(panels.size()):
		var panel:=mid.get_region(panels[i]);panel.resize(48,roundi(panel.get_height()*48.0/panel.get_width()),Image.INTERPOLATE_LANCZOS)
		panel.save_png(ROOT+"game/cabinet_%d.png"%i)
	var raw_far:=Image.load_from_file(SOURCE+"ARCHIVE_far_source_远景.png")
	var edge_error:=0.0
	for y in range(raw_far.get_height()):
		var a:=raw_far.get_pixel(0,y);var b:=raw_far.get_pixel(raw_far.get_width()-1,y)
		edge_error+=absf(a.r-b.r)+absf(a.g-b.g)+absf(a.b-b.b)
	var generated:=ROOT+"source/far-clean.png"
	if FileAccess.file_exists(generated):
		var far:=Image.load_from_file(generated)
		far.resize(768,roundi(far.get_height()*768.0/far.get_width()),Image.INTERPOLATE_LANCZOS)
		far.save_png(ROOT+"game/far.png")
	var manifest:={"props":regions,"source_far_edge_rgb_mean":edge_error/(raw_far.get_height()*3),"far_repeat":false,"panel_source_rects":panels.map(func(r):return [r.position.x,r.position.y,r.size.x,r.size.y])}
	var file:=FileAccess.open(ROOT+"game/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("Compiled 12 props and three cabinet facades; horizontal repeat disabled. far ready=",FileAccess.file_exists(generated))
	quit()

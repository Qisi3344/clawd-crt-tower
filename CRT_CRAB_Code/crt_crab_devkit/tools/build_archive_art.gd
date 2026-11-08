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
	# One authored canvas. No cabinet extraction or panel repetition.
	var mid:=Image.load_from_file(SOURCE+"mid-continuous-v2.png")
	mid.convert(Image.FORMAT_RGBA8)
	# Generated window interiors contain a painted neutral checker instead of alpha.
	# Flood-key only the four enclosed white interiors, never the architecture.
	var holes:Dictionary={}
	for seed in [Vector2(.155,.13),Vector2(.775,.13),Vector2(.20,.57),Vector2(.80,.57)]:
		var pending:Array[Vector2i]=[Vector2i(seed*Vector2(mid.get_size()))]
		while not pending.is_empty():
			var pixel:Vector2i=pending.pop_back()
			if holes.has(pixel) or pixel.x<0 or pixel.y<0 or pixel.x>=mid.get_width() or pixel.y>=mid.get_height(): continue
			var color:=mid.get_pixelv(pixel)
			if minf(color.r,minf(color.g,color.b))<.65 or maxf(color.r,maxf(color.g,color.b))-minf(color.r,minf(color.g,color.b))>.10: continue
			holes[pixel]=true
			for direction in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]: pending.append(pixel+direction)
	for y in range(mid.get_height()):
		for x in range(mid.get_width()):
			var c:=mid.get_pixel(x,y);c.a=0 if holes.has(Vector2i(x,y)) else 1;mid.set_pixel(x,y,c)
	mid.resize(1024,640,Image.INTERPOLATE_LANCZOS)
	mid.save_png(ROOT+"game/mid-continuous.png")
	var sheet:=Image.load_from_file(SOURCE+"terrain-material-v2.png");sheet.convert(Image.FORMAT_RGBA8)
	var bands:Array[Rect2i]=[]
	var start:=-1
	for y in range(sheet.get_height()):
		var occupied:=0
		for x in range(sheet.get_width()):
			if sheet.get_pixel(x,y).a>.5: occupied+=1
		var active:bool=occupied>sheet.get_width()*.25
		if active and start<0: start=y
		if not active and start>=0:
			if y-start>8: bands.append(Rect2i(0,start,sheet.get_width(),y-start))
			start=-1
	if start>=0: bands.append(Rect2i(0,start,sheet.get_width(),sheet.get_height()-start))
	if bands.size()!=2: push_error("Expected two material strips; got %d"%bands.size());quit(1);return
	for i in range(2):
		var band:=sheet.get_region(bands[i]);band=band.get_region(band.get_used_rect())
		if i==1:
			var shallow:=band.duplicate();shallow.resize(1024,32,Image.INTERPOLATE_LANCZOS);shallow.save_png(ROOT+"game/foundation-32.png")
		band.resize(1024,16 if i==0 else 48,Image.INTERPOLATE_LANCZOS)
		band.save_png(ROOT+"game/"+("walkway.png" if i==0 else "foundation.png"))
	var stem:=atlas.get_region(Rect2i(regions[5].rect[0],regions[5].rect[1],12,regions[5].rect[3]))
	var column:=Image.create(12,128,false,Image.FORMAT_RGBA8);column.fill(Color.TRANSPARENT)
	for y in range(128): column.blit_rect(stem,Rect2i(0,y%stem.get_height(),12,1),Vector2i(0,y))
	column.save_png(ROOT+"game/column.png")
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
	var manifest:={"props":regions,"source_far_edge_rgb_mean":edge_error/(raw_far.get_height()*3),"far_repeat":false,"mid_canvas_size":[1024,640],"window_key_pixels":holes.size(),"terrain_strip_sizes":[[1024,16],[1024,32],[1024,48]],"material_source_bands":bands.map(func(r):return [r.position.x,r.position.y,r.size.x,r.size.y])}
	var file:=FileAccess.open(ROOT+"game/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify(manifest,"\t"));file.close()
	print("Compiled continuous 1024x640 midground, two world-width materials, and 12 prop types.")
	quit()

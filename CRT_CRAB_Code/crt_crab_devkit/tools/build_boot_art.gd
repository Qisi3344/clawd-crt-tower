extends SceneTree
const ROOT="res://assets/pixel/boot/"
const SOURCE=ROOT+"source/"
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT+"game")
	# One authored canvas. No cabinet extraction or panel repetition.
	var mid:=Image.load_from_file(SOURCE+"mid-authored.png")
	mid.convert(Image.FORMAT_RGBA8)
	# White observation interiors are keyed as explicit alpha windows.
	# Flood-key only the four enclosed white interiors, never the architecture.
	var holes:Dictionary={}
	for seed in [Vector2(.11,.11),Vector2(.88,.11),Vector2(.20,.57),Vector2(.80,.57)]:
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
	var sheet:=Image.load_from_file(SOURCE+"terrain-material.png");sheet.convert(Image.FORMAT_RGBA8)
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
	var far:=Image.load_from_file(SOURCE+"far-authored.png");far.resize(1024,640,Image.INTERPOLATE_LANCZOS);far.save_png(ROOT+"game/far.png")
	var props:=Image.load_from_file(SOURCE+"boot_props_atlas_512x192.png");props.save_png(ROOT+"game/props.png")
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string(SOURCE+"props_manifest.json"))
	for entry in entries:
		var r:Array=entry.atlas_rect
		var used:=props.get_region(Rect2i(r[0],r[1],r[2],r[3])).get_used_rect()
		entry.atlas_rect=[r[0]+used.position.x,r[1]+used.position.y,used.size.x,used.size.y]
	var catalog:=FileAccess.open(ROOT+"game/props_manifest.json",FileAccess.WRITE);catalog.store_string(JSON.stringify(entries,"\t"));catalog.close()
	print("BOOT: continuous midground, far, three collision-height materials, twelve props compiled; window pixels=",holes.size());quit()

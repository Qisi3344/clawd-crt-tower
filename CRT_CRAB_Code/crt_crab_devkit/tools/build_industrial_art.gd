extends SceneTree
func _initialize() -> void:
	for key in ["recycle","signal"]: compile(key)
	quit()

func compile(key:String) -> void:
	var root:="res://assets/pixel/"+key+"/"
	var source_root:=root+"source/"
	var configs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/industrial_art_layout.json"))
	var config:Dictionary=configs[key]
	DirAccess.make_dir_recursive_absolute(root+"game")
	# One authored canvas. No cabinet extraction or panel repetition.
	var mid:=Image.load_from_file(source_root+"mid-authored.png")
	mid.convert(Image.FORMAT_RGBA8)
	# The open skyline is keyed explicitly; buildings stay fully opaque.
	# Flood-key the connected white sky opening, never colored scene details.
	var holes:Dictionary={}
	var pending:Array[Vector2i]=[]
	# All upper-sky components, including gaps separated by hanging cable bundles.
	for seed in config.sky_seed_points: pending.append(Vector2i(Vector2(seed[0],seed[1])*Vector2(mid.get_size())))
	for r in config.sky_seed_rects:
		for y in range(int(r[1]*mid.get_height()),int((r[1]+r[3])*mid.get_height())):
			for x in range(int(r[0]*mid.get_width()),int((r[0]+r[2])*mid.get_width())):
				var c:=mid.get_pixel(x,y)
				if minf(c.r,minf(c.g,c.b))>.85 and maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))<.05: pending.append(Vector2i(x,y))
	for y in range(int(mid.get_height()*.30)):
		for x in range(mid.get_width()):
			var c:=mid.get_pixel(x,y)
			if minf(c.r,minf(c.g,c.b))>.85 and maxf(c.r,maxf(c.g,c.b))-minf(c.r,minf(c.g,c.b))<.05: pending.append(Vector2i(x,y))
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
	# Fit the ONE elevation to actual floor anchors; never crop/repeat scene patches.
	# Per-scene source floor anchors are recorded in industrial_art_layout.json.
	var fitted:=Image.create(1024,768,false,Image.FORMAT_RGBA8)
	var target_y:Array=[0,208,448,688,768]
	var source_y:Array=config.source_floor_y
	for y in range(768):
		var section:=0
		while section<3 and y>=target_y[section+1]: section+=1
		var fraction:float=float(y-target_y[section])/(target_y[section+1]-target_y[section])
		var sy:=clampi(roundi(lerpf(source_y[section],source_y[section+1],fraction)*mid.get_height()),0,mid.get_height()-1)
		var row:=mid.get_region(Rect2i(0,sy,mid.get_width(),1));row.resize(1024,1,Image.INTERPOLATE_LANCZOS)
		fitted.blit_rect(row,Rect2i(0,0,1024,1),Vector2i(0,y))
	mid=fitted
	mid.save_png(root+"game/mid-continuous.png")
	var sheet:=Image.load_from_file(source_root+"terrain-material.png");sheet.convert(Image.FORMAT_RGBA8)
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
			var shallow:=band.duplicate();shallow.resize(1024,32,Image.INTERPOLATE_LANCZOS);shallow.save_png(root+"game/foundation-32.png")
		band.resize(1024,16 if i==0 else 48,Image.INTERPOLATE_LANCZOS)
		band.save_png(root+"game/"+("walkway.png" if i==0 else "foundation.png"))
	var far:=Image.load_from_file(source_root+"far-authored.png");far.resize(768,576,Image.INTERPOLATE_LANCZOS);far.save_png(root+"game/far.png")
	var original:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_root+("manifest.json" if key=="recycle" else "source/asset_manifest.json")))
	var atlas:=Image.create(512,128,false,Image.FORMAT_RGBA8);atlas.fill(Color.TRANSPARENT)
	var entries:Array=[]
	var widths:Array=[36,32,28,34,30,38,16,26,36,28,24,30] if key=="recycle" else [38,36,28,30,24,32,28,24,34,34,30,18]
	for i in range(12):
		var item:Dictionary=original.props[i]
		var source:=Image.load_from_file(source_root+"game/props/"+str(item.filename));source.convert(Image.FORMAT_RGBA8)
		var prop:=source.get_region(source.get_used_rect())
		var prop_scale:=minf(float(widths[i])/prop.get_width(),54.0/prop.get_height())
		prop.resize(roundi(prop.get_width()*prop_scale),roundi(prop.get_height()*prop_scale),Image.INTERPOLATE_LANCZOS)
		for y in range(prop.get_height()):
			for x in range(prop.get_width()):
				var c:=prop.get_pixel(x,y);c.a=0 if c.a<.25 else 1;prop.set_pixel(x,y,c)
		prop=prop.get_region(prop.get_used_rect())
		var pos:=Vector2i((i%8)*64+8,(i/8)*64+8);atlas.blit_rect(prop,Rect2i(Vector2i.ZERO,prop.get_size()),pos)
		entries.append({"id":i+1,"label":item.get("label",item.filename),"rect":[pos.x,pos.y,prop.get_width(),prop.get_height()]})
	atlas.save_png(root+"game/props.png")
	var file:=FileAccess.open(root+"game/manifest.json",FileAccess.WRITE);file.store_string(JSON.stringify({"props":entries,"composition":"open-industrial-v1","sky_key_pixels":holes.size()},"\t"));file.close()
	print(key," continuous scene compiled; open-air pixels=",holes.size())

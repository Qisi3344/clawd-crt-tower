extends SceneTree

var game: Node
var camera: Camera3D
var folder := "res://artifacts/club-stage/"
var failed := false
var checks := 0

func _initialize() -> void:
	run.call_deferred()

func pose(degrees: float) -> void:
	var angle := deg_to_rad(degrees)
	camera.position = Vector3(sin(angle)*35,20,cos(angle)*35)
	camera.look_at(Vector3(0,6,0))
	game.surroundings._update_occlusion()
	game.ambience._process(0)

func capture() -> Image:
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	return root.get_texture().get_image()

func check(label: String, ok: bool) -> void:
	checks += 1
	if not ok:
		failed = true
		push_error(label)

func purple_fraction(frame: Image) -> float:
	var hits := 0
	var samples := 0
	for y in range(0,frame.get_height(),8):
		for x in range(0,frame.get_width(),8):
			var c := frame.get_pixel(x,y)
			# The original background measured (120,87,160), with a subtle scanline over it.
			if absi(c.r8-120)<6 and absi(c.g8-87)<6 and absi(c.b8-160)<6: hits += 1
			samples += 1
	return float(hits)/samples

func check_lamps() -> void:
	var ambience: Node = game.ambience
	var footprints: PackedVector4Array = ambience.floor_material().get_shader_parameter("footprints")
	check("Four tube footprints",footprints.size()==4)
	for i in range(footprints.size()):
		var tube: MeshInstance3D = ambience.fittings[i]
		var cone: MeshInstance3D = ambience.club_mood.get_node("LampCone%d"%(i+1))
		var source := tube.to_global(Vector3.DOWN*tube.get_aabb().size.y*0.5)
		var drop: float = cone.material_override.get_shader_parameter("drop")
		var footprint: Vector2 = cone.material_override.get_shader_parameter("footprint")
		var f := footprints[i]
		check("Cone starts at fixture %d"%i,source.distance_to(cone.global_position)<0.001 and cone.mesh is CylinderMesh)
		check("Light lands at matching ellipse %d"%i,absf(source.y-drop+1.15)<0.001 and Vector2(f.x,f.y).is_equal_approx(Vector2(source.x,source.z)) and Vector2(f.z,f.w).is_equal_approx(footprint))

func check_cutaways() -> void:
	var stage: Node = game.ambience.stage
	var partial := false
	var blocked := false
	# Sweep an actual occluding cabinet across the line to the tower at a low elevation.
	var item: Dictionary = stage.cutaways.filter(func(entry): return entry.node.name=="EntryArcadeEast")[0]
	var target := Vector3(0,6,0)
	var center: Vector3 = item.bounds.get_center()
	var outward := (center-target).normalized()
	var tangent := outward.cross(Vector3.UP).normalized()
	var targets: Array[Vector3] = [target]
	for i in range(41):
		stage.update_cutaways(center+outward*6+tangent*i*0.4,targets)
		if i==0: blocked = not item.node.visible
		if item.coverage>0.02 and item.coverage<0.98: partial = true
	check("Cabinet yields on the sightline, fades and reappears",blocked and partial and is_equal_approx(item.coverage,1.0))
	var side_wall: Dictionary = game.ambience.room_occluders[2]
	camera.position = Vector3(24,10,4)
	game.ambience._process(0)
	check("Wall softens before the camera crosses it",side_wall.node.visible and side_wall.coverage>0.05 and side_wall.coverage<0.95)
	camera.position.x = 27
	game.ambience._process(0)
	check("Wall disappears once outside",not side_wall.node.visible)
	var clear := true
	for device in game.devices:
		game.director.focus(device,true)
		game.surroundings._update_occlusion()
		game.ambience._process(0)
		for entry in stage.cutaways:
			if not entry.node.visible: continue
			for point in game.surroundings._targets():
				if EnvironmentSurroundings.segment_hits(entry.bounds,camera.position,point): clear = false
	check("Stage clears all twelve focused screens",clear)
	game.director.frame_title()
	game.director.busy = true

func check_hall_finish() -> void:
	var ambience: Node = game.ambience
	var stage: Node = ambience.stage
	var banks := stage.find_children("DistantCRTBank*","MeshInstance3D",false,false)
	check("All eight monitor banks use the finished rack mesh",banks.size()==8 and banks.all(func(n): return n.material_override.shader == preload("res://assets/environment/crt_rack/rack.gdshader")))
	check("Contacts follow the actual imported prop footprints",ambience.finish.get_children().filter(func(n): return n is MeshInstance3D and n.material_override.shader==preload("res://assets/environment/crt_rack/contact.gdshader") and n.material_override.get_shader_parameter("masks") is Texture2D).size()>=12)
	check("Each tower screen supplies its own picture to the case",game.devices.all(func(d): return d.get_node("Case").material_override.get_shader_parameter("picture")==d.screen_material.get_shader_parameter("screen_texture")))
	var focus := Vector3(4,0.45,39)
	camera.position = focus+Vector3(6,5.4,-16)
	camera.look_at(focus)
	game.surroundings._update_occlusion()
	ambience._process(0)
	# Isolate receiver lighting. Both frames keep identical lit glass, geometry and lamps.
	stage.set_energy(0.0)
	var dark := await capture()
	stage.set_energy(1.0)
	var lit := await capture()
	var changed := 0
	for y in range(5,lit.get_height()-5,3):
		for x in range(5,lit.get_width()-5,3):
			var a := lit.get_pixel(x,y)
			var b := dark.get_pixel(x,y)
			if maxi(a.r8-b.r8,maxi(a.g8-b.g8,a.b8-b.b8))>4: changed += 1
	check("Screen light visibly reaches rack receiver pixels",changed>350)

func run() -> void:
	if not "--qa" in OS.get_cmdline_user_args() or DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(folder)
	root.size = Vector2i(1024,640)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for child in game.get_children():
		if child.get_script() and child.get_script().resource_path.begins_with("res://tests/"):
			game.remove_child(child)
			child.free()
	game.set_process(false)
	game.hud.hide()
	if game.front_end: game.front_end.hide()
	if game.world: game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.enabled = false
	game.director.frame_title()
	game.director.busy = true
	camera = game.director.camera
	for i in range(12): await process_frame
	check_lamps()
	check_cutaways()
	await check_hall_finish()
	var sheet := Image.create_empty(1024,480,false,Image.FORMAT_RGB8)
	for i in range(12):
		pose(i*30)
		var frame := await capture()
		check("Original flat purple cleared at %d degrees"%(i*30),purple_fraction(frame)<0.01)
		frame.save_png(folder+"angle-%03d.png"%(i*30))
		frame.resize(256,160,Image.INTERPOLATE_LANCZOS)
		frame.convert(Image.FORMAT_RGB8)
		sheet.blit_rect(frame,Rect2i(0,0,256,160),Vector2i((i%4)*256,floori(i/4.0)*160))
	sheet.save_png(folder+"orbit.png")
	camera.position = Vector3(7,4.0,37)
	camera.look_at(Vector3(0,0.6,20))
	game.surroundings._update_occlusion()
	game.ambience._process(0)
	(await capture()).save_png(folder+"entrance.png")
	if game.front_end:
		pose(145)
		game.front_end.show()
		(await capture()).save_png(folder+"title-menu.png")
	print("STAGE_QA ",not failed," / ",checks," checks")
	game.audio.stop_all()
	quit(1 if failed else 0)

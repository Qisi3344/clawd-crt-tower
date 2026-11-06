extends SceneTree
var game: Node
var report := {"checks":[],"perf":[],"captures":[]}
func _initialize() -> void:
	_run.call_deferred()
func check(label: String, passed: bool) -> void:
	report.checks.append({"name":label,"passed":passed})
	if not passed: push_error(label)
func pose(p: Vector3, target: Vector3, overview := true) -> void:
	game.director.overview = overview
	game.director.camera.position = p
	game.director.camera.look_at(target)
	game.surroundings._update_occlusion()
	game.ambience._process(0)
func capture(label: String) -> void:
	for i in range(4): await process_frame
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png("res://artifacts/hall-"+label+".png")
	report.captures.append(label)
func _run() -> void:
	if "--qa" not in OS.get_cmdline_user_args(): quit(1); return
	root.size = Vector2i(1600,1000)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for child in game.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://tests/sideview_qa.gd":
			game.remove_child(child);child.free()
	game.set_process(false)
	game.hud.hide()
	game.world.enabled = false
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.audio.enabled = false
	game.surroundings.set_micro_motion(false)
	game.director.busy = true
	for i in range(12): await process_frame
	check("full hall enabled by default",game.ambience.enabled and game.audio.arcade_ambience)
	check("all twelve CRT shells use cel shading",game.devices.all(func(d): return d.get_node("Case").material_override is ShaderMaterial))
	check("pixel shaders kept on all twelve glass surfaces",game.devices.all(func(d): return d.screen_material.shader.resource_path=="res://assets/shaders/crt.gdshader"))
	check("five decorative units retained",game.shell.get_node("GapFillers").get_child_count()==5)
	for pair in [["Speaker_A",1.38,Color("916c84")],["Speaker_B",1.26,Color("756185")],["Speaker_C",1.26,Color("916c84")]]:
		var cabinet: MeshInstance3D = game.shell.get_node("GapFillers/"+pair[0]+"/Cabinet")
		var color: Color = cabinet.material_override.get_shader_parameter("base_color")
		check(pair[0]+" wider pink or purple cabinet",absf(cabinet.get_aabb().size.x-pair[1])<0.0001 and color.is_equal_approx(pair[2]))
	check("no bloom or spotlights",not game.ambience.world_environment.environment.glow_enabled and game.ambience.additions.find_children("*","SpotLight3D",true,false).is_empty())
	check("original sourceless directional lights disabled",game.ambience.original_lights.all(func(l): return not l.visible))
	check("four enclosure surfaces and nineteen source lights",game.ambience.room_occluders.size()==4 and game.ambience.additions.find_children("*","OmniLight3D",true,false).size()==19)
	var pixels := PackedByteArray()
	var views := [["front",Vector3(0,17,34),Vector3(0,6.4,0)],["right",Vector3(34,17,0),Vector3(0,6.4,0)],["back",Vector3(0,17,-34),Vector3(0,6.4,0)],["left",Vector3(-34,17,0),Vector3(0,6.4,0)],["room",Vector3(23,18,32),Vector3(0,6,-3)],["arcade",Vector3(28,10,12),Vector3(18,2.7,-1)],["repair",Vector3(-27,10,12),Vector3(-18.4,2,1)],["focus",game.devices[0].focus_position(),game.devices[0].focus_point()]]
	for state in [false,true]:
		game.ambience.set_enabled(state)
		for view in views:
			pose(view[1],view[2],view[0]!="focus")
			await capture(("after-" if state else "before-")+view[0])
		RenderingServer.force_draw()
		var data: PackedByteArray = game.viewport.get_texture().get_image().get_data()
		if state: check("internal pixel framebuffer byte-identical across art toggle",pixels==data)
		else: pixels = data
		for view in [views[0],views[2],views[7]]:
			pose(view[1],view[2],view[0]!="focus")
			for i in range(20):
				RenderingServer.force_draw()
				await process_frame
			var times: Array = []
			for i in range(60):
				var start := Time.get_ticks_usec()
				RenderingServer.force_draw()
				root.get_texture().get_image()
				times.append((Time.get_ticks_usec()-start)/1000.0)
				await process_frame
			times.sort()
			report.perf.append({"art_enabled":state,"view":view[0],"median_ms":times[30],"p95_ms":times[57]})
	var clips := 0
	for i in range(72):
		var a := i*TAU/72
		pose(Vector3(sin(a)*34,17,cos(a)*34),Vector3(0,6.4,0))
		for wall in game.ambience.room_occluders:
			if wall.node.visible and wall.bounds.has_point(game.director.camera.position): clips += 1
		RenderingServer.force_draw()
		await process_frame
	check("72-angle orbit keeps camera outside visible room surfaces",clips==0)
	for device in game.devices:
		game.director.active = device
		pose(device.focus_position(),device.focus_point(),false)
		var blocked := false
		for wall in game.ambience.room_occluders:
			for target in game.surroundings._targets():
				if wall.node.visible and EnvironmentSurroundings.segment_hits(wall.bounds,game.director.camera.position,target): blocked = true
		check(device.screen_id+" focused glass clear of enclosure",not blocked)
	for view in [["arcade",Vector3(28,10,12),Vector3(18,2.7,-1)],["repair",Vector3(-27,10,12),Vector3(-18.4,2,1)]]:
		pose(view[1],view[2])
		var clear := true
		for wall in game.ambience.room_occluders:
			if wall.node.visible and EnvironmentSurroundings.segment_hits(wall.bounds,view[1],view[2]): clear = false
		check(view[0]+" peripheral cutaway camera keeps the room wall out of view",clear)
	var toggle: CheckButton
	for control in game.hud.find_children("*","CheckButton",true,false):
		if control.text=="游戏厅氛围": toggle = control
	toggle.button_pressed = false
	check("pause art switch restores original materials",not game.ambience.enabled and game.devices[0].get_node("Case").material_override is StandardMaterial3D)
	toggle.button_pressed = true
	check("pause art switch restores full cel layer",game.ambience.enabled and game.devices[0].get_node("Case").material_override is ShaderMaterial)
	game.ambience.cel_shading_enabled = false
	game.ambience.set_enabled(true)
	check("cel materials can be disabled independently",game.devices[0].get_node("Case").material_override is StandardMaterial3D and game.ambience.additions.visible)
	game.ambience.cel_shading_enabled = true
	game.ambience.source_light_scale = 0
	game.ambience.set_enabled(true)
	check("local light intensity can be disabled independently",game.ambience.source_lights.all(func(l): return is_zero_approx(l.light_energy)))
	game.ambience.source_light_scale = 1
	game.ambience.decorations_enabled = false
	game.ambience.set_enabled(true)
	check("room decoration can be hidden independently",not game.ambience.decorations.visible and game.ambience.additions.visible)
	game.ambience.decorations_enabled = true
	game.ambience.set_enabled(true)
	var config_path := "user://qa-hall-%d.cfg"%OS.get_process_id()
	game.audio.preferences_path = config_path
	game.audio.preferences_enabled = true
	game.audio.set_visual("arcade_ambience",false)
	var config := ConfigFile.new()
	check("art preference saved separately from adventure",config.load(config_path)==OK and config.get_value("visual","arcade_ambience",true)==false)
	DirAccess.remove_absolute(config_path)
	game.audio.preferences_enabled = false
	check("QA never writes formal adventure",not game.save.enabled)
	report["passed"] = report.checks.all(func(c): return c.passed)
	report["method"] = "1600x1000 GPU; 60 forced-render/readback samples after 20 warmups per view, not gameplay FPS"
	var file := FileAccess.open("res://artifacts/arcade-hall-qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	game.audio.stop_all()
	OS.delay_msec(80)
	print("HALL_QA ",report.passed," / ",report.checks.size()," checks")
	quit(0 if report.passed else 1)

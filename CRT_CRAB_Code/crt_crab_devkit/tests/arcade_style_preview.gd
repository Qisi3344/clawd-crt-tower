extends SceneTree
var game: Node
var report := {"checks":[],"perf":[]}

func _initialize() -> void:
	_run.call_deferred()

func check(label: String, passed: bool) -> void:
	report.checks.append({"name":label,"passed":passed})
	if not passed: push_error(label)

func _run() -> void:
	if not "--qa" in OS.get_cmdline_user_args():
		push_error("Preview requires --qa to protect formal saves")
		quit(1)
		return
	root.size = Vector2i(1600,1000)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.audio.arcade_ambience = false
	game.apply_settings()
	for child in game.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://tests/sideview_qa.gd":
			game.remove_child(child)
			child.free()
	game.set_process(false)
	game.hud.hide()
	game.audio.enabled = false
	game.world.enabled = false
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.surroundings.set_process(false)
	game.director.busy = true
	game.director.overview = true
	var sample := Node3D.new()
	sample.set_script(load("res://scripts/arcade_style_sample.gd"))
	game.shell.add_child(sample)
	# Main builds static batches and frees their source meshes at frame end.
	for i in range(8): await process_frame
	sample.prepare(game)
	var pixel_material: Material = game.devices[0].screen.material_override
	var screen_size: Vector2i = game.viewport.size
	var views := [["tower",Vector3(13,11,23),Vector3(0,5,4)],["arcade",Vector3(28,10,12),Vector3(18,2.7,-1)],["focus",game.devices[0].focus_position(),game.devices[0].focus_point()],["wide",Vector3(0,22,39),Vector3(0,8,0)]]
	var original_pixels := PackedByteArray()
	for mode in [false,true]:
		sample.set_enabled(mode)
		for shot in views:
			game.director.camera.position = shot[1]
			game.director.camera.look_at(shot[2])
			game.surroundings._update_occlusion()
			for i in range(8): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://artifacts/style-"+("after-" if mode else "before-")+shot[0]+".png")
		RenderingServer.force_draw()
		var pixel_image: Image = game.viewport.get_texture().get_image()
		pixel_image.save_png("res://artifacts/style-pixels-"+("after" if mode else "before")+".png")
		if mode: check("internal pixel framebuffer remains byte-identical",pixel_image.get_data()==original_pixels)
		else: original_pixels = pixel_image.get_data()
		# Same-view forced-render/readback timing, not a gameplay FPS claim.
		game.director.camera.position = views[0][1]
		game.director.camera.look_at(views[0][2])
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
		report.perf.append({"sample_enabled":mode,"median_ms":times[30],"p95_ms":times[57],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	check("CRT pixel shader and 320x240 viewport stay unchanged",game.devices[0].screen.material_override==pixel_material and game.viewport.size==screen_size and screen_size==Vector2i(320,240))
	check("QA disables formal progress writes",not game.save.enabled)
	check("only local sample materials replaced",sample.changed.size()>0 and not game.devices[1].get_node("Case").material_override is ShaderMaterial)
	check("sample actually applies cel material and visible-source lighting",game.devices[0].get_node("Case").material_override is ShaderMaterial and sample.additions.visible and sample.original_lights.all(func(l): return not l.visible))
	check("no bloom in sample",not sample.world_environment.environment.glow_enabled)
	var lights: Array = sample.additions.find_children("*","OmniLight3D",true,false)
	check("five physical-source lights; no spotlight",lights.size()==5 and sample.additions.find_children("*","SpotLight3D",true,false).is_empty())
	sample.set_enabled(false)
	check("sample can restore original environment and materials",sample.world_environment.environment==sample.original_environment and game.devices[0].get_node("Case").material_override is StandardMaterial3D and not sample.additions.visible)
	report["passed"] = report.checks.all(func(c): return c.passed)
	var file := FileAccess.open("res://artifacts/arcade-style-sample.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	game.audio.stop_all()
	OS.delay_msec(80)
	print("STYLE_SAMPLE ",report.passed," / ",report.checks.size()," checks")
	quit(0 if report.passed else 1)

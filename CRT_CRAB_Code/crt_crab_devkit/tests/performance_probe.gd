extends Node

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var game := get_parent()
	game.world.enabled = false
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.director.busy = true
	get_tree().root.size = Vector2i(1280,800)
	for i in range(10): await get_tree().process_frame
	var samples: Array[Dictionary] = []
	for view in ["active","front","back"]:
		if view=="active":
			game.director.camera.position = game._device("BOOT").focus_position()
			game.director.camera.look_at(game._device("BOOT").focus_point())
		else:
			game.director.camera.position = Vector3(24,20,29)*(Vector3(-1,1,-1) if view=="back" else Vector3.ONE)
			game.director.camera.look_at(Vector3(0,7,0))
		for i in range(10):
			RenderingServer.force_draw()
			await get_tree().process_frame
		var started := Time.get_ticks_msec()
		var durations: Array[float] = []
		while Time.get_ticks_msec()-started<2500:
			var before := Time.get_ticks_usec()
			RenderingServer.force_draw()
			get_viewport().get_texture().get_image()
			durations.append((Time.get_ticks_usec()-before)/1000.0)
			await get_tree().process_frame
		var elapsed: float = Time.get_ticks_msec()-started
		durations.sort()
		samples.append({"view":view,"render_cycles":durations.size(),"elapsed_ms":elapsed,"measured_cycles_per_second":durations.size()*1000.0/elapsed,"render_readback_ms_median":durations[durations.size()/2],"render_readback_ms_p95":durations[int(durations.size()*0.95)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"static_memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0})
	var report := {"engine":Engine.get_version_info().string,"gpu":RenderingServer.get_video_adapter_name(),"size":[1280,800],"method":"wall clock, no fixed-fps; hidden-window forced OpenGL render and GPU image readback, 2.5 seconds per view; readback adds overhead, not an interactive gameplay FPS benchmark","samples":samples}
	var file := FileAccess.open("res://artifacts/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("PERFORMANCE "+JSON.stringify(report))
	game.audio.stop_all()
	get_tree().quit()

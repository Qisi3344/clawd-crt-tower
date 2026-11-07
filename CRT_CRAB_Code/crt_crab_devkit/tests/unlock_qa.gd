extends "res://tests/sideview_qa.gd"

func _run() -> void:
	await frames(20)
	check("six physical mappings and six auxiliary CRTs",game.unlock_director.config.size()==6 and game.devices.size()==12)
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/monitor_layout.json"))
	for id in game.unlock_director.config:
		var item: Dictionary = game.unlock_director.config[id]
		check("physical identity preserved "+id,game.devices[int(item.device_index)].computer_id==item.computer_id and game.devices[int(item.device_index)].position==ScreenWorld._vec(layout[int(item.device_index)].position))
	game.transitioning = true
	game._control_state()
	for index in [5,9,1,4,6,2]:
		var device: MonitorDevice = game.devices[index]
		game.director.focus(device,true)
		game.director.busy = true
		var director: ScreenUnlockDirector = game.unlock_director
		var original: Image = load("res://assets/pixel/standby_%d.png"%index).get_image()
		check("unlock begins with exact standby pixels %d"%index,director.frame(index,0).get_image().get_data()==original.get_data())
		director.play(device,false)
		var folder := "res://artifacts/unlock-%d"%index
		if visual: DirAccess.make_dir_recursive_absolute(folder)
		var shot := 0
		while director.playing:
			if visual:
				RenderingServer.force_draw()
				get_viewport().get_texture().get_image().save_png(folder+"/%03d.png"%shot)
				shot+=1
			await frames(5)
		check("theme completes on the actual glass %d"%index,device.status=="READY" and not director.playing)
		director.play(device,true)
		await frames(18)
		check("reduced motion finishes without waiting for full animation %d"%index,not director.playing and device.status=="READY")
		director.play(device,false)
		await frames(3)
		director.suspended = true
		var time: float = director.elapsed
		await frames(15)
		check("focus suspension stops clock %d"%index,is_equal_approx(director.elapsed,time))
		director.skip();director.skip()
		check("skip is idempotent and reaches READY %d"%index,not director.playing and device.status=="READY")
	game.transitioning = false
	game.director.busy = false
	game.director.focus(game._device(game.active_id),true)
	game._control_state()
	check("one 2D player and one gameplay viewport after all themes",get_tree().get_nodes_in_group("player").size()==1 and game.viewport.size==Vector2i(320,240))
	var report := {"passed":not failed,"renderer":DisplayServer.get_name(),"tests":results,"note":"Theme playback isolates devices; gameplay unlock/roundtrip is covered by sideview QA."}
	var file := FileAccess.open("res://artifacts/unlock-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	get_tree().quit(1 if failed else 0)

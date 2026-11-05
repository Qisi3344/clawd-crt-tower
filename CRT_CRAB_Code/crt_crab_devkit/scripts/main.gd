extends Node3D

var shell: Node3D
var devices: Array[MonitorDevice] = []
var director: ShellDirector
var viewport: SubViewport
var world: SideWorld
var hud: GameHUD
var audio: GameAudio
var save := SaveStore.new()
var manifest: Dictionary
var links: Array
var active_id := "BOOT"
var transitioning := false
var test_mode := false
var autosave := 0.0
var front_end: FrontEnd
var in_menu := true
var transfer_phase := ""
var surroundings: EnvironmentSurroundings
enum InputMode { PLAY_2D, TRANSITION_3D, ARRAY_VIEW, PAUSED, MAIN_MENU, WARDROBE, SETTINGS, TRANSITION_EXIT_2D, TRANSITION_ENTER_2D }
var input_mode := InputMode.PLAY_2D

func _ready() -> void:
	test_mode = "--qa" in OS.get_cmdline_user_args() or "--perf" in OS.get_cmdline_user_args()
	save.enabled = not test_mode
	save.load_progress()
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_manifest.json"))
	links = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_links.json"))
	_input_map()
	_build_shell()
	director = ShellDirector.new()
	add_child(director)
	if surroundings!=null: surroundings.configure(director,devices)
	viewport = SubViewport.new()
	viewport.name = "ActiveScreenViewport"
	viewport.size = Vector2i(320,240)
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_DISABLED
	add_child(viewport)
	audio = GameAudio.new()
	add_child(audio)
	if test_mode and DisplayServer.get_name()=="headless": audio.enabled = false
	hud = GameHUD.new()
	add_child(hud)
	hud.pause_changed.connect(func(_v: bool): _control_state())
	hud.overview_requested.connect(_toggle_overview)
	hud.sfx_toggle.set_pressed_no_signal(audio.enabled)
	hud.music_toggle.set_pressed_no_signal(audio.music_enabled)
	hud.music_slider.set_value_no_signal(audio.music_volume)
	hud.audio_changed.connect(audio.set_sfx_enabled)
	hud.music_changed.connect(audio.set_music_enabled)
	hud.music_volume_changed.connect(audio.set_music_volume)
	hud.motion_changed.connect(func(v: bool): audio.set_visual("reduced_motion",v); apply_settings())
	hud.environment_motion_changed.connect(func(v: bool):
		audio.set_visual("environment_motion",v)
		apply_settings()
	)
	hud.quit_requested.connect(_quit)
	hud.title_requested.connect(return_to_title)
	hud.reset_requested.connect(func():
		hud.set_paused(false)
		world.reset_puzzle()
	)
	get_tree().auto_accept_quit = false
	get_tree().root.min_size = Vector2i(640,480)
	get_tree().root.size_changed.connect(_resize_ui)
	_resize_ui()
	apply_settings()
	director.focus(_device("BOOT"),true)
	if test_mode and "--menu-qa" not in OS.get_cmdline_user_args():
		in_menu = false
		_load_world(save.data.active)
		director.focus(_device(active_id),true)
		_control_state()
		var harness := Node.new()
		harness.set_script(load("res://tests/performance_probe.gd" if "--perf" in OS.get_cmdline_user_args() else "res://tests/sideview_qa.gd"))
		add_child(harness)
	else:
		front_end = FrontEnd.new()
		front_end.game = self
		add_child(front_end)
		hud.hide()
		director.frame_title()
		if test_mode:
			var harness := Node.new()
			harness.set_script(load("res://tests/stage2_qa.gd"))
			add_child(harness)

func apply_settings() -> void:
	director.reduced_motion = audio.reduced_motion
	if in_menu: director.busy = audio.reduced_motion
	if surroundings!=null: surroundings.set_micro_motion(audio.environment_motion)
	if not test_mode: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if audio.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for button in hud.find_children("*","CheckButton",true,false):
		if button.text=="减少转场动态": button.set_pressed_no_signal(audio.reduced_motion)
		if button.text=="环境微动态": button.set_pressed_no_signal(audio.environment_motion)
	hud.sfx_toggle.set_pressed_no_signal(audio.enabled)
	hud.music_toggle.set_pressed_no_signal(audio.music_enabled)
	hud.music_slider.set_value_no_signal(audio.music_volume)

func begin_adventure(reset: bool) -> void:
	if _level_definition("BOOT" if reset else save.data.active).is_empty():
		front_end.message = "关卡数据不可用，进度未覆盖。"
		front_end.show_page("title")
		return
	if reset and not save.new_adventure():
		front_end.message = "备份或保存失败，旧进度保持不变。"
		front_end.show_page("title")
		return
	if not _load_world(save.data.active):
		front_end.message = "无法安全进入关卡，请检查出生点与关卡数据。"
		front_end.show_page("title")
		return
	in_menu = false
	front_end.hide()
	hud.show()
	hud.set_paused(false)
	apply_settings()
	director.busy = false
	director.focus(_device(active_id),true)
	_control_state()
	_checkpoint()
	audio.play("start")

func return_to_title() -> void:
	if transitioning or in_menu: return
	if not _checkpoint(): return
	in_menu = true
	hud.set_paused(false)
	hud.hide()
	_control_state()
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		_device(active_id).set_texture(ImageTexture.create_from_image(viewport.get_texture().get_image()))
	viewport.remove_child(world)
	world.free()
	world = null
	director.frame_title()
	front_end.show()
	front_end.message = "进度已保存。"
	front_end.show_page("title")

func _build_shell() -> void:
	shell = Node3D.new()
	shell.name = "WorldShell"
	add_child(shell)
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("20171e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("b4a1b1")
	env.ambient_light_energy = 0.28
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	# A very mild peach grade; keep black/white endpoints and near-equal luminance.
	var grade := Gradient.new()
	grade.offsets = PackedFloat32Array([0,0.25,0.5,0.75,1])
	grade.colors = PackedColorArray([Color(0,0,0),Color(0.254,0.249,0.244),Color(0.506,0.498,0.492),Color(0.754,0.749,0.744),Color(1,1,1)])
	var lut := GradientTexture1D.new()
	lut.gradient = grade
	env.adjustment_enabled = true
	env.adjustment_color_correction = lut
	environment.environment = env
	shell.add_child(environment)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45,-25,0)
	key.light_color = Color("f3deca")
	key.light_energy = 0.70
	key.shadow_enabled = true
	key.directional_shadow_max_distance = 60
	shell.add_child(key)
	var rim := DirectionalLight3D.new()
	rim.rotation_degrees = Vector3(-20,155,0)
	rim.light_color = Color("6b94a9")
	rim.light_energy = 0.35
	shell.add_child(rim)
	Craft.box(shell,Vector3(0,-1.7,0),Vector3(25,1.2,25),Color("1c2731"),0.4)
	var layout: Array = JSON.parse_string(FileAccess.get_file_as_string("res://data/monitor_layout.json"))
	for item in layout:
		var device := MonitorDevice.new()
		device.device_index = int(item.index)
		device.model = int(item.model)
		device.has_keyboard = item.get("keyboard",false)
		device.computer_id = item.computer_id
		device.screen_id = item.screen
		device.position = ScreenWorld._vec(item.position)
		device.rotation_degrees = ScreenWorld._vec(item.rotation)
		shell.add_child(device)
		devices.append(device)
	# Stacked speaker cabinets make the reference's media tower silhouette.
	for layer in range(3):
		var p := Vector3(-2.5+layer*1.7,1.2+layer*4.5,0)
		Craft.box(shell,p,Vector3(2.6,4.0,2.5),Color("232c34"),0.09)
		for y in [-0.9,0.9]:
			_speaker(p+Vector3(0,y,1.27))
	var dressing := Node3D.new()
	dressing.name = "ExteriorDressing"
	shell.add_child(dressing)
	ExteriorDressing.build(dressing,devices)
	Craft.batch_static(dressing)
	if "--no-surroundings" not in OS.get_cmdline_user_args():
		surroundings = (load("res://scenes/environment/surroundings_root.tscn") as PackedScene).instantiate() as EnvironmentSurroundings
		shell.add_child(surroundings)

func _speaker(p: Vector3) -> void:
	for radius in [0.92,0.68,0.34]:
		var node := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 0.06
		mesh.radial_segments = 20
		node.mesh = mesh
		node.material_override = Craft.material(Color("43515b") if radius == 0.68 else Color("19232b"))
		node.rotation_degrees.x = 90
		node.position = p+Vector3(0,0,(1-radius)*0.14)
		shell.add_child(node)

func _load_world(id: String, spawn_id: String = "") -> bool:
	var config := _level_definition(id)
	if config.is_empty(): return false
	var entrance := SideWorld.point(config.spawns.get("entrance"),Vector2(-1,-1))
	var requested := SideWorld.point(config.spawns.get(spawn_id,config.spawns.get("entrance")),Vector2(-1,-1))
	if entrance.x<0 or requested.x<0: return false
	var previous_id := active_id
	var previous_flags: Dictionary = save.data.flags.duplicate(true)
	active_id = id
	world = SideWorld.new()
	world.name = "ScreenWorld_"+id
	world.screen_id = id
	world.level_id = manifest[id].level_id
	world.definition = config
	world.session = save.data
	world.flags = save.data.flags
	var saved = save.data.worlds.get(world.level_id,{})
	world.state = saved.duplicate(true) if saved is Dictionary else {}
	world.links = links
	viewport.add_child(world)
	var spawn_point := SideWorld.point(config.spawns.get(spawn_id,config.spawns.entrance))
	world.player.spawn = spawn_point
	world.player.position = spawn_point if spawn_id!="" else SideWorld.point(world.state.get("position"),spawn_point)
	if world.player.test_move(world.player.transform,Vector2.ZERO,null,0.0,true):
		if spawn_id=="": world.player.position = entrance
		if spawn_id!="" or world.player.test_move(world.player.transform,Vector2.ZERO,null,0.0,true):
			viewport.remove_child(world)
			world.free()
			world = null
			active_id = previous_id
			save.data.flags.clear()
			save.data.flags.merge(previous_flags,true)
			return false
	var saved_health = save.data.get("health",3)
	world.player.health = clampi(int(saved_health),1,3) if saved_health is float or saved_health is int else 3
	world._snap_camera()
	world.message.connect(hud.show_message)
	world.prompt_changed.connect(func(text: String): hud.prompt_label.text = text)
	world.travel_requested.connect(_travel)
	world.sound_requested.connect(audio.play)
	world.progress_changed.connect(_progress)
	world.player.health_changed.connect(hud.set_health)
	world.player.health_changed.connect(func(_v: int): _checkpoint())
	_device(id).set_texture(viewport.get_texture())
	hud.set_health(world.player.health)
	_progress()
	return true

func _level_definition(id: String) -> Dictionary:
	if not manifest.has(id): return {}
	if not FileAccess.file_exists(manifest[id].definition): return {}
	var config = JSON.parse_string(FileAccess.get_file_as_string(manifest[id].definition))
	if not config is Dictionary or not config.get("spawns") is Dictionary: return {}
	for field in ["platforms","ladders","blocks","plates","doors","chests","crystals","breakables","enemies","terminals"]:
		if not config.get(field) is Array: return {}
	return config

func _pixel_phase(entering: bool) -> void:
	transfer_phase = "ENTER" if entering else "EXIT"
	_control_state()
	var sprite := world.player.sprite
	if director.reduced_motion:
		sprite.visible = true
		sprite.modulate.a = 0 if entering else 1
		var fade := create_tween()
		fade.tween_property(sprite,"modulate:a",1.0 if entering else 0.0,0.1)
		await fade.finished
	else:
		var fx := PortalFX2D.new()
		fx.position = world.player.position+sprite.position
		fx.scale.x = -1 if sprite.flip_h else 1
		fx.entering = entering
		fx.z_index = 12
		fx.configure(sprite)
		world.add_child(fx)
		sprite.visible = false
		var animation := create_tween()
		animation.tween_property(fx,"progress",1.0,0.30 if entering else 0.25)
		await animation.finished
		fx.queue_free()
	sprite.visible = entering
	sprite.modulate = Color.WHITE

func _travel(link: Dictionary) -> void:
	if in_menu or transitioning or hud.paused or director.overview or link.from!=active_id: return
	var destination := _level_definition(link.to)
	if not manifest.has(link.to) or _device(link.to)==null or destination.is_empty() or not destination.spawns.has(link.spawn_id):
		hud.show_message("NO SIGNAL / 连接失败，已返回原屏幕")
		audio.play("error")
		return
	if _device(link.to).computer_id!=link.target_computer_id: return
	if not _checkpoint(): return
	var direction := SideWorld.point(link.position).x-world.player.position.x
	if absf(direction)>0.1: world.player.facing = int(signf(direction))
	world.player.sprite.flip_h = world.player.facing<0
	transitioning = true
	_control_state()
	hud.prompt_label.text = ""
	hud.show_message("CONNECTING / "+str(link.to))
	audio.play("transfer_exit")
	await _pixel_phase(false)
	transfer_phase = "LINK"
	_control_state()
	audio.play("transfer_link")
	var signal_root := Node3D.new()
	add_child(signal_root)
	var a := _device(active_id).cable_anchor()
	var b := _device(link.to).cable_anchor()
	var points := PackedVector3Array()
	for i in range(13):
		var t := i/12.0
		points.append(a.lerp(b,t)+Vector3(0,-sin(PI*t)*0.7,-sin(PI*t)*0.55))
	if not director.reduced_motion: Craft.cable(signal_root,points,Color("365e62"),0.025)
	var dot := MeshInstance3D.new()
	var ball := SphereMesh.new();ball.radius=0.10;ball.height=0.2
	dot.mesh=ball;dot.material_override=Craft.material(Color("54cfc3"),0.4);dot.visible=not director.reduced_motion
	signal_root.add_child(dot)
	var success := [false]
	await director.travel(_device(link.to),func():
		if DisplayServer.get_name()!="headless":
			RenderingServer.force_draw()
			_device(active_id).set_texture(ImageTexture.create_from_image(viewport.get_texture().get_image()))
		var previous := world
		viewport.remove_child(previous)
		if _load_world(link.to,link.spawn_id):
			success[0] = true
			world.player.sprite.visible = false
			previous.free()
		else:
			world = previous
			viewport.add_child(previous)
			_device(active_id).set_texture(viewport.get_texture())
			world.last_prompt = ""
	,func(t: float): dot.position = a.lerp(b,t)+Vector3(0,-sin(PI*t)*0.7,-sin(PI*t)*0.55))
	signal_root.queue_free()
	director.focus(_device(active_id),true)
	if success[0]:
		audio.play("transfer_enter")
		await _pixel_phase(true)
	world.player.sprite.visible = true
	world.player.sprite.modulate = Color.WHITE
	transitioning = false
	transfer_phase = ""
	_control_state()
	var saved := _checkpoint()
	hud.show_message("LINK ESTABLISHED / "+str(manifest[active_id].name) if success[0] else "NO SIGNAL / 连接失败，已返回原屏幕")
	if not saved: hud.show_message("已连接，但进度未保存，请检查存储空间。")
	if not success[0]: audio.play("error")

func _process(delta: float) -> void:
	if in_menu:
		if not director.reduced_motion: director.orbit += delta*0.025
		return
	autosave += delta
	if autosave > 8 and not transitioning:
		autosave = 0
		_checkpoint()
	if hud.debug_label.visible:
		hud.debug_label.text = "FPS %d   DRAW %d   VIEWPORT 1   PLAYER %d\n%s · %.1f MB"%[Engine.get_frames_per_second(),Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),get_tree().get_nodes_in_group("player").size(),active_id,Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0]
	# Hide only a device that intersects the line from shell camera to active glass.
	if not director.overview and not director.busy:
		var target := _device(active_id).focus_point()
		var from := director.camera.position
		var line := target-from
		for device in devices:
			if device.screen_id == active_id:
				device.visible = true
				continue
			var t := clampf((device.global_position-from).dot(line)/line.length_squared(),0,1)
			device.visible = not (t>0.03 and t<0.94 and (from+line*t).distance_to(device.global_position)<2.9)
	else:
		for device in devices: device.visible = true

func _unhandled_input(event: InputEvent) -> void:
	if in_menu: return
	if event.is_action_pressed("pause") and not transitioning:
		if director.overview:
			_toggle_overview()
		else:
			hud.set_paused(not hud.paused)
	if event.is_action_pressed("overview"):
		_toggle_overview()
	if event.is_action_pressed("debug"):
		hud.debug_label.visible = not hud.debug_label.visible
	if event is InputEventMouseMotion:
		if director.overview and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			director.orbit -= event.relative.x*0.007
	if event is InputEventMouseButton and director.overview:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: director.elevation = clampf(director.elevation-1,5,30)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: director.elevation = clampf(director.elevation+1,5,30)

func _toggle_overview() -> void:
	if in_menu or transitioning or hud.paused:
		return
	director.toggle_overview()
	hud.overview_panel.visible = director.overview
	hud.prompt_label.text = ""
	_control_state()

func _control_state() -> void:
	if in_menu:
		input_mode = InputMode.WARDROBE if is_instance_valid(front_end) and front_end.page=="wardrobe" else (InputMode.SETTINGS if is_instance_valid(front_end) and front_end.page=="settings" else InputMode.MAIN_MENU)
	elif transitioning:
		input_mode = InputMode.TRANSITION_EXIT_2D if transfer_phase=="EXIT" else (InputMode.TRANSITION_ENTER_2D if transfer_phase=="ENTER" else InputMode.TRANSITION_3D)
	else:
		input_mode = InputMode.PAUSED if hud.paused else (InputMode.ARRAY_VIEW if director.overview else InputMode.PLAY_2D)
	if is_instance_valid(world):
		var allowed := not in_menu and not transitioning and not hud.paused and not director.overview
		world.enabled = allowed
		world.player.enabled = allowed
		world.process_mode = Node.PROCESS_MODE_INHERIT if allowed else Node.PROCESS_MODE_DISABLED

func _progress() -> void:
	if save.data.collected.has("archive_hidden") and not save.data.wardrobe.owned.has("glitch_crab"): save.data.wardrobe.owned.append("glitch_crab")
	hud.update_progress(active_id,save.data)
	for device in devices:
		device.set_status("ACTIVE" if device.screen_id==active_id else ("CONNECTED" if device.screen_id in ["BOOT","ARCHIVE"] and save.data.flags.get("boot_access",false) else "SLEEP"))
	_checkpoint()

func _checkpoint() -> bool:
	if in_menu or not is_instance_valid(world): return true
	save.data.started = true
	save.data.active = active_id
	save.data.computer_id = manifest[active_id].computer_id
	save.data.level_id = manifest[active_id].level_id
	save.data.health = world.player.health
	save.data.worlds[world.level_id] = world.snapshot()
	if not save.write():
		hud.show_message("进度未能写入磁盘，请检查存储空间。")
		return false
	return true

func _device(id: String) -> MonitorDevice:
	for device in devices:
		if device.screen_id == id: return device
	return null

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST: _quit()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not test_mode and not transitioning and not in_menu:
		hud.set_paused(true)

func _quit() -> void:
	if transitioning: return
	if not _checkpoint(): return
	audio.stop_all()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()

func _input_map() -> void:
	var map := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"attack":[KEY_J],"dash":[KEY_SHIFT],"interact":[KEY_E,KEY_K],"reset_puzzle":[KEY_R],"overview":[KEY_TAB],"pause":[KEY_ESCAPE],"debug":[KEY_F3]}
	for action in map:
		InputMap.add_action(action)
		for key in map[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack",mouse)

func _resize_ui() -> void:
	var window := get_tree().root
	var portrait := float(window.size.x)/maxf(window.size.y,1)<1.1
	var reference := Vector2i(900,1125) if portrait else (Vector2i(960,600) if window.size.x<1000 else Vector2i(1440,900))
	if window.content_scale_size != reference:
		window.content_scale_size = reference

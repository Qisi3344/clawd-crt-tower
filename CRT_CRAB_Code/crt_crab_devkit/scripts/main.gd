extends Node3D

var pet_gacha := PetGachaStore.new()
var gacha_panel: PetGachaPanel
var ambience: Node3D
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
var unlock_director: ScreenUnlockDirector
var auxiliary_unlock: ScreenUnlockDirector
var repaired_count := 0
var treasure_count := 4
var story: StoryDirector
var story_active := false
var story_commit_dialog: AcceptDialog
var delivery_pending := false
var ending_tour_clock := 0.0
var controls:=ControlProfile.new()
var input_router: ControlRouter
var touch_controls: TouchControls
var tutorial:=TutorialDirector.new()
var orientation_blocked:=false
enum InputMode { PLAY_2D, TRANSITION_3D, ARRAY_VIEW, PAUSED, MAIN_MENU, WARDROBE, SETTINGS, TRANSITION_EXIT_2D, TRANSITION_ENTER_2D, STORY }
var input_mode := InputMode.PLAY_2D

func _ready() -> void:
	test_mode = "--qa" in OS.get_cmdline_user_args() or "--perf" in OS.get_cmdline_user_args()
	pet_gacha.storage.enabled = not test_mode
	if not test_mode: pet_gacha.load_collection()
	save.enabled = not test_mode
	save.load_progress()
	controls.enabled=not test_mode
	controls.load_preferences()
	input_router=ControlRouter.new();input_router.profile=controls;add_child(input_router)
	tutorial.game=self
	manifest = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_manifest.json"))
	links = JSON.parse_string(FileAccess.get_file_as_string("res://data/screen_links.json"))
	treasure_count = _treasure_total()
	_input_map()
	_build_shell()
	director = ShellDirector.new()
	director.touch_framing=controls.profile=="touch"
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
	unlock_director = ScreenUnlockDirector.new()
	unlock_director.audio = audio
	add_child(unlock_director)
	auxiliary_unlock = ScreenUnlockDirector.new()
	auxiliary_unlock.audio = audio
	add_child(auxiliary_unlock)
	story=StoryDirector.new();story.audio=audio;add_child(story)
	story.finished.connect(_on_story_finished)
	if test_mode and DisplayServer.get_name()=="headless": audio.enabled = false
	hud = GameHUD.new()
	add_child(hud)
	touch_controls=TouchControls.new();touch_controls.game=self;add_child(touch_controls)
	hud.gacha_requested.connect(open_gacha)
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
	var retro := CanvasLayer.new(); retro.set_script(load("res://scripts/retro_ui.gd")); add_child(retro)
	_prepare_ambience.call_deferred()
	director.focus(_device("BOOT"),true)
	if test_mode and "--menu-qa" not in OS.get_cmdline_user_args():
		in_menu = false
		_load_world(save.data.active)
		director.focus(_device(active_id),true)
		_control_state()
		var harness := Node.new()
		var test_script := "res://tests/performance_probe.gd" if "--perf" in OS.get_cmdline_user_args() else "res://tests/sideview_qa.gd"
		if "--unlock-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/unlock_qa.gd"
		if "--chapter-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/exploration_qa.gd"
		if "--ecology-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/ecology_qa.gd"
		if "--touch-route-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/touch_route_qa.gd"
		if "--portal-hud-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/portal_hud_qa.gd"
		if "--archive-art-qa" in OS.get_cmdline_user_args(): test_script = "res://tests/archive_art_qa.gd"
		harness.set_script(load(test_script))
		add_child(harness)
	else:
		front_end = FrontEnd.new()
		front_end.game = self
		add_child(front_end)
		hud.hide()
		director.frame_title()
		if test_mode:
			var harness := Node.new()
			var script_path:="res://tests/story_qa.gd" if "--story-qa" in OS.get_cmdline_user_args() else "res://tests/stage2_qa.gd"
			if "--controls-qa" in OS.get_cmdline_user_args(): script_path="res://tests/controls_qa.gd"
			harness.set_script(load(script_path))
			add_child(harness)

func _prepare_ambience() -> void:
	# Craft batches release source meshes at the end of their construction frame.
	await get_tree().process_frame
	if "--art-preview" in OS.get_cmdline_user_args() or surroundings==null: return
	ambience = Node3D.new()
	ambience.set_script(load("res://scripts/arcade_ambience.gd"))
	shell.add_child(ambience)
	ambience.prepare(self,true)
	ambience.set_enabled(audio.arcade_ambience)

func apply_settings() -> void:
	if is_instance_valid(ambience): ambience.set_enabled(audio.arcade_ambience)
	director.reduced_motion = audio.reduced_motion
	if in_menu: director.busy = audio.reduced_motion
	if surroundings!=null: surroundings.set_micro_motion(audio.environment_motion)
	if not test_mode: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if audio.fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
	for button in hud.find_children("*","CheckButton",true,false):
		if button.text=="减少转场动态": button.set_pressed_no_signal(audio.reduced_motion)
		if button.text=="环境微动态": button.set_pressed_no_signal(audio.environment_motion)
		if button.text=="游戏厅氛围": button.set_pressed_no_signal(audio.arcade_ambience)
		if button.text=="全屏显示": button.set_pressed_no_signal(audio.fullscreen)
	hud.sfx_toggle.set_pressed_no_signal(audio.enabled)
	hud.music_toggle.set_pressed_no_signal(audio.music_enabled)
	hud.music_slider.set_value_no_signal(audio.music_volume)
	hud.sfx_slider.set_value_no_signal(audio.sfx_volume)
	hud.refresh_controls()

func begin_adventure(reset: bool) -> void:
	if transitioning or story_active or not in_menu: return
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
	if save.data.flags.get("message_delivered",false):
		if not save.data.story.outro_seen: _start_story("outro")
	elif not save.data.story.intro_seen: _start_story("intro")

func request_adventure(reset: bool) -> void:
	if not controls.chosen: front_end.choose_controls(reset)
	else: begin_adventure(reset)

func change_profile(value: String) -> bool:
	if not controls.apply(value,controls.show_tutorial): return false
	hud.refresh_controls()
	input_router.release_all()
	if is_instance_valid(touch_controls): touch_controls.release_all()
	director.touch_framing=value=="touch"
	if is_instance_valid(world):
		world.last_prompt="";hud.set_prompt("")
		if not save.data.tutorial.mode_hint_seen.get(value,false):
			save.data.tutorial.mode_hint_seen[value]=true
			hud.show_message("左侧摇杆移动，右侧跳跃 / 螯击 / 互动。按住互动配合摇杆推拉。" if value=="touch" else "已切回键鼠，操作指南可从暂停查看。")
	_control_state();_checkpoint()
	return true

func set_tutorial_enabled(value: bool) -> void:
	if not controls.apply(controls.profile,value): hud.show_message("操作偏好保存失败。")
	hud.refresh_controls()

func toggle_local_map() -> void:
	if in_menu or transitioning or story_active or hud.paused or director.overview or is_instance_valid(gacha_panel): return
	hud.set_map(not hud.map_open,world);_control_state()

func _start_story(kind: String) -> void:
	if story_active: return
	story_active=true;ending_tour_clock=0
	if kind=="outro":
		for device in devices: device.visible=true
	hud.hide();director.busy=true
	_control_state()
	story.play(kind,str(save.data.wardrobe.equipped),audio.reduced_motion)

func _on_story_finished(kind: String) -> void:
	if not story_active: return
	var candidate:=save.data.duplicate(true)
	candidate.story["intro_seen" if kind=="intro" else "outro_seen"]=true
	if kind=="intro": candidate.story.message_state="failed"
	if not save.commit(candidate):
		if not is_instance_valid(story_commit_dialog):
			story_commit_dialog=AcceptDialog.new();story_commit_dialog.title="进度未能保存";story_commit_dialog.dialog_text="剧情已结束，但记录尚未写入。检查存储空间后按确认重试；原进度保持不变。";add_child(story_commit_dialog)
			story_commit_dialog.confirmed.connect(func(): _on_story_finished(kind))
			story_commit_dialog.canceled.connect(func(): story_commit_dialog.popup_centered())
		story_commit_dialog.popup_centered()
		return
	world.flags=save.data.flags;world.session=save.data
	if is_instance_valid(story_commit_dialog): story_commit_dialog.queue_free();story_commit_dialog=null
	story_active=false
	director.busy=false;director.focus(_device(active_id),true)
	hud.show();_control_state();_progress()
	hud.show_message(str(story.dialogue.mission) if kind=="intro" else "CONNECTION RESTORED · 已完整通关，可继续探索")
	if kind=="outro": _show_ending_actions()

func _show_ending_actions() -> void:
	hud.set_paused(true)
	var result:=ConfirmationDialog.new();result.title="CRT CRAB / CONNECTION RESTORED";result.dialog_text="User："+str(story.dialogue.user_message)+"\n已送达 [OK]\n\nClawd："+str(story.dialogue.clawd_reply).replace("🦀","");result.ok_button_text="继续探索";result.cancel_button_text="返回菜单";add_child(result)
	result.add_button("回看结局",false,"replay")
	result.confirmed.connect(func(): hud.set_paused(false);result.queue_free())
	result.canceled.connect(func(): hud.set_paused(false);return_to_title();result.queue_free())
	result.custom_action.connect(func(_action: String): result.queue_free();hud.set_paused(false);_start_story("outro"))
	result.popup_centered()

func _maybe_deliver() -> void:
	if delivery_pending or story_active or transitioning or in_menu or save.data.flags.get("message_delivered",false) or not WorldProgress.delivery_ready(save.data.flags): return
	delivery_pending=true
	if not _checkpoint(): delivery_pending=false;return
	var candidate:=save.data.duplicate(true)
	candidate.flags.message_delivered=true;candidate.story.message_state="delivered";candidate.story.intro_seen=true
	if save.commit(candidate):
		world.flags=save.data.flags;world.session=save.data
		_progress()
		_start_story("outro")
	else: hud.show_message("核心已修复，送达事务尚未保存；请检查存储空间，稍后重试。")
	delivery_pending=false

func return_to_title() -> void:
	if transitioning or in_menu or story_active: return
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
	# Lift unlit case faces without flattening the directional key and rim.
	env.ambient_light_energy = 0.38
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
	# Existing audio cabinets rest on one another; they never support a CRT.
	for layer in range(3):
		var p := Vector3(0,0.9+layer*4.0,0)
		Craft.box(shell,p,Vector3(2.6,4.0,2.5),Color("62556e") if layer%2 else Color("785c70"),0.09)
		for y in [-0.9,0.9]:
			_speaker(p+Vector3(0,y,1.27))
	var dressing := Node3D.new()
	dressing.name = "ExteriorDressing"
	shell.add_child(dressing)
	ExteriorDressing.build(dressing,devices)
	Craft.batch_static(dressing)
	ExteriorDressing.build_fillers(shell)
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

func _load_world(id: String, spawn_id: String = "", requested_room: String = "") -> bool:
	var root_definition := _level_definition(id)
	if root_definition.is_empty(): return false
	var saved = save.data.worlds.get(manifest[id].level_id,{})
	if not saved is Dictionary: saved = {}
	var room_id := ""
	var config := root_definition
	if not root_definition.has("rooms") and not requested_room.is_empty():
		var legacy_spawn:=requested_room+":"+(spawn_id if not spawn_id.is_empty() else "entrance")
		if not config.spawns.has(legacy_spawn): return false
		spawn_id=legacy_spawn
	if root_definition.has("rooms"):
		room_id = requested_room if not requested_room.is_empty() else (str(saved.get("room_id",root_definition.entry_room)) if spawn_id.is_empty() else str(root_definition.entry_room))
		config = RoomCatalog.room(root_definition,room_id)
		if config.is_empty() and requested_room.is_empty():
			room_id=str(root_definition.entry_room);config=RoomCatalog.room(root_definition,room_id)
		if config.is_empty(): return false
	var entrance := SideWorld.point(config.spawns.get("entrance"),Vector2(-1,-1))
	var requested := SideWorld.point(config.spawns.get(spawn_id,config.spawns.get("entrance")),Vector2(-1,-1))
	var bounds:=Vector2(config.get("size",[768,240])[0],config.get("size",[768,240])[1])
	if entrance.x<8 or requested.x<8 or entrance.x>bounds.x-8 or requested.x>bounds.x-8 or entrance.y<18 or requested.y<18 or entrance.y>bounds.y or requested.y>bounds.y: return false
	var previous_id := active_id
	var previous_flags: Dictionary = save.data.flags.duplicate(true)
	active_id = id
	world = SideWorld.new()
	world.name = "ScreenWorld_"+id
	world.screen_id = id
	world.level_id = manifest[id].level_id
	world.definition = config
	world.session = save.data
	world.controls=input_router
	world.flags = save.data.flags
	world.room_id = room_id
	if not room_id.is_empty():
		world.room_states = saved.get("rooms",{}).duplicate(true) if saved.get("rooms",{}) is Dictionary else {}
		var room_state = world.room_states.get(room_id,{})
		world.state = room_state.duplicate(true) if room_state is Dictionary else {}
	else: world.state = saved.duplicate(true)
	world.links = links
	viewport.add_child(world)
	var spawn_point := SideWorld.point(config.spawns.get(spawn_id,config.spawns.entrance))
	world.player.spawn = spawn_point
	world.player.position = spawn_point if spawn_id!="" else SideWorld.point(world.state.get("position"),spawn_point)
	if world.player.position.x<8 or world.player.position.x>bounds.x-8 or world.player.position.y<18 or world.player.position.y>bounds.y: world.player.position=_safe_checkpoint(config,world.state,world.player.position)
	if world.player.test_move(world.player.transform,Vector2.ZERO,null,0.0,true):
		if spawn_id=="": world.player.position = _safe_checkpoint(config,world.state,world.player.position)
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
	world._snap_camera(true)
	world.message.connect(hud.show_message)
	world.prompt_changed.connect(hud.set_prompt)
	world.learning_event.connect(tutorial.observe)
	world.travel_requested.connect(_travel)
	world.room_requested.connect(_change_room)
	world.sound_requested.connect(audio.play)
	world.progress_changed.connect(_progress)
	world.player.health_changed.connect(hud.set_health)
	world.player.health_changed.connect(func(_v: int): _checkpoint())
	_device(id).set_texture(viewport.get_texture())
	hud.set_health(world.player.health)
	_progress()
	return true

func _safe_checkpoint(config: Dictionary, state: Dictionary, p: Vector2) -> Vector2:
	var choices:Array=config.get("areas",[]).duplicate()
	choices.sort_custom(func(a,b):return SideWorld.point(a.checkpoint).distance_squared_to(p)<SideWorld.point(b.checkpoint).distance_squared_to(p))
	for area in choices:
		if str(area.id)==str(state.get("current_area","")): choices.erase(area);choices.push_front(area);break
	for area in choices:
		var checkpoint:=SideWorld.point(area.checkpoint)
		world.player.position=checkpoint
		if not world.player.test_move(world.player.transform,Vector2.ZERO,null,0.0,true):
			world.player.spawn=checkpoint;return checkpoint
	return SideWorld.point(config.spawns.entrance)

func _level_definition(id: String) -> Dictionary:
	if not manifest.has(id): return {}
	if not manifest[id].get("implemented",true): return {}
	if not FileAccess.file_exists(manifest[id].definition): return {}
	var config = JSON.parse_string(FileAccess.get_file_as_string(manifest[id].definition))
	return config if config is Dictionary and RoomCatalog.valid(config) else {}

func _treasure_total() -> int:
	var total := 0
	for id in manifest:
		var definition := _level_definition(id)
		if definition.has("rooms"):
			for room in definition.rooms.values(): total+=room.chests.size()
		else: total+=definition.get("chests",[]).size()
	return total

func _change_room(portal: Dictionary) -> void:
	if transitioning or in_menu or hud.paused or not _checkpoint(): return
	var config := _level_definition(active_id)
	var target := RoomCatalog.room(config,str(portal.to))
	if target.is_empty() or not target.spawns.has(portal.get("spawn","entrance")):
		hud.show_message("房间入口不可用，已保留当前进度。")
		return
	transitioning = true
	_control_state()
	var fade := create_tween()
	fade.tween_property(world,"modulate:a",0.0,0.08 if director.reduced_motion else 0.14)
	await fade.finished
	var previous := world
	viewport.remove_child(previous)
	if _load_world(active_id,str(portal.get("spawn","entrance")),str(portal.to)):
		previous.free()
	else:
		world = previous
		viewport.add_child(world)
		hud.show_message("出生点被阻挡，已回退原房间。")
	world.modulate.a = 0
	fade = create_tween()
	fade.tween_property(world,"modulate:a",1.0,0.08 if director.reduced_motion else 0.14)
	await fade.finished
	transitioning = false
	_control_state()
	_checkpoint()

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
	var arrival := RoomCatalog.room(destination,str(destination.get("entry_room",""))) if destination.has("rooms") else destination
	if not manifest.has(link.to) or _device(link.to)==null or arrival.is_empty() or not arrival.spawns.has(link.spawn_id):
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
	var first_entry: bool = save.data.screen_unlocked.get(link.to,false) and not save.data.screen_unlock_seen.get(link.to,false)
	await director.travel(_device(link.to),func():
		if DisplayServer.get_name()!="headless":
			RenderingServer.force_draw()
			_device(active_id).set_texture(ImageTexture.create_from_image(viewport.get_texture().get_image()))
		var previous := world
		viewport.remove_child(previous)
		if _load_world(link.to,link.spawn_id):
			success[0] = true
			world.player.sprite.visible = false
			if first_entry: _device(link.to).set_texture(unlock_director.frame(_device(link.to).device_index,0))
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
		if first_entry:
			transfer_phase = "UNLOCK"
			hud.show_message("首次唤醒 / "+str(link.to)+" · E / Esc 跳过")
			await unlock_director.play(_device(active_id),director.reduced_motion)
			var candidate := save.data.duplicate(true)
			candidate.screen_unlock_seen[active_id] = true
			if not save.commit(candidate): hud.show_message("解锁记录未保存，可继续探索，重访时会重播。")
			world.flags = save.data.flags
			world.session = save.data
			_device(active_id).set_texture(viewport.get_texture())
		audio.play("transfer_enter")
		await _pixel_phase(true)
	world.player.sprite.visible = true
	world.player.sprite.modulate = Color.WHITE
	transitioning = false
	transfer_phase = ""
	_control_state()
	var saved := _checkpoint()
	if success[0]: tutorial.observe("travel")
	hud.show_message("LINK ESTABLISHED / "+str(link.from)+" → "+str(link.to) if success[0] else "NO SIGNAL / 连接失败，已返回原屏幕")
	if not saved: hud.show_message("已连接，但进度未保存，请检查存储空间。")
	if not success[0]: audio.play("error")

func _process(delta: float) -> void:
	if is_instance_valid(touch_controls): touch_controls.refresh()
	if story_active:
		if story.kind=="outro" and story.playing and not story.suspended and story.clock<3.8:
			ending_tour_clock=story.clock
			if not audio.reduced_motion:
				var angle: float=story.clock*.65
				director.camera.position=Vector3(sin(angle)*28,lerpf(10,24,minf(story.clock/3.8,1)),cos(angle)*28)
				director.camera.look_at(Vector3(0,7,0))
		return
	if is_instance_valid(gacha_panel): return
	if in_menu:
		if not director.reduced_motion: director.orbit += delta*0.025
		return
	autosave += delta
	if autosave > 8 and not transitioning:
		autosave = 0
		_checkpoint()
		if save.data.flags.get("error_core_disabled",false): _maybe_deliver.call_deferred()
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
	if story_active: return
	if is_instance_valid(gacha_panel): return
	if in_menu: return
	if event.is_action_pressed("pause") and not transitioning:
		if hud.map_open: toggle_local_map()
		elif hud.paused and hud.pause_page_id!="main": hud.show_pause_page("settings" if hud.pause_page_id in ["controls","audio","video"] else "main")
		elif director.overview:
			_toggle_overview()
		else:
			hud.set_paused(not hud.paused)
	if event.is_action_pressed("overview"):
		_toggle_overview()
	if event.is_action_pressed("local_map"): toggle_local_map()
	if event.is_action_pressed("debug"):
		hud.debug_label.visible = not hud.debug_label.visible
	if event is InputEventMouseMotion:
		if director.overview and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			director.orbit -= event.relative.x*0.007
	if event is InputEventMouseButton and director.overview:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: director.elevation = clampf(director.elevation-1,5,30)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: director.elevation = clampf(director.elevation+1,5,30)

func _toggle_overview() -> void:
	if in_menu or transitioning or story_active or hud.map_open or hud.paused or is_instance_valid(gacha_panel):
		return
	director.toggle_overview()
	if not director.overview: tutorial.observe("array")
	hud.overview_panel.visible = director.overview
	hud.prompt_label.text = ""
	_control_state()

func open_gacha() -> void:
	if transitioning or story_active or surroundings==null or is_instance_valid(gacha_panel): return
	gacha_panel = PetGachaPanel.new()
	gacha_panel.game = self
	gacha_panel.machine = surroundings.zones[1].get_node("PetGashaponMachine")
	gacha_panel.store = pet_gacha
	add_child(gacha_panel)
	_control_state()

func _control_state() -> void:
	if is_instance_valid(gacha_panel):
		input_mode = InputMode.PAUSED
	elif story_active:
		input_mode=InputMode.STORY
	elif in_menu:
		input_mode = InputMode.WARDROBE if is_instance_valid(front_end) and front_end.page=="wardrobe" else (InputMode.SETTINGS if is_instance_valid(front_end) and front_end.page=="settings" else InputMode.MAIN_MENU)
	elif transitioning:
		input_mode = InputMode.TRANSITION_EXIT_2D if transfer_phase=="EXIT" else (InputMode.TRANSITION_ENTER_2D if transfer_phase=="ENTER" else InputMode.TRANSITION_3D)
	else:
		input_mode = InputMode.PAUSED if hud.paused or hud.map_open or orientation_blocked else (InputMode.ARRAY_VIEW if director.overview else InputMode.PLAY_2D)
	if is_instance_valid(world):
		var allowed := not in_menu and not transitioning and not story_active and not orientation_blocked and not hud.map_open and not hud.paused and not director.overview and not is_instance_valid(gacha_panel)
		world.enabled = allowed
		world.player.enabled = allowed
		world.process_mode = Node.PROCESS_MODE_INHERIT if allowed else Node.PROCESS_MODE_DISABLED
		input_router.allowed=allowed
		if not allowed: input_router.release_all()
	if is_instance_valid(touch_controls): touch_controls.refresh()

func _progress() -> void:
	if save.data.collected.has("archive_hidden") and not save.data.wardrobe.owned.has("glitch_crab"): save.data.wardrobe.owned.append("glitch_crab")
	WorldProgress.synchronize(save.data,manifest)
	hud.update_progress(active_id,save.data)
	for device in devices:
		if device.status=="UNLOCKING": continue
		if device.screen_id==active_id:
			device.set_status("ACTIVE")
		elif manifest.has(device.screen_id):
			var unlocked: bool = save.data.screen_unlocked.get(device.screen_id,false)
			device.set_status("REPAIRED" if save.data.screen_repaired.get(device.screen_id,false) else ("CORRUPTED" if unlocked and save.data.screen_unlock_seen.get(device.screen_id,false) else ("READY" if unlocked else "LOCKED")))
			if unlocked and save.data.screen_unlock_seen.get(device.screen_id,false): device.set_texture(unlock_director.frame(device.device_index,36))
		else:
			device.set_status("CONNECTED" if save.data.flags.get("message_delivered",false) else "SLEEP")
			if save.data.flags.get("message_delivered",false): device.set_texture(unlock_director.frame(device.device_index,36))
	var count: int = save.data.screen_repaired.size()
	if count>repaired_count and not auxiliary_unlock.playing:
		auxiliary_unlock.play(devices[1],audio.reduced_motion)
	repaired_count = count
	_checkpoint()
	if save.data.flags.get("error_core_disabled",false): _maybe_deliver.call_deferred()

func _checkpoint() -> bool:
	if story_active: return true
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
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(input_router):
		input_router.release_all()
		if is_instance_valid(touch_controls): touch_controls.release_all()
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(hud) and not test_mode and not transitioning and not in_menu and not story_active:
		hud.set_paused(true)

func _quit() -> void:
	if transitioning: return
	if not _checkpoint(): return
	audio.stop_all()
	await get_tree().create_timer(0.08).timeout
	get_tree().quit()

func _input_map() -> void:
	var map := {"move_left":[KEY_A,KEY_LEFT],"move_right":[KEY_D,KEY_RIGHT],"move_up":[KEY_W,KEY_UP],"move_down":[KEY_S,KEY_DOWN],"jump":[KEY_SPACE],"attack":[KEY_J],"dash":[KEY_SHIFT],"interact":[KEY_E,KEY_K],"reset_puzzle":[KEY_R],"overview":[KEY_TAB],"local_map":[KEY_M],"pause":[KEY_ESCAPE],"debug":[KEY_F3]}
	for action in map:
		InputMap.add_action(action)
		for key in map[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action,event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	# Left click is admitted only through unhandled input, after GUI consumption.
	var buttons := {"jump":JOY_BUTTON_A,"attack":JOY_BUTTON_X,"interact":JOY_BUTTON_Y,"reset_puzzle":JOY_BUTTON_LEFT_STICK,"overview":JOY_BUTTON_BACK,"pause":JOY_BUTTON_START}
	for action in buttons:
		var event:=InputEventJoypadButton.new();event.button_index=buttons[action];InputMap.action_add_event(action,event)
	for action in ["move_left","move_right","move_up","move_down"]:
		InputMap.action_set_deadzone(action,.25)
		var axis:=InputEventJoypadMotion.new()
		axis.axis=JOY_AXIS_LEFT_X if action in ["move_left","move_right"] else JOY_AXIS_LEFT_Y
		axis.axis_value=-1 if action in ["move_left","move_up"] else 1
		InputMap.action_add_event(action,axis)
		var dpad:=InputEventJoypadButton.new()
		dpad.button_index={"move_left":JOY_BUTTON_DPAD_LEFT,"move_right":JOY_BUTTON_DPAD_RIGHT,"move_up":JOY_BUTTON_DPAD_UP,"move_down":JOY_BUTTON_DPAD_DOWN}[action]
		InputMap.action_add_event(action,dpad)

func _resize_ui() -> void:
	var window := get_tree().root
	var portrait := float(window.size.x)/maxf(window.size.y,1)<1.1
	var reference := Vector2i(900,1125) if portrait else Vector2i(960,540)
	if window.content_scale_size != reference:
		window.content_scale_size = reference

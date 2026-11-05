extends Node

var game: Node
var results: Array[Dictionary] = []
var failed := false
var visual := false
var captures: Array[Dictionary] = []

func _ready() -> void:
	game = get_parent()
	visual = DisplayServer.get_name() != "headless"
	_run.call_deferred()

func check(label: String, condition: bool) -> void:
	results.append({"test":label,"passed":condition})
	print(("PASS " if condition else "FAIL ")+label)
	if not condition: failed = true

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func press(action: String, count: int = 2) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)
	await frames(2)

func _run() -> void:
	await frames(15)
	check("12 monitors / three tiers / three silhouettes",game.devices.size()==12)
	check("single isolated render target",game.viewport.own_world_3d and game.viewport.get_child_count()==1)
	check("one crab is a child of ScreenWorld, never WorldShell",get_tree().get_nodes_in_group("player").size()==1 and game.world.player.get_parent()==game.world)
	check("QA never reads, writes, or deletes the user's save",not game.save.enabled)
	await capture("01-boot")
	var player: CrabPlayer = game.world.player
	var start := player.position
	var camera_start: Vector3 = game.world.camera.position
	await press("move_right",35)
	check("WASD physically moves crab",player.position.x>start.x+1.4)
	check("internal camera follows moving crab",game.world.camera.position.distance_to(camera_start)>1)
	await press("jump",4)
	check("Space produces an actual jump",player.position.y>0.15)
	await frames(65)
	check("jump lands on collision floor",player.is_on_floor())
	player.position = Vector3(6.5,0.05,3)
	await press("move_right",50)
	check("wall collider prevents leaving screen world",player.position.x<7.1)
	player.position = Vector3(5.2,0.05,-4.8)
	await frames(4)
	await press("interact")
	check("unpowered portal is locked",game.active_id=="BOOT" and not game.transitioning)
	player.position = Vector3(-4.8,0.05,-1.4)
	await frames(4)
	await press("interact")
	check("signal terminal unlocks route",game.save.data.flags.get("signal",false))
	game.hud.set_paused(true)
	var paused_at := player.position
	await press("move_up",12)
	check("pause freezes gameplay",player.position.distance_to(paused_at)<0.001)
	game.hud.set_paused(false)
	game._toggle_overview()
	await frames(35)
	check("array overview locks player control",not player.enabled and game.director.overview)
	await capture("02-array")
	game.director.orbit += PI
	await frames(40)
	await capture("03-array-back")
	game._toggle_overview()
	await frames(40)
	player.position = Vector3(5.2,0.05,-3.5)
	await frames(4)
	await press("interact")
	check("transition freezes input during camera travel",game.transitioning and not game.world.player.enabled)
	await frames(32)
	await capture("04-transfer")
	await frames(100)
	check("actual E portal transitions BOOT to ARCHIVE",game.active_id=="ARCHIVE" and not game.transitioning)
	check("transition preserves exactly one controllable entity",get_tree().get_nodes_in_group("player").size()==1 and game.world.player.enabled)
	check("outer camera focuses new higher angled screen",game.director.camera.position.distance_to(game._device("ARCHIVE").focus_position())<0.15)
	await capture("04-archive")
	player = game.world.player
	player.invulnerable = 0
	player.take_damage()
	check("damage updates health and HUD",player.health==2 and game.hud.health_label.text.count("●")==2)
	player.take_damage()
	check("invulnerability prevents repeated damage",player.health==2)
	player.invulnerable = 0
	player.take_damage(3)
	check("death respawns in current world",player.health==3 and player.position.distance_to(player.spawn)<0.1 and game.active_id=="ARCHIVE")
	# Invoke real attack through its input and hit rules; no direct health edits.
	for enemy in game.world.enemies.duplicate():
		for strike in range(2):
			var p: Vector3 = enemy.node.position
			player.position = p+Vector3(0,0,1.1)
			player.avatar.rotation.y = PI
			player.attack_cooldown = 0
			await press("attack")
	check("claw attacks defeat both enemy types",game.world.enemies.is_empty())
	player.position = Vector3(4.5,0.05,-1.7)
	await frames(4)
	await press("interact")
	check("cleared archive yields persistent record",game.save.data.flags.get("record",false))
	await capture("05-record")
	player.position = Vector3(-5.2,0.05,3.5)
	await frames(4)
	await press("interact")
	await frames(120)
	check("return portal restores BOOT and signal state",game.active_id=="BOOT" and game.save.data.flags.get("signal",false))
	check("archived enemy state survives return",game.save.data.worlds.get("ARCHIVE",{}).get("defeated",[]).size()==2)
	# Reload from in-memory snapshot through the exact same loader as disk saves.
	var old_world: ScreenWorld = game.world
	game.viewport.remove_child(old_world)
	old_world.free()
	game._load_world("ARCHIVE")
	game.director.focus(game._device("ARCHIVE"),true)
	game._control_state()
	await frames(5)
	check("restore loader preserves cleared enemies and collected item",game.world.enemies.is_empty() and not game.world.fragment.visible)
	var disk := SaveStore.new()
	disk.path = "user://qa-roundtrip-"+str(OS.get_process_id())+".json"
	disk.data = game.save.data.duplicate(true)
	check("save writes atomically to dedicated QA file",disk.write())
	var restored := SaveStore.new()
	restored.path = disk.path
	restored.load_progress()
	check("disk reload restores route and enemy state",restored.data.flags.get("record",false) and restored.data.worlds.ARCHIVE.defeated.size()==2)
	var corrupt := FileAccess.open(disk.path,FileAccess.WRITE)
	corrupt.store_string("{broken save")
	corrupt.close()
	var recovery := SaveStore.new()
	recovery.path = disk.path
	recovery.load_progress()
	check("corrupt save safely starts at BOOT",recovery.data.active=="BOOT" and recovery.data.flags.is_empty())
	DirAccess.remove_absolute(disk.path)
	if visual:
		get_tree().root.size = Vector2i(720,900)
		await frames(15)
		check("portrait renderer expands to actual window ratio",get_viewport().get_visible_rect().size.y>get_viewport().get_visible_rect().size.x)
		await capture("06-portrait")
		game.hud.set_paused(true)
		await frames(4)
		await capture("07-pause")
		check("pause defaults to a focused resume control",game.hud.resume_button.has_focus())
	var report := {"engine":Engine.get_version_info().string,"renderer":DisplayServer.get_name(),"passed":not failed,"tests":results,"captures":captures}
	var file := FileAccess.open("res://artifacts/qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("QA_RESULT "+JSON.stringify(report))
	get_tree().quit(1 if failed else 0)

func capture(label: String) -> void:
	if not visual: return
	await RenderingServer.frame_post_draw
	var rendered := get_viewport().get_texture().get_image()
	rendered.save_png("res://artifacts/"+label+".png")
	captures.append({"name":label,"size":[rendered.get_width(),rendered.get_height()],"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0})

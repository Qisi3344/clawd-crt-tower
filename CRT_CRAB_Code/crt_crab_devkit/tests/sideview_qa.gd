extends Node

var game: Node
var results: Array[Dictionary] = []
var captures: Array[Dictionary] = []
var failed := false
var visual := false

func _ready() -> void:
	game = get_parent()
	visual = DisplayServer.get_name()!="headless"
	_run.call_deferred()

func check(label: String, condition: bool) -> void:
	results.append({"test":label,"passed":condition})
	print(("PASS " if condition else "FAIL ")+label)
	failed = failed or not condition

func frames(n: int) -> void:
	for i in range(n): await get_tree().physics_frame

func press(action: String, n: int = 2) -> void:
	Input.action_press(action)
	await frames(n)
	Input.action_release(action)
	await frames(2)

func walk_to(x: float, grab: bool = false, limit: int = 600) -> bool:
	if grab: Input.action_press("interact")
	for i in range(limit):
		var difference: float = x-game.world.player.position.x
		if absf(difference)<2: break
		Input.action_release("move_left")
		Input.action_release("move_right")
		Input.action_press("move_right" if difference>0 else "move_left")
		await frames(1)
	Input.action_release("move_left")
	Input.action_release("move_right")
	if grab: Input.action_release("interact")
	await frames(5)
	var ok: bool = absf(game.world.player.position.x-x)<5
	if not ok: print("WALK_BLOCKED target=",x," actual=",game.world.player.position)
	return ok

func capture(label: String) -> void:
	if not visual: return
	var expected := Vector2i(720,900) if label in ["m2-portrait","m2-pause"] else Vector2i(1280,800)
	get_tree().root.size = expected
	await frames(4)
	await get_tree().process_frame
	# Windows may stop normal redraws for a hidden/minimized QA window.
	# Force a real GPU render instead of waiting forever for a redraw signal.
	RenderingServer.force_draw()
	var image := get_viewport().get_texture().get_image()
	image.save_png("res://artifacts/"+label+".png")
	game.viewport.get_texture().get_image().save_png("res://artifacts/"+label+"-screen.png")
	captures.append({"name":label,"size":[image.get_width(),image.get_height()],"fps":Engine.get_frames_per_second(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"memory_mb":Performance.get_monitor(Performance.MEMORY_STATIC)/1048576.0})

func _run() -> void:
	await frames(20)
	check("M0 exterior twelve devices retained",game.devices.size()==12)
	check("upper keyboards absent and base configuration retained",game.devices.slice(4).all(func(d): return not d.has_keyboard) and game.devices[0].has_keyboard)
	check("real isolated 320x240 2D screen",game.viewport.disable_3d and game.viewport.size==Vector2i(320,240) and game.world.player is CharacterBody2D)
	check("only player belongs to internal screen",get_tree().get_nodes_in_group("player").size()==1 and game.world.player.get_parent()==game.world)
	check("QA disables user save access",not game.save.enabled)
	await capture("m1-01-boot")
	var start: Vector2 = game.world.player.position
	await press("move_up",12)
	check("W away from a ladder never creates flying movement",game.world.player.position.distance_to(start)<1)
	check("walk toward gap",await walk_to(112))
	Input.action_press("move_right")
	await press("jump",25)
	Input.action_release("move_right")
	await frames(30)
	check("jump crosses gap and lands",game.world.player.position.x>145 and game.world.player.is_on_floor())
	check("walk to crate",await walk_to(224))
	check("push crate using held E",await walk_to(256,true))
	check("pull crate without changing facing",await walk_to(224,true))
	check("push to normal pressure plate",await walk_to(304,true))
	await frames(25)
	check("weight opens actual collision door",game.save.data.flags.get("boot_gate_open",false) and game.world.doors[0].collider.disabled)
	await capture("m1-02-pressure")
	# Step over the box, not through its collider.
	Input.action_press("move_right")
	await press("jump",33)
	Input.action_release("move_right")
	await frames(20)
	check("pass opened gate",await walk_to(480))
	await press("move_up",85)
	await frames(10)
	check("ladder reaches raised treasure platform",game.world.player.position.y<150)
	check("approach BOOT chest",await walk_to(512))
	await press("interact")
	check("BOOT chest grants unique key and crystals",game.save.data.collected.has("boot_access") and game.save.data.flags.get("boot_access",false) and game.save.data.crystals>=2)
	var balance: int = game.save.data.crystals
	await press("interact")
	check("same chest cannot pay twice",game.save.data.crystals==balance)
	await capture("m1-03-treasure")
	game.hud.set_paused(true)
	var paused_at: Vector2 = game.world.player.position
	await press("move_right",15)
	check("pause freezes 2D control",game.world.player.position==paused_at)
	game.hud.set_paused(false)
	game._toggle_overview()
	await frames(30)
	check("array mode freezes internal physics",not game.world.player.enabled)
	await capture("m3-front")
	for entry in [[PI,"m3-back"],[PI/2,"m3-left"],[-PI/2,"m3-right"]]:
		game.director.orbit = entry[0]
		await frames(45)
		await capture(entry[1])
	game.director.busy = true
	game.director.camera.position = Vector3(0.01,37,0.01)
	game.director.camera.look_at(Vector3(0,6,0))
	await frames(45)
	await capture("m3-top")
	game.director.busy = false
	game._toggle_overview()
	await frames(40)
	check("reach first port by normal movement",await walk_to(592))
	await frames(20)
	var invalid: Dictionary = game.links[0].duplicate(true)
	invalid.spawn_id = "missing_spawn"
	game._travel(invalid)
	check("bad spawn safely refuses travel",not game.transitioning and game.world.player.enabled)
	var definition_path: String = game.manifest.ARCHIVE.definition
	game._travel(game.links[0])
	await frames(15)
	game.manifest.ARCHIVE.definition = "res://data/missing-qa-level.json"
	await frames(100)
	game.manifest.ARCHIVE.definition = definition_path
	check("mid-transition failure returns live original screen",game.active_id=="BOOT" and not game.transitioning and game.world.player.enabled and game._device("BOOT").screen_material.get_shader_parameter("screen_texture")==game.viewport.get_texture())
	await press("interact")
	check("transition input is locked",game.transitioning and not game.world.player.enabled)
	await press("interact",8)
	await frames(32)
	await capture("m2-04-transition")
	await frames(80)
	check("BOOT to ARCHIVE via actual E interaction",game.active_id=="ARCHIVE" and not game.transitioning)
	if game.active_id!="ARCHIVE":
		finish()
		return
	check("unique player after transfer",get_tree().get_nodes_in_group("player").size()==1 and game.world.player.enabled)
	await capture("m2-05-archive")
	game.world.player.position = Vector2(392,208)
	await frames(4)
	check("player weight alone cannot activate heavy plate",not game.save.data.flags.get("signal_archive_gate",false))
	game.world.player.position = game.world.player.spawn
	# Isolated combat check uses normal attack input near the patrol.
	var bug: DataBug = game.world.enemies[0]
	game.world.player.position = bug.position-Vector2(23,0)
	game.world.player.facing = 1
	await press("attack")
	await frames(24)
	game.world.player.position = bug.position-Vector2(23,0)
	await press("attack")
	check("two claw strikes defeat data bug",game.world.enemies.is_empty())
	# Resume a complete, normal platform/push route at the checkpoint.
	game.world.player.position = game.world.player.spawn
	game.world.player.velocity = Vector2.ZERO
	check("walk to archive box",await walk_to(176))
	Input.action_press("move_right")
	await press("jump",34)
	Input.action_release("move_right")
	await frames(20)
	check("reach archive ladder",await walk_to(288))
	await press("move_up",85)
	await frames(12)
	check("climb archive platform",game.world.player.position.y<150)
	check("approach marked obstacle",await walk_to(306))
	game.world.player.facing = 1
	await press("attack")
	check("pinch breaks marked obstacle",game.world.state.broken.has("archive_crack"))
	check("reach heavy stone",await walk_to(328))
	check("push heavy stone off platform",await walk_to(368,true))
	await frames(55)
	check("gravity lands heavy stone on persistent plate",game.save.data.flags.get("signal_archive_gate",false))
	if not game.save.data.flags.get("signal_archive_gate",false):
		finish()
		return
	await capture("m2-06-heavy-plate")
	# Jump clear of the stone before continuing along the lower floor.
	Input.action_press("move_right")
	await press("jump",36)
	Input.action_release("move_right")
	await frames(20)
	check("walk through heavy-signal gate",await walk_to(560))
	await press("interact")
	check("archive chest grants persistent key",game.save.data.collected.has("archive_key"))
	await capture("m2-07-key")
	var stone_before: Vector2 = game.world.blocks[1].position
	check("walk to marked hidden wall",await walk_to(610))
	await press("attack")
	check("hidden wall can be broken",game.world.state.broken.has("hidden_crack"))
	check("reach optional archive ladder",await walk_to(656))
	await press("move_up",70)
	await frames(10)
	check("reach hidden archive chest",await walk_to(672))
	await press("interact")
	check("optional archive treasure is collectible",game.save.data.collected.has("archive_hidden"))
	check("reach archive exit without teleport",await walk_to(736))
	await frames(20)
	await press("interact")
	await frames(110)
	check("return route reaches BOOT",game.active_id=="BOOT")
	check("ARCHIVE pressure opens real BOOT remote gate",game.world.doors[1].open)
	await capture("m2-08-remote-gate")
	check("walk through BOOT remote gate",await walk_to(704))
	await press("interact")
	check("remote reward obtainable only after cross-screen signal",game.save.data.collected.has("boot_remote"))
	check("walk back to outgoing port",await walk_to(592))
	await press("interact")
	await frames(110)
	check("BOOT ARCHIVE BOOT ARCHIVE roundtrip",game.active_id=="ARCHIVE")
	check("heavy stone and signal persist on revisit",game.world.blocks[1].position.distance_to(stone_before)<1 and game.save.data.flags.get("signal_archive_gate",false))
	check("treasure ledger survives revisit",game.save.data.collected.has("archive_key"))
	await disk_checks()
	var count: int = game.save.data.collected.size()
	await press("reset_puzzle")
	await frames(8)
	check("R resets current stone and clears supported signal",game.world.blocks[1].position.distance_to(game.world.blocks[1].origin)<1 and not game.save.data.flags.get("signal_archive_gate",true))
	check("R keeps unique treasure rewards",game.save.data.collected.size()==count and game.save.data.flags.get("archive_key",false))
	game.world.player.invulnerable = 0
	game.world.player.take_damage()
	check("damage has invulnerable interval",game.world.player.health==2 and game.world.player.invulnerable>0)
	game.world.player.take_damage()
	check("no chain damage",game.world.player.health==2)
	game.world.player.invulnerable = 0
	game.world.player.take_damage(3)
	check("death keeps collected chests",game.world.player.health==3 and game.save.data.collected.size()==count)
	await disk_checks()
	if visual:
		get_tree().root.size = Vector2i(720,900)
		await frames(30)
		await capture("m2-portrait")
		game.hud.set_paused(true)
		await frames(3)
		await capture("m2-pause")
		check("pause menu has focused resume",game.hud.resume_button.has_focus())
	finish()

func disk_checks() -> void:
	game._checkpoint()
	var disk := SaveStore.new()
	disk.path = "user://qa-side-"+str(OS.get_process_id())+".json"
	disk.data = game.save.data.duplicate(true)
	check("atomic version two save",disk.write())
	var restored := SaveStore.new()
	restored.path = disk.path
	restored.load_progress()
	var expected_flag: bool = disk.data.flags.get("signal_archive_gate",false)
	var expected_stone: Vector2 = game.world.blocks[1].position
	check("reload restores treasure ledger",restored.data.collected==disk.data.collected and restored.data.crystals==disk.data.crystals)
	game.viewport.remove_child(game.world)
	game.world.free()
	game.save.data = restored.data
	game._load_world(restored.data.active)
	game.director.focus(game._device(game.active_id),true)
	game._control_state()
	await frames(12)
	check("disk world reload reproduces stone and pressure signal",game.world.blocks[1].position.distance_to(expected_stone)<0.2 and game.save.data.flags.get("signal_archive_gate",false)==expected_flag)
	var old := {"version":1,"active":"ARCHIVE","health":2,"flags":{"record":true},"worlds":{"ARCHIVE":{"position":[4,1,2]}}}
	var migrated := SaveStore.migrate(old)
	check("legacy 3D save preserved with safe 2D spawn",migrated.version==2 and migrated.active=="BOOT" and migrated.health==2 and migrated.legacy_progress==old and migrated.worlds.is_empty())
	var corrupt := FileAccess.open(disk.path,FileAccess.WRITE)
	corrupt.store_string("{bad")
	corrupt.close()
	var recovery := SaveStore.new()
	recovery.path = disk.path
	recovery.load_progress()
	check("corrupt JSON recovers safely",recovery.data.active=="BOOT" and recovery.data.collected.is_empty())
	DirAccess.remove_absolute(disk.path)
	var legacy_file := FileAccess.open(disk.path,FileAccess.WRITE)
	legacy_file.store_string(JSON.stringify(old))
	legacy_file.close()
	var legacy_load := SaveStore.new()
	legacy_load.path = disk.path
	legacy_load.load_progress()
	check("real legacy file gets independent rollback backup",legacy_load.data.has("legacy_progress") and FileAccess.file_exists(disk.path+".v1-backup"))
	DirAccess.remove_absolute(disk.path)
	DirAccess.remove_absolute(disk.path+".v1-backup")

func finish() -> void:
	game.audio.stop_all()
	if visual: OS.delay_msec(80)
	var report := {"passed":not failed,"engine":Engine.get_version_info().string,"renderer":DisplayServer.get_name(),"tests":results,"captures":captures}
	var file := FileAccess.open("res://artifacts/sideview-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	print("QA_RESULT "+JSON.stringify(report))
	get_tree().quit(1 if failed else 0)

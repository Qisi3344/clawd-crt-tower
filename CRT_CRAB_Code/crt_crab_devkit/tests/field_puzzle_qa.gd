extends "res://tests/sideview_qa.gd"

func touch_board(panel, cell: int, phase: String) -> void:
	var event: InputEvent
	if phase=="move":
		event = InputEventScreenDrag.new()
	else:
		event = InputEventScreenTouch.new()
		event.pressed = phase=="down"
	event.index = 11
	event.position = panel.board.get_global_transform_with_canvas() * panel._tile(cell).get_center()
	get_viewport().push_input(event,true)

func _run() -> void:
	await frames(20)
	get_tree().root.size = Vector2i(960,540)
	var bug: DataBug = game.world.enemies[0]
	var start := bug.position
	await frames(30)
	check("boot patrol moves on the far side of the pressure door",bug.position.distance_to(start)>4 and bug.position.x>400)
	await walk_to(80)
	await press("move_up",155)
	await press("move_left", 40)
	check("locked shutter physically protects the visible reward",game.world.player.position.x>60 and not game.save.data.pickups.has("boot_service_crystal") and game.world.player.position.y<70)
	await walk_to(104)
	await press("interact")
	var panel = game.field_puzzle
	check("world interaction opens the maintenance box and freezes the world",is_instance_valid(panel) and not game.world.enabled)
	if not is_instance_valid(panel): finish(); return
	game.change_profile("touch")
	await frames(3)
	check("mobile overlay hides movement controls",not game.touch_controls.play_visible)
	check_layout(panel)
	button_press(panel,"提示")
	check("hint button explains the actual wire solution",panel.status.text.contains("左缘"))
	if visual: await capture("field-wire")
	touch_board(panel,0,"down")
	touch_board(panel,1,"move")
	touch_board(panel,5,"move")
	check("wire cannot cross a foreign socket",panel.routes[0]==[0,1])
	touch_board(panel,2,"move")
	touch_board(panel,6,"up")
	for route in [[4,8,12,13],[5,9,10,11,15]]:
		touch_board(panel,route[0],"down")
		for cell in route.slice(1,-1): touch_board(panel,cell,"move")
		touch_board(panel,route.back(),"up")
	await frames(4)
	check("three real touch routes restore power and player control",game.save.data.flags.get("boot_service_power",false) and game.world.enabled)
	game.change_profile("keyboard")
	await walk_to(25)
	check("upper service cache pays exactly once",game.save.data.pickups.count("boot_service_crystal")==1)
	if not failed: await archive_route()
	if not failed: await popup_route()
	if not failed: await enemy_and_assist_checks()
	finish()

func enter_chapter(id: String) -> bool:
	# Each optional route begins at its normal entrance; chapter transfers are covered by exploration_qa.
	var previous: SideWorld = game.world
	game.viewport.remove_child(previous)
	previous.free()
	var ok: bool = game._load_world(id,"entrance")
	check("load playable entrance "+id,ok)
	if ok:
		game._control_state()
		await frames(10)
	return ok

func check_layout(panel) -> void:
	var frame: Rect2 = get_viewport().get_visible_rect()
	var buttons: Array[Node] = panel.find_children("*","Button",true,false)
	check("board and all four actions fit in landscape",frame.encloses(panel.board.get_global_rect()) and buttons.size()==4 and buttons.all(func(b): return frame.encloses(b.get_global_rect())))

func button_press(panel, label: String) -> void:
	var button: Button = panel.find_children("*","Button",true,false).filter(func(b): return b.text==label)[0]
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.pressed = down
		get_viewport().push_input(event,true)

func mouse_cell(panel, cell: int, down: bool, close_button := false) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	var rect: Rect2 = panel._close_rect(cell) if close_button else panel._tile(cell)
	event.position = panel.board.get_global_transform_with_canvas() * rect.get_center()
	get_viewport().push_input(event,true)

func click_cell(panel, cell: int, close_button := false) -> void:
	mouse_cell(panel,cell,true,close_button)
	mouse_cell(panel,cell,false,close_button)

func archive_route() -> void:
	if not await enter_chapter("ARCHIVE"): return
	await walk_to(80)
	await press("move_up",155)
	var roller_gate: Dictionary = game.world.doors.filter(func(d): return d.id=="archive_sort_gate")[0]
	var opened := false
	var closed_again := false
	for i in 240:
		await frames(1)
		if roller_gate.open: opened = true
		elif opened: closed_again = true; break
	check("patrolling roller arms and releases the secondary pressure gate",opened and closed_again)
	await walk_to(166)
	await press("interact")
	check("cabinet directs player to the missing receipt",game.field_puzzle==null and game.hud.toast_label.text.contains("回执"))
	await walk_to(205)
	Input.action_press("move_right")
	await press("jump",48)
	Input.action_release("move_right")
	await walk_to(350)
	await press("interact")
	var panel = game.field_puzzle
	check("paper bench reachable past shelf guard",is_instance_valid(panel))
	if not is_instance_valid(panel): return
	if visual: await capture("field-paper")
	for swap in [[0,1],[1,3],[2,3]]:
		touch_board(panel,swap[0],"down")
		touch_board(panel,swap[1],"move")
		touch_board(panel,swap[1],"up")
	await frames(4)
	check("four dragged paper pieces yield reusable clue",game.save.data.flags.get("archive_receipt",false) and game.hud.toast_label.text.contains("4 · 架号 · 2"))
	if not game.world.enabled: return
	await walk_to(300)
	Input.action_press("move_left")
	await press("jump",55)
	Input.action_release("move_left")
	await walk_to(166)
	await press("interact")
	panel = game.field_puzzle
	check("repaired receipt opens three-digit lock",is_instance_valid(panel))
	if not is_instance_valid(panel): return
	if visual: await capture("field-cabinet")
	click_cell(panel,3)
	check("wrong code keeps the cabinet locked",not game.save.data.flags.get("archive_cabinet_open",false))
	for i in 3:
		for n in [4,7,2][i]: click_cell(panel,i)
	click_cell(panel,3)
	await frames(3)
	await walk_to(194)
	check("code assembled from receipt and shelf number releases a single pickup",game.save.data.pickups.count("archive_cabinet_crystal")==1)

func popup_route() -> void:
	if not await enter_chapter("POP-UP"): return
	await walk_to(80)
	await press("move_down",245)
	await walk_to(234)
	await press("interact")
	var panel = game.field_puzzle
	check("cache terminal reachable from hall ladder",is_instance_valid(panel))
	if not is_instance_valid(panel): return
	check_layout(panel)
	if visual: await capture("field-popup")
	var wrong: int = (panel.original+1)%4
	click_cell(panel,wrong,true)
	check("false close opens another window",panel.window_count==5 and not game.world.enabled)
	panel._process(19.0)
	click_cell(panel,panel.original,true)
	check("expired deadline rejects late solution",panel.seconds==0 and not game.save.data.flags.get("popup_cache_clean",false))
	button_press(panel,"重新开始")
	button_press(panel,"离开")
	await frames(3)
	check("leaving resumes play without granting reward",game.world.enabled and not game.save.data.flags.get("popup_cache_clean",false))
	await press("interact")
	panel = game.field_puzzle
	if not is_instance_valid(panel): check("reopen terminal",false); return
	click_cell(panel,panel.original,true)
	await frames(3)
	check("real process restores cache",game.save.data.flags.get("popup_cache_clean",false))
	await walk_to(270)
	Input.action_press("move_right")
	await press("jump",34)
	Input.action_release("move_right")
	await frames(22)
	await walk_to(320)
	Input.action_press("move_right")
	await press("jump",34)
	Input.action_release("move_right")
	await frames(22)
	check("two jumps reach the guarded cache",game.save.data.pickups.count("popup_process_crystal")==1)
	var normalized: Dictionary = SaveStore.migrate(game.save.data.duplicate(true))
	check("save normalization retains all puzzle completions and pickups",normalized.flags.get("archive_receipt",false) and normalized.flags.get("popup_cache_clean",false) and normalized.pickups==game.save.data.pickups)

func enemy_and_assist_checks() -> void:
	var world: SideWorld = game.world
	var moth: MechanicalAnimal = world.mechanisms.animals.filter(func(a): return is_instance_valid(a) and a.animal_id=="popup_drain_moth")[0]
	check("distant optional moth waits without emitting shots",moth.phase=="patrol" and is_zero_approx(moth.time))
	# Isolate the enemy's wind-up after completing the playable route above.
	world.player.position = moth.origin + Vector2(-90,19)
	await frames(18)
	check("approaching the projectile lane shows the wind-up",moth.phase=="cue" and not has_nearby_shot(moth))
	await frames(30)
	check("warned moth emits a real projectile",has_nearby_shot(moth))
	var assist := preload("res://scripts/ui/field_puzzle.gd").new()
	assist.entry = {"game":"wire","label":"接线"}
	var completions := []
	assist.finished.connect(func(solved): completions.append(solved))
	add_child(assist)
	await frames(3)
	button_press(assist,"辅助完成")
	button_press(assist,"辅助完成")
	check("assisted completion resolves once",completions==[true])
	assist.queue_free()

func has_nearby_shot(moth: MechanicalAnimal) -> bool:
	for child in moth.system.get_children():
		if child is SignalProjectile and child.position.distance_to(moth.position)<22: return true
	return false

func finish() -> void:
	get_tree().quit(1 if failed else 0)


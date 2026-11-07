extends "res://tests/stage2_qa.gd"

func touch(index:int,p:Vector2,pressed:bool) -> void:
	var event:=InputEventScreenTouch.new();event.index=index;event.position=p;event.pressed=pressed;get_viewport().push_input(event,true);await frames(2)

func _run() -> void:
	await frames(15)
	game.controls.chosen=false
	var before:Dictionary=game.save.data.duplicate(true)
	await activate(button("开始游戏"))
	check("Start asks for two profiles before initializing adventure",game.front_end.page=="controls" and not game.save.data.started and game.world==null)
	await capture("controls-choice")
	await activate(button("返回"))
	check("cancel selection preserves adventure byte-equivalent state",game.save.data==before and not game.controls.chosen and game.front_end.page=="title")
	await activate(button("开始游戏"));await activate(button("确认并开始冒险"));await frames(4)
	check("confirmed choice enters original intro once",game.controls.chosen and game.story.playing and game.story_active)
	game.change_profile("touch");get_tree().root.size=Vector2i(720,900);await frames(12)
	var story_time:float=game.story.clock
	await frames(15)
	check("portrait guard pauses story time and draws above the cinematic",game.touch_controls.guard.visible and game.touch_controls.layer>game.story.layer and is_equal_approx(story_time,game.story.clock))
	get_tree().root.size=Vector2i(1280,720);game.change_profile("keyboard");await frames(3)
	game.story.skip();await frames(3)
	var id:int=game.world.get_instance_id()
	await press("attack")
	check("empty attack does not teach a hit",not game.save.data.tutorial.completed.has("attack"))
	await press("move_right",30)
	check("moving actual body completes movement teaching",game.save.data.tutorial.completed.has("move"))
	game.change_profile("touch");await frames(4)
	await capture("controls-touch")
	var points:Dictionary=game.touch_controls.centers()
	var x:float=game.world.player.position.x
	await touch(1,points.stick+Vector2(54,0),true)
	await touch(2,points.jump,true);await frames(12)
	check("two fingers move and jump the real crab",game.world.player.position.x>x+8 and game.world.player.velocity.y<0)
	await touch(2,points.jump,false)
	check("releasing jump preserves the moving finger",game.input_router.pressed("move_right"))
	await touch(3,points.interact,true)
	await touch(1,points.stick,false)
	check("releasing joystick preserves held interaction",not game.input_router.pressed("move_right") and game.input_router.pressed("interact"))
	game.hud.set_paused(true);await frames(3)
	check("pause releases all virtual sources",game.input_router.sources.is_empty() and not game.world.enabled)
	game.hud.show_pause_page("settings");game.change_profile("keyboard")
	check("changing profile preserves the same world and state",game.world.get_instance_id()==id and game.input_router.sources.is_empty())
	game.hud.set_paused(false);game.change_profile("touch")
	get_tree().root.size=Vector2i(720,900);await frames(12)
	check("portrait touch is blocked with landscape guidance",game.orientation_blocked and game.touch_controls.guard.visible and not game.world.enabled)
	get_tree().root.size=Vector2i(1280,720);await frames(12)
	check("landscape restores the existing world",not game.orientation_blocked and game.world.enabled and game.world.get_instance_id()==id)
	var framed:=true
	var height:float=get_viewport().get_visible_rect().size.y
	for screen_id in WorldProgress.ORDER:
		var device:MonitorDevice=game._device(screen_id)
		game.director.focus(device,true)
		for x_corner in [-2.08,2.08]:
			for y_corner in [-1.56,1.56]:
				var projected:Vector2=game.director.camera.unproject_position(device.screen.to_global(Vector3(x_corner,y_corner,0)))
				framed=framed and projected.y>76 and projected.y<height-160
				if projected.y<=76 or projected.y>=height-160: print("FRAMING_DIAGNOSTIC ",screen_id," ",projected," available_height=",height)
	game.director.focus(game._device(game.active_id),true)
	check("all six touch CRT screens fit between HUD and thumb controls",framed)
	await capture("controls-landscape-fit")
	game.change_profile("keyboard");game.toggle_local_map();await frames(2)
	check("local map freezes play separately from CRT array",game.hud.map_open and not game.world.enabled and not game.director.overview)
	await capture("controls-local-map")
	game.hud.set_paused(true);await frames(2)
	check("pause replaces the local map instead of stacking two panels",game.hud.paused and not game.hud.map_open and not game.hud.map_panel.visible)
	game.hud.set_paused(false);game._toggle_overview();game._toggle_overview()
	check("array teaching completes only after returning",game.save.data.tutorial.completed.has("array"))
	var cfg:=ControlProfile.new();cfg.path="user://qa-controls-%d.cfg"%OS.get_process_id()
	check("profile writes independently",cfg.apply("touch",false))
	var loaded:=ControlProfile.new();loaded.path=cfg.path;loaded.load_preferences()
	check("profile and tutorial preference survive restart",loaded.profile=="touch" and loaded.chosen and not loaded.show_tutorial)
	DirAccess.remove_absolute(cfg.path)
	var failed_cfg:=ControlProfile.new();failed_cfg.path="user://qa-missing-controls-%d/config.cfg"%OS.get_process_id()
	check("failed preference write leaves choice unchanged",not failed_cfg.apply("touch",false) and not failed_cfg.chosen and failed_cfg.profile=="keyboard")
	var report:={"passed":not failed,"tests":results,"captures":captures,"scope":"Desktop native touch events; no Android or iOS hardware claim"}
	var file:=FileAccess.open("res://artifacts/controls-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	get_tree().quit(1 if failed else 0)

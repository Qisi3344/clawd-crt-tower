extends "res://tests/stage2_qa.gd"

func screenshot(name: String, portrait: bool=false) -> void:
	if not visual: return
	get_tree().root.size=Vector2i(1280,720) if "--landscape-story-qa" in OS.get_cmdline_user_args() else (Vector2i(720,900) if portrait else Vector2i(1280,800))
	await frames(8);RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+name+".png")

func _run() -> void:
	await frames(15)
	if "--landscape-story-qa" in OS.get_cmdline_user_args():
		get_tree().root.size=Vector2i(1280,720);game.change_profile("touch")
	check("fresh menu has no player",game.in_menu and game.world==null)
	await activate(button("开始游戏"))
	check("real Start menu plays story after safe initialization",game.story_active and game.story.playing and game.active_id=="BOOT" and game.world!=null and not game.world.enabled)
	var initial: Dictionary=game.save.data.duplicate(true)
	game.begin_adventure(true)
	check("repeated Start cannot initialize twice",game.save.data==initial and get_tree().get_nodes_in_group("player").size()==1)
	await frames(125)
	check("opening establishes working conversation first",game.story.desktop.beat=="chat" and not game.story.desktop.outgoing.visible)
	await screenshot("story-intro-chat")
	await frames(190)
	check("same identified user message visibly fails",game.story.desktop.outgoing.text.contains(game.story.dialogue.user_message) and game.story.desktop.delivery.text.contains("发送失败") and game.story.dialogue.message_id=="user-presence-001")
	await screenshot("story-intro-failed")
	game.story._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	var paused_clock: float=game.story.clock
	await frames(30)
	check("focus loss freezes story clock",is_equal_approx(game.story.clock,paused_clock) and game.story.pause_button.visible)
	game.story._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	game.story.pause_button.pressed.emit()
	await frames(200)
	check("Clawd chooses repair instead of being pulled in",game.story.desktop.beat in ["diagnostic","repair"] and game.story.desktop.diagnosis.visible)
	await screenshot("story-intro-repair",true)
	await frames(180)
	await screenshot("story-intro-jump")
	await frames(220)
	check("natural completion hands control to the one BOOT crab",not game.story_active and game.world.player.enabled and game.save.data.story.intro_seen and game.save.data.story.message_state=="failed")
	var before: Vector2=game.world.player.position
	if "--landscape-story-qa" in OS.get_cmdline_user_args():
		var points:Dictionary=game.touch_controls.centers()
		var finger:=InputEventScreenTouch.new();finger.index=41;finger.position=points.stick+Vector2(54,0);finger.pressed=true;get_viewport().push_input(finger,true)
		await frames(15)
		finger=finger.duplicate();finger.pressed=false;get_viewport().push_input(finger,true);await frames(2)
	else: await press("move_right",15)
	check("crab actually moves after opening",game.world.player.position.x>before.x+8)
	game.return_to_title();game.begin_adventure(false);await frames(3)
	check("Continue never repeats completed opening",not game.story_active and game.world.enabled)
	game.return_to_title();game.begin_adventure(true);await frames(3)
	var escape:=InputEventKey.new();escape.physical_keycode=KEY_ESCAPE;escape.keycode=KEY_ESCAPE;escape.pressed=true
	get_viewport().push_input(escape)
	escape=escape.duplicate();escape.pressed=false;get_viewport().push_input(escape);await frames(2)
	check("Escape skip uses the same durable finish path",not game.story_active and game.save.data.story.intro_seen and game.world.player.enabled)
	game.story.skip();game.story.skip()
	check("repeated skip does not duplicate player or finish",get_tree().get_nodes_in_group("player").size()==1 and not game.story_active)
	game.audio.reduced_motion=true;game.return_to_title();game.begin_adventure(true)
	await frames(15);game.story.skip();await frames(2)
	check("reduced-motion opening can safely skip",not game.story_active and game.world.player.enabled)
	# Test the failure path with a process-local path, never the formal save.
	game.return_to_title();game.begin_adventure(true);await frames(3)
	var original_path: String=game.save.path
	game.save.enabled=true;game.save.path="user://qa-story-missing-%d/progress.json"%OS.get_process_id()
	game.story.skip();await frames(2)
	check("failed story commit remains retryable without claiming it saved",game.story_active and not game.save.data.story.intro_seen and game.story_commit_dialog.visible)
	game.save.enabled=false;game.save.path=original_path
	game.story_commit_dialog.confirmed.emit();await frames(2)
	check("retry commits once and restores control",not game.story_active and game.save.data.story.intro_seen and game.world.player.enabled)
	var file:=FileAccess.open("res://artifacts/story-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"landscape_touch_simulation":"--landscape-story-qa" in OS.get_cmdline_user_args()},"\t"));file.close()
	get_tree().quit(1 if failed else 0)

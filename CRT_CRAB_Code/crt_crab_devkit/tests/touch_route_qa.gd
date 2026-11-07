extends "res://tests/sideview_qa.gd"

var actions:Dictionary={}
var stick_down:=false
var strikes:=0
func check(label: String, condition: bool) -> void:
	super.check(label,condition)
	if not condition:
		print("TOUCH_DIAGNOSTIC position=",game.world.player.position," facing=",game.world.player.facing," sources=",game.input_router.sources," blocks=",game.world.snapshot().blocks," learned=",game.save.data.tutorial.completed)
		finish()
func finger(id: int, p: Vector2, down: bool, drag:=false) -> void:
	var event:InputEvent
	if drag:
		event=InputEventScreenDrag.new();event.index=id;event.position=p
	else:
		event=InputEventScreenTouch.new();event.index=id;event.position=p;event.pressed=down
	get_viewport().push_input(event,true)

func hold(action: String, down: bool) -> void:
	actions[action]=down
	var points:Dictionary=game.touch_controls.centers()
	if action in ["move_left","move_right","move_up","move_down"]:
		var axis:=Vector2(int(actions.get("move_right",false))-int(actions.get("move_left",false)),int(actions.get("move_down",false))-int(actions.get("move_up",false)))
		var held:=axis!=Vector2.ZERO
		finger(11,points.stick+axis.normalized()*54,held,held and stick_down)
		stick_down=held
	else: finger({"jump":12,"attack":13,"interact":14}[action],points[action],down)

func press(action: String, n: int = 2) -> void:
	hold(action,true);await frames(n);hold(action,false);await frames(2)

func walk_to(x: float, grab: bool = false, limit: int = 750) -> bool:
	if grab: hold("interact",true)
	for i in range(limit):
		var difference:float=x-game.world.player.position.x
		if absf(difference)<2: break
		hold("move_left",difference<0);hold("move_right",difference>0);await frames(1)
	hold("move_left",false);hold("move_right",false)
	if grab: hold("interact",false)
	await frames(6)
	var ok:bool=absf(x-game.world.player.position.x)<5
	if not ok: print("TOUCH_WALK_BLOCKED ",x," at ",game.world.player.position," facing=",game.world.player.facing," actions=",actions)
	return ok

func wait_transition() -> void:
	for i in range(300):
		if not game.transitioning: break
		await frames(1)
	await frames(8)

func _run() -> void:
	await frames(20);get_tree().root.size=Vector2i(1280,720);game.change_profile("touch");await frames(6)
	await walk_to(112);hold("move_right",true);await press("jump",32);hold("move_right",false);await frames(30)
	check("native touch jump clears the gap and reaches the raised floor",game.world.player.position.x>160 and game.world.player.position.y<210 and game.world.player.is_on_floor())
	await walk_to(224);await walk_to(304,true);await frames(25)
	check("simultaneous held touch interaction and joystick opens real crate gate",game.save.data.flags.get("boot_gate_open",false) and game.save.data.tutorial.completed.has("push"))
	hold("move_right",true);await press("jump",33);hold("move_right",false);await frames(20)
	await walk_to(480);await press("move_up",85);await walk_to(512);await press("interact")
	check("touch ladder and interaction collect the original BOOT key",game.save.data.collected.has("boot_access") and game.save.data.tutorial.completed.has("ladder"))
	await capture("touch-route-boot-key")
	await walk_to(592);await press("interact");await wait_transition()
	check("touch port makes a genuine BOOT to ARCHIVE transfer",game.active_id=="ARCHIVE")
	if game.active_id!="ARCHIVE": finish();return
	await walk_to(112)
	for i in range(18):
		if game.world.enemies.is_empty(): break
		await press("attack");await frames(24)
	check("touch claw hits a real patrol and records hit-based learning",game.world.enemies.is_empty() and game.save.data.tutorial.completed.has("attack"))
	await walk_to(176);hold("move_right",true);await press("jump",34);hold("move_right",false);await frames(20)
	await walk_to(288);await press("move_up",85);await walk_to(306);await press("attack");await walk_to(328);await walk_to(368,true);await frames(55)
	check("touch pushes actual heavy stone into the live cross-screen source",game.save.data.flags.get("signal_archive_gate",false))
	await walk_to(40);await press("interact");await wait_transition()
	check("touch roundtrip returns to the same persistent BOOT world",game.active_id=="BOOT" and game.save.data.collected.has("boot_access"))
	await walk_to(704);await press("interact")
	check("touch roundtrip reaches the remote signal reward",game.save.data.collected.has("boot_remote"))
	await capture("touch-route-roundtrip")
	# Native GUI click must not fall through into the polled combat action.
	game.change_profile("keyboard");await frames(3)
	game.world.player.struck.connect(func():strikes+=1)
	var pause_button:Button
	for b in game.hud.find_children("*","Button",true,false):
		if b.text=="暂停": pause_button=b;break
	for down in [true,false]:
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=pause_button.get_global_rect().get_center();event.pressed=down;get_viewport().push_input(event,true);await frames(2)
	check("native GUI pause click is consumed before combat polling",game.hud.paused and strikes==0)
	game.hud.show_pause_page("settings");await capture("touch-route-pause-settings")
	finish()

func finish() -> void:
	var report:={"passed":not failed,"tests":results,"captures":captures,"scope":"Desktop native ScreenTouch and ScreenDrag only; mobile hardware pending"}
	var file:=FileAccess.open("res://artifacts/touch-route-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close();get_tree().quit(1 if failed else 0)

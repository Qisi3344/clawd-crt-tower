extends "res://tests/chapter_qa.gd"

func _ready() -> void:
	base_finished=true
	super._ready()

func fixture(id: String, room: String) -> void:
	record_tag=""
	game.hud.set_paused(false)
	game.viewport.remove_child(game.world);game.world.free()
	check("isolated room fixture loads "+id+" / "+room,game._load_world(id,"entrance",room))
	game.director.focus(game._device(id),true);game._control_state()
	await frames(8)

func _run() -> void:
	await frames(15)
	base_finished=true
	# These are focused behaviour fixtures, not evidence of campaign progression.
	await fixture("POP-UP","hall");record("moth-counter")
	check("timed popup warns before enabling its collider",game.world.mechanisms.colliders.timed_popup.disabled)
	await frames(50)
	check("timed popup is a real world obstacle during its down phase",not game.world.mechanisms.colliders.timed_popup.disabled)
	await walk_to(176);await press("interact");await press("interact")
	for i in range(600):
		if game.world.state.defeated.has("popup_moth_a"): break
		await frames(1)
	check("180-degree reflected enemy shot defeats its own moth",game.world.state.defeated.has("popup_moth_a"))
	await press("interact");await press("interact")
	await walk_to(80);await press("interact");await wait_flag("popup_fuse_a",450)
	check("fixed test emitter prevents dead-moth softlock",game.save.data.flags.get("popup_fuse_a",false))
	await press("reset_puzzle")
	check("R restores puzzle species but keeps unique progress",game.world.mechanisms.animals.any(func(a):return is_instance_valid(a) and a.animal_id=="popup_moth_a") and game.save.data.flags.get("popup_fuse_a",false))
	var flea:MechanicalAnimal
	for animal in game.world.mechanisms.animals:
		if animal.species=="flea": flea=animal
	var highest:float=flea.position.y
	for i in range(100):
		highest=minf(highest,flea.position.y);await frames(1)
	check("capacitor flea performs a telegraphed physical jump",highest<flea.origin.y-15)
	await fixture("POP-UP","loft");record("snail-spider")
	for i in range(600):
		if game.save.data.flags.get("popup_loft_supported",false): break
		await frames(1)
	check("heavy tape snail physically supports weight-two plate",game.save.data.flags.get("popup_loft_supported",false))
	for i in range(600):
		if game.save.data.flags.get("popup_wire_live",false): break
		await frames(1)
	check("spider wire enables an actual one-way bridge",game.save.data.flags.get("popup_wire_live",false) and not game.world.mechanisms.colliders.spider_bridge.disabled)
	var spider: MechanicalAnimal
	for animal in game.world.mechanisms.animals:
		if animal.species=="spider": spider=animal
	await walk_to(112);await press("move_up",60)
	for i in range(500):
		var offset:float=spider.position.x-game.world.player.position.x
		Input.action_release("move_left");Input.action_release("move_right")
		if absf(offset)<22 and spider.phase=="weave":
			await press("attack");break
		if absf(offset)>5: Input.action_press("move_right" if offset>0 else "move_left")
		await frames(1)
	Input.action_release("move_left");Input.action_release("move_right")
	check("claw cuts cable spider wire without hitting ceiling body",spider.stun>0 and spider.health==2)
	await fixture("RECYCLE","sorter");record("hamster-crusher")
	await walk_to(80)
	for i in range(1800):
		if game.world.state.defeated.has("recycle_hamster"): break
		await frames(1)
	check("crusher really defeats rolling hamster",game.world.state.defeated.has("recycle_hamster") and game.save.data.flags.get("recycle_press_used",false))
	await fixture("RECYCLE","tunnel");record("beaver-scrap")
	await frames(180)
	check("beaver gnaws only its named marked scrap",game.world.state.broken.has("scrap_tunnel"))
	await fixture("SIGNAL","relay");record("eel-insulator")
	await walk_to(112);await press("interact");await wait_flag("signal_eel_coil",240)
	check("insulated eel pulse charges remote coil",game.save.data.flags.get("signal_eel_coil",false))
	var map:=InputMap.action_get_events("jump")
	check("controller mappings include physical face button and stick movement",map.any(func(e):return e is InputEventJoypadButton) and InputMap.action_get_events("move_left").any(func(e):return e is InputEventJoypadMotion))
	var event:=InputEventJoypadButton.new();event.device=0;event.button_index=JOY_BUTTON_DPAD_RIGHT;event.pressed=true
	var x:float=game.world.player.position.x
	Input.parse_input_event(event);await frames(12)
	event=event.duplicate();event.pressed=false;Input.parse_input_event(event);await frames(4)
	check("synthetic gamepad input moves the actual crab",game.world.player.position.x>x+5)
	record_tag=""
	var file:=FileAccess.open("res://artifacts/ecology-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"clips":record_counts,"scope":"isolated enemy fixtures; controller hardware was not tested"},"\t"));file.close()
	get_tree().quit(1 if failed else 0)

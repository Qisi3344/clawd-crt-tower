extends "res://tests/chapter_qa.gd"

func check(label: String, condition: bool) -> void:
	super.check(label,condition)
	if not condition:
		print("ROUTE_DIAGNOSTIC ",game.active_id," ",game.world.player.position," area=",game.world.current_area," nearest=",game.world.nearest.get("prompt",""))
		finish()

func walk_to(x: float, grab: bool = false, limit: int = 1000) -> bool:
	return await super.walk_to(x,grab,limit)

# Inherits the original BOOT/ARCHIVE campaign. All new routes below use actions,
# without moving the player, moving a block, setting a flag, or room teleporting.
func continue_chapters() -> void:
	game.hud.set_paused(false)
	get_tree().root.size=Vector2i(1280,800)
	await walk_to(176)
	Input.action_press("move_right");await press("jump",34);Input.action_release("move_right");await frames(20)
	await walk_to(288);await press("move_up",85);await walk_to(328);await walk_to(368,true);await frames(55)
	check("live A restored through the original heavy-stone route",game.save.data.flags.get("signal_archive_gate",false))
	Input.action_press("move_right");await press("jump",36);Input.action_release("move_right");await frames(20)
	await walk_to(704);await press("interact");await wait_transition()
	check("ARCHIVE port enters continuous POP-UP",game.active_id=="POP-UP" and game.world.room_id.is_empty())
	if game.active_id!="POP-UP": finish();return
	record("popup-v2")
	await walk_to(176);await press("interact");await wait_flag("popup_fuse_a")
	await walk_to(112);await press("move_up",300);await walk_to(272);await press("interact")
	check("native ladder reaches optional loft without a room portal",game.save.data.collected.has("popup_hidden") and game.world.player.position.y<170)
	await walk_to(112);await press("move_down",300);await walk_to(928);await press("move_up",225)
	await walk_to(672);await press("interact");await wait_flag("popup_fuse_b")
	await walk_to(768);await press("move_up",135);await press("interact")
	check("two physical reflected fuses restore POP-UP power",game.save.data.flags.get("popup_power_restored",false))
	await capture("exploration-popup-upper")
	var popup_instance:int=game.world.get_instance_id()
	await press("move_down",135);await walk_to(112);await press("move_down",245)
	check("powered window shortcut closes a continuous hall loop",game.world.get_instance_id()==popup_instance and game.world.player.position.y>430 and game.world.state.visited_areas.has("loft"))
	await walk_to(928);await press("move_up",225);await walk_to(768);await press("move_up",135)
	await walk_to(800);await press("interact");await wait_transition()
	check("powered CRT port reaches RECYCLE",game.active_id=="RECYCLE")
	if game.active_id!="RECYCLE": finish();return
	record("recycle-v2")
	var recycle_instance:int=game.world.get_instance_id()
	await walk_to(80);await press("move_up",365);await walk_to(460)
	check("upper observation route shows a visibly closed future loop",game.world.player.position.y<80 and not game.world.doors.filter(func(d):return d.id=="hoist_loop_lock")[0].open)
	await walk_to(80);await press("move_down",365)
	await walk_to(112);await press("interact");await walk_to(80);await press("interact")
	check("central controls reverse the conveyor and stop the crusher",game.world.mechanisms.switches.get("safe_stop",false) and game.world.mechanisms.conveyor_velocity(Vector2(192,440))<0)
	await hop_to(448);await press("move_down",235);await walk_to(400)
	check("underground fragment and vertical camera survive former Y limit",game.save.data.flags.get("recycle_part_1",false) and game.world.player.position.y>660 and game.world.camera.position.y>500)
	await capture("exploration-recycle-lower")
	await walk_to(592);await press("move_up",90);await press("move_down",90)
	check("second fragment uses the raised magnetic-well platform",game.save.data.flags.get("recycle_part_2",false))
	await walk_to(672);await press("interact");await frames(190)
	var metal:PuzzleBlock=game.world.blocks.filter(func(b):return b.block_id=="recycle_metal")[0]
	check("magnet transports actual steel at translated world coordinates",metal.position.distance_to(Vector2(744,600))<3)
	await press("interact");await frames(45);await walk_to(736);await press("jump",6);await press("attack");await walk_to(704);await frames(60)
	check("claw breaks marked suspended scrap in the lower layer",game.world.state.broken.has("scrap_bridge"))
	await wait_flag("recycle_heavy_supported",180)
	await hop_to(976);await press("move_up",450);await walk_to(608)
	check("maintenance shaft reaches the third fragment above the hall",game.save.data.flags.get("recycle_part_3",false) and game.world.player.position.y<220)
	await walk_to(768);await press("interact")
	check("three fixed fragments restore the original packet transaction",game.save.data.flags.get("message_packet_restored",false) and not game.save.data.flags.get("message_delivered",false))
	await walk_to(656);await press("move_up",75);await walk_to(784);await press("interact")
	check("upper optional RECYCLE chest retains its ledger ID",game.save.data.collected.has("recycle_cache"))
	await capture("exploration-recycle-upper")
	await walk_to(976);await press("move_up",140);await walk_to(80);await press("move_down",365)
	check("lower-well-maintenance-upper route returns to the same hall instance",game.world.get_instance_id()==recycle_instance and game.world.current_area=="sorter" and game.world.player.position.y>430)
	var supported_position:Vector2=metal.position
	await press("reset_puzzle")
	check("local R leaves the other area's metal and supported signal intact",metal.position.distance_to(supported_position)<1 and game.save.data.flags.get("recycle_heavy_supported",false))
	await hop_to(448);await press("move_down",235);await walk_to(304)
	check("post-repair underground return door is now physically open",game.world.current_area=="tunnel" and game.save.data.flags.get("recycle_route_repaired",false))
	await hop_to(80);await press("interact");await frames(220);await hop_to(128);await press("interact")
	check("optional return tunnel yields the ninth unique chest",game.save.data.collected.has("recycle_hidden"))
	await hop_to(976);await press("move_up",450);await walk_to(800);await press("interact");await wait_transition()
	check("restored packet reaches SIGNAL through its real CRT port",game.active_id=="SIGNAL")
	if game.active_id!="SIGNAL": finish();return
	record("signal-v2")
	await walk_to(112);await press("move_up",225);await press("interact")
	check("A branch calibrates without inventing upstream support",game.save.data.flags.get("signal_local_a",false) and game.save.data.flags.get("signal_archive_gate",false))
	await press("move_down",225);await walk_to(432);await press("interact")
	await hop_to(672,1100);await press("interact")
	check("real relay bee plus repaired B saves a permanent bypass",game.save.data.flags.get("signal_bee_charged",false) and game.save.data.flags.get("signal_local_b",false) and game.save.data.flags.get("signal_shortcut",false))
	await walk_to(976);await press("move_up",225);await walk_to(848);await press("move_up",110);await press("interact")
	check("C branch calibrates restored packet in its fiber socket",game.save.data.flags.get("signal_local_c",false) and game.save.data.flags.get("signal_optics_aligned",false))
	await walk_to(944);await press("move_up",155);await press("interact")
	check("all local branches and live inputs make READY without delivery",game.save.data.flags.get("signal_core_ready",false) and not game.save.data.flags.get("message_delivered",false))
	await walk_to(992);await press("interact")
	check("SIGNAL cache stays an independent optional reward",game.save.data.collected.has("signal_cache"))
	await capture("exploration-signal-ready")
	var signal_instance:int=game.world.get_instance_id()
	await walk_to(976);await press("move_down",140);await walk_to(112);await press("move_down",225)
	check("three-branch return reconnects to the known diagnostic hub",game.world.get_instance_id()==signal_instance and game.world.current_area=="hub")
	await hop_to(976);await press("move_up",225);await walk_to(992);await press("interact");await wait_transition()
	check("READY unlocks the ERROR CRT",game.active_id=="ERROR")
	if game.active_id!="ERROR": finish();return
	record("error-v2")
	await walk_to(112);await press("move_up",55);await walk_to(144);await press("interact")
	check("ERROR cache remains outside the core objective",game.save.data.collected.has("error_cache") and not game.save.data.flags.get("error_core_disabled",false))
	await walk_to(256);await frames(45);await wait_flag("error_foyer_open",900)
	await hop_to(624);await press("interact");await walk_to(672);await walk_to(768,true);await frames(30)
	check("outer-ring steel really supports the piston gate",game.save.data.flags.get("error_piston_supported",false))
	await hop_to(976);await press("move_up",225);await walk_to(928);await press("interact")
	check("live diagnostic authorizes the continuous core entrance",game.save.data.flags.get("error_diagnostic_cleared",false))
	await walk_to(976);await press("move_down",450);await hop_to(400)
	await press("move_right",2);await walk_to(464,true);await frames(20)
	var core:Node=game.world.mechanisms.boss
	check("relocated core A requires its actual heavy block",core.stage==1 and core.status.get("node_a",false))
	await hop_to(528);await press("interact")
	for i in range(500):
		if core.stage>=2: break
		await frames(1)
	check("relocated core B requires a reflected projectile",core.stage==2 and core.status.get("node_b",false))
	await capture("exploration-error-core")
	await walk_to(640);await press("move_up",60);await press("interact")
	for i in range(240):
		if core.stage>=3: break
		await frames(1)
	check("core C still uses live SIGNAL after A then B",core.stage==3 and core.status.get("node_c",false))
	await press("move_down",60);await walk_to(560);await press("interact");await frames(10)
	check("only final core repair commits the delivered message",game.save.data.flags.get("message_delivered",false) and game.save.data.story.message_state=="delivered")
	check("six repairs and all nine chests retain a single active crab",game.save.data.screen_repaired.size()==6 and game.save.data.collected.size()==9 and get_tree().get_nodes_in_group("player").size()==1)
	record_tag=""
	if game.story.playing:
		await frames(360);await capture("exploration-ending-delivered");await frames(110);await capture("exploration-ending-reply");game.story.skip();await frames(2)
	check("ending is durable and leaves play available",game.save.data.story.outro_seen and not game.story_active)
	var disk:=SaveStore.new();disk.path="user://qa-exploration-%d.json"%OS.get_process_id();game._checkpoint();disk.data=game.save.data.duplicate(true)
	check("complete continuous campaign writes atomically",disk.write())
	var restored:=SaveStore.new();restored.path=disk.path;restored.load_progress()
	var retained:bool=restored.data.collected==disk.data.collected and restored.data.flags==disk.data.flags
	for key in disk.data.worlds:
		var expected:Dictionary=disk.data.worlds[key];var actual:Dictionary=restored.data.worlds.get(key,{})
		# JSON restores numbers as float Variants; nested dictionary equality is
		# type-sensitive even for 1 versus 1.0. Compare serialized records, and
		# independently compare live body coordinates with a subpixel tolerance.
		var serialized:Dictionary=JSON.parse_string(JSON.stringify(expected,"",true,true))
		for field in ["layout_version","visited_areas","explored_cells","discovered_connections","broken","defeated","mechanisms","boss"]:
			retained=retained and actual.get(field)==serialized.get(field)
		retained=retained and SideWorld.point(actual.get("position")).distance_to(SideWorld.point(expected.get("position")))<.01
		for block in expected.get("blocks",{}): retained=retained and SideWorld.point(actual.get("blocks",{}).get(block)).distance_to(SideWorld.point(expected.blocks[block]))<.01
	check("reload retains navigation puzzle records block positions and all chests",retained)
	DirAccess.remove_absolute(disk.path)
	finish()

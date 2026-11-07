extends "res://tests/sideview_qa.gd"

var base_finished := false
var record_tag := ""
var recorded_frames := 0
var sample_clock := 0
var record_counts: Dictionary={}
func _process(_delta: float) -> void:
	if not visual: return
	if not base_finished: record_tag="boot" if game.active_id=="BOOT" else "archive"
	if record_tag.is_empty(): return
	sample_clock+=1
	if sample_clock%6!=0: return
	var directory: String="res://artifacts/chapter-clips/"+record_tag
	DirAccess.make_dir_recursive_absolute(directory)
	if not record_counts.has(record_tag):
		for name in DirAccess.get_files_at(directory):
			if name.ends_with(".png"): DirAccess.remove_absolute(directory+"/"+name)
	RenderingServer.force_draw()
	var index:int=int(record_counts.get(record_tag,0))
	game.viewport.get_texture().get_image().save_png(directory+"/%04d.png"%index)
	record_counts[record_tag]=index+1

func record(tag: String) -> void:
	record_tag=tag;recorded_frames=0

func hop_to(x: float, limit: int=700) -> void:
	for i in range(limit):
		var difference: float=x-game.world.player.position.x
		if absf(difference)<3: break
		Input.action_release("move_left");Input.action_release("move_right")
		Input.action_press("move_right" if difference>0 else "move_left")
		if i%40==0: Input.action_press("jump")
		if i%40==2: Input.action_release("jump")
		await frames(1)
	Input.action_release("move_left");Input.action_release("move_right");Input.action_release("jump")
	await frames(60)
func finish() -> void:
	if failed or base_finished:
		var file:=FileAccess.open("res://artifacts/chapter-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
		file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures,"clips":record_counts},"\t"));file.close()
		get_tree().quit(1 if failed else 0)
	else:
		base_finished=true
		continue_chapters.call_deferred()

func wait_transition() -> void:
	for i in range(300):
		if not game.transitioning: break
		await frames(1)
	await frames(8)

func wait_flag(flag: String, limit: int=480) -> void:
	for i in range(limit):
		if game.save.data.flags.get(flag,false): break
		await frames(1)
	check("real mechanism raises "+flag,game.save.data.flags.get(flag,false))
	await frames(2)

func continue_chapters() -> void:
	game.hud.set_paused(false)
	get_tree().root.size=Vector2i(1280,800)
	# The inherited test has completed the original four chests, death, R and disk reload.
	# Re-establish ARCHIVE's supported signal through the real crate/ladder/stone route.
	check("old route still starts at ARCHIVE",game.active_id=="ARCHIVE")
	await walk_to(176)
	Input.action_press("move_right");await press("jump",34);Input.action_release("move_right");await frames(20)
	await walk_to(288);await press("move_up",85);await frames(10)
	await walk_to(328);await walk_to(368,true);await frames(55)
	check("supported A input restored by physically repushing stone",game.save.data.flags.get("signal_archive_gate",false))
	Input.action_press("move_right");await press("jump",36);Input.action_release("move_right");await frames(20)
	await walk_to(704);await press("interact");await wait_transition()
	check("normal ARCHIVE port enters POP-UP",game.active_id=="POP-UP" and game.world.room_id=="hall")
	if game.active_id!="POP-UP": finish();return
	await capture("chapter-popup-hall")
	record("popup")
	await walk_to(176);await press("interact")
	await wait_flag("popup_fuse_a")
	check("enemy projectile really opens room-one gate",game.world.doors[0].open)
	await capture("chapter-popup-reflected")
	# Optional room is reached by climbing, not by writing a collection flag.
	await walk_to(112);await press("move_up",55);await press("interact");await wait_transition()
	check("local room portal enters optional loft",game.world.room_id=="loft")
	await walk_to(112);await press("move_up",55);await walk_to(272);await press("interact")
	check("fifth chest is a real optional pickup",game.save.data.collected.has("popup_hidden"))
	await walk_to(32);await frames(20);await press("interact");await wait_transition()
	check("loft returns to the recorded upper spawn",game.world.room_id=="hall" and game.world.player.position.y<170)
	await walk_to(432);await frames(20);await press("interact");await wait_transition()
	check("local door reaches vertical shaft",game.world.room_id=="shaft")
	await walk_to(160);await press("interact");await wait_flag("popup_fuse_b")
	await walk_to(256);await press("move_up",135);await press("interact")
	check("repair needs two actual reflected fuses",game.save.data.flags.get("popup_noise_clean",false) and game.save.data.flags.get("popup_power_restored",false))
	check("POP-UP repair does not deliver the message",not game.save.data.flags.get("message_delivered",false))
	await capture("chapter-popup-repaired")
	game._checkpoint()
	var saved: Dictionary=game.save.data.worlds.popup_01.duplicate(true)
	check("per-room persistence records both active and inactive rooms",saved.room_id=="shaft" and saved.rooms.has("hall") and saved.rooms.has("loft"))
	await press("reset_puzzle")
	check("local reset preserves other rooms and permanent repair",game.save.data.collected.has("popup_hidden") and game.save.data.flags.get("popup_power_restored",false))
	check("one crab and one active gameplay viewport",get_tree().get_nodes_in_group("player").size()==1 and game.viewport.get_child_count()==1)
	record_tag=""
	# RECYCLE is reached through the actual newly powered CRT port.
	await walk_to(256);await press("move_up",135);await walk_to(288);await press("interact");await wait_transition()
	check("powered POP-UP port reaches RECYCLE",game.active_id=="RECYCLE" and game.world.room_id=="sorter")
	if game.active_id!="RECYCLE": finish();return
	record("recycle")
	await walk_to(80);await press("interact")
	check("REVERSE changes the real conveyor",game.world.mechanisms.conveyor_velocity(Vector2(192,200))<0)
	await walk_to(112);await press("interact")
	check("safe stop disables the real crusher",game.world.mechanisms.switches.get("safe_stop",false))
	await hop_to(376)
	check("first communication fragment is fixed pickup",game.save.data.flags.get("recycle_part_1",false))
	await walk_to(432);await press("interact");await wait_transition()
	check("room portal enters magnetic well",game.world.room_id=="well")
	await walk_to(80);await press("move_up",90);await frames(6)
	check("vertical ladder reaches second fixed fragment",game.save.data.flags.get("recycle_part_2",false))
	await press("move_down",90)
	await walk_to(160);await frames(50);await press("interact")
	await frames(180)
	check("magnet physically transports metal to target",game.world.blocks[0].position.distance_to(Vector2(232,120))<3)
	await press("interact");await frames(40)
	await walk_to(224);await press("jump",6)
	await press("attack")
	await walk_to(192);await frames(60)
	check("claw breaks only marked scrap bridge",game.world.state.broken.has("scrap_bridge"))
	await wait_flag("recycle_heavy_supported",150)
	await hop_to(304);await press("interact");await wait_transition()
	check("real dropped metal opens cache room",game.world.room_id=="cache")
	await walk_to(96)
	await walk_to(256);await press("interact")
	check("three physical fragments reconstruct communication packet",game.save.data.flags.get("message_packet_restored",false) and game.save.data.flags.get("recycle_route_repaired",false))
	await capture("chapter-recycle-repaired")
	await walk_to(144);await press("move_up",75);await walk_to(272);await press("interact")
	check("RECYCLE cache chest uses existing unique ledger",game.save.data.collected.has("recycle_cache"))
	game._checkpoint()
	check("repair is persistent without delivering early",game.save.data.screen_repaired.get("RECYCLE",false) and not game.save.data.flags.get("message_delivered",false))
	record_tag=""
	await walk_to(144);await press("move_down",80);await walk_to(288);await press("interact");await wait_transition()
	check("restored packet powers the real SIGNAL CRT",game.active_id=="SIGNAL" and game.world.room_id=="diagnostic")
	if game.active_id!="SIGNAL": finish();return
	record("signal")
	check("diagnostic panel reads three true upstream inputs",WorldProgress.missing_inputs(game.save.data.flags).is_empty())
	await capture("chapter-signal-diagnostic")
	await walk_to(288);await press("interact");await wait_transition()
	await walk_to(112);await press("interact")
	check("insulator controls the water hazard",game.save.data.flags.get("signal_water_safe",false))
	await hop_to(352,1000);await press("interact")
	check("bee actually conducts and player saves the bypass",game.save.data.flags.get("signal_bee_charged",false) and game.save.data.flags.get("signal_shortcut",false))
	await capture("chapter-signal-bee")
	await walk_to(432);await press("interact");await wait_transition()
	check("local room system enters the three-storey fiber well",game.world.room_id=="shaft")
	await walk_to(144);await press("move_up",110);await press("interact")
	check("middle fiber socket is connected by interaction",game.save.data.flags.get("signal_optics_aligned",false))
	await walk_to(240);await frames(35);await press("move_up",155);await press("interact")
	check("live A plus repaired B C unlock sending channel",game.save.data.flags.get("signal_core_ready",false))
	check("SIGNAL READY never means message delivered",game.save.data.story.message_state=="ready" and not game.save.data.flags.get("message_delivered",false))
	await walk_to(288);await press("interact")
	check("SIGNAL optional cache recorded",game.save.data.collected.has("signal_cache"))
	await capture("chapter-signal-ready")
	record_tag=""
	await walk_to(240);await press("move_down",165);await walk_to(288);await press("interact");await wait_transition()
	check("SIGNAL unlocks the real ERROR CRT",game.active_id=="ERROR" and game.world.room_id=="foyer")
	if game.active_id!="ERROR": finish();return
	record("error")
	await walk_to(112);await press("move_up",55);await walk_to(144);await press("interact")
	check("ERROR optional chest is independent of the boss",game.save.data.collected.has("error_cache") and not game.save.data.flags.get("error_core_disabled",false))
	await walk_to(256);await frames(45)
	await wait_flag("error_foyer_open",900)
	check("owl's actual dive clears marked panel",game.save.data.flags.get("error_foyer_open",false))
	await hop_to(432);await press("interact");await wait_transition()
	check("owl room connects to piston room",game.world.room_id=="piston")
	await walk_to(112);await press("interact")
	await walk_to(160);await walk_to(256,true);await frames(30)
	check("real steel holds piston pressure plate",game.save.data.flags.get("error_piston_supported",false))
	await hop_to(432);await press("interact");await wait_transition()
	await walk_to(224);await press("interact");await walk_to(288);await press("interact");await wait_transition()
	check("live diagnostic authorizes boss room",game.world.room_id=="boss")
	if game.world.room_id!="boss": finish();return
	var core: Node=game.world.mechanisms.boss
	await walk_to(48);await walk_to(112,true);await frames(15)
	check("boss node A requires an actual heavy block",core.stage==1 and core.status.get("node_a",false))
	await hop_to(176);await press("interact")
	for i in range(500):
		if core.stage>=2: break
		await frames(1)
	check("boss node B requires reflected core projectile",core.stage==2 and core.status.get("node_b",false))
	await capture("chapter-error-core-reflect")
	await walk_to(288);await press("move_up",60);await press("interact")
	for i in range(240):
		if core.stage>=3: break
		await frames(1)
	check("boss node C uses live SIGNAL and reversed pulse",core.stage==3 and core.status.get("node_c",false))
	await press("move_down",60);await walk_to(208);await press("interact");await frames(8)
	check("only final core repair commits delivery",game.save.data.flags.get("error_core_disabled",false) and game.save.data.flags.get("message_delivered",false) and game.save.data.story.message_state=="delivered")
	check("six repaired screens with one single player",game.save.data.screen_repaired.size()==6 and get_tree().get_nodes_in_group("player").size()==1)
	record_tag=""
	if game.story.playing:
		await frames(360)
		await capture("chapter-ending-delivered")
		await frames(110)
		await capture("chapter-ending-reply")
		game.story.skip();await frames(2)
	check("ending viewed state is durable",game.save.data.story.outro_seen and not game.story_active)
	for child in game.get_children():
		if child is ConfirmationDialog and child.title=="CRT CRAB / CONNECTION RESTORED": child.confirmed.emit()
	await frames(2)
	# Persist and reopen the real completed campaign through a process-local save.
	var disk:=SaveStore.new();disk.path="user://qa-campaign-%d.json"%OS.get_process_id();disk.data=game.save.data.duplicate(true)
	check("completed six-room campaign writes atomically",disk.write())
	var restored:=SaveStore.new();restored.path=disk.path;restored.load_progress()
	if not is_instance_valid(game.front_end):
		game.front_end=FrontEnd.new();game.front_end.game=game;game.add_child(game.front_end);game.front_end.hide()
	game.save=restored;game.return_to_title();game.begin_adventure(false);await frames(5)
	check("restart resumes repaired boss room without replaying ending",game.active_id=="ERROR" and game.world.room_id=="boss" and not game.story_active and game.world.mechanisms.boss.stage==4)
	await press("reset_puzzle")
	check("R never resurrects a repaired boss or repeats delivery",game.world.mechanisms.boss.stage==4 and game.save.data.story.outro_seen and game.save.data.flags.message_delivered)
	await hop_to(16);await press("interact");await wait_transition()
	await walk_to(64);await press("interact");await wait_transition()
	check("safe return route from ERROR reaches ARCHIVE",game.active_id=="ARCHIVE")
	await press("reset_puzzle")
	check("live A can turn off without revoking ERROR access",not game.save.data.flags.signal_archive_gate and game.save.data.screen_unlocked.ERROR)
	await walk_to(176);Input.action_press("move_right");await press("jump",34);Input.action_release("move_right");await frames(20)
	await walk_to(288);await press("move_up",85);await frames(10);await walk_to(328);await walk_to(368,true);await frames(55)
	check("A is physically repairable after completion",game.save.data.flags.signal_archive_gate)
	Input.action_press("move_right");await press("jump",36);Input.action_release("move_right");await frames(20)
	await walk_to(704);await press("interact");await wait_transition()
	await walk_to(432);await press("interact");await wait_transition()
	await walk_to(256);await press("move_up",135);await walk_to(288);await press("interact");await wait_transition()
	await hop_to(432);await press("interact");await wait_transition()
	check("revisit reaches repaired RECYCLE well",game.active_id=="RECYCLE" and game.world.room_id=="well")
	await walk_to(80);await press("move_up",90);await press("interact");await wait_transition()
	check("post-repair side route opens hidden magnetic tunnel",game.world.room_id=="tunnel")
	await walk_to(80);await press("interact");await frames(200);await hop_to(272);await press("interact")
	check("ninth unique chest is obtainable on revisit",game.save.data.collected.has("recycle_hidden") and game.save.data.collected.size()==9)
	await capture("chapter-postgame-nine-chests")
	check("exploration never repeats the completed ending",game.save.data.story.outro_seen and not game.story_active)
	DirAccess.remove_absolute(disk.path)
	finish()

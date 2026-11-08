extends "res://tests/exploration_qa.gd"
var area_captures:Dictionary={}
var finalizing:=false
var water_detour_done:=false

func _process(delta:float) -> void:
	if not visual or game==null or game.active_id not in ["RECYCLE","SIGNAL"] or finalizing: return
	record_tag=game.active_id.to_lower()+"-art"
	super._process(delta)

func capture(label:String) -> void:
	if game.active_id in ["RECYCLE","SIGNAL"]: await super.capture(label)
	if label=="exploration-signal-ready" and not water_detour_done:
		water_detour_done=true
		await walk_to(976);await press("move_down",650);await walk_to(600)
		check("SIGNAL lower water bypass reached by actual ladder input",game.world.player.position.y>680)
		await super.capture("signal-art-water-walk")
		await walk_to(976);await press("move_up",650)
		check("SIGNAL lower bypass returns to the original upper route",game.world.player.position.y<70)

func frames(n:int) -> void:
	await super.frames(n)
	if not visual or finalizing or game.transitioning or game.active_id not in ["RECYCLE","SIGNAL"]: return
	if not is_instance_valid(game.world) or not game.world.enabled or not game.world.player.is_on_floor(): return
	var label:String=game.active_id.to_lower()+"-art-action-"+game.world.current_area
	if area_captures.has(label): return
	area_captures[label]=true
	# Snapshot only: no input changes, teleports, flags, or extra physics frames.
	RenderingServer.force_draw()
	game.viewport.get_texture().get_image().save_png("res://artifacts/"+label+"-screen.png")
	get_viewport().get_texture().get_image().save_png("res://artifacts/"+label+".png")

func finish() -> void:
	if not base_finished or failed:
		super.finish();return
	if finalizing: return
	finalizing=true;record_tag=""
	# Campaign inputs above are complete. These are isolated art/camera fixtures.
	if visual:
		# The real ending opens a pause/dialog; close it before independent art fixtures.
		for child in game.get_children():
			if child is ConfirmationDialog: child.hide();child.queue_free()
		game.hud.set_paused(false)
		for key in ["RECYCLE","SIGNAL"]:
			game.viewport.remove_child(game.world);game.world.free()
			check(key+" independent art fixture loads",game._load_world(key,"entrance"))
			game.director.focus(game._device(key),true);game._control_state();game.world.enabled=false
			var art:Node=game.world.get_node("RecycleArt" if key=="RECYCLE" else "SignalArt")
			check(key+" decorations add no collision bodies",art.find_children("*","CollisionObject2D",true,false).is_empty())
			check(key+" retains one native viewport",game.viewport.size==Vector2i(320,240) and get_tree().get_nodes_in_group("player").size()==1)
			var samples:Array=[{"name":"upper-left","p":Vector2(240,120)},{"name":"upper-right","p":Vector2(800,120)},{"name":"hall","p":Vector2(240,408)},{"name":"relay-well","p":Vector2(656,408)},{"name":"lower-left","p":Vector2(240,648)},{"name":"lower-right","p":Vector2(720,648)},{"name":"maintenance","p":Vector2(864,408)}]
			for entry in samples:
				game.world.camera.position=entry.p;await frames(3);await super.capture(key.to_lower()+"-art-fixture-"+entry.name)
			for pos in [Vector2(160,120),Vector2(864,120),Vector2(160,648),Vector2(864,648)]:
				game.world.camera.position=pos;await frames(3);RenderingServer.force_draw()
				game.viewport.get_texture().get_image().save_png("res://artifacts/%s-art-edge-%d-%d.png"%[key.to_lower(),pos.x,pos.y])
	var file:=FileAccess.open("res://artifacts/industrial-art-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures,"action_area_captures":area_captures.keys(),"clips":record_counts,"scope":"Original complete campaign uses actual inputs; final labeled fixtures isolate art at additional camera positions"},"\t"));file.close()
	super.finish()

extends "res://tests/chapter_qa.gd"

func pair(label: String) -> void:
	if not visual: return
	var tag:String=record_tag;record_tag=""
	game.world.enabled=false
	await frames(3);await capture("archive-v2-"+label)
	game.world.enabled=true;record_tag=tag

func _run() -> void:
	base_finished=true
	await frames(15)
	game.viewport.remove_child(game.world);game.world.free()
	check("ARCHIVE loads its dedicated art layer",game._load_world("ARCHIVE","entrance") and game.world.has_node("ArchiveArt"))
	game.director.focus(game._device("ARCHIVE"),true);game._control_state();await frames(10)
	var art:Node=game.world.get_node("ArchiveArt")
	check("all 15 curated props have no decoration collision bodies",art.get_children().filter(func(n):return n is Sprite2D).size()==15 and art.find_children("*","CollisionObject2D",true,false).is_empty())
	var surface:ArchiveTerrain=game.world.get_node("ArchiveTerrain")
	check("terrain material joins adjacent collider segments into seven visible surfaces",surface.surfaces.size()==7 and surface.find_children("*","CollisionObject2D",true,false).is_empty())
	check("pixel output stays one 320x240 gameplay viewport",game.viewport.size==Vector2i(320,240) and get_tree().get_nodes_in_group("player").size()==1)
	await pair("main-entry")
	record("archive-v2")
	await walk_to(88)
	for i in range(18):
		if game.world.enemies.is_empty(): break
		await press("attack");await frames(24)
	await walk_to(176);Input.action_press("move_right");await press("jump",34);Input.action_release("move_right");await frames(20)
	await walk_to(288);await press("move_up",85);await walk_to(306);await press("attack");await walk_to(328);await walk_to(368,true);await frames(55)
	check("actual stone still supports the live A signal through the new art",game.save.data.flags.get("signal_archive_gate",false))
	await pair("main-puzzle")
	await walk_to(80);await press("move_up",145);await walk_to(420)
	check("upper retrieval bridge is reached by normal ladder input",game.world.player.position.y<70)
	await pair("upper")
	await walk_to(736);await press("move_down",145);await walk_to(640);await press("attack");await walk_to(608);await press("move_down",235);await walk_to(304)
	check("lower broken records area is reached continuously",game.world.player.position.y>440 and game.world.current_area=="lower")
	await walk_to(360);await pair("lower")
	# Full camera sweep is a rendering fixture, separate from the action-only clip.
	record_tag=""
	var bg:Node=game.world.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path=="res://scripts/world_backdrop.gd")[0]
	var far:Texture2D=bg.archive_far
	check("midground is a single world-sized canvas",bg.archive_mid.get_size()==Vector2(1024,640))
	var covered:=true
	for x in [0,176,352,528,704]:
		for y in [0,100,200,300,400]:
			var source:=Rect2(Vector2(x,y)*.15,Vector2(320,240))
			covered=covered and Rect2(Vector2.ZERO,far.get_size()).encloses(source)
	check("far image covers every camera bound without repeating",covered)
	var perf:Array=[]
	if visual:
		var saved:Vector2=game.world.camera.position
		for pos in [Vector2(160,120),Vector2(864,120),Vector2(160,520),Vector2(864,520)]:
			game.world.enabled=false;game.world.camera.position=pos;await frames(2);await get_tree().process_frame;RenderingServer.force_draw()
			game.viewport.get_texture().get_image().save_png("res://artifacts/archive-v2-edge-%d-%d.png"%[pos.x,pos.y])
		game.world.camera.position=saved;game.world.enabled=true
		# Full-width panoramas assembled only from native 320x240 GPU readbacks.
		game.world.enabled=false
		for layer in [{"name":"upper","y":120},{"name":"main","y":160},{"name":"lower","y":384}]:
			var panorama:=Image.create(1024,240,false,Image.FORMAT_RGBA8)
			for x in [0,320,640,704]:
				game.world.camera.position=Vector2(x+160,layer.y);await frames(3);await get_tree().process_frame;RenderingServer.force_draw()
				var shot:Image=game.viewport.get_texture().get_image()
				shot.save_png("res://artifacts/archive-v2-%s-x%d.png"%[layer.name,x])
				if x<704: panorama.blit_rect(shot,Rect2i(0,0,320,240),Vector2i(x,0))
				else: panorama.blit_rect(shot,Rect2i(256,0,64,240),Vector2i(960,0))
			panorama.save_png("res://artifacts/archive-v2-%s-full.png"%layer.name)
		game.world.camera.position=saved;game.world.enabled=true
		for i in range(20):
			var start:=Time.get_ticks_usec();RenderingServer.force_draw();game.viewport.get_texture().get_image();perf.append((Time.get_ticks_usec()-start)/1000.0);await get_tree().process_frame
	var file:=FileAccess.open("res://artifacts/archive-art-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures,"clips":record_counts,"render_readback_ms":perf,"scope":"Native art and traversal check; camera edge samples are fixtures, not campaign progression"},"\t"));file.close();get_tree().quit(1 if failed else 0)

extends "res://tests/chapter_qa.gd"

func shot(label:String) -> void:
	var tag:=record_tag;record_tag="";game.world.enabled=false
	await capture("popup-art-"+label)
	game.world.enabled=true;record_tag=tag

func _run() -> void:
	base_finished=true;await frames(25)
	game.viewport.remove_child(game.world);game.world.free()
	check("POP-UP loads its own continuous art",game._load_world("POP-UP","entrance") and game.world.has_node("PopupArt"))
	game.director.focus(game._device("POP-UP"),true);game._control_state();await frames(10)
	check("twelve curated props add no physics bodies",game.world.get_node("PopupArt").find_children("*","Sprite2D",true,false).size()==12 and game.world.get_node("PopupArt").find_children("*","CollisionObject2D",true,false).is_empty())
	check("single native pixel viewport",game.viewport.size==Vector2i(320,240))
	await shot("hall-entry");record("popup-art")
	await walk_to(176);await press("interact");await wait_flag("popup_fuse_a")
	await shot("hall-reflected")
	await walk_to(112);await press("move_up",100);await shot("cross-layer");await press("move_up",200);await walk_to(272);await press("interact")
	check("original loft ladder and treasure work",game.save.data.collected.has("popup_hidden") and game.world.player.position.y<170)
	await shot("loft")
	await walk_to(112);await press("move_down",300);await walk_to(840)
	check("east machinery reached through the real fuse door",game.world.player.position.x>800 and game.world.player.position.y>430)
	await shot("east")
	await walk_to(928);await press("move_up",225);await walk_to(672);await press("interact");await wait_flag("popup_fuse_b")
	await walk_to(768);await press("move_up",135);await press("interact")
	check("both reflected fuses restore original power",game.save.data.flags.get("popup_power_restored",false))
	await shot("shaft")
	await press("move_down",135);await walk_to(928);await press("move_down",500);await walk_to(720)
	check("drain is reached with real ladder input",game.world.player.position.y>680)
	await shot("drain")
	record_tag=""
	if visual:
		game.world.enabled=false
		for layer in [{"name":"upper","y":120},{"name":"main","y":408},{"name":"lower","y":648}]:
			var panorama:=Image.create(1024,240,false,Image.FORMAT_RGBA8)
			for x in [0,320,640,704]:
				game.world.camera.position=Vector2(x+160,layer.y);await frames(3);await get_tree().process_frame;RenderingServer.force_draw()
				var frame:Image=game.viewport.get_texture().get_image();frame.save_png("res://artifacts/popup-art-%s-x%d.png"%[layer.name,x])
				panorama.blit_rect(frame,Rect2i(0 if x<704 else 256,0,320 if x<704 else 64,240),Vector2i(x if x<704 else 960,0))
			panorama.save_png("res://artifacts/popup-art-%s-full.png"%layer.name)
		for landmark in [{"name":"skyline","position":Vector2(512,120)},{"name":"capsule","position":Vector2(864,120)},{"name":"cache-water","position":Vector2(560,648)}]:
			game.world.camera.position=landmark.position;await frames(3);await get_tree().process_frame;RenderingServer.force_draw()
			game.viewport.get_texture().get_image().save_png("res://artifacts/popup-art-landmark-%s.png"%landmark.name)
	var file:=FileAccess.open("res://artifacts/popup-art-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures,"clips":record_counts,"scope":"Fixture load at POP-UP entrance, then actual input through all five areas; panoramas are separate camera fixtures"},"\t"));file.close();get_tree().quit(1 if failed else 0)

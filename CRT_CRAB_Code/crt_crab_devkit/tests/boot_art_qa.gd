extends "res://tests/chapter_qa.gd"

func shot(label:String) -> void:
	var tag:=record_tag;record_tag="";game.world.enabled=false
	await capture("boot-art-"+label)
	game.world.enabled=true;record_tag=tag

func _run() -> void:
	base_finished=true;await frames(25)
	check("BOOT has twelve fixed decorations and no added decoration colliders",game.world.has_node("BootArt") and game.world.get_node("BootArt").find_children("*","Sprite2D",true,false).size()==12 and game.world.get_node("BootArt").find_children("*","CollisionObject2D",true,false).is_empty())
	check("one native 320x240 screen",game.viewport.size==Vector2i(320,240))
	await shot("entrance");record("boot-art")
	await walk_to(80);await press("move_up",145);await walk_to(360)
	check("upper maintenance deck reached with real ladder input",game.world.player.position.y<70)
	await shot("upper")
	await walk_to(80);await press("move_down",145);await walk_to(112)
	Input.action_press("move_right");await press("jump",25);Input.action_release("move_right");await frames(30)
	await walk_to(224);await walk_to(256,true);await walk_to(224,true);await walk_to(304,true);await frames(25)
	check("original crate still activates original gate",game.save.data.flags.get("boot_gate_open",false))
	await shot("power-hall")
	Input.action_press("move_right");await press("jump",33);Input.action_release("move_right");await frames(20)
	await walk_to(480);await press("move_up",85);await walk_to(512);await press("interact")
	check("real tutorial treasure remains collectible",game.save.data.collected.has("boot_access"))
	await hop_to(112);await press("move_down",235);await walk_to(336)
	check("lower cable well reached with real input",game.world.player.position.y>440)
	await shot("lower")
	record_tag=""
	if visual:
		game.world.enabled=false
		for layer in [{"name":"upper","y":120},{"name":"main","y":160},{"name":"lower","y":384}]:
			var panorama:=Image.create(1024,240,false,Image.FORMAT_RGBA8)
			for x in [0,320,640,704]:
				game.world.camera.position=Vector2(x+160,layer.y);await frames(3);await get_tree().process_frame;RenderingServer.force_draw()
				var frame:Image=game.viewport.get_texture().get_image();frame.save_png("res://artifacts/boot-art-%s-x%d.png"%[layer.name,x])
				panorama.blit_rect(frame,Rect2i(0 if x<704 else 256,0,320 if x<704 else 64,240),Vector2i(x if x<704 else 960,0))
			panorama.save_png("res://artifacts/boot-art-%s-full.png"%layer.name)
		for pos in [Vector2(160,520),Vector2(864,520)]:
			game.world.camera.position=pos;await frames(3);RenderingServer.force_draw();game.viewport.get_texture().get_image().save_png("res://artifacts/boot-art-edge-%d-%d.png"%[pos.x,pos.y])
	var file:=FileAccess.open("res://artifacts/boot-art-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures,"clips":record_counts,"scope":"Action traversal from BOOT entrance; full-width camera fixtures are separate"},"\t"));file.close();get_tree().quit(1 if failed else 0)

extends "res://tests/stage2_qa.gd"
var studio:SkinStudio

func snap(label:String,settle:int=4) -> void:
	if not visual:return
	await frames(settle)
	await get_tree().process_frame;RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://artifacts/skin-drafts-"+label+".png")
	if is_instance_valid(studio.viewport):studio.viewport.get_texture().get_image().save_png("res://artifacts/skin-drafts-"+label+"-screen.png")

func fire() -> void:
	studio.router.set_source(700,{"attack":1.0});await frames(2);studio.router.set_source(700,{})

func escape() -> void:
	for value in [true,false]:
		var event:=InputEventKey.new();event.keycode=KEY_ESCAPE;event.physical_keycode=KEY_ESCAPE;event.pressed=value;get_viewport().push_input(event,true);await frames(2)

func key(code:Key,down:bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down;Input.parse_input_event(event);Input.flush_buffered_events()

func mouse_button(control:Button,down:bool) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=control.get_global_rect().get_center();event.global_position=event.position;event.pressed=down;get_viewport().push_input(event,true)

func _run() -> void:
	await frames(20)
	var before:String=JSON.stringify(game.save.data)
	var pets:String=JSON.stringify(game.pet_gacha.data)
	check("four old wardrobe records remain unchanged",Cosmetics.catalog().map(func(e):return e.id)==["classic_orange","silver_shell","cyber_crab","glitch_crab"])
	check("sandbox begins with formal saves disabled in QA",not game.save.enabled and game.world==null)
	game.front_end.show_page("wardrobe")
	await activate(button("第一弹试衣间 · 八款示范"));await frames(3)
	studio=game.front_end.skin_studio
	check("wardrobe opens five-way original-plus-four comparison",is_instance_valid(studio) and studio.portraits.size()==5)
	await activate(studio.selection_buttons.chef_crab)
	check("keyboard Enter selects chef without changing equipment",studio.selected=="chef_crab" and game.save.data.wardrobe.equipped=="classic_orange")
	await snap("compare-idle")
	await activate(studio.content.get_child(2).get_child(3));await snap("compare-attack")
	await activate(studio.content.get_child(2).get_child(4));await snap("body-only")
	await activate(studio.content.get_child(2).get_child(4))
	await activate(studio.content.get_child(2).get_child(0))
	await activate(studio.content.get_child(0).get_child(1));await frames(6)
	check("second group includes original and all four new outfits",studio.portraits.map(func(p):return p.skin_id)==["classic_orange","pirate_crab","music_crab","player_one_crab","heavenly_crab"])
	await snap("new-four-idle")
	await activate(studio.content.get_child(2).get_child(3));check("attack pose button updates every portrait",studio.pose==3 and studio.portraits.all(func(p):return p.row==3));await snap("new-four-attack")
	var original:Image=load("res://assets/pixel/skins/classic_orange.png").get_image();original.convert(Image.FORMAT_RGBA8)
	var body:Image=SkinDrafts.body(0).atlas.get_image();body.convert(Image.FORMAT_RGBA8)
	var unchanged:=true;var only_fx:=true
	for y in range(192):
		for x in range(256):
			var a:=original.get_pixel(x,y);var b:=body.get_pixel(x,y)
			if y>=96 and y<128 and a==Color("f7e6aa"):only_fx=only_fx and b.a==0
			else:unchanged=unchanged and a==b
	check("all original body eye claw and leg pixels are preserved in all48frames",unchanged and only_fx)
	studio.body_only=false;studio.show_mode("arena");await frames(12)
	studio.picker.item_selected.emit(SkinDrafts.IDS.find("music_crab"));await frames(4)
	check("outfit dropdown changes the real trial rig",studio.selected=="music_crab" and studio.rig.skin_id=="music_crab")
	for id in SkinDrafts.IDS:
		studio.selected=id;studio.wall_enabled=false;studio.reset_arena();await frames(5)
		var player:SideCrab=studio.arena.player
		check(id+" keeps original collision and orange body catalog",player.get_child(0).shape.size==Vector2(12,18) and studio.arena.session.wardrobe.equipped=="classic_orange")
		studio.arena.enemies[0].position=player.position+Vector2(24,0);studio.arena.enemies[1].position=player.position+Vector2(28,0)
		await frames(1);await fire();await snap(id+"-attack");await frames(10)
		check(id+" single attack deals exactly1damage to one closest enemy",studio.arena.enemies[0].health==1 and studio.arena.enemies[1].health==2)
		check(id+" trial parameters stay within agreed range and damage",int(SkinDrafts.entry(id).combat.enemy_damage)==1 and SkinDrafts.entry(id).combat.cooldown_s>=.32 and SkinDrafts.entry(id).combat.cooldown_s<=.42)
		studio.reset_arena();await frames(4);player=studio.arena.player;player.facing=-1
		studio.arena.enemies[0].position=player.position-Vector2(24,0);studio.arena.enemies[1].position=player.position+Vector2(20,0)
		await frames(1);await fire();await frames(10)
		check(id+" left facing targets only the front enemy",studio.arena.enemies[0].health==1 and studio.arena.enemies[1].health==2)
	for melee in ["pirate_crab","heavenly_crab"]:
		studio.selected=melee;studio.wall_enabled=true;studio.reset_arena();await frames(5)
		await fire();await frames(12)
		check(melee+" cannot strike through a real wall",studio.arena.enemies.all(func(e):return e.health==2))
	for ranged in ["music_crab","player_one_crab"]:
		studio.selected=ranged;studio.wall_enabled=true;studio.reset_arena();await frames(5)
		await fire();await frames(12)
		check(ranged+" stops at a real wall",studio.arena.enemies.all(func(e):return e.health==2))
		studio.wall_enabled=false;studio.reset_arena();await frames(5)
		studio.arena.enemies[0].position.x=206;studio.arena.enemies[1].position.x=236
		await fire();await snap(ranged+"-flight",0);await frames(18)
		check(ranged+" expires without reaching distant targets",studio.arena.enemies.all(func(e):return e.health==2) and studio.arena.find_children("*","SkinLabShot",true,false).is_empty())
	studio.selected="academy_crab";studio.wall_enabled=true;studio.reset_arena();await frames(5)
	await fire();await frames(12)
	check("wand bolt is stopped by real world collision",studio.arena.enemies.all(func(e):return e.health==2))
	await snap("wand-blocked")
	studio.wall_enabled=false;studio.reset_arena();await frames(5)
	studio.arena.enemies[0].position=studio.arena.player.position+Vector2(62,0);studio.arena.enemies[1].position=studio.arena.player.position+Vector2(92,0)
	await fire();await frames(18)
	check("wand bolt expires at bounded42px range",studio.arena.enemies.all(func(e):return e.health==2) and studio.arena.find_children("*","SkinLabShot",true,false).is_empty())
	studio.reset_arena();await frames(5)
	studio.arena.enemies[0].position.x=206;studio.arena.enemies[1].position.x=236
	await fire();await snap("wand-flight",0);await frames(12)
	var start:Vector2=studio.arena.player.position
	studio.router.set_source(701,{"move_left":1.0});await frames(12);studio.router.set_source(701,{})
	check("trial uses real player movement",studio.arena.player.position.x<start.x-8)
	studio.router.set_source(702,{"jump":1.0});await frames(5);studio.router.set_source(702,{})
	check("trial uses real jump without extra mobility",studio.arena.player.position.y<198 and studio.arena.player.velocity.y<0)
	await snap("wand-jump")
	studio.reset_arena();await frames(5)
	var same_arena:=studio.arena
	studio.root_box.get_child(1).get_child(1).grab_focus()
	key(KEY_SPACE,true);await frames(5);key(KEY_SPACE,false);await frames(2)
	check("physical Space jumps without activating a focused navigation button",studio.arena==same_arena and studio.arena.player.position.y<198)
	studio.reset_arena();await frames(5)
	key(KEY_J,true);await frames(2);key(KEY_J,false);await frames(12)
	check("physical J fires the trial weapon",studio.arena.enemies[0].health==1 and studio.arena.enemies[1].health==2)
	studio.reset_arena();await frames(5)
	var attack_button:Button=studio.content.find_child("Lab_attack",true,false)
	mouse_button(attack_button,true);await frames(3);mouse_button(attack_button,false);await frames(12)
	check("clicking the attack button fires and releases its held input",studio.arena.enemies[0].health==1 and studio.arena.enemies[1].health==2 and studio.router.sources.is_empty())
	get_tree().root.size=Vector2i(844,480);await frames(6);check("attack control stays inside the small landscape viewport",Rect2(Vector2.ZERO,studio.size).encloses(attack_button.get_global_rect()));await snap("landscape-small")
	get_tree().root.size=Vector2i(1280,800)
	await escape();await frames(4)
	check("Escape returns to comparison and releases trial inputs",studio.mode=="compare" and get_tree().get_nodes_in_group("player").is_empty())
	await escape();await frames(4)
	check("Escape returns to original wardrobe",game.front_end.page=="wardrobe" and not is_instance_valid(game.front_end.skin_studio))
	check("trial changes neither progress equipment nor pet-gacha collection",JSON.stringify(game.save.data)==before and JSON.stringify(game.pet_gacha.data)==pets)
	var file:=FileAccess.open("res://artifacts/skin-drafts-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"scope":"Eight prototype outfits in an isolated trial; formal game skins, attacks, unlocks and gacha store remain original"},"\t"));file.close();get_tree().quit(1 if failed else 0)

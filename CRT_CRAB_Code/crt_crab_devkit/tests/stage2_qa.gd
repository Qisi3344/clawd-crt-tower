extends "res://tests/sideview_qa.gd"

var prefix := "user://qa-stage2-"+str(OS.get_process_id())

func button(text: String) -> Button:
	for control in game.front_end.column.get_children():
		if control is Button and control.text==text: return control
	return null

func activate(control: Button) -> void:
	control.grab_focus()
	for value in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ENTER
		event.physical_keycode = KEY_ENTER
		event.pressed = value
		get_viewport().push_input(event)
		await frames(2)

func _run() -> void:
	await frames(15)
	check("fresh boot stops at title with no playable world",game.in_menu and game.world==null and not game.hud.visible and game.devices.size()==12)
	check("bootstrap does not create an adventure",not game.save.data.started and not game.save.enabled)
	await press("attack");await press("reset_puzzle");await press("overview")
	check("title ignores combat reset and overview input",game.in_menu and game.world==null and game.director.overview)
	game.audio.reduced_motion = true
	game.apply_settings()
	var menu_camera: Vector3 = game.director.camera.position
	await frames(12)
	check("reduced motion holds the title camera still",game.director.camera.position.distance_to(menu_camera)<0.001)
	game.audio.reduced_motion = false
	game.apply_settings()
	await capture("stage2-title")
	await capture("stage2-title-portrait")
	get_tree().root.size = Vector2i(1280,800)
	for balance in [0,5,6,8,14,17]:
		var store := SaveStore.new()
		store.path = prefix+".json"
		store.data.crystals = balance
		var id := "cyber_crab" if balance==8 else "silver_shell"
		store.purchase(id)
		var price := 8 if id=="cyber_crab" else 6
		check("purchase boundary %d"%balance,store.data.crystals==(balance-price if balance>=price else balance) and store.data.wardrobe.owned.has(id)==(balance>=price))
		var after: int = store.data.crystals
		store.purchase(id)
		check("duplicate purchase cannot charge at %d"%balance,store.data.crystals==after)
		if balance>=14:
			store.purchase("cyber_crab")
			check("both outfits affordable at %d"%balance,store.data.crystals==balance-14 and store.data.wardrobe.owned.size()==3)
	var failed_store := SaveStore.new()
	failed_store.path = prefix+"-missing/fail.json"
	failed_store.data.crystals = 17
	var previous := failed_store.data.duplicate(true)
	failed_store.purchase("silver_shell")
	check("disk failure leaves balance and ownership unchanged",failed_store.data==previous)
	for payload in ["{bad",'{"version":99}', '{"version":3}']:
		var bad_file := FileAccess.open(prefix+"-invalid.json",FileAccess.WRITE)
		bad_file.store_string(payload);bad_file.close()
		var broken := SaveStore.new();broken.path=prefix+"-invalid.json";broken.load_progress()
		check("invalid or future save never silently overwrites source",not broken.writable and not broken.write() and FileAccess.get_file_as_string(broken.path)==payload)
	var legacy := SaveStore.fresh()
	legacy.version = 2
	legacy.erase("wardrobe");legacy.erase("started")
	legacy.active = "ARCHIVE";legacy.crystals=17;legacy.health=2;legacy.collected=["archive_hidden"]
	legacy.worlds={"archive_01":{"position":[48,208],"blocks":{}}}
	var file := FileAccess.open(prefix+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(legacy));file.close()
	var migrated := SaveStore.new();migrated.path=prefix+".json";migrated.load_progress()
	check("v2 migration preserves adventure and makes backup",migrated.data.active=="ARCHIVE" and migrated.data.crystals==17 and migrated.data.health==2 and SideWorld.point(migrated.data.worlds.archive_01.position)==Vector2(48,208) and FileAccess.file_exists(migrated.path+".v2-backup"))
	check("old hidden treasure unlocks outfit without another reward",migrated.data.wardrobe.owned.has("glitch_crab") and migrated.data.crystals==17)
	var invalid := migrated.data.duplicate(true);invalid.wardrobe.equipped="unknown"
	check("unknown equipped skin safely falls back",SaveStore.migrate(invalid).wardrobe.equipped=="classic_orange")
	game.save = migrated
	game.front_end.show_page("title")
	var snapshot: Dictionary = game.save.data.duplicate(true)
	await activate(button("新游戏"))
	check("new game requires confirmation",game.front_end.confirm.visible and game.save.data==snapshot)
	game.front_end.confirm.hide();game.front_end.confirm.canceled.emit()
	check("canceling new game preserves old progress",game.save.data==snapshot)
	await activate(button("更换服装"))
	check("keyboard opens wardrobe from title",game.front_end.page=="wardrobe" and game.in_menu)
	game.front_end.selected="silver_shell";game.front_end.show_page("wardrobe")
	await activate(button("解锁 · 6 晶体"))
	check("purchase asks before charging",game.front_end.confirm.visible and game.save.data.crystals==17)
	await capture("stage2-purchase-confirm")
	await activate(game.front_end.confirm.get_ok_button())
	check("confirmed purchase grants outfit but does not equip",game.save.data.crystals==11 and game.save.data.wardrobe.owned.has("silver_shell") and game.save.data.wardrobe.equipped=="classic_orange")
	await activate(button("装备"))
	check("equipment is separate from purchase",game.save.data.wardrobe.equipped=="silver_shell")
	await capture("stage2-wardrobe")
	await capture("stage2-wardrobe-portrait")
	var reloaded := SaveStore.new();reloaded.path=game.save.path;reloaded.load_progress()
	check("restart reloads owned equipped and balance",reloaded.data.wardrobe==game.save.data.wardrobe and reloaded.data.crystals==11)
	game.front_end.show_page("title")
	await activate(button("继续冒险"));await frames(10)
	check("continue enters saved ARCHIVE in equipped outfit",not game.in_menu and game.active_id=="ARCHIVE" and game.world.player.sprite.texture.atlas.resource_path.ends_with("silver_shell.png"))
	await press("attack");await press("jump",8)
	check("actions preserve skin and collision dimensions",game.world.player.sprite.texture.atlas.resource_path.ends_with("silver_shell.png") and game.world.player.get_child(0).shape.size==Vector2(12,18))
	await walk_to(96)
	var resume_x: float = game.world.player.position.x
	game.hud.set_paused(true)
	var original_path: String = game.save.path
	game.save.path = prefix+"-missing/fail.json"
	game.return_to_title()
	check("failed checkpoint keeps paused adventure live",not game.in_menu and game.world!=null and game.hud.paused)
	game.save.path = original_path
	game.return_to_title()
	check("return saves unloads only 2D and preserves tower",game.in_menu and game.world==null and game.devices.size()==12)
	game.begin_adventure(false);await frames(3)
	check("continue restores a safe saved horizontal position",absf(game.world.player.position.x-resume_x)<1)
	game.return_to_title()
	game.begin_adventure(true);await frames(5)
	check("new game resets adventure but keeps outfits",game.active_id=="BOOT" and game.save.data.crystals==0 and game.save.data.collected.is_empty() and game.save.data.wardrobe.owned.has("silver_shell"))
	for reduced in [false,true]:
		game.director.reduced_motion = reduced
		var link: Dictionary = game.links.filter(func(item): return item.from==game.active_id)[0]
		game._travel(link)
		await frames(3)
		check("exit freezes player and enemies",game.transitioning and not game.world.player.enabled)
		if not reduced: await capture("stage2-transfer-exit")
		var phases: Array[String] = [game.transfer_phase]
		for i in range(180):
			if not game.transitioning: break
			if not phases.has(game.transfer_phase):
				phases.append(game.transfer_phase)
				if not reduced: await capture("stage2-transfer-"+game.transfer_phase.to_lower())
			await frames(1)
		check("three phases complete in mode %s"%reduced,phases.has("EXIT") and phases.has("LINK") and phases.has("ENTER") and not game.transitioning and game.world.player.sprite.visible and game.world.player.enabled)
		check("transfer retains equipped outfit",game.world.player.sprite.texture.atlas.resource_path.ends_with("silver_shell.png"))
		if not reduced: await capture("stage2-transfer-complete")
	var original_definition: String = game.manifest.ARCHIVE.definition
	var blocked: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(original_definition))
	var blocked_link: Dictionary = game.links.filter(func(item): return item.from=="BOOT")[0]
	blocked.spawns[blocked_link.spawn_id] = [48,224]
	var blocked_file := FileAccess.open(prefix+"-destination.json",FileAccess.WRITE)
	blocked_file.store_string(JSON.stringify(blocked));blocked_file.close()
	var original_flags: Dictionary = game.save.data.flags.duplicate(true)
	game.manifest.ARCHIVE.definition = prefix+"-destination.json"
	game._travel(blocked_link);await frames(120)
	check("blocked destination rolls back visible player flags and input",game.active_id=="BOOT" and not game.transitioning and game.world.player.enabled and game.world.player.sprite.visible and game.save.data.flags==original_flags and game.hud.toast_label.text.contains("NO SIGNAL"))
	game.manifest.ARCHIVE.definition = original_definition
	game.return_to_title()
	await frames(4)
	var settings_button := button("游戏设置")
	var motion := InputEventMouseMotion.new()
	motion.position = settings_button.get_global_rect().get_center()
	motion.global_position = motion.position
	get_viewport().push_input(motion,true)
	await frames(2)
	for pressed in [true,false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.position = settings_button.get_global_rect().get_center()
		click.global_position = click.position
		click.pressed = pressed
		get_viewport().push_input(click,true)
		await frames(2)
	check("settings page reachable by mouse",game.front_end.page=="settings")
	await capture("stage2-settings")
	game.front_end.show_page("title")
	var directory := DirAccess.open("user://")
	for name in directory.get_files():
		if name.begins_with(prefix.get_file()): DirAccess.remove_absolute("user://"+name)
	finish()

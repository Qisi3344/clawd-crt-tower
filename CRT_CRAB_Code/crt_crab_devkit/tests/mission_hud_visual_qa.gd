extends SceneTree

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	# --qa disables persistence; replace the default campaign harness only.
	for child in game.get_children():
		var script = child.get_script()
		if script != null and str(script.resource_path).begins_with("res://tests/"):
			child.queue_free()
	for i in range(24): await process_frame
	var passed := true
	for id in ["BOOT", "ARCHIVE", "POP-UP", "RECYCLE", "SIGNAL", "ERROR"]:
		if id != game.active_id: game._load_world(id, "entrance")
		game.director.focus(game._device(id), true)
		game._control_state()
		for i in range(4): await process_frame
		game.hud.update_progress(id, game.save.data)
		await process_frame
		var hud = game.hud
		var card_rect: Rect2 = hud.mission_card.get_global_rect()
		var valid: bool = hud.mission_card.visible and hud.objective.visible and not hud.mission_step.text.is_empty()
		valid = valid and root.get_visible_rect().encloses(card_rect)
		for label in [hud.objective, hud.mission_step, hud.mission_lock]:
			if label.visible: valid = valid and card_rect.encloses(label.get_global_rect())
		passed = passed and valid
		print("MISSION HUD ", id, ": ", valid, " rect=", card_rect, " next=", hud.mission_step.text)
		if DisplayServer.get_name() != "headless":
			await process_frame
			RenderingServer.force_draw()
			DirAccess.make_dir_recursive_absolute("res://artifacts")
			root.get_texture().get_image().save_png("res://artifacts/mission-hud-" + id.to_lower() + ".png")
	quit(0 if passed else 1)

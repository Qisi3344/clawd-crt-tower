extends Node

var game: Node
var results: Array = []
var visual := false

func _ready() -> void:
	game = get_parent()
	visual = DisplayServer.get_name() != "headless"
	run.call_deferred()

func frames(count: int) -> void:
	for i in range(count): await get_tree().physics_frame

func check(label: String, passed: bool) -> void:
	results.append({"test":label,"passed":passed})
	print(("PASS " if passed else "FAIL ") + label)

func capture(label: String) -> void:
	if not visual: return
	await frames(3)
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://artifacts/upgrade-"+label+".png")
	game.viewport.get_texture().get_image().save_png("res://artifacts/upgrade-"+label+"-screen.png")

func run() -> void:
	await frames(12)
	var player: SideCrab = game.world.player
	var start := player.position
	check("BOOT teaches actual supplied weight", game.world.plates[0].get("load", -1) == 0)
	check("BOOT mission is visible before the first action", game.hud.mission_card.visible and not game.hud.mission_step.text.is_empty())
	Input.action_press("dash")
	await frames(2)
	Input.action_release("dash")
	await frames(9)
	check("Shift performs a real short movement in screen physics", player.position.x > start.x + 15 and player.position.x < start.x + 45)
	check("Dodge does not ignore solid collision", player.collision_mask == 5)
	var after := player.position.x
	Input.action_press("dash")
	await frames(2)
	Input.action_release("dash")
	await frames(3)
	check("Repeated Shift cannot bypass the cooldown", player.dash_time <= 0 and player.dash_cooldown < 0.7)
	for id in WorldProgress.ORDER:
		game.viewport.remove_child(game.world)
		game.world.free()
		game._load_world(id)
		game.director.focus(game._device(id), true)
		game._control_state()
		await frames(12)
		check(id+" has one active controllable crab inside the CRT", get_tree().get_nodes_in_group("player").size() == 1 and game.world.player.get_parent() == game.world)
		check(id+" does not complete through idle time", not game.save.data.flags.get(WorldProgress.REPAIRS[WorldProgress.ORDER.find(id)], false))
		var card: Rect2 = game.hud.mission_card.get_global_rect()
		var view: Rect2 = game.hud.mission_card.get_viewport_rect()
		check(id+" mission card leaves the play area readable", card.size.y < view.size.y * 0.22 and view.encloses(card))
		check(id+" has a visible inspection station", game.world.mechanisms.entries.any(func(e): return e.type in ["inspect","diagnostic"]))
		await capture(id.to_lower())
	game.viewport.remove_child(game.world)
	game.world.free()
	game._load_world("BOOT")
	game.director.focus(game._device("BOOT"),true)
	game._control_state()
	get_tree().root.size = Vector2i(720,900)
	await frames(8)
	check("Portrait mission stays within the window", game.hud.mission_card.get_viewport_rect().encloses(game.hud.mission_card.get_global_rect()))
	await capture("portrait")
	var report := {"passed":results.all(func(r): return r.passed),"tests":results,"visual":visual}
	DirAccess.make_dir_recursive_absolute("res://artifacts")
	var file := FileAccess.open("res://artifacts/gameplay-upgrade-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()
	get_tree().quit(0 if report.passed else 1)

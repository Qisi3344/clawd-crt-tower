extends SceneTree

func _initialize() -> void:
	var crab := SideCrab.new()
	crab.enabled = true
	crab.facing = -1
	if not crab.has_method("start_dash"):
		push_error("FAIL: screen-world crab cannot use the mapped dodge action")
		crab.free()
		quit(1)
		return
	assert(crab.start_dash())
	assert(crab.dash_direction == -1, "Dodge keeps the chosen facing")
	assert(crab.dash_time > 0 and crab.dash_cooldown > crab.dash_time)
	assert(crab.invulnerable > 0, "Dodge supplies a short defensive window")
	assert(not crab.start_dash(), "Dodge cannot be spammed during cooldown")
	crab.dash_time = 0
	crab.dash_cooldown = 0
	crab.climbing = true
	assert(not crab.start_dash(), "Dodge must not detach the player from a ladder")
	crab.climbing = false
	crab.pushing = true
	assert(not crab.start_dash(), "Dodge must not bypass a push puzzle")
	crab.pushing = false
	crab.dash_time = 0.1
	crab.respawn()
	assert(crab.dash_time == 0, "Respawn cancels active dash movement at the checkpoint")
	crab.enabled = false
	assert(not crab.start_dash(), "Paused player cannot dodge")
	crab.free()
	print("PASS: directional dodge, defense window, cooldown, ladder/push/pause guards")
	quit(0)

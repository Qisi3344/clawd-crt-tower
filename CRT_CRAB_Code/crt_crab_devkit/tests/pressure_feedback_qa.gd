extends SceneTree
func _initialize() -> void:
	var world := SideWorld.new()
	if not world.has_method("pressure_readout"):
		push_error("FAIL pressure puzzle does not explain actual weight")
		world.free();quit(1);return
	assert(world.pressure_readout({"weight":2,"load":1,"active":false}) == "重量 1/2 · 未接通")
	assert(world.pressure_readout({"weight":2,"load":2,"active":true}) == "重量 2/2 · 接通")
	assert(world.pressure_readout({"weight":1,"load":3,"active":true}) == "重量 3/1 · 接通")
	print("PASS actual load, required weight and electrical state are explicit")
	world.free();quit(0)

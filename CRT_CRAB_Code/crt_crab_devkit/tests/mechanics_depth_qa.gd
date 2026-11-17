extends SceneTree
var failures := 0
func check(label: String, value: bool) -> void:
	print(("PASS " if value else "FAIL ")+label)
	if not value: failures+=1
func _initialize() -> void:
	var world:=SideWorld.new()
	world.flags={};world.state={"defeated":[],"broken":[]}
	world.player=SideCrab.new();world.player.position=Vector2(100,108)
	var system:=ChapterMechanics.new();system.world=world
	var receiver:={"id":"fuse","type":"receiver","position":[100,100],"flag":"solved","reflector":"correct"}
	system.entries=[receiver]
	var shot:=SignalProjectile.new();shot.position=Vector2(100,100);shot.reflected=true;shot.last_reflector="wrong"
	system.projectile_step(shot,shot.position)
	check("wrong reflector cannot accidentally solve receiver",not world.flags.get("solved",false))
	world.flags.clear();shot.last_reflector="correct";system.projectile_step(shot,shot.position)
	check("correct deliberately routed reflection solves receiver",world.flags.get("solved",false))
	world.flags.clear();system.entries=[{"id":"panel","type":"break_panel","position":[100,100],"flag":"panel_open","impact_only":true}]
	system.attack()
	check("claw cannot bypass owl impact puzzle",not world.flags.get("panel_open",false))
	system.owl_impact(Vector2(100,100))
	check("owl impact still solves marked panel",world.flags.get("panel_open",false))
	var feedback: Array[String]=[]
	world.message.connect(func(text): feedback.append(text))
	system.interact({"id":"read_weight","type":"inspect","position":[100,108],"label":"压板","watch_flags":["panel_open"],"hint":"重物保持支撑"})
	check("inspection reports live mechanism state",not feedback.is_empty() and "1 / 1" in feedback.back())
	var core: Node2D=load("res://scripts/enemies/bsod_core.gd").new();core.system=system;core.status={};core.stage=2;core.pulse_redirected=true;core.clock=.9;world.enabled=true;world.player.position=Vector2(150,208)
	# Provide upstream input names through the game's actual circuit definition.
	world.flags.signal_archive_gate=true;world.flags.popup_noise_clean=true;world.flags.popup_power_restored=true;world.flags.message_packet_restored=true;world.flags.recycle_route_repaired=true
	core._physics_process(.05)
	check("unsafe pulse cannot advance boss by taking damage",core.stage==2)
	world.player.position=Vector2(288,160);core.clock=.9;core.pulse_redirected=true;core._physics_process(.05)
	check("safe reversed pulse advances boss",core.stage==3)
	var moth:=MechanicalAnimal.new();moth.system=system;moth.species="moth";moth.origin=Vector2(200,100);moth.position=moth.origin;moth.stun=.5;moth.time=.69
	moth._physics_process(.05)
	check("stunned moth cannot fire during recovery",moth.time<.71 and moth.phase=="stunned")
	moth.free()
	core.free();system.free();world.player.free();world.free();shot.free()
	quit(0 if failures==0 else 1)

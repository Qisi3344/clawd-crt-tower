extends "res://tests/sideview_qa.gd"

var activations:=0
func click(button: Button, down: bool) -> void:
	var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.position=button.get_global_rect().get_center();event.pressed=down
	get_viewport().push_input(event,true);await frames(2)

func _run() -> void:
	await frames(20)
	var icons:Array=game.hud.find_children("HUD_*","Button",true,false)
	check("three compact textless icon buttons",icons.size()==3 and icons.all(func(b):return b.text.is_empty() and b.size.x<=40))
	check("pause has no duplicate internal-map entry",not game.hud.pause_pages.keys().any(func(b):return b is Button and b.text=="关卡内部地图"))
	var pause:HudIconButton=game.hud.find_child("HUD_pause",true,false)
	pause.activated.connect(func():activations+=1)
	var motion:=InputEventMouseMotion.new();motion.position=pause.get_global_rect().get_center();get_viewport().push_input(motion,true);await frames(3)
	if visual: check("hover reveals the button caption",pause.hint_label.visible)
	await click(pause,true);OS.delay_msec(560);await frames(3)
	check("long hold reveals caption",pause.hint_label.visible)
	await click(pause,false)
	check("long hold does not activate pause",activations==0 and not game.hud.paused)
	await click(pause,true);await click(pause,false)
	check("short click still activates pause",activations==1 and game.hud.paused)
	await capture("portal-pause-clean")
	game.hud.set_paused(false)
	game.change_profile("touch");await frames(3)
	var touch:=InputEventScreenTouch.new();touch.index=52;touch.position=pause.get_global_rect().get_center();touch.pressed=true;get_viewport().push_input(touch,true)
	await frames(2)
	check("touch caption stays hidden before long-press threshold",not pause.hint_label.visible)
	OS.delay_msec(560);await frames(3)
	check("native touch long press reveals caption",pause.hint_label.visible)
	touch=touch.duplicate();touch.pressed=false;get_viewport().push_input(touch,true);await frames(3)
	check("native touch long press does not activate menu",not game.hud.paused and activations==1)
	game.change_profile("keyboard")
	game.viewport.remove_child(game.world);game.world.free();game._load_world("ARCHIVE","entrance");game.director.focus(game._device("ARCHIVE"),true);game._control_state();await frames(6)
	var ports:Array=game.world.get_children().filter(func(n):return n is EnergyPortal)
	check("every CRT exit has a native energy column",ports.size()==game.links.filter(func(l):return l.from=="ARCHIVE").size())
	var lower:Dictionary=game.links.filter(func(l):return l.id=="archive_popup")[0]
	var upper:Dictionary=game.links.filter(func(l):return l.id=="archive_exit")[0]
	check("two east exits separated onto different floors",SideWorld.point(lower.position)==Vector2(864,208) and SideWorld.point(upper.position)==Vector2(864,64))
	check("both exits clear all archive ladders",[lower,upper].all(func(l):return game.world.definition.ladders.all(func(s):return absf(s.x-l.position[0])>30)))
	# These are visual/interaction fixtures, not campaign progression evidence.
	game.world.player.position=Vector2(864,208);game.world.player.velocity=Vector2.ZERO;game.world._snap_camera(true);await frames(5)
	check("lower column resolves only the POP-UP destination",game.world.nearest.get("object",{}).get("id")=="archive_popup")
	await capture("portal-archive-lower")
	game.world.player.position=Vector2(864,64);game.world.player.velocity=Vector2.ZERO;game.world._snap_camera(true);await frames(5)
	check("upper column resolves only the BOOT destination",game.world.nearest.get("object",{}).get("id")=="archive_exit")
	await capture("portal-archive-upper")
	var column:EnergyPortal=ports.filter(func(p):return p.link.id=="archive_exit")[0]
	game.audio.reduced_motion=true;var clock:float=column.clock;await frames(10)
	check("reduced motion freezes the energy spiral",is_equal_approx(clock,column.clock))
	var file:=FileAccess.open("res://artifacts/portal-hud-qa-"+("visual" if visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":not failed,"tests":results,"captures":captures},"\t"));file.close();get_tree().quit(1 if failed else 0)

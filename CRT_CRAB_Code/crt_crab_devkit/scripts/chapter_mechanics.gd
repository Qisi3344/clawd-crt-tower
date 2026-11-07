class_name ChapterMechanics
extends Node2D

var world: SideWorld
var entries: Array = []
var animals: Array[MechanicalAnimal] = []
var switches: Dictionary = {}
var clock := 0.0
var boss: Node2D
var colliders: Dictionary={}

func _ready() -> void:
	if not world.state.get("mechanisms") is Dictionary: world.state.mechanisms={}
	switches=world.state.mechanisms
	entries=world.definition.get("mechanisms",[])
	for entry in entries:
		if entry.type not in ["popup_panel","web_bridge"]: continue
		var body:=StaticBody2D.new();body.position=SideWorld.point(entry.position);add_child(body)
		var shape:=CollisionShape2D.new();var rect:=RectangleShape2D.new()
		rect.size=Vector2(14,40) if entry.type=="popup_panel" else Vector2(48,8)
		shape.shape=rect;shape.position.y=-20 if entry.type=="popup_panel" else -4
		shape.one_way_collision=entry.type=="web_bridge"
		if shape.one_way_collision: world.ladder_platforms.append(body)
		body.add_child(shape);colliders[entry.id]=shape
	for entry in world.definition.get("animals",[]):
		if world.state.defeated.has(entry.id): continue
		var animal:=MechanicalAnimal.new();animal.system=self;animal.entry=entry
		add_child(animal);animals.append(animal)
	if world.definition.has("boss"):
		boss=Node2D.new();boss.set_script(load("res://scripts/enemies/bsod_core.gd"));boss.system=self;add_child(boss)
	z_index=4

func _physics_process(delta: float) -> void:
	if not world.enabled: return
	clock+=delta
	for entry in entries:
		var p:=SideWorld.point(entry.position)
		match str(entry.type):
			"popup_panel":
				var active:bool=not world.flags.get(entry.get("disabled_by",""),false) and fmod(clock,3.2)>=.7 and fmod(clock,3.2)<1.5
				colliders[entry.id].set_deferred("disabled",not active)
			"web_bridge":
				var active:=false
				for animal in animals:
					if is_instance_valid(animal) and animal.species=="spider" and animal.phase=="weave" and absf(animal.position.x-p.x)<20: active=true
				colliders[entry.id].set_deferred("disabled",not active)
				if world.flags.get(entry.flag,false)!=active: world.flags[entry.flag]=active;world.progress_changed.emit()
			"crusher":
				if crusher_active(entry):
					var rect:=Rect2(p.x-14,p.y-28,28,28)
					if rect.has_point(world.player.position-Vector2(0,8)): world.player.take_damage()
					for animal in animals:
						if is_instance_valid(animal) and rect.has_point(animal.position-Vector2(0,6)):
							animal.hit(true)
							if entry.has("flag"): latch(str(entry.flag))
			"hazard":
				if not world.flags.get(entry.get("disabled_by",""),false) and fmod(clock,2.5)>.7 and fmod(clock,2.5)<1.2:
					var rect:=Rect2(p.x-10,p.y-26,20,26)
					if rect.has_point(world.player.position-Vector2(0,8)): world.player.take_damage()
			"fragment":
				if not world.flags.get(entry.flag,false) and p.distance_to(world.player.position-Vector2(0,8))<20:
					latch(str(entry.flag));world.pickup_burst(p);world.message.emit("通信碎片已保存 · 可安全离开或复位")
			"sensor":
				for animal in animals:
					if is_instance_valid(animal) and not animal.defeated and p.distance_to(animal.position)<19: latch(str(entry.flag))
			"relay":
				if not entry.get("temporary",false): continue
				var active: bool=world.flags.get(entry.get("bypass",""),false)
				for animal in animals:
					if is_instance_valid(animal) and animal.species=="bee" and animal.phase=="relay" and animal.position.distance_to(p)<22:
						active=true
						if entry.has("charge_flag"): latch(str(entry.charge_flag))
				if world.flags.get(entry.flag,false)!=active:
					world.flags[entry.flag]=active;world.progress_changed.emit()
	queue_redraw()

func candidates() -> Array[Dictionary]:
	var list: Array[Dictionary]=[]
	for entry in entries:
		if entry.type in ["reflector","conveyor","magnet","stop","pulse","assembly","repair","insulator"]:
			list.append({"type":"mechanism","position":entry.get("control",entry.position),"object":entry,"prompt":"E  "+str(entry.get("label","操作机关"))})
	if is_instance_valid(boss): list.append_array(boss.candidates())
	return list

func interact(entry: Dictionary) -> void:
	var id:=str(entry.id)
	match str(entry.type):
		"reflector":
			switches[id]=(int(switches.get(id,0))+1)%3
			world.sound_requested.emit("select")
		"conveyor","magnet","stop","insulator":
			switches[id]=not bool(switches.get(id,entry.get("on",false)))
			if entry.has("flag"): world.flags[entry.flag]=switches[id]
			world.sound_requested.emit("select")
		"pulse":
			shoot(SideWorld.point(entry.get("emitter",entry.position)),SideWorld.point(entry.get("direction",[1,0]),Vector2.RIGHT))
		"repair","assembly":
			var missing: Array[String]=[]
			for flag in entry.get("requires_all",[]):
				if not world.flags.get(flag,false): missing.append(str(flag))
			if entry.get("circuit",false) and not WorldProgress.missing_inputs(world.flags).is_empty():
				world.message.emit("缺少跨屏输入："+WorldProgress.missing_inputs(world.flags));return
			if not missing.is_empty():
				world.message.emit(str(entry.get("locked_hint","尚未完成本房间机关。")));return
			for flag in entry.get("outputs",[]): latch(str(flag))
			world.message.emit(str(entry.get("success","本段链路已修复 · 其他屏幕也已收到信号")))
		"core":
			if is_instance_valid(boss): boss.interact()
	world.progress_changed.emit()

func latch(flag: String) -> void:
	if flag.is_empty() or world.flags.get(flag,false): return
	world.flags[flag]=true
	world.sound_requested.emit("unlock")
	world.progress_changed.emit()

func shoot(p: Vector2, direction: Vector2) -> void:
	var shot:=SignalProjectile.new();shot.system=self;shot.position=p;shot.velocity=direction.normalized()*70
	add_child(shot)
	world.sound_requested.emit("select")

func projectile_step(shot: SignalProjectile, _previous: Vector2) -> void:
	for entry in entries:
		var p:=SideWorld.point(entry.position)
		if shot.position.distance_to(p)>10: continue
		if entry.type=="reflector" and shot.last_reflector!=str(entry.id):
			shot.last_reflector=str(entry.id);shot.reflected=true
			var orientation:=int(switches.get(entry.id,0))
			if orientation==2: shot.velocity=-shot.velocity
			else: shot.velocity=Vector2(0,70 if orientation==1 else -70) if absf(shot.velocity.x)>0 else Vector2(70 if orientation==1 else -70,0)
			shot.position=p+shot.velocity.normalized()*11
			world.sound_requested.emit("hit")
		elif entry.type=="receiver" and (shot.reflected or not entry.get("reflected",true)):
			latch(str(entry.flag));shot.queue_free();return
	if is_instance_valid(boss) and boss.receive(shot): shot.queue_free();return
	if shot.reflected:
		for animal in animals:
			if is_instance_valid(animal) and not animal.defeated and shot.position.distance_to(animal.position)<17:
				animal.hit(true);shot.queue_free();return
	if shot.position.distance_to(world.player.position-Vector2(0,9))<11:
		world.player.take_damage();shot.queue_free()

func conveyor_velocity(p: Vector2) -> float:
	for entry in entries:
		if entry.type!="conveyor": continue
		var pos:=SideWorld.point(entry.position)
		if absf(p.y-pos.y)<14 and absf(p.x-pos.x)<float(entry.get("width",96))/2:
			return -26 if switches.get(entry.id,entry.get("on",false)) else 26
	return 0

func magnet_target(p: Vector2) -> Vector2:
	for entry in entries:
		if entry.type=="magnet" and switches.get(entry.id,false):
			var target:=SideWorld.point(entry.get("target",entry.position))
			if p.distance_to(SideWorld.point(entry.position))<float(entry.get("range",140)): return target
	return Vector2(-1,-1)

func crusher_active(entry: Dictionary) -> bool:
	return not switches.get(entry.get("stop",""),false) and fmod(clock+float(entry.get("offset",0)),3.2)>1.2 and fmod(clock+float(entry.get("offset",0)),3.2)<1.8

func conduct_near(p: Vector2) -> void:
	for entry in entries:
		if entry.type=="relay" and not entry.get("temporary",false) and SideWorld.point(entry.position).distance_to(p)<22: latch(str(entry.flag))

func owl_impact(p: Vector2) -> void:
	for entry in entries:
		if entry.type=="break_panel" and SideWorld.point(entry.position).distance_to(p)<30: latch(str(entry.flag))

func attack() -> void:
	var p:=world.player.position-Vector2(0,8)
	for animal in animals:
		if not is_instance_valid(animal): continue
		var offset:=animal.position-p
		if animal.species=="spider" and animal.phase=="weave" and absf(offset.x)<28 and p.y>animal.position.y and p.y<animal.position.y+100:
			animal.stun=1.2;world.sound_requested.emit("hit")
		if absf(offset.x)<31 and absf(offset.y)<25 and offset.x*world.player.facing>-5: animal.hit()
	for entry in entries:
		if entry.type=="break_panel" and SideWorld.point(entry.position).distance_to(p)<28: latch(str(entry.flag))
	if is_instance_valid(boss): boss.attack(p)

func break_marked(id: String) -> void:
	for i in range(world.breakables.size()-1,-1,-1):
		var block:Dictionary=world.breakables[i]
		if str(block.id)!=id: continue
		world.state.broken.append(id);block.body.queue_free();world.breakables.remove_at(i)
		world.sound_requested.emit("hit");world.progress_changed.emit()

func reset_local() -> void:
	for child in get_children():
		if child is SignalProjectile: child.queue_free()
	clock=0
	for entry in entries:
		if entry.type=="insulator" and entry.has("flag"): world.flags[entry.flag]=bool(entry.get("on",false))
	switches.clear()
	if is_instance_valid(boss): boss.reset_attempt()
	# Any puzzle-dependent species can be recovered even after it was defeated.
	for animal in animals:
		if is_instance_valid(animal): animal.free()
	animals.clear()
	for entry in world.definition.get("animals",[]):
		world.state.defeated.erase(entry.id)
		var animal:=MechanicalAnimal.new();animal.system=self;animal.entry=entry;add_child(animal);animals.append(animal)

func _draw() -> void:
	var font:=preload("res://assets/fonts/fusion-pixel.otf")
	var ink:=Color("182433");var green:=Color("54cfc3");var gold:=Color("efcd79");var red:=Color("ed839c")
	for entry in entries:
		var p:=SideWorld.point(entry.position)
		var on: bool=bool(switches.get(entry.id,entry.get("on",false)))
		match str(entry.type):
			"popup_panel":
				var active:bool=not world.flags.get(entry.get("disabled_by",""),false) and fmod(clock,3.2)>=.7 and fmod(clock,3.2)<1.5
				var warning:bool=not world.flags.get(entry.get("disabled_by",""),false) and fmod(clock,3.2)<.7
				var top:=p-Vector2(10,40 if active else 70)
				draw_rect(Rect2(top,Vector2(20,36)),Color("785777") if active else Color("3a3c54"))
				draw_rect(Rect2(top,Vector2(20,8)),red if warning else gold)
				draw_line(top+Vector2(13,2),top+Vector2(18,6),ink,1);draw_line(top+Vector2(18,2),top+Vector2(13,6),ink,1)
				if warning: draw_line(p-Vector2(10,0),p+Vector2(10,0),gold,1)
			"web_bridge":
				var active:bool=world.flags.get(entry.flag,false)
				draw_line(p-Vector2(24,4),p+Vector2(24,-4),green if active else Color("526471"),3 if active else 1)
			"reflector":
				draw_circle(p,11,ink);draw_circle(p,11,gold,false,1)
				draw_line(p+Vector2(-7,-7 if on else 7),p+Vector2(7,7 if on else -7),green,3)
				draw_line(p,p+Vector2(0,28 if on else -28),Color("54cfc366"),1)
				if int(switches.get(entry.id,0))==2: draw_line(p,p-Vector2(28,0),gold,2)
				var ctrl:=SideWorld.point(entry.get("control",entry.position))
				draw_line(p,ctrl,Color("536675"),1);draw_rect(Rect2(ctrl-Vector2(7,13),Vector2(14,13)),gold)
			"receiver","relay","sensor":
				var active: bool=world.flags.get(entry.flag,false)
				draw_rect(Rect2(p-Vector2(8,8),Vector2(16,16)),ink)
				draw_rect(Rect2(p-Vector2(6,6),Vector2(12,12)),green if active else gold,false,2)
				if active: draw_line(p-Vector2(4,0),p+Vector2(4,0),green,2)
			"hazard":
				var disabled: bool=world.flags.get(entry.get("disabled_by",""),false)
				var t:=fmod(clock,2.5)
				var color:=green if disabled else (red if t>.7 and t<1.2 else gold)
				draw_rect(Rect2(p-Vector2(8,26),Vector2(16,26)),Color(color,.25))
				draw_line(p-Vector2(8,0),p+Vector2(8,0),color,2)
				if not disabled: draw_line(p-Vector2(0,25),p,color,2 if t>.7 and t<1.2 else 1)
			"conveyor":
				var width:=float(entry.get("width",96))
				draw_rect(Rect2(p-Vector2(width/2,5),Vector2(width,5)),Color("687481"))
				for x in range(int(p.x-width/2)+8,int(p.x+width/2),16):
					var d:float=-1 if on else 1
					draw_line(Vector2(x-3*d,p.y-4),Vector2(x+3*d,p.y-2),gold,1)
			"crusher":
				var t:=fmod(clock+float(entry.get("offset",0)),3.2)
				var y:=p.y-60
				if not switches.get(entry.get("stop",""),false):
					if t>1.2 and t<1.8: y=p.y-16
					elif t>=1.8: y=lerpf(p.y-16,p.y-60,minf((t-1.8)/.7,1))
				draw_line(p-Vector2(0,85),Vector2(p.x,y),Color("687481"),4)
				draw_rect(Rect2(p.x-15,y-8,30,12),Color("9f9ca2"))
				draw_line(Vector2(p.x-15,y+5),Vector2(p.x+15,y+5),red,3)
				if t>.5 and t<1.2: draw_line(p-Vector2(14,0),p+Vector2(14,0),gold,2)
			"magnet":
				draw_arc(p,12,0,PI,12,red if on else Color("6d8291"),4)
				if on: draw_line(p,SideWorld.point(entry.get("target",entry.position)),Color("54cfc366"),1)
			"fragment":
				if not world.flags.get(entry.flag,false): draw_colored_polygon(PackedVector2Array([p+Vector2(0,-7),p+Vector2(6,0),p+Vector2(0,7),p+Vector2(-6,0)]),green)
			"break_panel":
				if not world.flags.get(entry.flag,false):
					draw_rect(Rect2(p-Vector2(12,20),Vector2(24,20)),Color("727587"));draw_line(p-Vector2(4,18),p+Vector2(4,-2),gold,2)
			"diagnostic":
				draw_rect(Rect2(p-Vector2(0,64),Vector2(260,64)),ink)
				var i:=0
				for key in WorldProgress.circuit_inputs(world.flags):
					var active: bool=WorldProgress.circuit_inputs(world.flags)[key]
					draw_string(font,p+Vector2(7,-48+i*16),("[OK] " if active else "[--] ")+str(key),HORIZONTAL_ALIGNMENT_LEFT,-1,12,green if active else gold);i+=1
			"stop","pulse","assembly","repair","insulator":
				draw_rect(Rect2(p-Vector2(8,16),Vector2(16,16)),ink)
				draw_rect(Rect2(p-Vector2(6,14),Vector2(12,10)),green if on else gold,false,2)
				draw_line(p-Vector2(4,6),p+Vector2(4,-6),gold)

class_name MechanicalAnimal
extends CharacterBody2D

var system: ChapterMechanics
var entry: Dictionary
var animal_id := ""
var species := "moth"
var health := 2
var origin := Vector2.ZERO
var time := 0.0
var stun := 0.0
var facing := 1
var phase := "patrol"
var phase_time := 0.0
var aim := Vector2.ZERO
var defeated := false
var weight := 0

func _ready() -> void:
	animal_id = str(entry.id)
	species = str(entry.species)
	health = int(entry.get("health",2))
	origin = SideWorld.point(entry.position)
	position = origin
	weight = 2 if species in ["snail","hamster"] else 0
	if species=="flea": weight=1
	collision_layer = 8
	collision_mask = 5
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new();rect.size = Vector2(20,16)
	shape.shape=rect;shape.position.y=-8;add_child(shape)
	z_index = 6

func _physics_process(delta: float) -> void:
	if not system.world.enabled or defeated: return
	time+=delta;phase_time+=delta;stun=maxf(0,stun-delta)
	match species:
		"moth": _moth(delta)
		"hamster","snail": _ground(delta)
		"bee": _bee(delta)
		"owl": _owl(delta)
		"flea": _flea(delta)
		"spider": _spider(delta)
		"beaver": _beaver(delta)
		"eel": _eel(delta)
	if position.y>system.world.world_size.y+20: position=origin;velocity=Vector2.ZERO
	if stun<=0 and position.distance_to(system.world.player.position-Vector2(0,8))<17 and (species!="eel" or not system.world.flags.get("signal_water_safe",false)): system.world.player.take_damage()
	queue_redraw()

func _moth(_delta: float) -> void:
	position=origin+Vector2(0,sin(time*1.5)*3)
	var period := fmod(time,2.8)
	phase = "cue" if period<.7 else "patrol"
	if period>=.7 and fmod(time-_delta,2.8)<.7:
		system.shoot(position,Vector2(float(entry.get("direction",1)),0))

func _ground(delta: float) -> void:
	velocity.y=minf(velocity.y+580*delta,320)
	velocity.x = facing*(46 if species=="hamster" else 18) if stun<=0 else 0
	velocity.x += system.conveyor_velocity(position)
	var magnet := system.magnet_target(position)
	if magnet.x>=0: velocity.x=clampf((magnet.x-position.x)*3,-70,70)
	move_and_slide()
	if is_on_wall(): facing*=-1
	var distance := float(entry.get("range",64))
	if position.x<origin.x-distance: facing=1
	if position.x>origin.x+distance: facing=-1

func _flea(delta: float) -> void:
	var cycle:=fmod(time,1.4)
	phase="cue" if cycle<.35 else "patrol"
	if cycle>=.35 and fmod(time-delta,1.4)<.35 and is_on_floor(): velocity=Vector2(facing*40,-165)
	velocity.y=minf(velocity.y+580*delta,320)
	move_and_slide()
	if is_on_wall() or absf(position.x-origin.x)>40: facing*=-1

func _spider(_delta: float) -> void:
	position=origin+Vector2(sin(time*.7)*38,0)
	phase="weave" if fmod(time,4)<2 and stun<=0 else "patrol"
	if phase=="weave" and absf(system.world.player.position.x-position.x)<7 and system.world.player.position.y>position.y and system.world.player.position.y<position.y+100:
		system.world.player.velocity.x*=.55

func _beaver(delta: float) -> void:
	for block in system.world.breakables:
		if str(block.id)!=str(entry.get("breaks","")) or block.body.position.distance_to(position-Vector2(0,8))>28: continue
		if phase!="gnaw": phase_time=0
		phase="gnaw";velocity.x=0;velocity.y=minf(velocity.y+580*delta,320)
		move_and_slide()
		if phase_time>1.2:
			system.break_marked(str(block.id));phase_time=0
		return
	phase="patrol";phase_time=0;_ground(delta)

func _eel(_delta: float) -> void:
	position=origin+Vector2(sin(time*.8)*float(entry.get("range",55)),0)
	var cycle:=fmod(time,3)
	phase="cue" if cycle<.8 else ("pulse" if cycle<1.25 else "patrol")
	if phase=="pulse":
		if system.world.flags.get("signal_water_safe",false):
			if entry.has("flag"): system.latch(str(entry.flag))
		elif system.world.player.position.y>origin.y-13 and absf(system.world.player.position.x-origin.x)<85: system.world.player.take_damage()

func _bee(_delta: float) -> void:
	var path: Array = entry.get("path",[entry.position,[origin.x+80,origin.y]])
	var segment := int(time/2.4)%path.size()
	var next := (segment+1)%path.size()
	var t := fmod(time,2.4)
	position=SideWorld.point(path[segment]).lerp(SideWorld.point(path[next]),minf(t/1.6,1))
	phase="relay" if t>=1.6 else "patrol"
	if phase=="relay": system.conduct_near(position)

func _owl(delta: float) -> void:
	if phase=="patrol":
		position=origin+Vector2(sin(time)*40,0)
		if phase_time>1.6:
			phase="cue";phase_time=0;aim=system.world.player.position-Vector2(0,6)
	elif phase=="cue":
		if phase_time>=.9: phase="dive";phase_time=0
	elif phase=="dive":
		position=position.move_toward(aim,170*delta)
		if position.distance_to(aim)<4:
			system.owl_impact(position);phase="stunned";phase_time=0;stun=1.0
	else:
		if phase_time>1.1:
			position=position.move_toward(origin,80*delta)
			if position.distance_to(origin)<3: phase="patrol";phase_time=0

func hit(crushed: bool = false) -> void:
	if defeated or (stun>0 and not crushed): return
	if species=="snail" and not crushed and (system.world.player.position.x-position.x)*facing>0:
		stun=.2;system.world.sound_requested.emit("hit");return
	health-=3 if crushed else 1
	if not crushed: system.world.learning_event.emit("attack")
	stun=.35
	system.world.sound_requested.emit("hit")
	if health<=0:
		defeated=true
		system.world.state.defeated.append(animal_id)
		system.world.progress_changed.emit()
		queue_free()

func _draw() -> void:
	var ink:=Color("1b2032");var metal:=Color("a6b6b4");var green:=Color("54cfc3");var gold:=Color("efcd79")
	var lit:=Color("f5d889") if phase=="cue" else green
	if stun>0: modulate=Color("ffe1bd")
	else: modulate=Color.WHITE
	match species:
		"moth":
			for side in [-1,1]:
				var flap: float=absf(sin(time*7))*3
				draw_colored_polygon(PackedVector2Array([Vector2(side*3,-10),Vector2(side*17,-19-flap),Vector2(side*19,-2),Vector2(side*5,3)]),Color("9d88be"))
				draw_line(Vector2(side*8,-13),Vector2(side*13,-7),Color("ee8b9f"),2)
				draw_line(Vector2(side*13,-13),Vector2(side*8,-7),Color("ee8b9f"),2)
			draw_rect(Rect2(-4,-15,8,17),ink);draw_rect(Rect2(-2,-13,4,12),metal)
			draw_line(Vector2(-2,-14),Vector2(-6,-20),gold);draw_line(Vector2(2,-14),Vector2(6,-20),gold)
			draw_rect(Rect2(-2,-13,4,3),lit)
			if phase=="cue": draw_line(Vector2(10,-5),Vector2(90,-5),Color("ef8b9f66"))
		"hamster":
			draw_circle(Vector2(0,-10),13,ink)
			for i in range(8):
				var v:=Vector2.from_angle(i*TAU/8+time*3)
				draw_line(Vector2(0,-10)+v*8,Vector2(0,-10)+v*14,metal,3)
			draw_circle(Vector2(0,-10),9,Color("c19e86"));draw_circle(Vector2(-7,-19),4,gold);draw_circle(Vector2(7,-19),4,gold)
			draw_rect(Rect2(-5,-13,3,3),ink);draw_rect(Rect2(3,-13,3,3),ink);draw_rect(Rect2(-2,-6,4,2),green)
		"snail":
			draw_rect(Rect2(-14,-5,28,5),Color("8ca8a1"));draw_circle(Vector2(-2,-12),11,metal);draw_circle(Vector2(-2,-12),7,ink);draw_circle(Vector2(-2,-12),3,gold)
			draw_line(Vector2(9,-4),Vector2(12,-15),green,2);draw_circle(Vector2(12,-15),2,gold)
		"bee":
			for side in [-1,1]: draw_colored_polygon(PackedVector2Array([Vector2(0,-10),Vector2(side*16,-18-absf(sin(time*15))*3),Vector2(side*13,-3)]),Color("9bcad2aa"))
			draw_rect(Rect2(-10,-13,20,12),gold)
			for x in [-5,2]: draw_rect(Rect2(x,-13,3,12),ink)
			draw_line(Vector2(10,-6),Vector2(16,-6),lit,2);draw_rect(Rect2(-8,-11,3,3),green)
			if phase=="relay": draw_circle(Vector2(0,-6),19,Color("54cfc344"),false,1)
		"owl":
			draw_colored_polygon(PackedVector2Array([Vector2(-20,-18),Vector2(0,-10),Vector2(20,-18),Vector2(12,3),Vector2(-12,3)]),Color("7c8fa1"))
			for x in [-7,7]:
				draw_circle(Vector2(x,-12),7,ink);draw_circle(Vector2(x,-12),4,lit);draw_rect(Rect2(x-1,-14,2,4),ink)
			draw_colored_polygon(PackedVector2Array([Vector2(-3,-6),Vector2(3,-6),Vector2(0,-1)]),gold)
			if phase=="cue": draw_line(Vector2(0,0),aim-position,Color("ef8b9f99"),1)
		"flea":
			var crouch:float=3 if phase=="cue" else 0
			draw_rect(Rect2(-7,-15+crouch,14,9),Color("8a91af"))
			for x in [-4,4]:
				draw_rect(Rect2(x-2,-17+crouch,4,5),gold)
				draw_polyline(PackedVector2Array([Vector2(x,-6),Vector2(x*2,-3),Vector2(x,-1),Vector2(x*2,2)]),metal,1)
			if phase=="cue": draw_circle(Vector2(0,-10),12,Color("efcd7955"),false,1)
		"spider":
			for side in [-1,1]:
				for i in range(4): draw_polyline(PackedVector2Array([Vector2(side*3,-8),Vector2(side*(12+i*2),-19+i*6),Vector2(side*(17+i*2),-14+i*6)]),metal,1)
			draw_rect(Rect2(-7,-15,14,12),ink);draw_rect(Rect2(-5,-13,10,8),gold)
			for x in [-3,2]: draw_rect(Rect2(x,-11,2,2),green)
			if phase=="weave": draw_line(Vector2(0,0),Vector2(0,100),Color("aab8c688"),1)
		"beaver":
			draw_colored_polygon(PackedVector2Array([Vector2(-9,-8),Vector2(-23,-6),Vector2(-24,1),Vector2(-9,3)]),Color("587d71"))
			draw_rect(Rect2(-11,-17,23,18),Color("9e887d"));draw_circle(Vector2(8,-15),6,metal)
			draw_rect(Rect2(10,-11,5,9),gold);draw_rect(Rect2(8,-17,3,3),ink)
			if phase=="gnaw": draw_line(Vector2(14,-8),Vector2(20,-12+sin(time*20)*4),green,1)
		"eel":
			var color:Color=gold if phase=="cue" else (green if phase=="pulse" else Color("8e88b9"))
			var points:=PackedVector2Array()
			for i in range(9): points.append(Vector2(-28+i*7,-7+sin(time*4+i)*4))
			draw_polyline(points,ink,7);draw_polyline(points,color,3)
			for i in range(1,8,2): draw_circle(points[i],2,metal)
			draw_rect(Rect2(25,-9,4,3),gold)

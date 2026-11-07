extends Node2D

var system: ChapterMechanics
var stage := 0
var clock := 0.0
var shot_clock := 0.0
var core_health := 3
var pulse_redirected := false
var closing := false
var status: Dictionary

func _ready() -> void:
	position=Vector2(208,88)
	if not system.world.state.get("boss") is Dictionary: system.world.state.boss={}
	status=system.world.state.boss
	stage=clampi(int(status.get("stage",0)),0,3)
	if system.world.flags.get("error_core_disabled",false): stage=4
	z_index=6

func _physics_process(delta: float) -> void:
	if not system.world.enabled or stage==4: return
	clock+=delta;shot_clock+=delta
	if stage==0 and system.world.flags.get("boss_weight_supported",false): advance()
	if stage<2 and shot_clock>=2.8:
		shot_clock=0
		system.shoot(Vector2(272,120),Vector2.LEFT)
	if stage==2:
		var p:=fmod(clock,3.0)
		if p>.9 and p<1.35:
			var safe: bool=system.world.player.position.y<=161 or system.world.player.position.x<54 or system.world.player.position.x>274
			if not safe: system.world.player.take_damage()
			if pulse_redirected and WorldProgress.missing_inputs(system.world.flags).is_empty(): advance()
	queue_redraw()

func advance() -> void:
	stage+=1;clock=0;shot_clock=0
	status.stage=stage
	status["node_a" if stage==1 else ("node_b" if stage==2 else "node_c")]=true
	# Each repaired node is a generous combat checkpoint, not an attrition tax.
	system.world.player.health=3
	system.world.player.invulnerable=1.4
	system.world.player.health_changed.emit(3)
	system.world.sound_requested.emit("unlock")
	var hints: Array[String]=["","节点 A 已解除 · 调整镜片，让核心的弹击中第二节点","节点 B 已解除 · 到右侧反接脉冲，站绝缘高台等蓄力结束","护罩解除 · 关闭地面核心开关，或用螯击修复它"]
	system.world.message.emit(hints[stage] if stage<4 else "核心保护程序已恢复")
	system.world.progress_changed.emit()

func receive(shot: SignalProjectile) -> bool:
	if stage==1 and shot.reflected and shot.position.distance_to(Vector2(176,184))<11:
		advance();return true
	return false

func candidates() -> Array[Dictionary]:
	if stage==2: return [{"type":"mechanism","position":[288,160],"object":{"id":"core_reverse","type":"core"},"prompt":"E  反接 SIGNAL 脉冲 · 随后站在绝缘高台"}]
	if stage==3: return [{"type":"mechanism","position":[208,208],"object":{"id":"core_close","type":"core"},"prompt":"E  关闭错误隔离核心 · 恢复守护程序"}]
	return []

func interact() -> void:
	if stage==2:
		if not WorldProgress.missing_inputs(system.world.flags).is_empty():
			system.world.message.emit("反向脉冲缺少："+WorldProgress.missing_inputs(system.world.flags));return
		pulse_redirected=true
		system.world.message.emit("脉冲已反接 · 站在两侧绝缘台，等 0.9 秒预警结束")
	elif stage==3: disable_core()

func attack(p: Vector2) -> void:
	if stage!=3 or p.distance_to(Vector2(208,192))>35: return
	core_health-=1
	system.world.sound_requested.emit("hit")
	if core_health<=0: disable_core()

func disable_core() -> void:
	if closing or stage==4: return
	closing=true
	# Main owns the durable delivery transaction. No chest or random reward is involved.
	system.latch("error_core_disabled")
	stage=4;status.stage=4
	system.world.message.emit("错误核心已修复 · 正在提交最后一段通信链")
	queue_redraw()

func reset_attempt() -> void:
	if system.world.flags.get("error_core_disabled",false): return
	stage=0;status.stage=0;clock=0;shot_clock=0;core_health=3;pulse_redirected=false;closing=false

func _draw() -> void:
	var green:=Color("54cfc3");var violet:=Color("858acb");var ink:=Color("182235");var red:=Color("ed839c")
	for side in [-1,1]:
		var flap: float=0 if stage==4 else sin(clock*3)*4
		var wing:=PackedVector2Array([Vector2(side*9,-9),Vector2(side*51,-34-flap),Vector2(side*45,25),Vector2(side*14,20)])
		draw_colored_polygon(wing,Color("486092"))
		for i in range(3): draw_line(Vector2(side*16,-4+i*6),Vector2(side*40,-18+i*10),violet,1)
		draw_line(Vector2(side*14,12),Vector2(side*30,32),Color("acafba"),3)
	draw_circle(Vector2.ZERO,24,ink)
	for i in range(12):
		var v:=Vector2.from_angle(i*TAU/12+clock*.25)
		draw_line(v*20,v*27,Color("7989a2"),3)
	draw_circle(Vector2.ZERO,15,Color("b2b6c2"));draw_circle(Vector2.ZERO,9,green if stage>=3 else red)
	for x in [-9,9]: draw_rect(Rect2(x-3,-24,6,6),green if stage==4 else Color("e6d48b"))
	var font:=preload("res://assets/fonts/fusion-pixel.otf")
	draw_string(font,Vector2(-90,-49),"BSOD CICADA / "+("REPAIRED" if stage==4 else ("SHIELD %d / 3"%(3-stage) if stage<3 else "CORE EXPOSED")),HORIZONTAL_ALIGNMENT_LEFT,-1,12,green if stage>=3 else Color("c7bdd6"))
	for i in range(3): draw_circle(Vector2(-20+i*20,44),4,green if stage>i else red)
	if stage==1:
		draw_line(Vector2(-32,32),Vector2(-32,96),Color("54cfc344"),1)
		draw_rect(Rect2(-40,88,16,16),red,false,2)
	if stage==2:
		var cue:=fmod(clock,3.0)<.9
		draw_line(Vector2(-140,111),Vector2(66,111),Color("efcd7966") if cue else Color("ed839c99"),1 if cue else 3)
		draw_string(font,Vector2(-120,66),"PULSE IN .9s / INSULATE" if cue else "REVERSE PULSE",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("efcd79"))
	if stage>=3:
		draw_rect(Rect2(-12,102,24,18),ink)
		draw_rect(Rect2(-8,105,16,10),green,false,2)

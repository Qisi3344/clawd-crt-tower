class_name ScreenWorld
extends Node3D

signal message(text: String)
signal prompt_changed(text: String)
signal travel_requested(link: Dictionary)
signal progress_changed
signal sound_requested(kind: String)
var screen_id := "BOOT"
var player: CrabPlayer
var camera: Camera3D
var flags: Dictionary = {}
var links: Array = []
var state: Dictionary = {}
var enabled := false
var objects: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var portal_nodes: Array[Node3D] = []
var nearest: Dictionary = {}
var last_prompt := ""
var elapsed := 0.0
var yaw := 0.0
var target_yaw := 0.0
var accent := Color("52d5b1")
var signal_lamp: MeshInstance3D
var fragment: Node3D

func _ready() -> void:
	accent = Color("52d5b1") if screen_id == "BOOT" else Color("ad92e7")
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("152d39") if screen_id == "BOOT" else Color("28213e")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("d8dbf1")
	env.ambient_light_energy = 0.68
	environment.environment = env
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50,-35,0)
	light.light_color = Color("dce9e0")
	light.light_energy = 1.0
	add_child(light)
	_build_level()
	player = CrabPlayer.new()
	add_child(player)
	player.spawn = Vector3(-4.5,0.15,4.5)
	player.position = player.spawn
	player.struck.connect(_attack)
	player.died.connect(_on_death)
	player.health_changed.connect(func(_hp: int): sound_requested.emit("hurt"))
	camera = Camera3D.new()
	camera.fov = 47
	camera.near = 0.1
	add_child(camera)
	camera.current = true
	_snap_camera()
	_refresh_visuals()

func _build_level() -> void:
	var floor_color := Color("254c55") if screen_id == "BOOT" else Color("423754")
	Craft.solid(self,Vector3(0,-0.3,0),Vector3(15,0.6,15),floor_color)
	# Floor traces are real geometry; no second 3D world is in WorldShell.
	for i in range(-7,8):
		Craft.box(self,Vector3(i,0.009,0),Vector3(0.018,0.012,14.8),accent.darkened(0.63),0.001)
		Craft.box(self,Vector3(0,0.01,i),Vector3(14.8,0.012,0.018),accent.darkened(0.63),0.001)
	for side in [-1,1]:
		Craft.solid(self,Vector3(side*7.6,0.225,0),Vector3(0.4,0.45,15.6),floor_color.lightened(0.08))
		Craft.solid(self,Vector3(0,0.225,side*7.6),Vector3(15.6,0.45,0.4),floor_color.lightened(0.08))
		for i in range(-6,7,3):
			Craft.box(self,Vector3(i,0.10,side*7.2),Vector3(1.1,0.18,0.12),accent,0.02,0.4)
	if screen_id == "BOOT":
		for p in [Vector3(-1,0.35,1),Vector3(0.6,0.65,0.1),Vector3(2,0.95,-0.8)]:
			Craft.solid(self,p,Vector3(1.4,p.y*2,1.6),Color("517b77"))
		Craft.label(self,"BOOT / 01",Vector3(0,2.6,-7.35),accent,0.015,48)
		var terminal := _terminal(Vector3(-4.8,0,-2.8),Color("56978d"))
		signal_lamp = Craft.box(terminal,Vector3(0,1.45,0.46),Vector3(0.6,0.22,0.04),Color("f2c44a"),0.015,0.4)
		objects.append({"type":"signal","position":Vector3(-4.8,0,-2.8),"prompt":"E  唤醒信号节点"})
		for z in range(-2,5):
			Craft.box(self,Vector3(-4.8,0.022,z),Vector3(0.09,0.025,0.65),accent,0.01,0.2)
		Craft.label(self,"SIGNAL",Vector3(-4.8,2.15,-2.8),accent,0.007)
		Craft.label(self,"W A S D\nMOVE",Vector3(-4.8,0.026,5.9),accent,0.006).rotation_degrees.x = -90
		for i in range(3):
			Craft.solid(self,Vector3(4.2+i*0.6,0.35,2.8),Vector3(0.35,0.7,0.35),Color("4b7175"))
	else:
		Craft.label(self,"ARCHIVE / 02",Vector3(0,2.6,-7.35),accent,0.013,48)
		for x in [-5.8,-2.7,2.8,5.8]:
			var cabinet := Craft.solid(self,Vector3(x,1.2,-5.6),Vector3(1.6,2.4,1.1),Color("756e91"))
			for y in [0.3,-0.4]:
				Craft.box(cabinet,Vector3(0,y,0.57),Vector3(1.38,0.58,0.08),Color("514767"),0.02)
				Craft.box(cabinet,Vector3(0,y,0.63),Vector3(0.36,0.07,0.04),accent,0.01)
		for p in [Vector3(-2,0.3,1.4),Vector3(3.3,0.45,-0.7)]:
			Craft.solid(self,p,Vector3(1.5,p.y*2,1.3),Color("817393"))
		fragment = Node3D.new()
		fragment.position = Vector3(4.5,0.8,-3)
		add_child(fragment)
		Craft.box(fragment,Vector3.ZERO,Vector3(0.65,0.85,0.12),Color("f2d97c"),0.04,0.4)
		for y in [-0.1,0.1]:
			Craft.box(fragment,Vector3(0,y,0.08),Vector3(0.35,0.05,0.02),Color("a08554"),0.004)
		objects.append({"type":"fragment","position":Vector3(4.5,0,-3),"prompt":"E  拾取遗失记录"})
		_spawn_enemy("popup",Vector3(0.4,0,2.7))
		_spawn_enemy("crawler",Vector3(2.2,0,-2.8))
	for link in links:
		if link.from != screen_id:
			continue
		var p := _vec(link.position)
		var gate := Node3D.new()
		gate.position = p
		add_child(gate)
		for side in [-1,1]:
			Craft.box(gate,Vector3(side*0.8,0.85,0),Vector3(0.2,1.7,0.3),Color("56858a"),0.04)
		Craft.box(gate,Vector3(0,1.8,0),Vector3(1.8,0.18,0.3),accent,0.04,0.5)
		Craft.box(gate,Vector3(0,0.045,0),Vector3(1.8,0.07,1.2),accent,0.025,0.2)
		Craft.label(gate,"↑ "+str(link.to),Vector3(0,2.25,0),accent,0.0055)
		portal_nodes.append(gate)
		objects.append({"type":"portal","position":p,"prompt":"E  "+str(link.label),"link":link})

func _terminal(p: Vector3, color: Color) -> Node3D:
	var terminal := Craft.solid(self,p+Vector3(0,0.55,0),Vector3(1.15,1.1,0.85),color)
	Craft.box(terminal,Vector3(0,0.65,0),Vector3(1.3,0.9,0.8),color,0.08)
	Craft.box(terminal,Vector3(0,0.67,0.42),Vector3(0.95,0.58,0.035),Color("102d36"),0.035)
	return terminal

func _spawn_enemy(kind: String, p: Vector3) -> void:
	var id := kind
	if state.get("defeated",[]).has(id):
		return
	var node := Node3D.new()
	node.position = p
	add_child(node)
	var color := Color("eb6870") if kind == "popup" else Color("f2b85d")
	Craft.box(node,Vector3(0,0.5,0),Vector3(0.85,0.72,0.65),color,0.06)
	Craft.box(node,Vector3(0,0.78,0.35),Vector3(0.65,0.10,0.035),color.lightened(0.3),0.01,0.3)
	Craft.label(node,"×",Vector3(0,0.5,0.36),Color("402e48"),0.012,40)
	for x in [-0.35,0.35]:
		Craft.box(node,Vector3(x,0.13,0),Vector3(0.2,0.2,0.7),color.darkened(0.25),0.03)
	enemies.append({"id":id,"kind":kind,"node":node,"health":2,"cooldown":0.0,"time":0.0,"charge_dir":Vector3.ZERO,"origin":p})

func _physics_process(delta: float) -> void:
	player.enabled = enabled
	if not enabled:
		return
	elapsed += delta
	_update_camera(delta)
	_update_enemies(delta)
	if is_instance_valid(fragment) and fragment.visible:
		fragment.position.y = 0.9 + sin(elapsed*2.8)*0.12
		fragment.rotation.y = sin(elapsed)*0.3
	nearest = {}
	var best := 1.8
	for object in objects:
		if object.type == "fragment" and flags.get("record",false):
			continue
		if object.type == "signal" and flags.get("signal",false):
			continue
		var distance: float = Vector2(player.position.x,player.position.z).distance_to(Vector2(object.position.x,object.position.z))
		if distance < best:
			best = distance
			nearest = object
	var prompt := str(nearest.get("prompt",""))
	if prompt != last_prompt:
		last_prompt = prompt
		prompt_changed.emit(prompt)
	if Input.is_action_just_pressed("interact"):
		interact()

func interact() -> void:
	if not enabled or nearest.is_empty():
		return
	match nearest.type:
		"signal":
			flags.signal = true
			message.emit("信号已接通。去右后方的接口，寻找另一块屏幕。")
			_refresh_visuals()
			progress_changed.emit()
			sound_requested.emit("unlock")
		"fragment":
			if not enemies.is_empty():
				message.emit("记录被病毒锁定了。先用 J 或左键清除两只病毒。")
				return
			flags.record = true
			_refresh_visuals()
			message.emit("找回记录：「每一块屏幕，都是一座岛。」可以返回启动区了。")
			progress_changed.emit()
			sound_requested.emit("unlock")
		"portal":
			var required: String = nearest.link.requires
			if required != "" and not flags.get(required,false):
				message.emit("接口没有信号。先到左后方终端按 E 唤醒节点。")
				return
			travel_requested.emit(nearest.link)

func _attack() -> void:
	sound_requested.emit("attack")
	for i in range(enemies.size()-1,-1,-1):
		var enemy: Dictionary = enemies[i]
		var node: Node3D = enemy.node
		var offset := node.position - player.position
		if offset.length() > 2.0 or absf(offset.y) > 1.5:
			continue
		var forward := Vector3(sin(player.avatar.rotation.y),0,cos(player.avatar.rotation.y))
		if offset.normalized().dot(forward) < -0.2:
			continue
		enemy.health -= 1
		enemy.cooldown = 0.6
		node.position += offset.normalized()*0.65
		sound_requested.emit("hit")
		if enemy.health <= 0:
			var defeated: Array = state.get("defeated",[])
			defeated.append(enemy.id)
			state.defeated = defeated
			node.queue_free()
			enemies.remove_at(i)
			progress_changed.emit()
			if enemies.is_empty():
				message.emit("弹窗已关闭。右后方的遗失记录可以拾取了。")

func _update_enemies(delta: float) -> void:
	for enemy in enemies:
		var node: Node3D = enemy.node
		enemy.time += delta
		enemy.cooldown = maxf(0,enemy.cooldown-delta)
		var offset := player.position-node.position
		offset.y = 0
		if enemy.cooldown > 0:
			node.scale = Vector3.ONE*(0.9+sin(elapsed*40)*0.05)
			continue
		node.scale = Vector3.ONE
		if enemy.kind == "popup":
			if offset.length() > 0.7:
				node.position += offset.normalized()*delta*1.45
			node.position.y = absf(sin(enemy.time*5))*0.38
		else:
			var phase: float = fmod(enemy.time,3.2)
			if phase < 1.5:
				enemy.charge_dir = offset.normalized()
				node.rotation.z = sin(enemy.time*22)*0.09
			elif phase < 2.1:
				node.position += enemy.charge_dir*delta*6.0
			else:
				node.rotation.z = 0
		node.position.x = clampf(node.position.x,-6.5,6.5)
		node.position.z = clampf(node.position.z,-4.6,6.5)
		if offset.length() < 0.95 and absf(player.position.y-node.position.y) < 0.9:
			player.take_damage()

func _on_death() -> void:
	message.emit("连接中断……已在当前屏幕入口重新连接。")
	player.respawn()
	for enemy in enemies:
		enemy.node.position = enemy.origin
		enemy.cooldown = 1.5
	_snap_camera()

func _update_camera(delta: float) -> void:
	yaw = lerp_angle(yaw,target_yaw,1-exp(-delta*5))
	player.camera_yaw = yaw
	var focus := player.position+Vector3(0,0.55,0)
	var offset := Vector3(0,4.1,6.2).rotated(Vector3.UP,yaw)
	camera.position = camera.position.lerp(focus+offset,1-exp(-delta*7))
	camera.look_at(focus)

func _snap_camera() -> void:
	camera.position = player.position+Vector3(0,4.65,6.2)
	camera.look_at(player.position+Vector3(0,0.55,0))

func _refresh_visuals() -> void:
	if is_instance_valid(signal_lamp):
		signal_lamp.material_override = Craft.material(accent if flags.get("signal",false) else Color("f2c44a"),0.5)
	if is_instance_valid(fragment):
		fragment.visible = not flags.get("record",false)

func snapshot() -> Dictionary:
	state.position = [player.position.x,player.position.y,player.position.z]
	return state.duplicate(true)

static func _vec(v: Array) -> Vector3:
	return Vector3(float(v[0]),float(v[1]),float(v[2]))

class_name SideWorld
extends Node2D

signal message(text: String)
signal prompt_changed(text: String)
signal travel_requested(link: Dictionary)
signal progress_changed
signal sound_requested(kind: String)
signal room_requested(portal: Dictionary)
var screen_id := "BOOT"
var level_id := "boot_01"
var definition: Dictionary = {}
var session: Dictionary = {}
var flags: Dictionary = {}
var links: Array = []
var state: Dictionary = {}
var enabled := false
var player: SideCrab
var camera: Camera2D
var blocks: Array[PuzzleBlock] = []
var ladder_platforms: Array[StaticBody2D] = []
var enemies: Array[DataBug] = []
var plates: Array[Dictionary] = []
var doors: Array[Dictionary] = []
var chests: Array[Dictionary] = []
var breakables: Array[Dictionary] = []
var crystals: Array[Dictionary] = []
var nearest: Dictionary = {}
var last_prompt := ""
var elapsed := 0.0
var plate_settle := 0.0
var room_id := ""
var room_states: Dictionary = {}
var world_size := Vector2(768,240)
var mechanisms: ChapterMechanics

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	world_size = Vector2(definition.get("size",[768,240])[0],definition.get("size",[768,240])[1])
	for field in ["broken","defeated"]:
		if not state.get(field) is Array: state[field] = []
	if not state.get("blocks") is Dictionary: state.blocks = {}
	var bg := Sprite2D.new()
	bg.texture = load("res://assets/pixel/background_"+str(definition.background)+".png")
	bg.centered = false
	bg.z_index = -10
	add_child(bg)
	for platform in definition.platforms: _solid(Rect2(platform[0],platform[1],platform[2],platform[3]))
	_solid(Rect2(-16,0,16,world_size.y+16))
	_solid(Rect2(world_size.x,0,16,world_size.y+16))
	for ladder in definition.ladders:
		for y in range(int(ladder.top),int(ladder.bottom),32): PixelArt.sprite(self,14,Vector2(ladder.x,y+16))
	for entry in definition.blocks:
		var block := PuzzleBlock.new()
		block.block_id = entry.id
		block.weight = int(entry.weight)
		block.origin = point(entry.position)
		block.position = point(state.blocks.get(entry.id,entry.position),block.origin)
		block.level = self
		add_child(block)
		blocks.append(block)
	for entry in definition.plates:
		var plate: Dictionary = entry.duplicate(true)
		plate.sprite = PixelArt.sprite(self,11,point(entry.position)+Vector2(0,-7))
		plate.active = false
		plates.append(plate)
	for entry in definition.doors:
		var door: Dictionary = entry.duplicate(true)
		var body := StaticBody2D.new()
		body.position = point(entry.position)
		add_child(body)
		var collider := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16,entry.height)
		collider.shape = shape
		collider.position.y = -entry.height/2.0
		body.add_child(collider)
		var visual := Node2D.new()
		body.add_child(visual)
		for y in range(0,int(entry.height),32): PixelArt.sprite(visual,12,Vector2(0,-16-y))
		door.collider = collider
		door.visual = visual
		door.open = false
		doors.append(door)
	for entry in definition.chests:
		var chest: Dictionary = entry.duplicate(true)
		chest.sprite = PixelArt.sprite(self,7 if session.collected.has(entry.id) else 6,point(entry.position)+Vector2(0,-11))
		chests.append(chest)
	for entry in definition.breakables:
		if state.broken.has(entry.id): continue
		var block: Dictionary = entry.duplicate(true)
		var body := StaticBody2D.new()
		body.position = point(entry.position)
		add_child(body)
		var collision := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		shape.size = Vector2(16,16)
		collision.shape = shape
		body.add_child(collision)
		PixelArt.sprite(body,16)
		block.body = body
		breakables.append(block)
	for entry in definition.crystals:
		if session.pickups.has(entry.id): continue
		var crystal: Dictionary = entry.duplicate(true)
		crystal.sprite = PixelArt.sprite(self,15,point(entry.position))
		crystals.append(crystal)
	for entry in definition.terminals: PixelArt.sprite(self,13,point(entry.position)+Vector2(0,-16))
	for link in links:
		if link.from==screen_id and str(link.get("room",""))==room_id: PixelArt.sprite(self,13,point(link.position)+Vector2(0,-16))
	for portal in definition.get("room_portals",[]): PixelArt.sprite(self,13,point(portal.position)+Vector2(0,-16))
	player = SideCrab.new()
	player.level = self
	player.spawn = point(definition.spawns.entrance)
	player.position = player.spawn
	add_child(player)
	player.struck.connect(_attack)
	player.died.connect(_on_death)
	for entry in definition.enemies:
		if state.defeated.has(entry.id): continue
		var bug := DataBug.new()
		bug.bug_id = entry.id
		bug.position = point(entry.position)
		bug.origin = bug.position
		bug.level = self
		add_child(bug)
		enemies.append(bug)
	camera = Camera2D.new()
	add_child(camera)
	camera.enabled = true
	_snap_camera()
	if definition.has("mechanisms") or definition.has("animals"):
		mechanisms=ChapterMechanics.new();mechanisms.world=self;add_child(mechanisms)
	_update_plates()
	queue_redraw()

func _solid(rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.position = rect.position+rect.size/2
	add_child(body)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = rect.size
	shape.shape = box
	shape.one_way_collision = rect.position.y<208 and rect.position.y>0
	if shape.one_way_collision: ladder_platforms.append(body)
	body.add_child(shape)
	for x in range(int(rect.position.x),int(rect.end.x),16):
		for y in range(int(rect.position.y),int(rect.end.y),16): PixelArt.tile(self,Vector2(x,y),screen_id=="ARCHIVE",(x/16)%8)

func _physics_process(delta: float) -> void:
	player.enabled = enabled
	if not enabled: return
	elapsed += delta
	plate_settle += delta
	_update_plates()
	_snap_camera()
	_update_prompt()
	for i in range(crystals.size()-1,-1,-1):
		var crystal: Dictionary = crystals[i]
		crystal.sprite.texture = PixelArt.frame(15,int(elapsed*8))
		if player.position.distance_to(point(crystal.position)+Vector2(0,10))<18:
			session.pickups.append(crystal.id)
			session.crystals += 1
			pickup_burst(crystal.sprite.position)
			crystal.sprite.queue_free()
			crystals.remove_at(i)
			sound_requested.emit("unlock")
			progress_changed.emit()
	if Input.is_action_just_pressed("interact"): interact()
	if Input.is_action_just_pressed("reset_puzzle"): reset_puzzle()

func _update_plates() -> void:
	var changed := false
	for plate in plates:
		var p := point(plate.position)
		var total := 0
		for block in blocks:
			if absf(block.position.x-p.x)<10 and absf(block.position.y+8-p.y)<3 and absf(block.velocity.y)<2: total += block.weight
		if is_instance_valid(player) and absf(player.position.x-p.x)<11 and absf(player.position.y-p.y)<3: total += player.weight
		if is_instance_valid(mechanisms):
			for animal in mechanisms.animals:
				if is_instance_valid(animal) and not animal.defeated and absf(animal.position.x-p.x)<11 and absf(animal.position.y-p.y)<4: total+=animal.weight
		var active: bool = total>=int(plate.weight)
		if plate.active!=active:
			plate.active = active
			plate.sprite.texture = PixelArt.frame(11,1 if active else 0)
			if plate_settle>0.1: sound_requested.emit("unlock")
		if flags.get(plate.flag,false)!=active:
			flags[plate.flag] = active
			changed = true
	for door in doors:
		var open: bool = flags.get(door.requires,false)
		if door.open!=open:
			door.open = open
			door.collider.set_deferred("disabled",open)
			door.visual.modulate = Color(0.5,1,0.8,0.12) if open else Color.WHITE
	if changed:
		queue_redraw()
		if plate_settle>0.1: progress_changed.emit()

func try_push(actor: SideCrab, axis: float, grab: bool) -> bool:
	if not grab or axis==0: return false
	for block in blocks:
		var offset := block.position-(actor.position-Vector2(0,8))
		if absf(offset.x)<26 and absf(offset.y)<9 and signf(offset.x)==actor.facing:
			if int(signf(axis))!=actor.facing and actor.test_move(actor.transform,Vector2(axis*16,0)): return false
			block.request_step(int(signf(axis)))
			return true
	return false

func ladder_at(p: Vector2) -> Dictionary:
	for ladder in definition.ladders:
		if absf(p.x-float(ladder.x))<10 and p.y>float(ladder.top)-7 and p.y<float(ladder.bottom)+2: return ladder
	return {}

func _update_prompt() -> void:
	nearest = {}
	var distance := 27.0
	var candidates: Array[Dictionary] = []
	for chest in chests:
		if not session.collected.has(chest.id): candidates.append({"type":"chest","position":chest.position,"object":chest,"prompt":"E  打开宝箱"})
	for terminal in definition.terminals: candidates.append({"type":"heal","position":terminal.position,"prompt":"E  用 1 晶体恢复 1 点生命"})
	for link in links:
		if link.from==screen_id and str(link.get("room",""))==room_id: candidates.append({"type":"portal","position":link.position,"object":link,"prompt":"E  "+str(link.label)})
	for portal in definition.get("room_portals",[]): candidates.append({"type":"room","position":portal.position,"object":portal,"prompt":"E  "+str(portal.label)})
	if is_instance_valid(mechanisms): candidates.append_array(mechanisms.candidates())
	for candidate in candidates:
		var dist := player.position.distance_to(point(candidate.position))
		if dist<distance:
			distance = dist
			nearest = candidate
	var prompt := str(nearest.get("prompt",""))
	if prompt=="":
		for block in blocks:
			if block.position.distance_to(player.position-Vector2(0,8))<27: prompt = "按住 E + A/D 推拉 · R 重置谜题"
	if prompt!=last_prompt:
		last_prompt = prompt
		prompt_changed.emit(prompt)

func interact() -> void:
	if not enabled or nearest.is_empty(): return
	match nearest.type:
		"mechanism":
			mechanisms.interact(nearest.object)
		"chest":
			var chest: Dictionary = nearest.object
			if session.collected.has(chest.id): return
			session.collected.append(chest.id)
			session.crystals += int(chest.crystals)
			flags[chest.flag] = true
			chest.sprite.texture = PixelArt.frame(7)
			pickup_burst(chest.sprite.position)
			message.emit("宝箱已记录 · +%d 晶体"%int(chest.crystals))
			if ["boot_access","boot_remote","archive_key","archive_hidden"].all(func(id): return session.collected.has(id)) and not flags.get("slice_complete",false):
				flags.slice_complete = true
				message.emit("旧区四个宝箱已记录 · 带着档案密钥前往 POP-UP。")
			sound_requested.emit("unlock")
			progress_changed.emit()
		"heal":
			if player.health>=3: message.emit("生命已满，保留晶体。")
			elif session.crystals<1: message.emit("需要 1 个晶体。")
			else:
				session.crystals -= 1
				player.health += 1
				player.health_changed.emit(player.health)
				progress_changed.emit()
		"portal":
			var link: Dictionary = nearest.object
			if str(link.requires)!="" and not flags.get(link.requires,false):
				message.emit(str(link.locked_hint))
				return
			travel_requested.emit(link)
		"room":
			var portal: Dictionary = nearest.object
			if not str(portal.get("requires","")).is_empty() and not flags.get(portal.requires,false):
				message.emit(str(portal.get("locked_hint","先完成当前房间的机关。")))
				return
			room_requested.emit(portal)

func _attack() -> void:
	sound_requested.emit("attack")
	if is_instance_valid(mechanisms): mechanisms.attack()
	for bug in enemies.duplicate():
		var offset: Vector2 = bug.position-player.position
		if absf(offset.x)<31 and absf(offset.y)<23 and offset.x*player.facing>-5: bug.hit()
	for i in range(breakables.size()-1,-1,-1):
		var block: Dictionary = breakables[i]
		var offset: Vector2 = block.body.position-(player.position-Vector2(0,8))
		if absf(offset.x)<28 and absf(offset.y)<24 and offset.x*player.facing>-4:
			state.broken.append(block.id)
			block.body.queue_free()
			breakables.remove_at(i)
			sound_requested.emit("hit")
			progress_changed.emit()

func reset_puzzle() -> void:
	if not enabled: return
	for block in blocks: block.reset()
	if is_instance_valid(mechanisms): mechanisms.reset_local()
	player.position = player.spawn
	player.velocity = Vector2.ZERO
	player.climbing = false
	_update_plates()
	_snap_camera()
	progress_changed.emit()
	message.emit("当前箱石谜题已复位；宝箱、密钥和晶体保留。")

func _on_death() -> void:
	player.respawn()
	_snap_camera()
	message.emit("已在当前屏幕检查点重连，机关与宝箱进度保留。")

func _snap_camera() -> void:
	camera.position = Vector2(clampf(roundf(player.position.x+56),160,world_size.x-160),120)
	camera.reset_smoothing()

func snapshot() -> Dictionary:
	state.position = [player.position.x,player.position.y]
	state.blocks = {}
	for block in blocks: state.blocks[block.block_id] = block.snapshot()
	if not room_id.is_empty():
		room_states[room_id] = state.duplicate(true)
		return {"room_id":room_id,"rooms":room_states.duplicate(true)}
	return state.duplicate(true)

func _draw() -> void:
	var font := preload("res://assets/fonts/fusion-pixel.otf")
	for sign in definition.get("signs",[]): draw_string(font,Vector2(sign[0],sign[1]),str(sign[2]),HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("aec8ba"))
	for plate in plates:
		if int(plate.weight)<2: continue
		var p := point(plate.position)-Vector2(0,15)
		var color := Color("54cfc3") if plate.active else Color("dce65b")
		for y in range(int(p.y)-35,int(p.y)-7,6): draw_line(Vector2(p.x,y),Vector2(p.x,y+2),color)
		draw_line(p-Vector2(5,5),p,color)
		draw_line(p-Vector2(-5,5),p,color)

static func point(value, fallback := Vector2.ZERO) -> Vector2:
	if value is Array and value.size()==2 and value.all(func(v): return v is float or v is int):
		var p := Vector2(float(value[0]),float(value[1]))
		if p.is_finite() and p.x>=0 and p.x<=768 and p.y>=0 and p.y<=256: return p
	return fallback

func pickup_burst(pos: Vector2) -> void:
	for i in range(10):
		var pixel := Polygon2D.new(); pixel.polygon = PackedVector2Array([Vector2(-1,-1),Vector2(1,-1),Vector2(1,1),Vector2(-1,1)]); pixel.color = Color("ffc478") if i%2==0 else Color("f4e7cf"); pixel.position = pos; pixel.z_index = 12; add_child(pixel)
		var tween := create_tween().set_parallel()
		tween.tween_property(pixel,"position",pos+Vector2(cos(i*TAU/10)*18,-12+sin(i*TAU/10)*14),0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(pixel,"modulate:a",0.0,0.3).set_delay(0.1)
		tween.chain().tween_callback(pixel.queue_free)

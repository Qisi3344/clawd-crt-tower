class_name SideCrab
extends CharacterBody2D

signal health_changed(value: int)
signal died
signal struck
var enabled := false
var health := 3
var weight := 1
var facing := 1
var invulnerable := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var jump_buffer := 0.0
var coyote := 0.0
var spawn := Vector2.ZERO
var sprite: Sprite2D
var animation_time := 0.0
var climbing := false
var pushing := false
var level: SideWorld

func _ready() -> void:
	name = "OnlyControllableCrab"
	add_to_group("player")
	collision_layer = 2
	collision_mask = 5
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12,18)
	shape.shape = rect
	shape.position.y = -9
	add_child(shape)
	sprite = PixelArt.sprite(self,0,Vector2(0,-12))
	floor_snap_length = 3
	z_index = 8

func _physics_process(delta: float) -> void:
	if not enabled: return
	invulnerable = maxf(0,invulnerable-delta)
	attack_time = maxf(0,attack_time-delta)
	attack_cooldown = maxf(0,attack_cooldown-delta)
	jump_buffer = maxf(0,jump_buffer-delta)
	coyote = 0.10 if is_on_floor() else maxf(0,coyote-delta)
	var axis := Input.get_axis("move_left","move_right")
	var vertical := Input.get_axis("move_up","move_down")
	var grab := Input.is_action_pressed("interact")
	if axis != 0 and not grab: facing = int(signf(axis))
	pushing = level.try_push(self,axis,grab)
	velocity.x = move_toward(velocity.x,axis*(48 if pushing else 88),delta*850)
	if Input.is_action_just_pressed("jump"): jump_buffer = 0.1
	var ladder := level.ladder_at(position)
	if not ladder.is_empty() and vertical != 0:
		climbing = true
	if climbing:
		if ladder.is_empty() or Input.is_action_just_pressed("jump"):
			climbing = false
		else:
			velocity.y = vertical*65
			position.x = move_toward(position.x,float(ladder.x),delta*75)
	if not climbing:
		velocity.y = minf(velocity.y+580*delta,320)
		if jump_buffer>0 and coyote>0:
			velocity.y = -228
			coyote = 0
			jump_buffer = 0
	if Input.is_action_just_pressed("attack") and attack_cooldown<=0:
		attack_time = 0.22
		attack_cooldown = 0.32
		struck.emit()
	move_and_slide()
	animation_time += delta
	var row := 0
	if absf(velocity.x)>1 or climbing: row = 1
	if not is_on_floor() and not climbing: row = 2
	if pushing: row = 4
	if attack_time>0: row = 3
	if invulnerable>0: row = 5
	sprite.texture = PixelArt.frame(row,int(animation_time*10))
	sprite.flip_h = facing<0
	sprite.visible = invulnerable<=0 or int(invulnerable*14)%2==0
	if position.y>280: take_damage(3,true)

func take_damage(amount: int = 1, forced: bool = false) -> void:
	if not enabled or (invulnerable>0 and not forced): return
	health = maxi(0,health-amount)
	level.sound_requested.emit("hurt")
	invulnerable = 1.1
	health_changed.emit(health)
	if health<=0: died.emit()
	else:
		velocity = Vector2(-facing*80,-120)

func respawn() -> void:
	position = spawn
	velocity = Vector2.ZERO
	climbing = false
	health = 3
	invulnerable = 1.1
	health_changed.emit(health)

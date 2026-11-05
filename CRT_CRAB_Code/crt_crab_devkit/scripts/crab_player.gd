class_name CrabPlayer
extends CharacterBody3D

signal health_changed(value: int)
signal died
signal struck
var avatar: CrabAvatar
var enabled := false
var health := 3
var invulnerable := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var camera_yaw := 0.0
var input_override := Vector2.ZERO
var spawn := Vector3.ZERO

func _ready() -> void:
	name = "OnlyControllableCrab"
	add_to_group("player")
	var collider := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.43
	shape.height = 1.02
	collider.shape = shape
	collider.position.y = 0.51
	add_child(collider)
	avatar = CrabAvatar.new()
	add_child(avatar)
	floor_snap_length = 0.22

func _physics_process(delta: float) -> void:
	invulnerable = maxf(0,invulnerable-delta)
	attack_time = maxf(0,attack_time-delta)
	attack_cooldown = maxf(0,attack_cooldown-delta)
	dash_time = maxf(0,dash_time-delta)
	dash_cooldown = maxf(0,dash_cooldown-delta)
	var axis := Input.get_vector("move_left","move_right","move_up","move_down") if enabled else Vector2.ZERO
	if input_override != Vector2.ZERO and enabled:
		axis = input_override
	var direction := Vector3(axis.x,0,axis.y).rotated(Vector3.UP,camera_yaw)
	if enabled and Input.is_action_just_pressed("dash") and dash_cooldown <= 0 and axis.length() > 0:
		dash_time = 0.19
		dash_cooldown = 0.75
		invulnerable = maxf(invulnerable,0.23)
	var speed := 10.0 if dash_time > 0 else 4.5
	velocity.x = move_toward(velocity.x,direction.x*speed,delta*35)
	velocity.z = move_toward(velocity.z,direction.z*speed,delta*35)
	if not is_on_floor():
		velocity.y -= delta*20
	elif enabled and Input.is_action_just_pressed("jump"):
		velocity.y = 7.2
	if enabled and Input.is_action_just_pressed("attack"):
		attack()
	if direction.length() > 0.1:
		avatar.rotation.y = lerp_angle(avatar.rotation.y,atan2(direction.x,direction.z),1-exp(-delta*15))
	move_and_slide()
	avatar.visible = invulnerable <= 0 or int(invulnerable*15)%2 == 0
	avatar.animate(delta,Vector2(velocity.x,velocity.z).length(),attack_time/0.24,invulnerable/1.1,not is_on_floor())
	if position.y < -5:
		take_damage(3)

func attack() -> void:
	if attack_cooldown > 0 or not enabled:
		return
	attack_time = 0.24
	attack_cooldown = 0.38
	struck.emit()

func take_damage(amount: int = 1) -> void:
	if invulnerable > 0 or not enabled:
		return
	health = maxi(0,health-amount)
	invulnerable = 1.1
	health_changed.emit(health)
	if health == 0:
		died.emit()

func respawn() -> void:
	position = spawn
	velocity = Vector3.ZERO
	health = 3
	invulnerable = 1.1
	health_changed.emit(health)

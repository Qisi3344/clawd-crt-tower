class_name PuzzleBlock
extends CharacterBody2D

var block_id := ""
var weight := 1
var origin := Vector2.ZERO
var target_x := 0.0
var sprite: Sprite2D
var level: SideWorld
var was_falling := false
var gravity_enabled := true

func _ready() -> void:
	collision_layer = 4
	collision_mask = 5
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(15.8,15.8)
	shape.shape = rect
	add_child(shape)
	sprite = PixelArt.sprite(self,10 if weight>=2 else 9)
	target_x = position.x
	floor_snap_length = 1
	z_index = 5

func request_step(direction: int) -> bool:
	if absf(target_x-position.x)>0.5 or not is_on_floor(): return false
	var step := Vector2(direction*16,0)
	if test_move(transform,step): return false
	target_x = position.x+step.x
	return true

func _physics_process(delta: float) -> void:
	if not level.enabled: return
	var dx := target_x-position.x
	velocity.x = clampf(dx/delta,-48,48) if absf(dx)>0.05 else 0
	velocity.y = minf(320,velocity.y+580*delta) if gravity_enabled else 0
	var fall_speed := velocity.y
	move_and_slide()
	if is_on_wall(): target_x = position.x
	if was_falling and is_on_floor(): level.sound_requested.emit("hit")
	was_falling = not is_on_floor() and fall_speed>40
	if fall_speed>80 and is_instance_valid(level.player):
		var p := level.player
		if absf(p.position.x-position.x)<13 and p.position.y-position.y>0 and p.position.y-position.y<26:
			p.take_damage(3)
	if position.y>260: reset()

func reset() -> void:
	position = origin
	target_x = origin.x
	velocity = Vector2.ZERO
	was_falling = false

func snapshot() -> Array:
	# At rest the saved block can reproduce a continuous pressure signal.
	return [position.x,position.y]

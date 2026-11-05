class_name DataBug
extends CharacterBody2D

var bug_id := ""
var level: SideWorld
var health := 2
var direction := -1
var stun := 0.0
var anim := 0.0
var origin := Vector2.ZERO
var sprite: Sprite2D

func _ready() -> void:
	collision_layer = 8
	collision_mask = 5
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(18,12)
	shape.position.y = -6
	shape.shape = rect
	add_child(shape)
	sprite = PixelArt.sprite(self,8,Vector2(0,-10))
	z_index = 6

func _physics_process(delta: float) -> void:
	if not level.enabled: return
	stun = maxf(0,stun-delta)
	anim += delta
	velocity.y += 580*delta
	velocity.x = direction*28 if stun<=0 else 0
	move_and_slide()
	if is_on_wall(): direction *= -1
	if position.x<origin.x-40: direction = 1
	if position.x>origin.x+40: direction = -1
	sprite.flip_h = direction<0
	sprite.texture = PixelArt.frame(8,int(anim*8))
	sprite.modulate = Color("ffffff") if stun<=0 else Color("f8d879")
	if absf(level.player.position.x-position.x)<14 and absf(level.player.position.y-position.y)<15 and stun<=0:
		level.player.take_damage()

func hit() -> void:
	if stun>0: return
	health -= 1
	stun = 0.35
	level.sound_requested.emit("hit")
	if health<=0:
		level.state.defeated.append(bug_id)
		level.enemies.erase(self)
		level.progress_changed.emit()
		queue_free()

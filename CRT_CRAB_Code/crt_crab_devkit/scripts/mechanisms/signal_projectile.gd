class_name SignalProjectile
extends Node2D

var velocity := Vector2(70,0)
var reflected := false
var age := 0.0
var last_reflector := ""
var system: ChapterMechanics

func _ready() -> void: z_index = 7
func _physics_process(delta: float) -> void:
	if not system.world.enabled: return
	age += delta
	var previous := position
	position += velocity*delta
	system.projectile_step(self,previous)
	if age>9 or position.x<0 or position.x>system.world.world_size.x or position.y<8 or position.y>system.world.world_size.y+8: queue_free()
	queue_redraw()
func _draw() -> void:
	var color := Color("54cfc3") if reflected else Color("ef8b9f")
	draw_rect(Rect2(-4,-3,8,6),Color("292338"))
	draw_rect(Rect2(-3,-2,6,4),color)
	draw_line(-velocity.normalized()*8,Vector2.ZERO,color.darkened(.4),2)

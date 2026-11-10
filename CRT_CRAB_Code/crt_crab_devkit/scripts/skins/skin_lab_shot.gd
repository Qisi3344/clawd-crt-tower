class_name SkinLabShot
extends Node2D
var player:SideCrab
var direction:=1
var remaining:=30.0
var life:=0.0
var style:="academy_crab"

func _ready() -> void:
	z_index=10;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _physics_process(delta:float) -> void:
	if not player.level.enabled: return
	var step:=minf(remaining,250*delta)
	var next:=position+Vector2(direction*step,0)
	var query:=PhysicsRayQueryParameters2D.create(global_position,get_parent().to_global(next),13,[player.get_rid()])
	query.hit_from_inside=true
	var hit:=get_world_2d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		if hit.collider is DataBug: hit.collider.hit()
		queue_free();return
	position=next;remaining-=step;life+=delta;queue_redraw()
	if remaining<=0: queue_free()

func _draw() -> void:
	if style=="music_crab":
		draw_arc(Vector2(-direction*2,0),4,-1.2 if direction>0 else 1.9,1.2 if direction>0 else 4.3,8,Color("d89aab"),1)
		draw_rect(Rect2(-1,-4,1,6),Color("e4c89f"));draw_rect(Rect2(-3,1,3,2),Color("e4c89f"));return
	if style=="player_one_crab":
		draw_rect(Rect2(-2,-2,4,4),Color("66cdc7"));draw_rect(Rect2(-direction*6,-1,2,2),Color("9b85c6"));return
	draw_colored_polygon(PackedVector2Array([Vector2(-3,0),Vector2(0,-3),Vector2(4,0),Vector2(0,3)]),Color("72b8a3"))
	draw_rect(Rect2(-1,-1,3,3),Color("d1d8fa"));draw_line(Vector2(-direction*7,0),Vector2.ZERO,Color("a6a8c9"),1)

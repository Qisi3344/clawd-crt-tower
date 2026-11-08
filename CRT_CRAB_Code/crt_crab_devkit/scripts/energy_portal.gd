class_name EnergyPortal
extends Node2D

var world: SideWorld
var link: Dictionary
var clock := 0.0

func _ready() -> void: z_index=3
func _process(delta: float) -> void:
	if world.enabled and not world.get_parent().get_parent().audio.reduced_motion: clock+=delta
	queue_redraw()

func _draw() -> void:
	var unlocked:bool=str(link.get("requires","")).is_empty() or world.flags.get(link.requires,false)
	var cyan:=Color("62dce6")
	var purple:=Color("b38bf2")
	# Compact feet leave the walkway readable. Energy has no collision body.
	draw_rect(Rect2(-15,-5,30,5),Color("171c2b"))
	draw_rect(Rect2(-12,-7,24,4),Color("68768b"))
	draw_line(Vector2(-10,-6),Vector2(10,-6),cyan,2)
	draw_rect(Rect2(-2,-4,4,2),Color("8dcabb") if unlocked else Color("efcd79"))
	for r in range(5,0,-1):
		var glow:=cyan;glow.a=.025*r
		draw_rect(Rect2(-11-r,-45,22+r*2,39),glow)
	var body:=purple;body.a=.22
	draw_rect(Rect2(-11,-45,22,38),body)
	draw_rect(Rect2(-3,-43,6,35),Color(cyan,.16))
	for x in [-11,11]: draw_line(Vector2(x,-44),Vector2(x,-8),Color(cyan,.7),1)
	for i in range(5):
		var y:float=-43+fposmod(i*8+clock*9,35)
		_ring(Vector2(0,y),11,2,Color(cyan,.4))
	for strand in range(2):
		var points:=PackedVector2Array()
		for i in range(37):
			var phase:=i*.28-clock*2.6+strand*PI
			points.append(Vector2(sin(phase)*8,-44+i))
		draw_polyline(points,cyan if strand==0 else purple,1.5)
	_ring(Vector2(0,-44),11,2,cyan)
	_ring(Vector2(0,-8),11,2,cyan)

func _ring(p: Vector2, rx: float, ry: float, color: Color) -> void:
	var points:=PackedVector2Array()
	for i in range(25): points.append(p+Vector2(cos(i*TAU/24)*rx,sin(i*TAU/24)*ry))
	draw_polyline(points,color,1)

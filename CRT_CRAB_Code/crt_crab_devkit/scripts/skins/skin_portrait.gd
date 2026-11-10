class_name SkinPortrait
extends Control
var skin_id:="classic_orange"
var row:=0
var clock:=0.0
var paused:=false
var body_only:=false
var frame_texture:Texture2D

func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE;custom_minimum_size=Vector2(128,112);texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta:float) -> void:
	if not paused: clock+=delta
	queue_redraw()

func _draw() -> void:
	var scale:=floorf(minf(size.x/52.0,size.y/38.0));scale=maxf(1,scale)
	draw_set_transform((size*.5).floor(),0,Vector2.ONE*scale)
	var index:=int(clock*8)%8
	if not body_only: SkinDrafts.paint(self,skin_id,row,index,float(index)/7.0,true)
	frame_texture=SkinDrafts.body(row,index) if body_only or skin_id!="classic_orange" else Cosmetics.frame("classic_orange",row,index)
	draw_texture(frame_texture,Vector2(-16,-16))
	if not body_only: SkinDrafts.paint(self,skin_id,row,index,float(index)/7.0)
	draw_set_transform(Vector2.ZERO)

class_name SkinDraftRig
extends Node2D
var player:SideCrab
var skin_id:="chef_crab"
var back_layer:Node2D
var row:=0
var frame:=0

func _ready() -> void:
	z_index=1;texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	back_layer=Node2D.new();back_layer.z_index=-2;add_child(back_layer)
	back_layer.draw.connect(func(): SkinDrafts.paint(back_layer,skin_id,row,frame,1-player.attack_time/.22,true))

func _process(_delta:float) -> void:
	position=player.sprite.position;scale.x=player.facing;visible=player.sprite.visible
	if player.sprite.texture is AtlasTexture:
		row=int(player.sprite.texture.region.position.y/32);frame=int(player.sprite.texture.region.position.x/32)
	if skin_id!="classic_orange": player.sprite.texture=SkinDrafts.body(row,frame)
	back_layer.queue_redraw();queue_redraw()

func _draw() -> void:
	SkinDrafts.paint(self,skin_id,row,frame,1-player.attack_time/.22)

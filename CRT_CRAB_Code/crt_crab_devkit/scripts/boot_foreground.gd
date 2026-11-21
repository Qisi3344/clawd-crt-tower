class_name BootForeground
extends Node2D

# BOOT 启动机房的前景遮挡层（近镜头剪影）。
# 中景本来就只是一张平铺贴在角色后方的整图，缺"前景压住角色"这一层，
# 所以看起来是平的。这里补上镜头近处的天花板线槽 + 底部线缆槽，压在最前，
# 让房间出现前/中/后三层纵深。纯视觉、无碰撞、不影响关卡逻辑。

var world: SideWorld

func _ready() -> void:
	name = "BootForeground"
	z_index = 11
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world == null or not is_instance_valid(world.camera):
		return
	var view := Rect2(world.camera.position - Vector2(176, 136), Vector2(352, 272))
	var tray := Color("0e1519")
	var tray_hi := Color("2a3a3f")
	var cable := Color("182327")
	# 顶部近镜头线槽
	draw_rect(Rect2(view.position.x, view.position.y, view.size.x, 16), tray)
	draw_rect(Rect2(view.position.x, view.position.y + 16, view.size.x, 2), tray_hi)
	# 从线槽垂下的近景线缆
	for i in range(0, 7):
		var x := view.position.x + 24.0 + i * 52.0
		draw_line(Vector2(x, view.position.y + 16), Vector2(x - 6, view.position.y + 38), cable, 2)
		draw_line(Vector2(x, view.position.y + 16), Vector2(x + 4, view.position.y + 30), cable, 2)
	# 底部近镜头线缆槽
	draw_rect(Rect2(view.position.x, view.position.y + view.size.y - 14, view.size.x, 14), tray)
	draw_rect(Rect2(view.position.x, view.position.y + view.size.y - 14, view.size.x, 2), tray_hi)
	draw_line(Vector2(view.position.x + 40, view.position.y + view.size.y - 7), Vector2(view.position.x + view.size.x - 40, view.position.y + view.size.y - 7), tray_hi, 2)
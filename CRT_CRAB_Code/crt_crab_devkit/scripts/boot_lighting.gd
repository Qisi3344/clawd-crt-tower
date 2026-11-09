class_name BootLighting
extends Node2D

# BOOT 启动机房的动态光照层（加色合成）。
# 原本冷色的"暖灯 / 磷光绿环"都是画死在贴图里的，这里是抽出来做成会呼吸的光源，
# 让房间从"贴图"变成"被照亮"的场景。纯视觉、无碰撞、不影响关卡逻辑。

var _t := 0.0

func _ready() -> void:
	name = "BootLighting"
	z_index = 10
	z_as_relative = false
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat

func _process(delta: float) -> void:
	_t += delta
	queue_redraw()

func _draw() -> void:
	var pulse := 0.5 + 0.5 * sin(_t * 2.4)
	# 磷光绿环（主地标，约 240,144）
	_draw_glow(Vector2(240, 144), Color(0.18, 1.0, 0.62, 0.20 + 0.08 * pulse), 46.0)
	# 吊式维修灯（400,90）暖光
	_draw_glow(Vector2(400, 92), Color(1.0, 0.64, 0.28, 0.16 + 0.08 * sin(_t * 1.7 + 1.0)), 34.0)
	# 顶角两处暖光
	_draw_glow(Vector2(160, 54), Color(1.0, 0.62, 0.26, 0.12), 26.0)
	_draw_glow(Vector2(900, 54), Color(1.0, 0.62, 0.26, 0.12), 26.0)

func _draw_glow(pos: Vector2, color: Color, radius: float) -> void:
	var steps := 7
	for i in range(steps, 0, -1):
		var t := float(i) / float(steps)
		var c := color
		c.a = color.a * (1.0 - t) * (1.0 - t)
		draw_circle(pos, radius * t, c)
class_name TutorialDirector
extends RefCounted

const TEXT := {
	"move":["A / D · 移动","拖动左侧摇杆 · 移动"],"jump":["空格 · 起跳并安全落地","点跳跃 · 起跳并安全落地"],
	"push":["按住 E + 方向 · 推拉箱石","按住互动 + 摇杆 · 推拉箱石"],"ladder":["W / S · 沿梯子攀爬","摇杆上下 · 沿梯子攀爬"],
	"chest":["E · 打开宝箱","互动 · 打开宝箱"],"travel":["E · 连接下一台电脑","互动 · 连接下一台电脑"],
	"attack":["J / 鼠标左键 · 命中敌人或裂纹板","螯击 · 命中敌人或裂纹板"],"heavy":["重石的重量可以持续接通信号","重石的重量可以持续接通信号"],
	"array":["Tab · 查看线路，随后返回","阵列 · 查看线路，随后返回"],"reflector":["E 旋转导流片 · 错误弹也能修复电路","互动旋转导流片 · 错误弹也能修复电路"],
	"conveyor":["E 切换输送带方向 · 观察箭头","互动切换输送带方向 · 观察箭头"],"magnet":["E 切换磁吸 · 再次操作释放钢块","互动切换磁吸 · 再次操作释放钢块"],
	"relay":["蜜蜂停驻节点时会临时导电","蜜蜂停驻节点时会临时导电"],"reset":["R 复位当前机关组 · 奖励保留","暂停 → 复位当前谜题 · 奖励保留"]}
var game: Node

func observe(id: String) -> void:
	if not TEXT.has(id) or game.save.data.tutorial.completed.has(id): return
	game.save.data.tutorial.completed.append(id)
	game._checkpoint()

func prompt(world: SideWorld) -> String:
	if not game.controls.show_tutorial or game.save.data.tutorial.skipped: return ""
	var completed:Array=game.save.data.tutorial.completed
	var candidate:=""
	if world.screen_id=="BOOT" and not completed.has("move"): candidate="move"
	for zone in world.definition.get("tutorial_zones",[]):
		var rect:=Rect2(zone.rect[0],zone.rect[1],zone.rect[2],zone.rect[3])
		if rect.has_point(world.player.position) and not completed.has(zone.id): candidate=str(zone.id);break
	if candidate.is_empty() and not world.nearest.is_empty():
		if world.nearest.type=="chest": candidate="chest"
		if world.nearest.type=="portal": candidate="travel"
		if world.nearest.type=="mechanism" and TEXT.has(world.nearest.object.type): candidate=world.nearest.object.type
	if candidate.is_empty() or completed.has(candidate): return ""
	return TEXT[candidate][0 if game.controls.profile=="keyboard" else 1]

func skip() -> void:
	game.save.data.tutorial.skipped=true;game._checkpoint()

func guide() -> String:
	var lines:Array[String]=[]
	var index:=0 if game.controls.profile=="keyboard" else 1
	for id in ["move","jump","push","ladder","chest","attack","array","reset"]: lines.append(TEXT[id][index])
	return "\n".join(lines)

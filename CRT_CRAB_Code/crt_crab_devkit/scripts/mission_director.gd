class_name MissionDirector
extends RefCounted
## Read-only presentation of actual puzzle state. Never grants flags or rewards.

const ORDER := ["BOOT", "ARCHIVE", "POP-UP", "RECYCLE", "SIGNAL", "ERROR"]
const TITLES := ["启动区 / 冷启动", "档案仓库 / 重量证据", "弹窗区 / 噪声导流", "回收站 / 数据重构", "信号中心 / 三路会合", "错误核心 / 隔离解除"]
const COLORS := ["b9db77", "efcd79", "ed9dbe", "e0b57c", "7bd9d3", "b9a9ec"]

func describe(id: String, session: Dictionary, live_state: Dictionary = {}) -> Dictionary:
	var index := ORDER.find(id)
	if index < 0:
		return {"chapter": 0, "title": "未知屏幕", "accent": Color.WHITE, "objective": "检查屏幕连接", "next_step": "返回已连接的屏幕", "lock_reason": "关卡数据不可用", "completed": 0, "total": 1, "complete": false, "checklist": []}
	var flags: Dictionary = session.get("flags", {})
	var steps := _steps(id)
	var completed := 0
	var checklist: Array[String] = []
	var next_step := ""
	var missing: Array[String] = []
	# Boss checkpoints reset independently of latched historic node flags.
	var boss: Dictionary = live_state.get("boss", session.get("worlds", {}).get("error_01", {}).get("boss", {}))
	var stage := int(boss.get("stage", 0))
	var complete := bool(flags.get(steps.back()[0], false))
	for i in range(steps.size()):
		var step: Array = steps[i]
		var done := bool(flags.get(step[0], false))
		if id == "ERROR" and str(step[0]).begins_with("error_node_"):
			done = stage >= i - 2
		if complete: done = true
		if done:
			completed += 1
		else:
			missing.append(step[1])
			if next_step.is_empty(): next_step = step[2]
		checklist.append(("[完成] " if done else "[待办] ") + str(step[1]))
	var lock_reason := "" if complete else "尚缺：" + "、".join(missing)
	if complete:
		next_step = "前往右侧 %s 端口，继续下一章" % ORDER[index + 1] if index < 5 else "等待通信送达记录；可继续探索宝箱"
	if id in ["SIGNAL", "ERROR"]:
		var absent := _missing_inputs(flags)
		if not absent.is_empty():
			lock_reason = "实时线路中断：" + "、".join(absent)
			next_step = "通过回访端口返回 ARCHIVE，让重石持续压住 WEIGHT 2 压板" if not flags.get("signal_archive_gate", false) else "回访供电或回收屏幕，恢复缺失输入"
	if flags.get("message_delivered", false):
		next_step = "消息已送达 · 可回访六屏补全宝箱"
		lock_reason = ""
	return {"chapter": index + 1, "title": TITLES[index], "accent": Color(COLORS[index]), "objective": steps.back()[1], "next_step": next_step, "lock_reason": lock_reason, "completed": completed, "total": steps.size(), "complete": complete, "checklist": checklist}

func route(session: Dictionary) -> String:
	var rows: Array[String] = []
	for id in ORDER:
		var mission := describe(id, session)
		var index := ORDER.find(id)
		var requirement: String = ["", "boot_access", "archive_key", "popup_power_restored", "message_packet_restored", "signal_core_ready"][index]
		var available: bool = index == 0 or session.get("flags", {}).get(requirement, false) or session.get("screen_unlocked", {}).get(id, false)
		var status := "已修复" if mission.complete else ("可进入 · %d/%d" % [mission.completed, mission.total] if available else "锁定 · 先完成" + str(TITLES[index - 1]).split(" / ")[0])
		rows.append("%02d %s  %s" % [index + 1, id, status])
	return "\n".join(rows)

func _missing_inputs(flags: Dictionary) -> Array[String]:
	var missing: Array[String] = []
	for pair in [["signal_archive_gate", "A 档案重压板"], ["popup_power_restored", "B 弹窗供电"], ["message_packet_restored", "C 通信数据包"]]:
		if not flags.get(pair[0], false): missing.append(pair[1])
	return missing

func _steps(id: String) -> Array:
	match id:
		"BOOT": return [
			["boot_gate_open", "启动门供压", "按住互动推箱到压板，保持箱子压住开门"],
			["boot_access", "取得启动密钥", "通过门后爬梯，在高台互动开启启动宝箱"]]
		"ARCHIVE": return [
			["signal_archive_gate", "档案重压板接通", "爬上档案台，把重石向右推到 WEIGHT 2 压板并留在上面"],
			["archive_key", "取得档案密钥", "通过右侧机关门，互动开启档案密钥宝箱"]]
		"POP-UP": return [
			["popup_fuse_a", "大厅保险丝", "调整大厅导流镜向下，引飞蛾弹击中保险丝；可用备用脉冲重试"],
			["popup_fuse_b", "竖井保险丝", "沿竖井向上，调整第二片导流镜，引弹击中第二个保险丝"],
			["popup_power_restored", "恢复供电", "到竖井顶层互动修复台，隔离噪声并恢复供电"]]
		"RECYCLE": return [
			["recycle_part_1", "分拣区碎片", "操作输送带与安全停机，前往分拣区下层取得第 1 片"],
			["recycle_part_2", "磁吸井碎片", "使用磁吸爪挪开钢块，在磁吸井取得第 2 片"],
			["recycle_part_3", "重构室碎片", "爬回重构室，取得高层第 3 片通信数据"],
			["message_packet_restored", "重构通信数据包", "带齐三片后，在右侧重构台互动，接通 SIGNAL"]]
		"SIGNAL": return [
			["signal_local_a", "A 压力支路校准", "确认档案重石仍在压板上，再互动左侧 A 校准台"],
			["signal_bee_charged", "继电蜜蜂充电", "引继电蜜蜂到充电节点，利用绝缘水道安全通过"],
			["signal_local_b", "B 旁路锁定", "蜜蜂充电后互动旁路台，保存 B 支路连接"],
			["signal_optics_aligned", "C 光纤对接", "爬上第二层，互动光纤插口，接入通信数据包"],
			["signal_core_ready", "接通发送总线", "确认 A/B/C 输入有效，到顶层总线终端互动"]]
		"ERROR": return [
			["error_foyer_open", "打开前厅通路", "螯击前厅裂板，或引机械猫头鹰撞开通路"],
			["error_piston_supported", "活塞区重压板", "安全停止活塞，把重块移到活塞区 WEIGHT 2 压板"],
			["error_diagnostic_cleared", "授权核心隔离", "确认三路实时输入，互动上层诊断台授权核心"],
			["error_node_a", "解除 A 重力护罩", "在核心区把重块留在压板上，解除 A 护罩"],
			["error_node_b", "解除 B 反射护罩", "调整核心导流镜，让核心弹击中下方 B 节点"],
			["error_node_c", "解除 C 电路护罩", "到核心右侧反接脉冲，站上两侧绝缘高台等待预警结束"],
			["error_core_disabled", "关闭错误隔离核心", "护罩已解除，互动地面核心开关；也可螯击修复核心"]]
	return []

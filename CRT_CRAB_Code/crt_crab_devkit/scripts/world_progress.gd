class_name WorldProgress
extends RefCounted

const ORDER := ["BOOT","ARCHIVE","POP-UP","RECYCLE","SIGNAL","ERROR"]
const NAMES := ["启动区","档案仓库","弹窗区","回收站","信号中心","错误核心"]
const REPAIRS := ["boot_access","archive_key","popup_power_restored","recycle_route_repaired","signal_core_ready","error_core_disabled"]
const REQUIREMENTS := ["","boot_access","archive_key","popup_power_restored","message_packet_restored","signal_core_ready"]

static func synchronize(session: Dictionary, manifest: Dictionary) -> void:
	for i in range(ORDER.size()):
		var id: String = ORDER[i]
		if not manifest.has(id) or not manifest[id].get("implemented",true): continue
		if i==0 or session.flags.get(REQUIREMENTS[i],false): session.screen_unlocked[id] = true
		if session.flags.get(REPAIRS[i],false): session.screen_repaired[id] = true
	if session.flags.get("signal_core_ready",false) and not session.flags.get("message_delivered",false): session.story.message_state="ready"

static func circuit_inputs(flags: Dictionary) -> Dictionary:
	return {"A / ARCHIVE 重石压力":flags.get("signal_archive_gate",false),"B / POP-UP 供电":flags.get("popup_power_restored",false),"C / RECYCLE 数据包":flags.get("message_packet_restored",false)}

static func missing_inputs(flags: Dictionary) -> String:
	var missing: Array[String] = []
	var inputs := circuit_inputs(flags)
	for key in inputs:
		if not inputs[key]: missing.append(key)
	return "、".join(missing)

static func delivery_ready(flags: Dictionary) -> bool:
	return missing_inputs(flags).is_empty() and flags.get("boot_access",false) and flags.get("archive_key",false) and flags.get("signal_core_ready",false) and flags.get("error_core_disabled",false)

extends SceneTree

var failures := 0

func check(label: String, passed: bool) -> void:
	print(("PASS " if passed else "FAIL ") + label)
	if not passed: failures += 1

func _initialize() -> void:
	var path := "res://scripts/mission_director.gd"
	if not ResourceLoader.exists(path):
		check("mission director provides chapter objectives", false)
		quit(1)
		return
	var director = load(path).new()
	var session := {"flags": {}, "screen_unlocked": {}, "screen_repaired": {}}
	var mission: Dictionary = director.describe("POP-UP", session)
	check("supply starts with zero of three steps", mission.completed == 0 and mission.total == 3)
	check("first fuse has an actionable instruction", mission.next_step.contains("导流") and mission.lock_reason.contains("保险丝"))
	session.flags.popup_fuse_a = true
	mission = director.describe("POP-UP", session)
	check("first fuse advances objective to shaft", mission.completed == 1 and mission.next_step.contains("竖井"))
	session.flags.popup_fuse_b = true
	mission = director.describe("POP-UP", session)
	check("two fuses still require repair interaction", mission.completed == 2 and not mission.complete and mission.next_step.contains("修复"))
	session.flags.popup_power_restored = true
	mission = director.describe("POP-UP", session)
	check("repair unlocks next chapter without inventing kill goals", mission.complete and mission.lock_reason.is_empty() and mission.next_step.contains("RECYCLE"))
	check("describing missions never mutates save", not session.screen_repaired.has("POP-UP"))
	var recycle: Dictionary = director.describe("RECYCLE", {"flags": {"recycle_part_2": true}})
	check("fragments can be collected out of order", recycle.completed == 1 and recycle.next_step.contains("分拣"))
	var signal_mission: Dictionary = director.describe("SIGNAL", {"flags": {"signal_core_ready": true, "popup_power_restored": true, "message_packet_restored": true}})
	check("historic repair cannot hide a lost live input", signal_mission.lock_reason.contains("A") and signal_mission.next_step.contains("ARCHIVE"))
	var core: Dictionary = director.describe("ERROR", {"flags": {"error_node_a": true, "error_node_b": true}}, {"boss": {"stage": 0}})
	check("core reset does not count stale shield flags", core.checklist[3].begins_with("[待办]") and core.checklist[4].begins_with("[待办]"))
	var titles: Array[String] = []
	for chapter in ["BOOT", "ARCHIVE", "POP-UP", "RECYCLE", "SIGNAL", "ERROR"]:
		var current: Dictionary = director.describe(chapter, {"flags": {}})
		titles.append(current.title)
		check(chapter + " has a next action and lock explanation", not current.next_step.is_empty() and not current.lock_reason.is_empty())
	check("six chapters have distinct identity", titles.size() == 6 and titles.all(func(t): return titles.count(t) == 1))
	var hud_script = load("res://scripts/hud.gd")
	var hud = hud_script.new()
	check("HUD exposes persistent tactical mission card", hud.has_method("_build_mission_card"))
	if hud.has_method("_build_mission_card"):
		var column := VBoxContainer.new()
		hud._build_mission_card(column)
		check("current objective is visible by default", hud.objective.visible)
		check("next action wraps within the card", hud.mission_step.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART)
		check("mission has a readable progress gauge", hud.mission_progress != null and not hud.mission_progress.show_percentage)
		column.free()
	check("HUD exposes dodge cooldown feedback", hud.has_method("_dodge_status"))
	if hud.has_method("_dodge_status"):
		check("ready dodge names its keyboard binding", hud._dodge_status(0.0, false, false).contains("Shift"))
		check("cooldown explains why dodge is unavailable", hud._dodge_status(0.5, false, false).contains("冷却"))
		check("ladder prevents a misleading ready label", hud._dodge_status(0.0, true, false).contains("离开梯子"))
	hud.free()
	quit(1 if failures else 0)

class_name ControlProfile
extends RefCounted

var path := "user://controls.cfg"
var enabled := true
var profile := "keyboard"
var chosen := false
var show_tutorial := true

func load_preferences() -> void:
	if not enabled: chosen=true;return
	var cfg:=ConfigFile.new()
	if cfg.load(path)!=OK: return
	var value=cfg.get_value("controls","profile","")
	if value not in ["keyboard","touch"]: return
	profile=value
	var picked=cfg.get_value("controls","chosen",false)
	var hints=cfg.get_value("controls","show_tutorial",true)
	chosen=picked is bool and picked
	show_tutorial=hints if hints is bool else true

func apply(value: String, tutorial: bool) -> bool:
	if value not in ["keyboard","touch"]: return false
	if enabled:
		var cfg:=ConfigFile.new()
		cfg.set_value("controls","profile",value);cfg.set_value("controls","chosen",true);cfg.set_value("controls","show_tutorial",tutorial)
		if cfg.save(path+".tmp")!=OK or DirAccess.rename_absolute(path+".tmp",path)!=OK: return false
	profile=value;chosen=true;show_tutorial=tutorial
	return true

func hint(text: String) -> String:
	if profile!="touch": return text
	return text.replace("按住 E + A/D","按住互动 + 摇杆").replace("按住 E + 方向","按住互动 + 摇杆").replace("E / Esc","跳过按钮").replace("E  ","互动 · ").replace("按住 E","按住互动").replace("按 E","点互动").replace("W 爬梯","摇杆向上爬梯").replace("Tab","阵列").replace("R 复位","暂停中复位").replace("R 重置谜题","暂停中复位谜题").replace("J ","螯击 ").replace("W/S","摇杆上下")

class_name GameHUD
extends CanvasLayer

signal pause_changed(value: bool)
signal overview_requested
signal audio_changed(value: bool)
signal motion_changed(value: bool)
signal quit_requested
signal reset_requested
var health_label: Label
var title_label: Label
var objective: Label
var collection_label: Label
var prompt_label: Label
var toast_label: Label
var overview_panel: PanelContainer
var route_label: Label
var pause_panel: Control
var resume_button: Button
var debug_label: Label
var veil: ColorRect
var paused := false
var toast_time := 0.0

func _ready() -> void:
	layer = 10
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	var margins := MarginContainer.new()
	margins.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for key in ["left","right","top","bottom"]:
		margins.add_theme_constant_override("margin_"+key,28)
	margins.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(margins)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margins.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation",16)
	column.add_child(top)
	var brand := _panel(Color("d4e852"))
	top.add_child(brand)
	brand.add_child(_label("  屏幕群岛  /  CRT CRAB  ",22,Color("16191a")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	health_label = _label("● ● ●",24,Color("f1dfb0"))
	top.add_child(health_label)
	var menu := Button.new()
	menu.focus_mode = Control.FOCUS_NONE
	menu.text = "暂停  Esc"
	menu.pressed.connect(func(): set_paused(true))
	top.add_child(menu)
	title_label = _label("01 / BOOT  启动区",25)
	column.add_child(title_label)
	objective = _label("去左后方终端，按 E 唤醒信号",20,Color("e1e2d6"))
	column.add_child(objective)
	collection_label = _label("",18,Color("dce65b"))
	column.add_child(collection_label)
	var space := Control.new()
	space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(space)
	toast_label = _label("",20)
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(toast_label)
	prompt_label = _label("",23,Color("d4e852"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prompt_label)
	var bottom := HBoxContainer.new()
	column.add_child(bottom)
	var help := _label("AD 移动   空格 跳跃   W/S 梯子   按住 E 推拉   J 螯击   R 复位",17,Color("c1c7c3"))
	help.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bottom.add_child(help)
	var map_button := Button.new()
	map_button.focus_mode = Control.FOCUS_NONE
	map_button.text = "阵列  Tab"
	map_button.pressed.connect(func(): overview_requested.emit())
	bottom.add_child(map_button)
	overview_panel = _panel(Color("192025ee"))
	overview_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	overview_panel.offset_left = -315
	overview_panel.offset_right = -28
	overview_panel.offset_top = -80
	overview_panel.offset_bottom = 110
	root.add_child(overview_panel)
	var map_column := VBoxContainer.new()
	map_column.add_theme_constant_override("separation",14)
	overview_panel.add_child(map_column)
	map_column.add_child(_label("  电脑阵列 / CONNECTIONS",20,Color("d4e852")))
	route_label = _label("  ● BOOT  ⇄  ○ ARCHIVE\n  唤醒信号后开启连接",18)
	map_column.add_child(route_label)
	map_column.add_child(_label("  拖动环绕 · 滚轮调整高度\n  Tab 回到当前屏幕",17,Color("aab4b2")))
	overview_panel.hide()
	debug_label = _label("",15,Color("d4e852"))
	debug_label.position = Vector2(28,148)
	debug_label.hide()
	root.add_child(debug_label)
	veil = ColorRect.new()
	veil.color = Color(0.05,0.06,0.09,0)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(veil)
	_build_pause(root)

func _build_pause(root: Control) -> void:
	pause_panel = ColorRect.new()
	pause_panel.color = Color("101519cc")
	pause_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(pause_panel)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_panel.add_child(center)
	var panel := _panel(Color("252a2c"))
	panel.custom_minimum_size = Vector2(390,0)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",18)
	panel.add_child(column)
	column.add_child(_label("信号暂存 / PAUSED",27,Color("d4e852")))
	resume_button = Button.new()
	resume_button.text = "继续冒险"
	resume_button.pressed.connect(func(): set_paused(false))
	column.add_child(resume_button)
	var reset := Button.new()
	reset.text = "重置当前箱石谜题（保留宝箱）"
	reset.pressed.connect(func(): reset_requested.emit())
	column.add_child(reset)
	var sound := CheckButton.new()
	sound.text = "交互音效"
	sound.button_pressed = true
	sound.toggled.connect(func(v: bool): audio_changed.emit(v))
	column.add_child(sound)
	var motion := CheckButton.new()
	motion.text = "减少转场动态"
	motion.toggled.connect(func(v: bool): motion_changed.emit(v))
	column.add_child(motion)
	column.add_child(_label("E / K：开箱、传送 · 按住可推拉\nF3：性能面板 · 进度自动保存",18,Color("c1c7c3")))
	var quit := Button.new()
	quit.text = "保存并退出"
	quit.pressed.connect(func(): quit_requested.emit())
	column.add_child(quit)
	pause_panel.hide()

func _process(delta: float) -> void:
	if toast_time > 0:
		toast_time -= delta
		if toast_time <= 0:
			toast_label.text = ""

func show_message(text: String) -> void:
	toast_label.text = text
	toast_time = 5.5

func set_health(value: int) -> void:
	health_label.text = "● ".repeat(value) + "○ ".repeat(3-value)

func set_paused(value: bool) -> void:
	paused = value
	pause_panel.visible = value
	if value:
		resume_button.grab_focus()
	else:
		resume_button.release_focus()
	pause_changed.emit(value)

func update_progress(id: String, session: Dictionary) -> void:
	var flags: Dictionary = session.flags
	title_label.text = "01 / BOOT  启动区" if id == "BOOT" else "02 / ARCHIVE  档案仓库"
	collection_label.text = "◇ %d 晶体   ▣ 宝箱 %d / 4"%[session.crystals,session.collected.size()]
	if id=="ARCHIVE":
		objective.text = "档案密钥已记录 · 可回访 BOOT 的远端门" if flags.get("archive_key",false) else ("重压板已接通 · 通过右侧机关门取得档案密钥" if flags.get("signal_archive_gate",false) else "爬上档案台 · 右推重石落到 WEIGHT 2 压板")
	elif flags.get("slice_complete",false):
		objective.text = "两屏切片完成 · 四个宝箱已记录，可以继续探索"
	elif flags.get("signal_archive_gate",false):
		objective.text = "ARCHIVE 重压板已接通 · 右侧远端宝库已开"
	elif flags.get("boot_access",false):
		objective.text = "启动密钥已记录 · 向右连接 ARCHIVE"
	else:
		objective.text = "按住 E 推箱压板 → 开门 → W 爬梯开箱"
	route_label.text = "  %s BOOT  ⇄  %s ARCHIVE\n  远端重压板：%s"%["●" if id=="BOOT" else "○","●" if id=="ARCHIVE" else "○","接通" if flags.get("signal_archive_gate",false) else "未接通"]

func _label(text: String, size: int, color := Color("f0f0df")) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	label.add_theme_color_override("font_shadow_color",Color("11131c"))
	label.add_theme_constant_override("shadow_offset_x",1)
	label.add_theme_constant_override("shadow_offset_y",1)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.corner_radius_top_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel",style)
	return panel

class_name GameHUD
extends CanvasLayer

signal pause_changed(value: bool)
signal overview_requested
signal audio_changed(value: bool)
signal music_changed(value: bool)
signal music_volume_changed(value: float)
var music_toggle: CheckButton
var music_slider: HSlider
var sfx_toggle: CheckButton
signal motion_changed(value: bool)
signal environment_motion_changed(value: bool)
signal quit_requested
signal title_requested
signal gacha_requested
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
var credits_button: Button
var credits_dialog: AcceptDialog
var debug_label: Label
var veil: ColorRect
var paused := false
var toast_time := 0.0
var cursor_time := 0.0
var prompt_cursor: Label
var inventory: HBoxContainer
var counters: Array[Label] = []

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
	brand.add_child(_label("  CRT小蟹闯塔记  ",24,Color("ffc478")))
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
	collection_label.hide()
	column.add_child(collection_label)
	inventory = HBoxContainer.new(); inventory.add_theme_constant_override("separation",12); column.add_child(inventory)
	for row in [15,6,8]:
		var icon := TextureRect.new(); icon.texture = PixelArt.icon(row); icon.custom_minimum_size = Vector2(32,32); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; inventory.add_child(icon)
		var count := _label("0",20); inventory.add_child(count); counters.append(count)
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
	prompt_cursor = _label("_",20,Color("ffc478")); prompt_cursor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; column.add_child(prompt_cursor)
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
	overview_panel.offset_left = -440
	overview_panel.offset_right = -28
	overview_panel.offset_top = -170
	overview_panel.offset_bottom = 190
	root.add_child(overview_panel)
	var map_column := VBoxContainer.new()
	map_column.add_theme_constant_override("separation",14)
	overview_panel.add_child(map_column)
	map_column.add_child(_label("  电脑阵列 / CONNECTIONS",20,Color("d4e852")))
	route_label = _label("  ● BOOT  ⇄  ○ ARCHIVE\n  唤醒信号后开启连接",18)
	route_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	map_column.add_child(route_label)
	var map_help := _label("  拖动环绕 · 滚轮调整高度\n  Tab 回到当前屏幕",17,Color("aab4b2"))
	map_help.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	map_column.add_child(map_help)
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
	var scroll := ScrollContainer.new()
	scroll.follow_focus = true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.custom_minimum_size = Vector2(390,minf(680,get_viewport().get_visible_rect().size.y-70))
	panel.add_child(scroll)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	column.minimum_size_changed.connect(func(): scroll.custom_minimum_size.y = minf(column.get_combined_minimum_size().y,get_viewport().get_visible_rect().size.y-100); panel.reset_size())
	column.add_child(_label("信号暂存 / PAUSED",27,Color("d4e852")))
	resume_button = Button.new()
	resume_button.text = "继续冒险"
	resume_button.pressed.connect(func(): set_paused(false))
	column.add_child(resume_button)
	var sound := CheckButton.new()
	sfx_toggle = sound
	sound.text = "交互音效"
	sound.button_pressed = true
	sound.toggled.connect(func(v: bool): audio_changed.emit(v))
	column.add_child(sound)
	music_toggle = CheckButton.new()
	music_toggle.text = "背景音乐 · NO SIGNAL"
	music_toggle.button_pressed = true
	music_toggle.toggled.connect(func(v: bool): music_changed.emit(v))
	column.add_child(music_toggle)
	var volume_row := HBoxContainer.new()
	volume_row.add_child(_label("音乐音量",18))
	music_slider = HSlider.new()
	music_slider.min_value = 0
	music_slider.max_value = 1
	music_slider.step = 0.01
	music_slider.value = 0.35
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.custom_minimum_size.x = 150
	music_slider.value_changed.connect(func(v: float): music_volume_changed.emit(v))
	volume_row.add_child(music_slider)
	column.add_child(volume_row)
	var ambience_toggle := CheckButton.new()
	ambience_toggle.text = "游戏厅氛围"
	ambience_toggle.toggled.connect(func(v): get_parent().audio.set_visual("arcade_ambience",v);get_parent().apply_settings())
	column.add_child(ambience_toggle)
	var motion := CheckButton.new()
	motion.text = "减少转场动态"
	motion.toggled.connect(func(v: bool): motion_changed.emit(v))
	column.add_child(motion)
	var surroundings := CheckButton.new()
	surroundings.text = "环境微动态"
	surroundings.button_pressed = true
	surroundings.toggled.connect(func(v: bool): environment_motion_changed.emit(v))
	column.add_child(surroundings)
	credits_dialog = AcceptDialog.new()
	credits_dialog.title = "素材署名 / CREDITS"
	credits_dialog.dialog_autowrap = true
	credits_dialog.dialog_text = "外围模型：Kenney · CC0 1.0\nMini Arcade 1.2 / Furniture Kit 2.0\nFactory Kit 3.0 / Survival Kit 2.0\nMini Arcade 同时致谢 Fleur Keijsers、Guus Vermeulen。\n\n本项目修改：尺寸、底部轴心、统一色板、哑光材质；工业机柜改为供电与储存设施。\n来源：kenney.nl/assets\n完整逐项路径与许可：docs/ASSET_CREDITS.md\n\n小蟹形体参考：Qisi3344 / 绮思 · clawd-motion\n像素图与场景标识：本工程原创\n引擎：Godot Engine · MIT · godotengine.org/license"
	credits_dialog.confirmed.connect(func(): resume_button.grab_focus())
	credits_dialog.canceled.connect(func(): resume_button.grab_focus())
	pause_panel.add_child(credits_dialog)
	var title_button := Button.new()
	title_button.text = "保存并返回主菜单"
	title_button.pressed.connect(func(): title_requested.emit())
	column.add_child(title_button)
	var quit := Button.new()
	quit.text = "保存并退出"
	quit.pressed.connect(func(): quit_requested.emit())
	column.add_child(quit)
	pause_panel.hide()

func _process(delta: float) -> void:
	cursor_time += delta
	prompt_cursor.modulate.a = 1.0 if not prompt_label.text.is_empty() and (get_parent().audio.reduced_motion or fmod(cursor_time,1.0)<0.55) else 0.0
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
		credits_dialog.hide()
		resume_button.release_focus()
	pause_changed.emit(value)

func update_progress(id: String, session: Dictionary) -> void:
	var flags: Dictionary = session.flags
	var total: int = get_parent().treasure_count
	if counters.size()==3:
		counters[0].text = str(session.crystals); counters[1].text = "%d / %d"%[session.collected.size(),total]; counters[2].text = str(session.screen_repaired.size())
	var index: int = WorldProgress.ORDER.find(id)
	title_label.text = "%02d / %s  %s"%[index+1,id,WorldProgress.NAMES[index]]
	collection_label.text = "◇ %d 晶体   ▣ 宝箱 %d / %d"%[session.crystals,session.collected.size(),total]
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
	if id=="ARCHIVE" and flags.get("archive_key",false): objective.text="档案密钥已记录 · 右侧 POP-UP 端口修复供电，仍可回 BOOT"
	if id=="POP-UP": objective.text="两房导流片把飞蛾弹引向保险丝 → 竖井顶层恢复供电" if not flags.get("popup_power_restored",false) else "噪声已隔离 · RECYCLE 已供电，可继续回访"
	if id=="RECYCLE": objective.text="输送、磁吸与压机 → 回收三片通信数据 → 重构台"
	if id=="SIGNAL": objective.text="三路输入 + 继电蜜蜂接线 → 向上接通发送通道"
	if id=="ERROR": objective.text="解除重力 / 反射 / 电路三个护罩节点，再关闭核心"
	if flags.get("message_delivered",false): objective.text="通信已恢复 · User 的消息已送达，继续探索与收集"
	var rows: Array[String]=[]
	for screen in WorldProgress.ORDER:
		rows.append(("▶ " if screen==id else "  ")+screen+" / "+("已修复" if session.screen_repaired.get(screen,false) else ("可进入" if session.screen_unlocked.get(screen,false) else "未连接")))
	rows.append("ARCHIVE 重压板："+("接通" if flags.get("signal_archive_gate",false) else "未接通"))
	rows.append("User 消息："+("已送达" if flags.get("message_delivered",false) else "发送失败"))
	route_label.text="\n".join(rows)

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

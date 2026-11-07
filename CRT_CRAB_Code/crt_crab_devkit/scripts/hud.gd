class_name GameHUD
extends CanvasLayer

signal pause_changed(value: bool)
signal overview_requested
signal audio_changed(value: bool)
signal music_changed(value: bool)
signal music_volume_changed(value: float)
var music_toggle: CheckButton
var music_slider: HSlider
var sfx_slider: HSlider
var profile_button: Button
var hints_toggle: CheckButton
var map_back: Button
var array_button: Button
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
var bottom_band: HBoxContainer
var tutorial_label: Label
var vitals: Control
var pause_pages: Dictionary={}
var pause_page_id:="main"
var detail_text: Label
var reset_confirm: ConfirmationDialog
var map_panel: PanelContainer
var map_view: LocalMapView
var map_open:=false
var last_objective:=""
var notice_priority:=0
var notices:Array[Dictionary]=[]

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
	title_label=_label("01 · 启动区",24)
	top.add_child(title_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	health_label = _label("● ● ●",24,Color("f1dfb0"))
	health_label.hide();root.add_child(health_label)
	vitals=Control.new();vitals.set_script(load("res://scripts/ui/vital_icons.gd"));top.add_child(vitals)
	array_button=Button.new();array_button.text="阵列";array_button.pressed.connect(func():overview_requested.emit());top.add_child(array_button)
	var local_map_button:=Button.new();local_map_button.text="地图";local_map_button.pressed.connect(func():get_parent().toggle_local_map());top.add_child(local_map_button)
	var menu := Button.new()
	menu.focus_mode = Control.FOCUS_NONE
	menu.text = "暂停"
	menu.pressed.connect(func(): set_paused(true))
	top.add_child(menu)
	objective = _label("去左后方终端，按 E 唤醒信号",20,Color("e1e2d6"))
	column.add_child(objective)
	objective.hide()
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
	toast_label.z_index=20
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(toast_label)
	tutorial_label=_label("",18,Color("b5acc6"));tutorial_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(tutorial_label)
	prompt_label = _label("",23,Color("d4e852"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(prompt_label)
	prompt_cursor = _label("",20,Color("ffc478")); prompt_cursor.hide();column.add_child(prompt_cursor)
	var bottom := HBoxContainer.new()
	bottom_band=bottom
	column.add_child(bottom)
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
	var map_help := _label("",17,Color("aab4b2"))
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
	_build_local_map(root)

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
	_configure_pause_pages(column)
	pause_panel.hide()

func _process(delta: float) -> void:
	var game:=get_parent()
	bottom_band.custom_minimum_size.y=140 if game.controls.profile=="touch" else 0
	var playable:bool=is_instance_valid(game.world) and game.world.enabled
	tutorial_label.text=game.tutorial.prompt(game.world) if playable and prompt_label.text.is_empty() else ""
	prompt_label.visible=playable and not prompt_label.text.is_empty()
	tutorial_label.visible=playable and not tutorial_label.text.is_empty()
	toast_label.visible=toast_time>0 and (notice_priority>=80 or (playable and prompt_label.text.is_empty() and tutorial_label.text.is_empty()))
	if notice_priority>=80 and toast_time>0: prompt_label.hide();tutorial_label.hide()
	if map_open: map_view.queue_redraw()
	cursor_time += delta
	prompt_cursor.modulate.a = 1.0 if not prompt_label.text.is_empty() and (get_parent().audio.reduced_motion or fmod(cursor_time,1.0)<0.55) else 0.0
	if toast_time > 0:
		if toast_label.visible: toast_time -= delta
		if toast_time <= 0:
			toast_label.text = ""
			notice_priority=0
			if not notices.is_empty():
				var next:Dictionary=notices.pop_front();_notice(next.text,next.priority)

func show_message(text: String) -> void:
	var priority:=100 if text.contains("失败") or text.contains("未能写入") or text.begins_with("NO SIGNAL") else 20
	if text.begins_with("LINK ESTABLISHED"): priority=70
	elif text.begins_with("宝箱已") or text.begins_with("通信碎片"): priority=60
	if text==toast_label.text: return
	if toast_time>0 and (priority<notice_priority or (priority==notice_priority and priority<80)):
		if notices.size()<4 and not notices.any(func(n):return n.text==text): notices.append({"text":text,"priority":priority})
		return
	_notice(text,priority)

func _notice(text: String,priority: int) -> void:
	toast_label.text=get_parent().controls.hint(text);notice_priority=priority;toast_time=5 if priority>=80 else 3
	toast_label.add_theme_color_override("font_color",Color("f2a5ae") if priority>=80 else Color("f0f0df"))

func set_health(value: int) -> void:
	health_label.text = "生命 %d / 3"%value
	vitals.health=value

func set_paused(value: bool) -> void:
	if value and map_open: set_map(false,get_parent().world)
	paused = value
	pause_panel.visible = value
	if value:
		show_pause_page("main")
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
	title_label.text = "%02d · %s"%[index+1,WorldProgress.NAMES[index]]
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
		rows.append(("▶ " if screen==id else "  ")+str(WorldProgress.NAMES[WorldProgress.ORDER.find(screen)])+" / "+("已修复" if session.screen_repaired.get(screen,false) else ("可进入" if session.screen_unlocked.get(screen,false) else "未连接")))
	rows.append("ARCHIVE 重压板："+("接通" if flags.get("signal_archive_gate",false) else "未接通"))
	rows.append("User 消息："+("已送达" if flags.get("message_delivered",false) else "发送失败"))
	route_label.text="\n".join(rows)
	if last_objective!=objective.text:
		last_objective=objective.text;show_message(objective.text)

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

func set_prompt(text: String) -> void:
	prompt_label.text=get_parent().controls.hint(text)

func _page_button(parent: VBoxContainer,text: String,target: String,callback: Callable) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size.y=38;b.add_theme_font_size_override("font_size",20);b.pressed.connect(callback);parent.add_child(b);pause_pages[b]=target;return b

func _configure_pause_pages(column: VBoxContainer) -> void:
	for child in column.get_children():
		var page_id:="audio"
		if child==resume_button or (child is Button and child.text.begins_with("保存")): page_id="main"
		elif child is Label: page_id="common"
		elif child is CheckButton and child.text in ["游戏厅氛围","减少转场动态","环境微动态"]: page_id="video"
		pause_pages[child]=page_id
	_page_button(column,"操作指南","main",func():show_detail(get_parent().tutorial.guide()))
	_page_button(column,"当前任务 / 关卡信息","main",func():show_detail(objective.text+"\n\n"+collection_label.text))
	_page_button(column,"关卡内部地图","main",func():set_paused(false);get_parent().toggle_local_map())
	_page_button(column,"游戏设置","main",func():show_pause_page("settings"))
	_page_button(column,"复位当前谜题","main",func():reset_confirm.popup_centered(Vector2i(460,160)))
	_page_button(column,"操作与新手提示","settings",func():show_pause_page("controls"))
	_page_button(column,"声音设置","settings",func():show_pause_page("audio"))
	_page_button(column,"画面设置","settings",func():show_pause_page("video"))
	var sfx_row:=VBoxContainer.new();sfx_row.add_child(_label("音效音量",18));sfx_slider=HSlider.new();sfx_slider.min_value=0;sfx_slider.max_value=1;sfx_slider.step=.01;sfx_slider.value=get_parent().audio.sfx_volume;sfx_slider.custom_minimum_size.y=36;sfx_slider.value_changed.connect(get_parent().audio.set_sfx_volume);sfx_row.add_child(sfx_slider);column.add_child(sfx_row);pause_pages[sfx_row]="audio"
	var full:=CheckButton.new();full.text="全屏显示";full.button_pressed=get_parent().audio.fullscreen;full.toggled.connect(func(v):get_parent().audio.set_visual("fullscreen",v);get_parent().apply_settings());column.add_child(full);pause_pages[full]="video"
	profile_button=_page_button(column,"操作方式：键鼠 · 点击切换","controls",func():get_parent().change_profile("touch" if get_parent().controls.profile=="keyboard" else "keyboard"))
	var hints:=CheckButton.new();hints_toggle=hints;hints.text="新手提示";hints.button_pressed=get_parent().controls.show_tutorial;hints.toggled.connect(func(v):get_parent().set_tutorial_enabled(v));column.add_child(hints);pause_pages[hints]="controls"
	_page_button(column,"跳过本次新手指引","controls",func():get_parent().tutorial.skip();show_pause_page("main"))
	_page_button(column,"重新查看教学提示","controls",func():get_parent().save.data.tutorial.completed.clear();get_parent().save.data.tutorial.skipped=false;get_parent()._checkpoint();show_pause_page("main"))
	credits_button=_page_button(column,"素材署名","settings",func():credits_dialog.popup_centered(Vector2i(530,330)))
	_page_button(column,"返回暂停","settings",func():show_pause_page("main"))
	for page_id in ["controls","audio","video"]: _page_button(column,"返回设置",page_id,func():show_pause_page("settings"))
	detail_text=_label("",20);detail_text.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;column.add_child(detail_text);pause_pages[detail_text]="detail"
	_page_button(column,"返回暂停","detail",func():show_pause_page("main"))
	reset_confirm=ConfirmationDialog.new();reset_confirm.title="复位当前机关组";reset_confirm.dialog_text="当前箱石和临时机关回到检查点状态。\n宝箱、永久捷径和故事进度保留。";reset_confirm.confirmed.connect(func():reset_requested.emit());pause_panel.add_child(reset_confirm)
	show_pause_page("main")

func show_pause_page(value: String) -> void:
	pause_page_id=value
	for control in pause_pages: control.visible=pause_pages[control] in [value,"common"]
	for control in pause_pages:
		if control.visible and control is Button: control.grab_focus();break

func show_detail(text: String) -> void:
	detail_text.text=get_parent().controls.hint(text);show_pause_page("detail")

func _build_local_map(root: Control) -> void:
	map_panel=_panel(Color("292033f5"));map_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);map_panel.offset_left=30;map_panel.offset_right=-30;map_panel.offset_top=85;map_panel.offset_bottom=-25;root.add_child(map_panel)
	var col:=VBoxContainer.new();map_panel.add_child(col);col.add_child(_label("关卡内部地图 · 已探索区域",24,Color("e89aaa")))
	map_view=LocalMapView.new();map_view.size_flags_vertical=Control.SIZE_EXPAND_FILL;col.add_child(map_view)
	col.add_child(_label("粉点：当前位置   青方块：已开宝箱   通路：青色通行 / 金色条件门",16))
	map_back=Button.new();map_back.text="返回闯关  M / Esc";map_back.pressed.connect(func():get_parent().toggle_local_map());col.add_child(map_back);map_panel.hide()

func refresh_controls() -> void:
	profile_button.text="操作方式："+("触屏" if get_parent().controls.profile=="touch" else "键鼠")+" · 点击切换"
	hints_toggle.set_pressed_no_signal(get_parent().controls.show_tutorial)
	map_back.text="返回闯关" if get_parent().controls.profile=="touch" else "返回闯关  M / Esc"

func set_map(value: bool,world: SideWorld) -> void:
	map_open=value;map_panel.visible=value;map_view.world=world
	array_button.disabled=value
	if value:
		for b in map_panel.find_children("*","Button",true,false): b.grab_focus();break

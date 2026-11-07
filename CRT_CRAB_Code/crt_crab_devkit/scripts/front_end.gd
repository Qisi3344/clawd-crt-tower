class_name FrontEnd
extends CanvasLayer

var game: Node
var root: Control
var panel: PanelContainer
var column: VBoxContainer
var page := "title"
var selected := "classic_orange"
var message := ""
var preview: TextureRect
var preview_row := 0
var preview_paused := false
var clock := 0.0
var return_focus := "继续冒险"
var confirm: ConfirmationDialog
var pending_adventure:=-1
var selected_profile:="keyboard"

func _ready() -> void:
	layer = 20
	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("241c28e0")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,20)
	style.border_width_left = 4
	style.border_color = Color("de9b88")
	panel.add_theme_stylebox_override("panel",style)
	root.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	panel.add_child(scroll)
	column = VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation",12)
	scroll.add_child(column)
	confirm = ConfirmationDialog.new()
	confirm.title = "确认操作"
	confirm.dialog_autowrap = true
	root.add_child(confirm)
	show_page("title")

func _process(delta: float) -> void:
	if not visible: return
	var portrait := root.size.x/root.size.y<1.1
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(root.size.x*(0.06 if portrait else 0.035),root.size.y*(0.35 if portrait else 0.09))
	panel.size = Vector2(root.size.x*0.88 if portrait else 430,root.size.y*(0.59 if portrait else 0.82))
	if not preview_paused: clock += delta
	if is_instance_valid(preview): preview.texture = Cosmetics.frame(selected,preview_row,int(clock*8))

func _label(text: String, size: int = 21, color := Color("ddd4c2")) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	column.add_child(label)
	return label

func _button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	# Recolor the existing styles so padding, border widths and focus navigation stay intact.
	for state in ["normal","hover","pressed","focus"]:
		var skin := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		if skin==null: continue
		skin.bg_color = Color("30212bc4") if state=="normal" else Color("68434bdd")
		if state=="focus": skin.bg_color = Color("ffb38f18")
		skin.border_color = Color("f5b392")
		button.add_theme_stylebox_override(state,skin)
	button.add_theme_color_override("font_color",Color("eadbce"))
	button.add_theme_color_override("font_focus_color",Color("ffc09e"))
	button.add_theme_color_override("font_hover_color",Color("ffd4b9"))
	button.add_theme_color_override("font_pressed_color",Color("ffd4b9"))
	button.custom_minimum_size.y = 42
	button.pressed.connect(func(): game.audio.play("select"); callback.call())
	column.add_child(button)
	return button

func show_page(value: String) -> void:
	page = value
	game._control_state()
	preview = null
	for child in column.get_children(): column.remove_child(child); child.queue_free()
	_label("CRT小蟹闯塔记",32,Color("ffc09e"))
	_label("CRT CRAB // SCREEN ADVENTURE",15,Color("86bdb4"))
	if value=="title":
		_label("SYSTEM ONLINE · 修复通信，回到 User 身边",18)
		_inventory()
		if game.save.data.started:
			_button("继续冒险",func(): game.request_adventure(false))
			_button("新游戏",func(): _ask("将重置关卡、晶体和宝箱；保留已解锁外观、宠物收藏与设置。旧进度先备份。",func(): game.request_adventure(true)))
		else:
			_button("开始游戏",func():
				if game.save.writable: game.request_adventure(true)
				else: _ask("存档损坏或版本不受支持。先备份原文件，再开始新游戏？",func(): game.request_adventure(true))
			)
		_button("宠物扭蛋",game.open_gacha)
		_button("更换服装",func(): return_focus="更换服装"; show_page("wardrobe"))
		_button("游戏设置",func(): return_focus="游戏设置"; show_page("settings"))
		_label("操作方式："+("触屏" if game.controls.profile=="touch" else "键鼠") if game.controls.chosen else "首次冒险时选择操作方式",16)
		_button("退出游戏",game._quit)
		if game.save.status not in ["valid","missing"]: _label("原存档暂不可继续，已停止自动覆盖。",18,Color("ea5985"))
	elif value=="wardrobe":
		_inventory()
		preview = TextureRect.new()
		preview.custom_minimum_size = Vector2(160,160)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		column.add_child(preview)
		var modes := HBoxContainer.new()
		column.add_child(modes)
		for entry in [["待机",0],["走动",1],["钳击",3]]:
			var b := Button.new(); b.text=entry[0]; b.pressed.connect(func(): preview_row=int(entry[1])); modes.add_child(b)
		var freeze := CheckButton.new();freeze.text="暂停预览";freeze.button_pressed=preview_paused;freeze.toggled.connect(func(v): preview_paused=v);modes.add_child(freeze)
		for item in Cosmetics.catalog():
			var owned: bool = game.save.data.wardrobe.owned.has(item.id)
			var state := "已装备" if game.save.data.wardrobe.equipped==item.id else ("已拥有" if owned else ("%d 晶体"%int(item.price) if item.condition=="purchase" else "隐藏数据尚未找到"))
			_button(("▶ " if item.id==selected else "")+item.name+" · "+state,func(): selected=item.id; show_page("wardrobe"))
		var item: Dictionary = Cosmetics.catalog().filter(func(c): return c.id==selected)[0]
		if game.save.data.wardrobe.owned.has(selected):
			var equip := _button("已装备" if game.save.data.wardrobe.equipped==selected else "装备",func():
				message = "已装备。" if game.save.equip(selected) else "保存失败，装备保持不变。"
				show_page("wardrobe"))
			equip.disabled = game.save.data.wardrobe.equipped==selected
		elif item.condition=="purchase":
			_button("解锁 · %d 晶体"%int(item.price),func(): _ask("花费 %d 晶体解锁%s？购买后可另行装备。"%[int(item.price),item.name],func(): message=game.save.purchase(selected);game.audio.play("purchase" if game.save.data.wardrobe.owned.has(selected) else "error");show_page("wardrobe")))
		else: _label("隐藏数据尚未找到",18)
		_button("返回主菜单",func(): show_page("title"))
	elif value=="settings":
		_label("游戏设置",24,Color("86bdb4"))
		_button("操作与新手提示",func():show_page("control_settings"))
		_button("声音设置",func():show_page("audio_settings"))
		_button("画面设置",func():show_page("video_settings"))
		_button("返回主菜单",func():show_page("title"))
	elif value=="control_settings":
		_label("操作与新手提示",24,Color("86bdb4"))
		_button("操作方式",func():pending_adventure=-1;selected_profile=game.controls.profile;show_page("controls"))
		_button("操作指南",func():show_page("guide"))
		_toggle("新手提示",game.controls.show_tutorial,game.set_tutorial_enabled)
		_button("返回设置",func():show_page("settings"))
	elif value=="audio_settings":
		_label("声音设置",24,Color("86bdb4"))
		_toggle("背景音乐 · NO SIGNAL",game.audio.music_enabled,game.audio.set_music_enabled)
		_slider("音乐音量",game.audio.music_volume,game.audio.set_music_volume)
		_toggle("交互音效",game.audio.enabled,game.audio.set_sfx_enabled)
		_slider("音效音量",game.audio.sfx_volume,game.audio.set_sfx_volume)
		_button("返回设置",func():show_page("settings"))
	elif value=="video_settings":
		_label("画面设置",24,Color("86bdb4"))
		_toggle("减少动态",game.audio.reduced_motion,func(v): game.audio.set_visual("reduced_motion",v);game.apply_settings())
		_toggle("环境微动态",game.audio.environment_motion,func(v): game.audio.set_visual("environment_motion",v);game.apply_settings())
		_toggle("游戏厅氛围",game.audio.arcade_ambience,func(v): game.audio.set_visual("arcade_ambience",v);game.apply_settings())
		_toggle("全屏显示",game.audio.fullscreen,func(v): game.audio.set_visual("fullscreen",v);game.apply_settings())
		_button("返回设置",func():show_page("settings"))
	elif value=="controls":
		_label("选择操作方式",28,Color("e89aaa"))
		_label("之后可在设置里切换；手机请横屏游玩。",18)
		for mode in ["keyboard","touch"]:
			_button(("▶ " if selected_profile==mode else "")+("键盘 + 鼠标" if mode=="keyboard" else "触屏操作"),func():selected_profile=mode;show_page("controls"))
		_button("确认并开始冒险" if pending_adventure>=0 else "应用操作方式",func():
			if not game.change_profile(selected_profile): message="操作设置未保存，请检查存储空间。";show_page("controls");return
			if pending_adventure>=0:
				var reset:bool=pending_adventure==1;pending_adventure=-1;game.begin_adventure(reset)
			else: show_page("control_settings")
		)
		_button("返回",func():var destination:="title" if pending_adventure>=0 else "control_settings";pending_adventure=-1;show_page(destination))
	elif value=="guide":
		_label("操作指南",26)
		_label(game.tutorial.guide(),20)
		_button("返回设置",func():show_page("control_settings"))
	if message!="": _label(message,18,Color("ffc09e"))
	if value=="wardrobe":
		for child in column.get_children():
			if child is Button and child.text.begins_with("▶ "):
				child.grab_focus();return
	for child in column.get_children():
		if child is Button and (child.text==return_focus or value!="title"):
			child.grab_focus();return
	for child in column.get_children():
		if child is Button: child.grab_focus();break

func _toggle(text: String, value: bool, callback: Callable) -> void:
	var button := CheckButton.new();button.text=text;button.button_pressed=value;button.toggled.connect(callback);column.add_child(button)

func _slider(text: String, value: float, callback: Callable) -> void:
	_label(text,18)
	var slider := HSlider.new();slider.min_value=0;slider.max_value=1;slider.step=0.01;slider.value=value;slider.value_changed.connect(callback);slider.custom_minimum_size.y=30;column.add_child(slider)

func _ask(text: String, callback: Callable) -> void:
	for connection in confirm.confirmed.get_connections(): confirm.confirmed.disconnect(connection.callable)
	confirm.dialog_text = text
	confirm.confirmed.connect(callback,CONNECT_ONE_SHOT)
	confirm.popup_centered(Vector2i(500,170))

func _unhandled_input(event: InputEvent) -> void:
	if not visible: return
	if event.is_action_pressed("pause") and not confirm.visible and page!="title":
		var destination:="title"
		if page in ["control_settings","audio_settings","video_settings"]: destination="settings"
		elif page in ["controls","guide"] and pending_adventure<0: destination="control_settings"
		pending_adventure=-1;show_page(destination);get_viewport().set_input_as_handled()

func choose_controls(reset: bool) -> void:
	pending_adventure=1 if reset else 0
	selected_profile="touch" if DisplayServer.is_touchscreen_available() else "keyboard"
	show_page("controls")

func _inventory() -> void:
	var row := HBoxContainer.new(); row.add_theme_constant_override("separation",12); column.add_child(row)
	for entry in [[15,str(game.save.data.crystals)],[6,"%d / %d"%[game.save.data.collected.size(),game.treasure_count]],[8,str(game.save.data.screen_repaired.size())]]:
		var icon := TextureRect.new(); icon.texture = PixelArt.icon(entry[0]); icon.custom_minimum_size = Vector2(32,32); icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST; row.add_child(icon)
		var count := Label.new(); count.text = entry[1]; row.add_child(count)

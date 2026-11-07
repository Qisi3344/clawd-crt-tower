extends Control

var dialogue: Dictionary
var skin := "classic_orange"
var reduced := false
var grid: GridContainer
var chat_panel: PanelContainer
var conversation: VBoxContainer
var editor: Label
var outgoing: Label
var delivery: Label
var reply: Label
var diagnosis: Label
var repair: Label
var status: Label
var footer: Label
var crab: Sprite2D
var reply_icon: Sprite2D
var beat := "desktop"
var kind := "intro"
var clock := 0.0
var portal := Vector2.ZERO
var code_panel: PanelContainer

func label(text: String, font_size: int=22, color: String="dfd8d0") -> Label:
	var item:=Label.new();item.text=text;item.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	item.add_theme_font_size_override("font_size",font_size);item.add_theme_color_override("font_color",Color(color))
	return item

func panel() -> PanelContainer:
	var item:=PanelContainer.new();item.size_flags_horizontal=Control.SIZE_EXPAND_FILL;item.size_flags_vertical=Control.SIZE_EXPAND_FILL
	var style:=StyleBoxFlat.new();style.bg_color=Color("282536");style.border_color=Color("72647d")
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_border_width(side,3);style.set_content_margin(side,20)
	item.add_theme_stylebox_override("panel",style)
	return item

func _ready() -> void:
	set_meta("story_ui",true)
	var background:=ColorRect.new();background.color=Color("171624");background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(background)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,32)
	add_child(margin)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",18);margin.add_child(column)
	var top:=HBoxContainer.new();column.add_child(top)
	var title:=label("CLAWD DESKTOP / LOCAL SESSION",20,"b7a5c9");title.size_flags_horizontal=Control.SIZE_EXPAND_FILL;top.add_child(title)
	status=label("● ONLINE",20,"54cfc3")
	status.autowrap_mode=TextServer.AUTOWRAP_OFF
	status.custom_minimum_size.x=170
	status.horizontal_alignment=HORIZONTAL_ALIGNMENT_RIGHT
	top.add_child(status)
	grid=GridContainer.new();grid.columns=2;grid.size_flags_vertical=Control.SIZE_EXPAND_FILL;grid.add_theme_constant_override("h_separation",20);grid.add_theme_constant_override("v_separation",16);column.add_child(grid)
	chat_panel=panel();grid.add_child(chat_panel)
	conversation=VBoxContainer.new();conversation.add_theme_constant_override("separation",18);chat_panel.add_child(conversation)
	conversation.add_child(label("MESSAGES  /  User ↔ Clawd",24,"efcd9c"))
	conversation.add_child(HSeparator.new())
	conversation.add_child(label("User  /  "+str(dialogue.user_success),23))
	conversation.add_child(label("Clawd  /  "+str(dialogue.clawd_success),23,"8cd5c4"))
	outgoing=label("User  /  "+str(dialogue.user_message),28);conversation.add_child(outgoing)
	delivery=label("正在发送…",21,"c5b9ce");conversation.add_child(delivery)
	reply=label("Clawd  /  "+str(dialogue.clawd_reply).replace("🦀",""),26,"8cd5c4");conversation.add_child(reply)
	var spacer:=Control.new();spacer.size_flags_vertical=Control.SIZE_EXPAND_FILL;spacer.custom_minimum_size.y=64;conversation.add_child(spacer)
	footer=label("本地会话 · 与 User 一起写代码",16,"92899c");conversation.add_child(footer)
	code_panel=panel();grid.add_child(code_panel)
	var code:=VBoxContainer.new();code.add_theme_constant_override("separation",14);code_panel.add_child(code)
	code.add_child(label("workspace / hello_clawd.gd",20,"ada3c3"));code.add_child(HSeparator.new())
	editor=label("01  func hello_user():\n02      build_small_feature()\n03      print(\"Hello, User!\")\n04\n05  # BUILD SUCCEEDED\n06  # 0 errors · 0 warnings\n07\n08  ready_for_next_message()",20,"8cbab7");code.add_child(editor)
	diagnosis=label("本地诊断 · 异常链路 6 段\n□ BOOT    □ ARCHIVE\n□ POP-UP  □ RECYCLE\n□ SIGNAL  □ ERROR\n手动修复可用",18,"cfc4a9");code.add_child(diagnosis)
	repair=label("[  REPAIR / 手动修复  ]",25,"efd58a");code.add_child(repair)
	code_panel.custom_minimum_size.x=300
	crab=Sprite2D.new();crab.texture=Cosmetics.frame(skin,0);crab.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;crab.z_index=10;add_child(crab)
	reply_icon=Sprite2D.new();reply_icon.texture=Cosmetics.frame(skin,0);reply_icon.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;reply_icon.z_index=10;add_child(reply_icon)
	set_beat("desktop")

func set_beat(value: String) -> void:
	beat=value
	var outgoing_visible: bool=kind=="outro" or value not in ["desktop","chat"]
	outgoing.visible=outgoing_visible;delivery.visible=outgoing_visible
	reply.visible=kind=="outro" and value in ["reply","online","restored"]
	diagnosis.visible=kind=="intro" and value in ["diagnostic","repair","jump_in","boot"]
	repair.visible=diagnosis.visible
	if kind=="intro":
		var failed: bool=value not in ["desktop","chat","pending"]
		delivery.text="发送失败   [重试]" if failed else "正在发送…"
		delivery.modulate=Color("ed839c") if failed else Color.WHITE
		status.text="NO SIGNAL" if failed else "● ONLINE"
		status.modulate=Color("ed839c") if failed else Color("54cfc3")
		footer.text="连接中断 · 请稍后重试" if failed else "本地会话 · 与 User 一起写代码"
		editor.text="01  func hello_user():\n02      build_small_feature()\n03      print(\"Hello, User!\")\n04\n05  # NO SIGNAL\n06  # link diagnostics available" if failed else "01  func hello_user():\n02      build_small_feature()\n03      print(\"Hello, User!\")\n04\n05  # BUILD SUCCEEDED\n06  # 0 errors · 0 warnings"
		if value=="repair": repair.text="[  REPAIR OK  ]  "+str(dialogue.clawd_decision)
		if diagnosis.visible: editor.text="LOCAL DIAGNOSTIC\n连接中断 · 检查线路";editor.add_theme_font_size_override("font_size",18)
		if value in ["jump_in","boot"]: footer.text="CONNECTING... BOOT / "+str(dialogue.mission)
	else:
		diagnosis.hide();repair.hide()
		var delivered: bool=value in ["delivered","reply","online","restored"]
		delivery.text="已送达  [OK]" if delivered else "发送失败   →  重新连接…"
		delivery.modulate=Color("54cfc3") if delivered else Color("ed839c")
		status.text="● ONLINE" if delivered else "RECONNECTING"
		status.modulate=Color("54cfc3")
		footer.text="CONNECTION RESTORED / 继续一起写代码吧" if value=="restored" else "六段通信链已修复"

func animate(t: float) -> void:
	clock=t
	grid.columns=1 if size.x<size.y else 2
	chat_panel.custom_minimum_size.x=size.x*.53 if grid.columns==2 else 0
	code_panel.custom_minimum_size.x=size.x*.29 if grid.columns==2 else 0
	var rect:=chat_panel.get_global_rect()
	var home:=Vector2(rect.end.x-70,rect.end.y-84)
	portal=home+Vector2(-110,0)
	crab.scale=Vector2.ONE*3
	crab.position=home
	crab.visible=true
	crab.flip_h=true
	var row:=0
	if kind=="intro":
		if t<4.8: crab.position.y-=0 if reduced else absf(sin(t*2))*7
		elif t<8.1:
			var walk:=clampf((t-5.5)/.8,0,1)
			crab.position=home.lerp(home+Vector2(-90,-12),walk)
			row=1 if t<6.3 else 0
			if t>=6.6 and t<7.3:
				row=3
				if not reduced: crab.position.x+=sin((t-6.6)*20)*3
		elif t<11.6:
			var repair_rect:=repair.get_global_rect()
			var target:=Vector2(repair_rect.position.x+20,repair_rect.position.y-22)
			crab.position=(home+Vector2(-90,-12)).lerp(target,clampf((t-8.1)/1.7,0,1))
			crab.flip_h=false;row=1 if t<9.8 else (3 if t>10.2 else 0)
		else:
			var repair_rect:=repair.get_global_rect()
			var from:=Vector2(repair_rect.position.x+20,repair_rect.position.y-22)
			var jump:=clampf((t-11.6)/1.8,0,1)
			crab.position=from.lerp(portal,jump)-Vector2(0,sin(jump*PI)*70 if not reduced else 0)
			row=2;crab.visible=t<13.5
	else:
		crab.visible=t>=6.6
		crab.flip_h=false
		if not reduced and t<9.5: crab.position.y-=absf(sin((t-6.6)*5))*20
		row=3 if t<9.5 else 0
	crab.texture=Cosmetics.frame(skin,row,int(t*8))
	reply_icon.visible=reply.visible
	if reply.visible:
		var width:float=reply.get_theme_font("font").get_string_size(reply.text,HORIZONTAL_ALIGNMENT_LEFT,-1,26).x
		reply_icon.position=reply.get_global_rect().position+Vector2(minf(width+18,reply.size.x-20),17)
	queue_redraw()

func _draw() -> void:
	if kind=="intro" and clock>=11.6 and clock<14.5:
		for y in range(3):
			for x in range(6):
				draw_rect(Rect2(portal+Vector2(x*7-21,y*5+17),Vector2(5,3)),Color("54cfc3"))

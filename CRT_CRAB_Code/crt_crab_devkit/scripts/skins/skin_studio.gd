class_name SkinStudio
extends Control
signal closed
var game:Node
var selected:="chef_crab"
var root_box:VBoxContainer
var content:VBoxContainer
var status:Label
var portraits:Array[SkinPortrait]=[]
var selection_buttons:Dictionary={}
var mode:="compare"
var pose:=0
var body_only:=false
var paused:=false
var viewport:SubViewport
var arena:SideWorld
var rig:SkinDraftRig
var router:ControlRouter
var wall:StaticBody2D
var wall_enabled:=false
var grid:GridContainer
var detail:Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop:=ColorRect.new();backdrop.color=Color("171421fa");backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(backdrop)
	var margin:=MarginContainer.new();margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	add_child(margin)
	var scroll:=ScrollContainer.new();scroll.follow_focus=true;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;margin.add_child(scroll)
	root_box=VBoxContainer.new();root_box.size_flags_horizontal=Control.SIZE_EXPAND_FILL;root_box.add_theme_constant_override("separation",14);scroll.add_child(root_box)
	var heading:=Label.new();heading.text="第一弹试衣间 · 四款示范";heading.add_theme_font_size_override("font_size",30);root_box.add_child(heading)
	var navigation:=HBoxContainer.new();root_box.add_child(navigation)
	button(navigation,"并排对比",func(): show_mode("compare"))
	button(navigation,"试穿与试打",func(): show_mode("arena"))
	button(navigation,"返回换装",func(): closed.emit())
	var note:=Label.new();note.text="原版身体 · 单次伤害 1 · 本轮试穿不计入收藏";note.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;note.add_theme_font_size_override("font_size",18);root_box.add_child(note)
	content=VBoxContainer.new();content.add_theme_constant_override("separation",12);root_box.add_child(content)
	show_mode("compare")

func button(parent:Node,text:String,callback:Callable) -> Button:
	var b:=Button.new();b.text=text;b.custom_minimum_size=Vector2(100,44);b.pressed.connect(callback);parent.add_child(b);return b

func show_mode(value:String) -> void:
	if is_instance_valid(router): router.release_all()
	if is_instance_valid(arena): arena.enabled=false
	mode=value;portraits.clear();selection_buttons.clear();grid=null;status=null
	for c in content.get_children(): content.remove_child(c);c.queue_free()
	viewport=null;arena=null;rig=null;router=null;wall=null
	if value=="compare": build_compare()
	else: build_arena()

func build_compare() -> void:
	grid=GridContainer.new();grid.add_theme_constant_override("h_separation",12);grid.add_theme_constant_override("v_separation",12);content.add_child(grid)
	for id in SkinDrafts.IDS:
		var b:=Button.new();b.custom_minimum_size=Vector2(160,184);b.size_flags_horizontal=Control.SIZE_EXPAND_FILL;b.tooltip_text=SkinDrafts.entry(id).name
		b.pressed.connect(func(): select_skin(id));grid.add_child(b);selection_buttons[id]=b
		var box:=VBoxContainer.new();box.mouse_filter=Control.MOUSE_FILTER_IGNORE;box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);box.offset_left=8;box.offset_right=-8;box.offset_top=8;box.offset_bottom=-8;b.add_child(box)
		var portrait:=SkinPortrait.new();portrait.skin_id=id;portrait.row=pose;portrait.body_only=body_only;portrait.paused=paused;box.add_child(portrait);portraits.append(portrait)
		var label:=Label.new();label.text=SkinDrafts.entry(id).name;label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;label.add_theme_font_size_override("font_size",20);box.add_child(label)
		var rarity:=Label.new();rarity.text={"default":"原版","common":"普通 · 示范","rare":"稀有 · 示范","hidden":"隐藏 · 示范"}[SkinDrafts.entry(id).rarity];rarity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;rarity.add_theme_font_size_override("font_size",16);box.add_child(rarity)
	var poses:=HFlowContainer.new();content.add_child(poses)
	for item in [["待机",0],["走动",1],["跳跃",2],["攻击",3]]:
		button(poses,item[0],func():pose=item[1];for portrait in portraits:portrait.row=pose)
	var toggle:=CheckButton.new();toggle.text="只看原版身体";toggle.button_pressed=body_only;toggle.toggled.connect(func(v):body_only=v;for portrait in portraits:portrait.body_only=v);poses.add_child(toggle)
	var freeze:=CheckButton.new();freeze.text="暂停动作";freeze.button_pressed=paused;freeze.toggled.connect(func(v):paused=v;for portrait in portraits:portrait.paused=v);poses.add_child(freeze)
	detail=Label.new();detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_theme_font_size_override("font_size",20);content.add_child(detail)
	select_skin(selected);selection_buttons[selected].grab_focus()

func select_skin(id:String) -> void:
	selected=id
	var entry:=SkinDrafts.entry(id)
	if is_instance_valid(detail): detail.text="%s · %s\n试调：1 伤害 / %dpx 距离 / %.2fs 冷却。配件和攻击演出独立；八款与扭蛋奖励尚未接入。"%[entry.name,entry.appearance.weapon_name,entry.combat.enemy_reach_px,entry.combat.cooldown_s]
	for key in selection_buttons:
		var skin:=StyleBoxFlat.new();skin.bg_color=Color("30273e") if key==id else Color("211e2d");skin.border_color=Color("82dde5") if key==id else Color("70596e");skin.set_border_width_all(3 if key==id else 1);skin.set_corner_radius_all(8);selection_buttons[key].add_theme_stylebox_override("normal",skin)

func build_arena() -> void:
	var choices:=HFlowContainer.new();content.add_child(choices)
	for id in SkinDrafts.IDS: button(choices,SkinDrafts.entry(id).name,func():selected=id;reset_arena())
	var center:=CenterContainer.new();content.add_child(center)
	viewport=SubViewport.new();viewport.size=Vector2i(320,240);viewport.world_2d=World2D.new();viewport.disable_3d=true;viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS;content.add_child(viewport)
	var image:=TextureRect.new();image.name="ArenaImage";image.texture=viewport.get_texture();image.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;image.custom_minimum_size=Vector2(640,480) if size.x>=1000 and size.y>=780 else Vector2(320,240);image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;center.add_child(image)
	var actions:=HFlowContainer.new();content.add_child(actions)
	for item in [["← 移动","move_left"],["移动 →","move_right"],["跳跃","jump"],["攻击","attack"]]:
		var b:=button(actions,item[0],func():pass);b.name="Lab_"+item[1]
		b.button_down.connect(func():if is_instance_valid(router):router.set_source(int(b.get_instance_id()),{item[1]:1.0}))
		b.button_up.connect(func():if is_instance_valid(router):router.set_source(int(b.get_instance_id()),{}))
	button(actions,"重置试打",reset_arena)
	button(actions,"切换挡板",func():wall_enabled=not wall_enabled;reset_arena())
	status=Label.new();status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;status.add_theme_font_size_override("font_size",18);content.add_child(status)
	reset_arena()

func reset_arena() -> void:
	if is_instance_valid(router): router.release_all();router.queue_free()
	if is_instance_valid(arena): viewport.remove_child(arena);arena.free()
	router=ControlRouter.new();router.profile=ControlProfile.new();router.profile.enabled=false;router.allowed=true;viewport.add_child(router)
	arena=SideWorld.new();arena.screen_id="BOOT";arena.level_id="skin_trial";arena.session=SaveStore.fresh();arena.flags=arena.session.flags;arena.controls=router
	var definition:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels/boot_01.json"))
	for key in ["ladders","blocks","plates","doors","chests","breakables","crystals","terminals","mechanisms","animals","connections","room_portals","tutorial_zones","signs"]: definition[key]=[]
	definition.size=[320,240];definition.platforms=[[0,208,320,32,false]];definition.spawns={"entrance":[144,208]};definition.areas=[{"id":"trial","name":"试穿台","rect":[0,0,320,240],"checkpoint":[144,208]}]
	definition.enemies=[{"id":"trial_a","position":[170,208]},{"id":"trial_b","position":[188,208]}];arena.definition=definition;viewport.add_child(arena)
	# Dedicated sandbox attack: no new IDs or combat parameters enter the campaign.
	arena.player.struck.disconnect(arena._attack);arena.player.struck.connect(swing)
	for enemy in arena.enemies: enemy.set_physics_process(false)
	rig=SkinDraftRig.new();rig.player=arena.player;rig.skin_id=selected;arena.player.add_child(rig)
	arena.enabled=true
	wall=null
	if wall_enabled:
		wall=StaticBody2D.new();wall.position=Vector2(161,192);arena.add_child(wall)
		var shape:=CollisionShape2D.new();var box:=RectangleShape2D.new();box.size=Vector2(6,32);shape.shape=box;wall.add_child(shape)
		var face:=Polygon2D.new();face.polygon=PackedVector2Array([Vector2(-3,-16),Vector2(3,-16),Vector2(3,16),Vector2(-3,16)]);face.color=Color("8194a4");wall.add_child(face)

func swing() -> void:
	var combat:Dictionary=SkinDrafts.entry(selected).combat
	arena.player.attack_cooldown=float(combat.cooldown_s)
	if combat.pattern=="short_projectile":
		var shot:=SkinLabShot.new();shot.player=arena.player;shot.direction=arena.player.facing;shot.remaining=float(combat.enemy_reach_px)-12;shot.position=arena.player.position+Vector2(arena.player.facing*12,-9);arena.add_child(shot);return
	var target:DataBug
	var nearest:=INF
	for enemy in arena.enemies:
		var delta:Vector2=enemy.position-arena.player.position
		if delta.x*arena.player.facing<0 or absf(delta.x)>float(combat.enemy_reach_px) or absf(delta.y)>=23: continue
		if delta.length()<nearest: nearest=delta.length();target=enemy
	if target!=null:
		var query:=PhysicsRayQueryParameters2D.create(arena.player.global_position-Vector2(0,9),target.global_position-Vector2(0,6),5,[arena.player.get_rid()])
		if arena.get_world_2d().direct_space_state.intersect_ray(query).is_empty(): target.hit()

func _process(_delta:float) -> void:
	if is_instance_valid(grid): grid.columns=5 if size.x>=900 else (3 if size.x>=700 else 2)
	if is_instance_valid(status) and is_instance_valid(arena):
		var hp:Array=[]
		for enemy in arena.enemies: hp.append(str(enemy.health))
		var entry:=SkinDrafts.entry(selected)
		status.text="%s · %s · 单次1伤 / %dpx / %.2fs\nA/D 移动 · 空格跳跃 · J 攻击；按钮可触屏操作。靶虫生命：%s。挡板：%s。"%[entry.name,entry.appearance.weapon_name,entry.combat.enemy_reach_px,entry.combat.cooldown_s,", ".join(hp) if not hp.is_empty() else "已击败，可重置","开" if wall_enabled else "关"]

func _physics_process(delta:float) -> void:
	if is_instance_valid(arena):
		for enemy in arena.enemies:
			enemy.stun=maxf(0,enemy.stun-delta);enemy.anim+=delta;enemy.queue_redraw()

func _input(event:InputEvent) -> void:
	# Space belongs to the real player while trying an outfit, even when a menu
	# button still has keyboard focus. Input state remains available to the router.
	if mode=="arena" and (event.is_action("jump") or event.is_action("attack")):
		get_viewport().set_input_as_handled()

func _unhandled_input(event:InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if mode=="arena": show_mode("compare")
		else: closed.emit()

func _exit_tree() -> void:
	if is_instance_valid(router): router.release_all()

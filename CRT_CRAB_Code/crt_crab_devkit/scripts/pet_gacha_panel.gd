class_name PetGachaPanel
extends CanvasLayer
var game: Node
var machine: Node3D
var store: PetGachaStore
var panel: PanelContainer
var column: VBoxContainer
var draw_button: Button
var result: Label
var collection: Label
var history: Label
var pity: Label
var close_button: Button
var drawing := false
var last_award := {}
var previous := {}

func label(text: String, size := 18) -> Label:
    var n := Label.new(); n.text = text; n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; n.add_theme_font_size_override("font_size",size); column.add_child(n); return n

func _ready() -> void:
    layer = 30
    previous = {"camera":game.director.camera.transform,"fov":game.director.camera.fov,"h":game.director.camera.h_offset,"v":game.director.camera.v_offset,"busy":game.director.busy,"overview":game.director.overview,"hud":game.hud.visible,"menu":game.front_end.visible if is_instance_valid(game.front_end) else false,"occlusion":game.surroundings.occlusion_enabled}
    game.director.busy = true; game.director.overview = true; game.hud.hide()
    if is_instance_valid(game.front_end): game.front_end.hide()
    game.surroundings.occlusion_enabled = false; machine.show()
    var root := Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
    panel = PanelContainer.new(); panel.name = "GachaPanel"
    var skin := StyleBoxFlat.new(); skin.bg_color = Color("2c2233ef"); skin.border_color = Color("c897af"); skin.set_border_width_all(2); skin.set_corner_radius_all(12)
    for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: skin.set_content_margin(edge,18)
    panel.add_theme_stylebox_override("panel",skin); root.add_child(panel)
    var scroll := ScrollContainer.new(); scroll.follow_focus = true; scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED; panel.add_child(scroll)
    column = VBoxContainer.new(); column.add_theme_constant_override("separation",10); column.size_flags_horizontal = Control.SIZE_EXPAND_FILL; scroll.add_child(column)
    label("宠物扭蛋 / PET GACHA",25)
    label("免费测试 · 每次 0 晶体",20).add_theme_color_override("font_color",Color("a7d5c2"))
    label("普通 72% · 稀有 25% · 隐藏 3%\n第 4 抽稀有保底；第 13 抽起提升隐藏概率，第 20 抽隐藏保底。",16)
    label("仓内 18 颗展示扭蛋",16)
    pity = label("")
    draw_button = Button.new(); draw_button.name = "DrawPet"; draw_button.text = "免费抽取一次"; draw_button.custom_minimum_size.y = 48; draw_button.pressed.connect(draw); column.add_child(draw_button)
    result = label("",20)
    label("我的收藏",21)
    collection = label("")
    label("最近抽取",20); history = label("",16)
    close_button = Button.new(); close_button.text = "返回"; close_button.custom_minimum_size.y = 44; close_button.pressed.connect(close); column.add_child(close_button)
    machine.dispensed.connect(_finished)
    get_viewport().size_changed.connect(layout)
    layout(); refresh()
    if not store.error.is_empty(): result.text = store.error
    elif not store.data.recent.is_empty():
        var entry: Dictionary = store.data.recent.back(); result.text = "最近获得："+PetCapsule.TITLES[PetGachaStore.IDS.find(entry.id)]
    else: result.text = "试着转动机器，收集六款小动物。"
    draw_button.grab_focus()

func layout() -> void:
    var extent := get_viewport().get_visible_rect().size
    var mobile := extent.x<800 or extent.x/extent.y<0.90
    panel.anchor_left = 0.03; panel.anchor_right = 0.97 if mobile else 0.34
    panel.anchor_top = 0.57 if mobile else 0.05; panel.anchor_bottom = 0.97 if mobile else 0.95
    game.director.camera.fov = 43
    game.director.camera.h_offset = 0 if mobile else -2.15
    game.director.camera.v_offset = -3.4 if mobile else 0
    game.director.camera.position = machine.to_global(Vector3(0,8.0,20 if mobile else 14.0))
    game.director.camera.look_at(machine.to_global(Vector3(0,3.4,0)))

func refresh() -> void:
    var d := store.data
    pity.text = "累计 %d 抽 · 当前隐藏 %.0f%%\n稀有保底还需 %d 抽 · 隐藏保底还需 %d 抽"%[d.total,store.hidden_chance()*100,4-int(d.rare_misses),20-int(d.hidden_misses)]
    collection.text = ""
    for i in range(6): collection.text += "%s  × %d\n"%[PetCapsule.TITLES[i],d.owned[PetGachaStore.IDS[i]]]
    history.text = "暂无记录"
    if not d.recent.is_empty():
        history.text = ""
        for i in range(d.recent.size()-1,maxi(-1,d.recent.size()-6),-1):
            var entry: Dictionary = d.recent[i]; history.text += "第 %d 抽 · %s\n"%[entry.draw,PetCapsule.TITLES[PetGachaStore.IDS.find(entry.id)]]
    draw_button.disabled = drawing or not store.storage.writable

func draw() -> void:
    if drawing or machine.busy: return
    drawing = true; draw_button.disabled = true
    var award := store.draw()
    if not award.ok:
        drawing = false; result.text = award.error; refresh(); return
    last_award = award
    result.text = "出蛋中…"
    machine.sfx_enabled = game.audio.enabled
    machine.voice.volume_db = -14+linear_to_db(maxf(game.audio.sfx_volume,0.0001))
    machine.present_reward(award)
    if game.ambience!=null and game.ambience.enabled:
        for n in machine.reward.find_children("*","MeshInstance3D",true,false):
            if game.ambience.eligible(n.material_override): n.material_override = game.ambience.cel(n.material_override)

func _finished() -> void:
    drawing = false
    result.text = "%s · %s\n已收藏 × %d"%[PetCapsule.TITLES[last_award.kind],["普通","稀有","隐藏"][last_award.rarity],last_award.count]
    result.add_theme_color_override("font_color",[Color("e6e1d8"),Color("efb1d8"),Color("f5d17b")][last_award.rarity])
    refresh(); draw_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"): get_viewport().set_input_as_handled(); close()

func close() -> void:
    if machine.cycle!=null: machine.cycle.kill()
    machine.busy = false; machine.clear_reward()
    machine.knob.rotation.z = 0; machine.flap.rotation.x = 0; machine.flap.position = Vector3(-0.58,1.95,1.49)
    game.director.camera.transform = previous.camera; game.director.camera.fov = previous.fov
    game.director.camera.h_offset = previous.h; game.director.camera.v_offset = previous.v
    game.director.busy = previous.busy; game.director.overview = previous.overview
    game.hud.visible = previous.hud
    if is_instance_valid(game.front_end): game.front_end.visible = previous.menu
    game.surroundings.occlusion_enabled = previous.occlusion
    game.gacha_panel = null; game._control_state()
    if game.in_menu and is_instance_valid(game.front_end):
        for button in game.front_end.column.get_children():
            if button is Button and button.text=="宠物扭蛋": button.grab_focus()
    queue_free()

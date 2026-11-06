class_name PetGachaPanel
extends CanvasLayer
var game: Node
var machine: Node3D
var store: PetGachaStore
var root: Control
var panel: PanelContainer
var column: VBoxContainer
var draw_button: Button
var result: Label
var pity: Label
var close_button: Button
var help_button: Button
var collection: HBoxContainer
var icons: Array[Button] = []
var drawing := false
var last_award := {}
var previous := {}
var pointer := -2
var press_position := Vector2.ZERO
var last_pointer := Vector2.ZERO
var turn := 0.0
var travel := 0.0
var resting_turn := 0.0

func label(text: String, size := 18) -> Label:
    var n := Label.new(); n.text = text; n.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; n.add_theme_font_size_override("font_size",size); column.add_child(n); return n

func _ready() -> void:
    layer = 30
    previous = {"camera":game.director.camera.transform,"fov":game.director.camera.fov,"h":game.director.camera.h_offset,"v":game.director.camera.v_offset,"busy":game.director.busy,"overview":game.director.overview,"hud":game.hud.visible,"menu":game.front_end.visible if is_instance_valid(game.front_end) else false,"occlusion":game.surroundings.occlusion_enabled}
    game.director.busy = true; game.director.overview = true; game.hud.hide()
    if is_instance_valid(game.front_end): game.front_end.hide()
    game.surroundings.occlusion_enabled = false; machine.show()
    root = Control.new(); root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); root.mouse_filter = Control.MOUSE_FILTER_IGNORE; add_child(root)
    draw_button = Button.new(); draw_button.name = "KnobInteraction"; draw_button.tooltip_text = "转动旋钮 · 点击 / 拖动 / 回车"; root.add_child(draw_button)
    var clear := StyleBoxEmpty.new()
    for state in ["normal","pressed","disabled"]: draw_button.add_theme_stylebox_override(state,clear)
    var halo := StyleBoxFlat.new(); halo.bg_color = Color(1,0.65,0.8,0.06); halo.border_color = Color("e9b1c4"); halo.set_border_width_all(2); halo.set_corner_radius_all(100)
    draw_button.add_theme_stylebox_override("hover",halo); draw_button.add_theme_stylebox_override("focus",halo)
    draw_button.pressed.connect(draw)
    close_button = Button.new(); close_button.text = "‹ 返回"; close_button.custom_minimum_size = Vector2(76,44); root.add_child(close_button); close_button.position = Vector2(24,24); close_button.pressed.connect(close)
    help_button = Button.new(); help_button.text = "?"; help_button.tooltip_text = "概率与保底"; help_button.toggle_mode = true; help_button.custom_minimum_size = Vector2(44,44); root.add_child(help_button)
    help_button.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT); help_button.offset_left = -68; help_button.offset_right = -24; help_button.offset_top = 24; help_button.offset_bottom = 68
    panel = PanelContainer.new(); panel.name = "ProbabilityHelp"; root.add_child(panel)
    var skin := StyleBoxFlat.new(); skin.bg_color = Color("2c2233f5"); skin.border_color = Color("9a768e"); skin.set_border_width_all(1); skin.set_corner_radius_all(12)
    for edge in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: skin.set_content_margin(edge,16)
    panel.add_theme_stylebox_override("panel",skin)
    column = VBoxContainer.new(); column.add_theme_constant_override("separation",10); panel.add_child(column)
    column.minimum_size_changed.connect(panel.reset_size)
    label("概率与保底",20)
    label("免费测试 · 每次 0 晶体\n普通 72% · 稀有 25% · 隐藏 3%\n第 4 抽稀有保底；第 13 抽起逐抽增加 5% 隐藏概率，第 20 抽隐藏保底。隐藏优先判定。",16)
    pity = label("",16)
    panel.hide(); help_button.toggled.connect(func(open: bool): panel.visible = open; cancel_turn(); refresh())
    var footer := VBoxContainer.new(); footer.name = "CollectionStrip"; footer.mouse_filter = Control.MOUSE_FILTER_IGNORE; footer.add_theme_constant_override("separation",8); root.add_child(footer)
    footer.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM); footer.offset_top = -122; footer.offset_bottom = -24; footer.offset_left = -220; footer.offset_right = 220
    result = Label.new(); result.text = "转动旋钮"; result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; result.add_theme_font_size_override("font_size",16); result.mouse_filter = Control.MOUSE_FILTER_IGNORE; footer.add_child(result)
    collection = HBoxContainer.new(); collection.alignment = BoxContainer.ALIGNMENT_CENTER; collection.add_theme_constant_override("separation",8); footer.add_child(collection)
    for kind in range(6): make_icon(kind)
    machine.dispensed.connect(_finished)
    get_viewport().size_changed.connect(layout)
    layout(); refresh()
    if not store.error.is_empty(): result.text = store.error
    draw_button.grab_focus()

func make_icon(kind: int) -> void:
    var viewport := SubViewport.new(); viewport.size = Vector2i(128,128); viewport.transparent_bg = true; viewport.own_world_3d = true; viewport.render_target_update_mode = SubViewport.UPDATE_ONCE; add_child(viewport)
    var environment := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color(0,0,0,0); env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("fff0df"); env.ambient_light_energy = 0.7; environment.environment = env; viewport.add_child(environment)
    var light := DirectionalLight3D.new(); light.rotation_degrees = Vector3(-35,-25,0); light.light_energy = 0.9; viewport.add_child(light)
    var pet: Node3D = load("res://scenes/pets/"+PetGachaStore.IDS[kind]+".tscn").instantiate(); viewport.add_child(pet)
    var camera := Camera3D.new(); viewport.add_child(camera); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 3.0; camera.position = Vector3(0,1.5,6); camera.look_at(Vector3(0,1.35,0)); camera.current = true
    var button := Button.new(); button.name = "Collection_"+PetGachaStore.IDS[kind]; button.custom_minimum_size = Vector2(56,60); collection.add_child(button); icons.append(button)
    var image := TextureRect.new(); image.texture = viewport.get_texture(); image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE; image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED; image.mouse_filter = Control.MOUSE_FILTER_IGNORE; button.add_child(image); image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); image.offset_left = 2; image.offset_right = -2
    var shader := Shader.new(); shader.code = "shader_type canvas_item; uniform bool owned = false; void fragment(){ vec4 pet = texture(TEXTURE, UV); COLOR = vec4(owned ? pet.rgb : vec3(0.34,0.32,0.38),pet.a); }"
    var material := ShaderMaterial.new(); material.shader = shader; image.material = material
    button.pressed.connect(func(): result.text = button.tooltip_text)

func layout() -> void:
    cancel_turn()
    var extent := get_viewport().get_visible_rect().size
    panel.position = Vector2(maxf(16,extent.x-368),80); panel.custom_minimum_size.x = minf(344,extent.x-32); panel.reset_size()
    game.director.camera.fov = 43; game.director.camera.h_offset = 0; game.director.camera.v_offset = 0
    game.director.camera.position = machine.to_global(Vector3(0,7.5,maxf(12.5,6.0/(extent.x/extent.y))))
    game.director.camera.look_at(machine.to_global(Vector3(0,3.6,0)))
    var camera: Camera3D = game.director.camera
    var center := camera.unproject_position(machine.knob.to_global(Vector3(0,0,0.25)))
    var edge := camera.unproject_position(machine.knob.to_global(Vector3(0.52,0,0.25)))
    var diameter := maxf(48,center.distance_to(edge)*2)
    draw_button.position = center-Vector2.ONE*diameter/2; draw_button.size = Vector2.ONE*diameter

func refresh() -> void:
    var d := store.data
    pity.text = "累计 %d 抽 · 当前隐藏 %.0f%%\n稀有保底还需 %d 抽 · 隐藏保底还需 %d 抽"%[d.total,store.hidden_chance()*100,4-int(d.rare_misses),20-int(d.hidden_misses)]
    for i in range(6):
        var owned: bool = int(d.owned[PetGachaStore.IDS[i]])>0
        var icon := icons[i]
        icon.tooltip_text = PetCapsule.TITLES[i].split(" / ")[0]+(" · 已收藏" if owned else " · 未获得")
        icon.get_child(0).material.set_shader_parameter("owned",owned)
        var skin := StyleBoxFlat.new(); skin.bg_color = Color("211827a0"); skin.set_corner_radius_all(14); skin.border_color = Color("a57c94") if owned else Color("504357"); skin.set_border_width_all(1)
        icon.add_theme_stylebox_override("normal",skin)
    draw_button.disabled = drawing or not store.storage.writable or panel.visible

func draw() -> void:
    if drawing or machine.busy or not store.storage.writable: return
    drawing = true; draw_button.disabled = true; cancel_turn()
    var award := store.draw()
    if not award.ok:
        drawing = false; result.text = award.error; refresh(); return
    last_award = award; result.text = "出蛋中…"
    machine.sfx_enabled = game.audio.enabled
    machine.voice.volume_db = -14+linear_to_db(maxf(game.audio.sfx_volume,0.0001))
    machine.present_reward(award)
    if game.ambience!=null and game.ambience.enabled:
        for n in machine.reward.find_children("*","MeshInstance3D",true,false):
            if game.ambience.eligible(n.material_override): n.material_override = game.ambience.cel(n.material_override)

func _finished() -> void:
    drawing = false; result.text = "转动旋钮"
    refresh(); draw_button.grab_focus()

func cancel_turn() -> void:
    if pointer!=-2 and not machine.busy: machine.knob.rotation.z = resting_turn
    pointer = -2

func pointer_down(id: int, pos: Vector2) -> bool:
    if pointer!=-2 or draw_button.disabled or not draw_button.get_global_rect().has_point(pos) or (panel.visible and panel.get_global_rect().has_point(pos)): return false
    pointer = id; press_position = pos; last_pointer = pos; turn = 0; travel = 0; resting_turn = machine.knob.rotation.z
    draw_button.grab_focus()
    return true

func pointer_move(pos: Vector2) -> void:
    travel = maxf(travel,press_position.distance_to(pos))
    var center := draw_button.get_global_rect().get_center()
    if last_pointer.distance_to(center)>8 and pos.distance_to(center)>8: turn += (last_pointer-center).angle_to(pos-center)
    machine.knob.rotation.z = resting_turn-clampf(turn,-PI/2,PI/2)
    last_pointer = pos

func pointer_up(pos: Vector2) -> void:
    pointer_move(pos)
    var activate := travel<8 and draw_button.get_global_rect().has_point(pos) or absf(turn)>=PI/4
    cancel_turn()
    if activate: draw()

func _input(event: InputEvent) -> void:
    if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
        if event.pressed:
            if pointer_down(-1,event.position): get_viewport().set_input_as_handled()
        elif pointer==-1:
            pointer_up(event.position); get_viewport().set_input_as_handled()
    elif event is InputEventMouseMotion and pointer==-1:
        pointer_move(event.position); get_viewport().set_input_as_handled()
    elif event is InputEventScreenTouch:
        if event.pressed:
            if pointer_down(event.index,event.position): get_viewport().set_input_as_handled()
        elif pointer==event.index:
            if event.canceled: cancel_turn()
            else: pointer_up(event.position)
            get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and pointer==event.index:
        pointer_move(event.position); get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
    if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(machine): cancel_turn()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        get_viewport().set_input_as_handled()
        if panel.visible: help_button.button_pressed = false; help_button.grab_focus()
        else: close()

func close() -> void:
    cancel_turn()
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

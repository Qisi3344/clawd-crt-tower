extends CanvasLayer
# Shared UI palette only; scene and puzzle art retain their authored colors.
const COLORS = [Color("17121f"),Color("292033"),Color("41334d"),Color("68516d"),Color("a88496"),Color("f4e7cf"),Color("ffc478"),Color("e89aaa"),Color("8dcabb"),Color("62b8c1")]
var skins := {}

func nearest(color: Color) -> Color:
    var best: Color = COLORS[0]; var distance := INF
    for candidate in COLORS:
        var delta := Vector3(color.r-candidate.r,color.g-candidate.g,color.b-candidate.b).length_squared()
        if delta<distance: distance = delta; best = candidate
    best.a = color.a
    return best

func skin(bg: Color, border: Color, pressed := false) -> StyleBoxTexture:
    var key := str(bg)+str(border)+str(pressed)
    if skins.has(key): return skins[key]
    var image := Image.create(12,12,false,Image.FORMAT_RGBA8); image.fill(Color.TRANSPARENT)
    image.fill_rect(Rect2i(3,3,9,9),COLORS[0])
    image.fill_rect(Rect2i(0,0,9,9),border)
    image.fill_rect(Rect2i(2,2,5,5),bg)
    var box := StyleBoxTexture.new(); box.texture = ImageTexture.create_from_image(image)
    for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]:
        box.set_texture_margin(side,5); box.set_content_margin(side,14)
    box.content_margin_top = 17 if pressed else 13; box.content_margin_bottom = 9 if pressed else 13
    skins[key] = box
    return box

func polish(node) -> void:
    if not is_instance_valid(node): return
    var ancestor: Node = node
    while ancestor!=null:
        if ancestor.get_meta("story_ui",false): return
        ancestor=ancestor.get_parent()
    if node is Control:
        node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # Respect authored heading/body/caption sizes; never promote every label.
        for property in node.get_property_list():
            var path: String = property.name
            if path.begins_with("theme_override_colors/") and node.get(path) is Color: node.set(path,nearest(node.get(path)))
    if node is Button and node.name!="KnobInteraction" and not str(node.name).begins_with("Collection_"):
        for state in ["normal","hover","focus","pressed","disabled"]:
            node.add_theme_stylebox_override(state,skin(COLORS[1] if state in ["normal","disabled"] else COLORS[2],COLORS[6] if state in ["hover","focus","pressed"] else COLORS[3],state=="pressed"))
        node.add_theme_color_override("font_color",COLORS[5]); node.add_theme_color_override("font_hover_color",COLORS[6]); node.add_theme_color_override("font_focus_color",COLORS[6])
        node.focus_entered.connect(func():
            if get_parent().audio.reduced_motion: return
            node.pivot_offset = node.size/2
            var tween: Tween = node.create_tween(); tween.tween_property(node,"rotation",0.008,0.04); tween.tween_property(node,"rotation",-0.008,0.04); tween.tween_property(node,"rotation",0.0,0.06))
    elif node is PanelContainer and node.name!="CollectionStrip":
        var old: StyleBox = node.get_theme_stylebox("panel")
        var box := skin(COLORS[1],COLORS[3]).duplicate()
        for side in [SIDE_LEFT,SIDE_RIGHT,SIDE_TOP,SIDE_BOTTOM]: box.set_content_margin(side,old.get_content_margin(side))
        node.add_theme_stylebox_override("panel",box)
    elif node is Label and node.get_theme_font_size("font_size")>=25:
        node.add_theme_constant_override("outline_size",1); node.add_theme_color_override("font_outline_color",nearest(node.get_theme_color("font_color")))

func _ready() -> void:
    layer = 90
    for node in get_tree().root.find_children("*","Control",true,false): polish(node)
    get_tree().node_added.connect(func(node: Node):
        if node is Control: polish.call_deferred(node))
    var screen := ColorRect.new(); screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    var shader := Shader.new(); shader.code = """shader_type canvas_item;
    uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
    void fragment(){
        vec2 uv = SCREEN_UV; vec3 c = texture(screen_texture,uv).rgb;
        vec3 glow = vec3(0.0);
        for(int i=0;i<4;i++) { vec2 p = vec2(i==0 ? 1.0 : i==1 ? -1.0 : 0.0,i==2 ? 1.0 : i==3 ? -1.0 : 0.0)*SCREEN_PIXEL_SIZE*2.0; glow += max(texture(screen_texture,uv+p).rgb-vec3(0.75),vec3(0.0)); }
        float scan = 1.0-0.018*step(0.66,fract(uv.y/SCREEN_PIXEL_SIZE.y/3.0));
        float edge = smoothstep(0.20,0.72,length(uv-0.5));
        COLOR = vec4((c+glow*0.025)*scan*(1.0-edge*0.075),1.0);
    }"""
    var material := ShaderMaterial.new(); material.shader = shader; screen.material = material; add_child(screen)

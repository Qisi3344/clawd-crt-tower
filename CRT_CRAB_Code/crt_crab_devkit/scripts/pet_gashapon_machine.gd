extends Node3D
signal dispensed
const PETS := ["cat","dog","hamster","rabbit","bear","hidden_cat"]
const ROUTE := [Vector3(0,4.332,-0.45),Vector3(-0.58,4.40,-0.95),Vector3(-0.58,3.62,-0.90),Vector3(-0.58,3.05,-0.50),Vector3(-0.58,2.64,-0.50),Vector3(-0.58,1.70,-0.50),Vector3(-0.58,0.48,0.10),Vector3(-0.58,0.48,1.12),Vector3(-0.58,0.48,1.12)]
const TIMES := [0.35,0.55,0.70,1.15,1.40,1.65,1.95,2.18,2.50]
var casing: Array[Node3D] = []
var pile: Array[Node3D] = []
var selected: Node3D
var knob: Node3D
var disk: Node3D
var gate: Node3D
var flap: Node3D
var busy := false
var cutaway := false
var cycle: Tween
var sounds: Dictionary = {}
var voice: AudioStreamPlayer3D
var sound_step := -1

func orb(parent: Node3D, p: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
    var mesh := SphereMesh.new()
    mesh.radius = 1; mesh.height = 2; mesh.radial_segments = 16; mesh.rings = 8
    var n := MeshInstance3D.new()
    n.mesh = mesh; n.position = p; n.scale = size
    n.material_override = Craft.material(color)
    parent.add_child(n)
    return n

func box(parent: Node3D, label: String, p: Vector3, size: Vector3, color: Color, shell := false) -> MeshInstance3D:
    var n := Craft.box(parent,p,size,color,0.015)
    n.name = label
    if shell: casing.append(n)
    return n

func mesh_node(label: String, vertices: PackedVector3Array, color: Color) -> MeshInstance3D:
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    st.set_smooth_group(-1)
    for v in vertices: st.add_vertex(v)
    st.generate_normals()
    var n := MeshInstance3D.new(); n.name = label; n.mesh = st.commit()
    n.material_override = Craft.material(color)
    add_child(n)
    return n

func quad(out: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3, d: Vector3, normal: Vector3) -> void:
    # Godot front faces use clockwise winding.
    if (b-a).cross(c-a).dot(normal)>0:
        out.append_array(PackedVector3Array([a,c,b,a,d,c]))
    else: out.append_array(PackedVector3Array([a,b,c,a,c,d]))

func rounded(rect: Rect2, radius: float) -> PackedVector2Array:
    var points := PackedVector2Array()
    for c in range(4):
        var center := rect.get_center()+Vector2(1 if c in [0,1] else -1,1 if c in [1,2] else -1)*(rect.size/2-Vector2.ONE*radius)
        for i in range(9):
            var a := deg_to_rad(-90+c*90+i*90.0/8)
            points.append(center+Vector2(cos(a),sin(a))*radius)
    return points

func front_panel() -> void:
    var outer := rounded(Rect2(-1.925,0.2,3.85,3.2),0.12)
    var inner := rounded(Rect2(-1.23,0.48,1.30,1.47),0.12)
    var points := PackedVector3Array()
    for i in range(outer.size()):
        var j := (i+1)%outer.size()
        var a := Vector3(outer[i].x,outer[i].y,1.575)
        var b := Vector3(outer[j].x,outer[j].y,1.575)
        var c := Vector3(inner[j].x,inner[j].y,1.575)
        var d := Vector3(inner[i].x,inner[i].y,1.575)
        var offset := Vector3(0,0,-0.15)
        quad(points,a,b,c,d,Vector3.FORWARD*-1)
        quad(points,a+offset,d+offset,c+offset,b+offset,Vector3.FORWARD)
        quad(points,d,c,c+offset,d+offset,(Vector3(-0.58,1.215,1.5)-(c+d)/2).normalized())
        quad(points,a,a+offset,b+offset,b,((a+b)/2-Vector3(0,1.8,1.5)).normalized())
    casing.append(mesh_node("OpenFrontPanel",points,Color("d4b49d")))

func outlet_door() -> MeshInstance3D:
    var loop := rounded(Rect2(-0.61,-1.40,1.22,1.40),0.12)
    var ids := Geometry2D.triangulate_polygon(loop)
    var points := PackedVector3Array()
    for side in [-1.0,1.0]:
        for i in range(0,ids.size(),3):
            var a := Vector3(loop[ids[i]].x,loop[ids[i]].y,side*0.0125)
            var b := Vector3(loop[ids[i+1]].x,loop[ids[i+1]].y,side*0.0125)
            var c := Vector3(loop[ids[i+2]].x,loop[ids[i+2]].y,side*0.0125)
            points.append_array(PackedVector3Array([a,c,b] if (b-a).cross(c-a).z*side>0 else [a,b,c]))
    for i in range(loop.size()):
        var j := (i+1)%loop.size()
        var a := Vector3(loop[i].x,loop[i].y,0.0125)
        var b := Vector3(loop[j].x,loop[j].y,0.0125)
        quad(points,a,b,b-Vector3(0,0,0.025),a-Vector3(0,0,0.025),(a+b)/2-Vector3(0,-0.70,0))
    var door := mesh_node("ClearFlap",points,Color("aa9daf"))
    door.reparent(flap,false)
    return door

func funnel() -> void:
    var vertices := PackedVector3Array()
    for i in range(32):
        var a := TAU*i/32; var b := TAU*(i+1)/32
        var p := Vector3(-0.58+cos(a)*0.825,3.55,-0.50+sin(a)*0.825)
        var q := Vector3(-0.58+cos(b)*0.825,3.55,-0.50+sin(b)*0.825)
        var r := Vector3(-0.58+cos(b)*0.45,3.10,-0.50+sin(b)*0.45)
        var s := Vector3(-0.58+cos(a)*0.45,3.10,-0.50+sin(a)*0.45)
        quad(vertices,p,q,r,s,Vector3.UP)
    var n := mesh_node("OpenFunnel",vertices,Color("978799"))
    n.material_override = n.material_override.duplicate()
    n.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
    # Storage floor is an annulus around the real funnel inlet, never a sealing plate.
    var floor_vertices := PackedVector3Array()
    for i in range(32):
        var a := TAU*i/32; var b := TAU*(i+1)/32
        var p := Vector3(cos(a)*1.72,3.55,sin(a)*1.47)
        var q := Vector3(cos(b)*1.72,3.55,sin(b)*1.47)
        var r := Vector3(-0.58+cos(b)*0.825,3.55,-0.5+sin(b)*0.825)
        var s := Vector3(-0.58+cos(a)*0.825,3.55,-0.5+sin(a)*0.825)
        quad(floor_vertices,p,q,r,s,Vector3.UP)
    mesh_node("HopperFloorWithOpening",floor_vertices,Color("a48d9b"))

func chute() -> void:
    # Sloped trough sections, open at the top. Net vertical clearance >=1.30.
    var points := [Vector3(-0.58,2.50,-1.05),Vector3(-0.58,0.48,-1.05),Vector3(-0.58,0.48,1.575)]
    var verts := PackedVector3Array()
    for i in range(points.size()-1):
        var a: Vector3 = points[i]; var b: Vector3 = points[i+1]
        var l := Vector3(0.625,0,0)
        quad(verts,a-l,b-l,b+l,a+l,Vector3.UP)
        quad(verts,a-l-Vector3(0,0.08,0),a+l-Vector3(0,0.08,0),b+l-Vector3(0,0.08,0),b-l-Vector3(0,0.08,0),Vector3.DOWN)
        for side in [-1.0,1.0]:
            var x := Vector3(side*0.665,0,0)
            var wall := Craft.box(self,(a+b)/2+x,Vector3(0.08,0.16,a.distance_to(b)),Color("726679"),0.01)
            wall.name = "ChuteSide"
            wall.look_at_from_position((a+b)/2+x,b+x,Vector3.FORWARD if absf((b-a).normalized().dot(Vector3.UP))>0.99 else Vector3.UP)
            wall.position += wall.basis.y*0.08
    mesh_node("ContinuousChuteFloor",verts,Color("887586"))
    box(self,"CollectionBack",Vector3(-0.58,0.96,0.685),Vector3(1.30,0.96,0.08),Color("514453"))
    # Backstop only reaches below the descending path; it does not close the trough.
    get_node("CollectionBack").scale.y = 0.20
    get_node("CollectionBack").position.y = 0.37

const GLASS_CENTER := 4.82
const GLASS_RADII := Vector3(2.10,2.20,2.10)
const GLASS_BOTTOM := 3.55
const GLASS_TOP := 6.24

func glass_radius(y: float) -> float:
    return GLASS_RADII.x*sqrt(1-pow((y-GLASS_CENTER)/GLASS_RADII.y,2))

func glass_mesh() -> ArrayMesh:
    # True spherical coordinates, cropped only at the two mounting openings.
    var bottom := asin((GLASS_BOTTOM-GLASS_CENTER)/GLASS_RADII.y)
    var top := asin((GLASS_TOP-GLASS_CENTER)/GLASS_RADII.y)
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(12):
        for col in range(32):
            var p: Array[Vector3] = []
            for ij in [Vector2i(col,row),Vector2i(col+1,row),Vector2i(col+1,row+1),Vector2i(col,row+1)]:
                var a: float = TAU*ij.x/32.0
                var b := lerpf(bottom,top,ij.y/12.0)
                p.append(Vector3(cos(a)*cos(b),sin(b),sin(a)*cos(b)))
            var vertices := PackedVector3Array()
            quad(vertices,p[0],p[1],p[2],p[3],p[0])
            for v in vertices: st.set_normal(v); st.add_vertex(v)
    return st.commit()

func mounting_groove(label: String, y: float, direction: float, parent: Node3D) -> MeshInstance3D:
    var radius := glass_radius(y)
    # U-section: 0.04-wide groove receives the glass edge, with a supporting bottom.
    var profile := [Vector2(-0.09,0.08),Vector2(-0.02,0.08),Vector2(-0.02,0),Vector2(0.02,0),Vector2(0.02,0.08),Vector2(0.09,0.08),Vector2(0.09,-0.15),Vector2(-0.09,-0.15)]
    var vertices := PackedVector3Array()
    for row in range(profile.size()):
        var next := (row+1)%profile.size()
        var delta: Vector2 = profile[next]-profile[row]
        for col in range(32):
            var a := TAU*col/32; var b := TAU*(col+1)/32
            var r: float = radius+profile[row].x; var t: float = radius+profile[next].x
            var h: float = profile[row].y*direction; var k: float = profile[next].y*direction
            quad(vertices,Vector3(cos(a)*r,h,sin(a)*r),Vector3(cos(b)*r,h,sin(b)*r),Vector3(cos(b)*t,k,sin(b)*t),Vector3(cos(a)*t,k,sin(a)*t),Vector3(-delta.y*cos((a+b)/2),delta.x*direction,-delta.y*sin((a+b)/2)))
    var n := mesh_node(label,vertices,Color("d4b49d"))
    n.reparent(parent,false); n.position.y = y if parent==self else 0
    n.set_meta("opening_radius",radius)
    casing.append(n)
    return n

func glass_highlight(parent: Node3D, azimuth: float, low: float, high: float, width: float) -> void:
    var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for row in range(8):
        var points: Array[Vector3] = []
        for ij in [Vector2i(0,row),Vector2i(1,row),Vector2i(1,row+1),Vector2i(0,row+1)]:
            var a: float = azimuth+(ij.x-0.5)*width
            var b := lerpf(low,high,ij.y/8.0)
            points.append(Vector3(cos(a)*cos(b),sin(b),sin(a)*cos(b))*GLASS_RADII+Vector3(0,GLASS_CENTER,0))
        var vertices := PackedVector3Array()
        quad(vertices,points[0],points[1],points[2],points[3],points[0]-Vector3(0,GLASS_CENTER,0))
        for v in vertices:
            var normal := ((v-Vector3(0,GLASS_CENTER,0))/GLASS_RADII).normalized()
            st.set_normal(normal); st.add_vertex(v+normal*0.008)
    var n := MeshInstance3D.new(); n.mesh = st.commit()
    var mat := StandardMaterial3D.new(); mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; mat.albedo_color = Color(0.91,0.94,0.97,0.65)
    n.material_override = mat; n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; parent.add_child(n)

func lower_dressing() -> void:
    var details := Node3D.new(); details.name = "CabinetDetails"; add_child(details); casing.append(details)
    box(details,"PriceInset",Vector3(-0.82,2.70,1.654),Vector3(0.88,0.44,0.018),Color("332b3b"))
    get_node("CrystalPrice").position.z = 1.68
    for x in [-1.65,1.65]:
        for y in [0.42,3.16]: orb(details,Vector3(x,y,1.590),Vector3(0.035,0.035,0.018),Color("9c9298"))
    var arc := PackedVector3Array()
    for i in range(17):
        var a := deg_to_rad(20+i*140.0/16)
        arc.append(Vector3(1.01+cos(a)*0.60,2.50+sin(a)*0.60,1.61))
    Craft.cable(details,arc,Color("c77b9d"),0.026)
    Craft.label(details,"TURN",Vector3(1.01,3.19,1.60),Color("906b7f"),0.0016,26)
    Craft.label(details,"SERIES 06",Vector3(1.0,1.18,1.60),Color("896d73"),0.0015,24)
    # Thin continuous lip follows the real opening, without reducing its clearance.
    var outer := rounded(Rect2(-1.31,0.40,1.46,1.63),0.20)
    var inner := rounded(Rect2(-1.23,0.48,1.30,1.47),0.12)
    var points := PackedVector3Array()
    for i in range(outer.size()):
        var j := (i+1)%outer.size()
        quad(points,Vector3(outer[i].x,outer[i].y,1.590),Vector3(outer[j].x,outer[j].y,1.590),Vector3(inner[j].x,inner[j].y,1.590),Vector3(inner[i].x,inner[i].y,1.590),Vector3.BACK)
    var lip := mesh_node("OutletTrim",points,Color("e2c8ad")); lip.reparent(details,false)

func _ready() -> void:
    name = "PetGashaponMachine"; set_meta("scenery_group",true)
    var cream := Color("d4b49d"); var teal := Color("437e76"); var dark := Color("332b3b"); var pink := Color("c77b9d")
    box(self,"Foot",Vector3(0,0.10,0),Vector3(3.85,0.20,3.15),dark)
    # Five real shell panels, never a solid body behind the opening.
    for side in [-1,1]:
        box(self,"SidePanel",Vector3(side*1.85,1.8,-0.075),Vector3(0.15,3.2,3.00),teal,true)
    box(self,"RearPanel",Vector3(0,1.8,-1.5),Vector3(3.55,3.2,0.15),teal,true)
    box(self,"BottomPanel",Vector3(0,0.275,0),Vector3(3.55,0.15,2.85),teal)
    front_panel()
    var hatch := box(self,"RearHatch",Vector3(0,1.8,-1.59),Vector3(2.7,2.3,0.04),cream,true)
    for x in [-1.12,1.12]:
        for y in [0.88,2.72]: orb(hatch,Vector3(x,y-1.8,-0.04),Vector3.ONE*0.055,dark)
    for y in [0.95,1.10,1.25]: box(hatch,"Vent",Vector3(0,y-1.8,-0.035),Vector3(0.9,0.045,0.02),dark)
    for side in [-1,1]:
        var paw := orb(self,Vector3(side*1.935,1.95,0),Vector3(0.025,0.27,0.28),cream)
        casing.append(paw)
        for z in [-0.24,0,0.24]: casing.append(orb(self,Vector3(side*1.935,2.34,z),Vector3(0.025,0.11,0.09),cream))
    knob = Node3D.new(); knob.name = "Knob"; knob.position = Vector3(1.01,2.50,1.61); add_child(knob)
    orb(knob,Vector3.ZERO,Vector3(0.48,0.48,0.12),pink)
    box(knob,"Handle",Vector3(0,0,0.16),Vector3(0.67,0.15,0.12),pink.lightened(0.1))
    box(self,"PriceFrame",Vector3(-0.82,2.70,1.61),Vector3(1.05,0.62,0.07),teal)
    casing.append(knob)
    casing.append(get_node("PriceFrame"))
    var price := Craft.label(self,"◇ 100",Vector3(-0.82,2.70,1.66),Color("9ad8c5"),0.004,36); price.name = "CrystalPrice"; casing.append(price)
    casing.append(Craft.sticker(self,"boot_ok",Vector3(1.0,1.57,1.586),0.55))
    for i in range(3): casing.append(box(self,"FrontVent",Vector3(1.0,0.67+i*0.14,1.587),Vector3(0.65,0.04,0.02),dark))
    for x in [-1.36,1.36]: casing.append(Craft.box(self,Vector3(x,0.12,1.583),Vector3(0.65,0.035,0.02),pink,0.01,0.45))
    for p in [Vector3(1.71,0.48,1.585),Vector3(-1.71,3.11,1.585)]: casing.append(box(self,"PaintChip",p,Vector3(0.18,0.025,0.01),Color("aaa194")))
    flap = Node3D.new(); flap.name = "OutletFlap"; flap.position = Vector3(-0.58,1.95,1.49); add_child(flap)
    var door := outlet_door()
    var door_mat := StandardMaterial3D.new(); door_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; door_mat.albedo_color = Color(0.8,0.75,0.85,0.16); door.material_override = door_mat
    for x in [-1.20,0.04]: box(self,"FlapHingeGuide",Vector3(x,2.24,1.27),Vector3(0.04,0.64,0.06),Color("93849a"))
    funnel(); chute()
    disk = Node3D.new(); disk.name = "SelectionDisk"; disk.position = Vector3(-0.58,2.96,-0.50); add_child(disk)
    var torus := TorusMesh.new(); torus.inner_radius = 0.43; torus.outer_radius = 0.675; torus.rings = 24; torus.ring_segments = 8
    var ring := MeshInstance3D.new(); ring.mesh = torus; ring.scale.y = 0.18/0.245; ring.material_override = Craft.material(teal); disk.add_child(ring)
    box(disk,"IndexTab",Vector3(0.53,0,0),Vector3(0.22,0.18,0.12),pink)
    gate = box(self,"ReleaseGate",Vector3(-0.58,2.84,-0.50),Vector3(0.85,0.04,0.85),Color("77687e"))
    var glass := MeshInstance3D.new(); glass.name = "ClearHopper"; glass.mesh = glass_mesh(); glass.position.y = GLASS_CENTER; glass.scale = GLASS_RADII
    var mat := ShaderMaterial.new(); mat.shader = load("res://assets/shaders/gashapon_glass.gdshader"); glass.material_override = mat
    glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF; add_child(glass); casing.append(glass)
    mounting_groove("BaseGroove",GLASS_BOTTOM,1,self)
    var top := Node3D.new(); top.name = "TopCap"; top.position.y = GLASS_TOP; add_child(top)
    mounting_groove("LidGroove",GLASS_TOP,-1,top)
    var lid := MeshInstance3D.new(); lid.name = "FlatLid"
    var cylinder := CylinderMesh.new(); cylinder.top_radius = glass_radius(GLASS_TOP)+0.12; cylinder.bottom_radius = cylinder.top_radius; cylinder.height = 0.24; cylinder.radial_segments = 32
    lid.mesh = cylinder; lid.position.y = 0.15; lid.material_override = Craft.material(cream); top.add_child(lid)
    orb(top,Vector3(0,0.26,0),Vector3(0.48,0.08,0.40),teal)
    var ears := Node3D.new(); ears.position.y = -1.97; top.add_child(ears)
    PetCapsule.cat_ear(ears,-1,cream,pink,false); PetCapsule.cat_ear(ears,1,cream,pink,false)
    var title := box(top,"TitlePlate",Vector3(0,0.02,1.75),Vector3(2.45,0.46,0.12),dark)
    Craft.label(top,"PET GASHAPON",Vector3(0,0.02,1.83),Color("dd98bd"),0.0037,32)
    for side in [-1,1]:
        for y in [0.10,0.17,0.24]:
            var whisker := box(top,"Whisker",Vector3(side*1.40,y,1.0),Vector3(0.23,0.025,0.025),dark)
            whisker.rotation.y = atan2(side*1.40,1.0)
    box(self,"LampFixture",Vector3(0,6.02,0),Vector3(0.48,0.08,0.40),dark)
    Craft.box(self,Vector3(0,5.965,0),Vector3(0.4,0.025,0.34),Color("eedab1"),0.01,0.4)
    var lamp := SpotLight3D.new(); lamp.name = "HopperLamp"; lamp.position.y = 5.94; lamp.rotation_degrees.x = -90
    lamp.light_color = Color("ffe6bf"); lamp.light_energy = 0.60; lamp.spot_range = 4; lamp.spot_angle = 48; add_child(lamp)
    var highlights := Node3D.new(); highlights.name = "GlassHighlights"; add_child(highlights); casing.append(highlights)
    glass_highlight(highlights,deg_to_rad(140),-0.25,0.35,0.045)
    glass_highlight(highlights,deg_to_rad(40),0.06,0.30,0.026)
    lower_dressing()
    reset()
    make_sounds()

func reset(kind := 5) -> void:
    if busy: return
    for pet in pile: pet.free()
    pile.clear()
    var positions := [Vector3(-0.70,3.55,0.40),Vector3(0,3.55,0.40),Vector3(-0.35,3.881,-0.08),Vector3(0.35,3.881,-0.08),Vector3(0.70,3.55,0.40),Vector3(0,4.332,-0.45)]
    for i in range(6):
        var pet := load("res://scenes/pets/"+PETS[kind if i==5 else i]+".tscn").instantiate() as Node3D
        pet.position = positions[i]; pet.scale = Vector3.ONE*0.34; add_child(pet); pile.append(pet)
    selected = pile[5]
    knob.rotation.z = 0; disk.rotation.y = 0; gate.position.x = -0.58; flap.rotation.x = 0; flap.position = Vector3(-0.58,1.95,1.49)

func set_cutaway(value: bool) -> void:
    cutaway = value
    for part in casing: part.visible = not value

func dispense() -> bool:
    if busy or selected==null or selected.position.y<1: return false
    busy = true; sound_step = -1
    cycle = create_tween()
    cycle.tween_method(sample,0.0,2.5,2.5)
    cycle.finished.connect(func(): busy = false; dispensed.emit())
    return true

func sample(t: float) -> void:
    knob.rotation.z = -PI/2*clampf(t/0.35,0,1)
    disk.rotation.y = PI/2*clampf((t-0.35)/0.35,0,1)
    gate.position.x = -0.58+1.25*clampf((t-0.55)/0.15,0,1)
    flap.rotation.x = deg_to_rad(55)*clampf((t-0.70)/0.25,0,1)
    # After tilting, the hinge carriage lifts behind the lintel, clearing rabbit ears.
    flap.position.z = 1.49-0.10*clampf((t-0.95)/0.10,0,1)
    flap.position.y = 1.95+0.52*clampf((t-1.05)/0.10,0,1)
    var idx := 0
    while idx<TIMES.size()-2 and t>TIMES[idx+1]: idx += 1
    var u := clampf((t-TIMES[idx])/(TIMES[idx+1]-TIMES[idx]),0,1)
    selected.position = ROUTE[idx].lerp(ROUTE[idx+1],u)
    if t<0.35: selected.position = ROUTE[0]
    if t>2.18: selected.position.y += sin(u*PI)*0.07*(1-u)
    selected.rotation.z = sin(t*18)*0.035 if t>0.7 and t<2.18 else 0
    var step := 0 if t<0.7 else 1 if t<2.18 else 2
    if step!=sound_step:
        sound_step = step; voice.stream = sounds[step]; voice.play()

func make_sounds() -> void:
    voice = AudioStreamPlayer3D.new(); voice.position = Vector3(0,2,0); voice.volume_db = -14; voice.max_distance = 24; add_child(voice)
    var rng := RandomNumberGenerator.new(); rng.seed = 707
    for kind in range(3):
        var data := PackedByteArray(); var duration := 0.12 if kind==0 else 1.48 if kind==1 else 0.25
        for i in range(int(22050*duration)):
            var t := i/22050.0
            var env := exp(-t*40) if kind==0 else pow(1-t/duration,2)
            var wave := rng.randf_range(-1,1)*0.3+sin(TAU*(150 if kind==0 else 85 if kind==1 else 210)*t)*0.6
            if kind==1: wave *= 0.3+0.7*pow(absf(sin(t*65)),6)
            var v := int(wave*env*13000); data.append(v&255); data.append((v>>8)&255)
        var stream := AudioStreamWAV.new(); stream.format = AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate = 22050; stream.data = data; sounds[kind] = stream

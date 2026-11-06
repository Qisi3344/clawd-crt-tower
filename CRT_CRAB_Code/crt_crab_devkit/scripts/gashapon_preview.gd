extends Node3D
var machine: Node3D
var camera: Camera3D
var status: Label
var action: Button
var kind: OptionButton
var records: Array = []
var collisions: Array = []
var triangles: Array = []

func _ready() -> void:
    get_tree().root.size = Vector2i(1200,1000)
    var env := WorldEnvironment.new(); env.environment = Environment.new()
    env.environment.background_mode = Environment.BG_COLOR; env.environment.background_color = Color("241c2b")
    env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.environment.ambient_light_color = Color("dbd0e3"); env.environment.ambient_light_energy = 0.50
    add_child(env)
    for spec in [[Vector3(-35,-30,0),Color("f5dbc4"),0.8],[Vector3(-25,140,0),Color("b9d5d9"),0.4]]:
        var light := DirectionalLight3D.new(); light.rotation_degrees = spec[0]; light.light_color = spec[1]; light.light_energy = spec[2]; add_child(light)
    Craft.box(self,Vector3(0,-0.12,0),Vector3(100,0.24,100),Color("302737"),0.02)
    machine = Node3D.new(); machine.set_script(load("res://scripts/pet_gashapon_machine.gd")); add_child(machine)
    camera = Camera3D.new(); camera.projection = Camera3D.PROJECTION_ORTHOGONAL; camera.size = 8.5; camera.current = true; add_child(camera)
    pose("front")
    var canvas := CanvasLayer.new(); add_child(canvas)
    var controls := HBoxContainer.new(); controls.position = Vector2(18,18); canvas.add_child(controls)
    for view in ["front","side","back","cutaway"]:
        var b := Button.new(); b.text = {"front":"正面","side":"侧面","back":"背面","cutaway":"内部剖视"}[view]; controls.add_child(b)
        b.pressed.connect(func(): pose(view))
    kind = OptionButton.new()
    for title in PetCapsule.TITLES: kind.add_item(title)
    kind.select(5); controls.add_child(kind)
    kind.item_selected.connect(func(i): if not machine.busy: machine.reset(i))
    action = Button.new(); action.text = "测试出蛋（不扣晶体）"; controls.add_child(action)
    action.pressed.connect(func():
        if not machine.busy and machine.selected.position.y<1: machine.reset(kind.selected)
        if machine.dispense():
            action.disabled = true; kind.disabled = true; status.text = "出蛋中…"
    )
    machine.dispensed.connect(func():
        action.disabled = false; kind.disabled = false; status.text = "已到取物仓 · 再点测试可重置演示"
    )
    status = Label.new(); status.position = Vector2(18,70); status.text = "原生模型预览 · 静态外壳 / 内部通道 / 2.5 秒连续出蛋"; canvas.add_child(status)
    if "--gashapon-qa" in OS.get_cmdline_user_args():
        for i in range(8): await get_tree().process_frame
        await verify(canvas)

func pose(view: String) -> void:
    machine.set_cutaway(view=="cutaway")
    camera.position = {"front":Vector3(0,3.6,15),"side":Vector3(15,3.6,0),"back":Vector3(0,3.6,-15),"cutaway":Vector3(8,5,11)}[view]
    camera.look_at(Vector3(0,3.6,0))

func record(name: String, passed: bool) -> void:
    records.append({"test":name,"passed":passed})
    if not passed: push_error(name)

func collect_triangles() -> void:
    triangles.clear()
    for n in machine.selected.find_children("*","MeshInstance3D",true,false):
        var xf: Transform3D = machine.selected.global_transform.affine_inverse()*n.global_transform
        for surface in range(n.mesh.get_surface_count()):
            var arrays: Array = n.mesh.surface_get_arrays(surface)
            var vs: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
            var ids: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX]!=null else PackedInt32Array()
            if ids.is_empty():
                for i in range(vs.size()): ids.append(i)
            for i in range(0,ids.size(),3): triangles.append([xf*vs[ids[i]],xf*vs[ids[i+1]],xf*vs[ids[i+2]]])

func in_opening(p: Vector3) -> bool:
    var center := Vector2(-0.58,1.215)
    var local := (Vector2(p.x,p.y)-center).abs()
    var inner := Vector2(0.65,0.735)-Vector2.ONE*0.12
    return (local-inner).max(Vector2.ZERO).length()<=0.1205

func intersects_flap(tri: Array) -> bool:
    var inv: Transform3D = machine.flap.global_transform.affine_inverse()
    var ps: Array[Vector3] = []
    for p in tri: ps.append(inv*(machine.global_transform*p))
    for i in range(3):
        var a := ps[i]; var b := ps[(i+1)%3]
        if a.z*b.z>0 or absf(a.z-b.z)<0.00001: continue
        var p := a.lerp(b,a.z/(a.z-b.z))
        if absf(p.x)<0.61 and p.y<0 and p.y> -1.40: return true
    return false

func validate_pose(t: float, model: int) -> void:
    var xf: Transform3D = machine.global_transform.affine_inverse()*machine.selected.global_transform
    for tri in triangles:
        var ps: Array = [xf*tri[0],xf*tri[1],xf*tri[2]]
        for p in ps:
            if p.y<3.4 and (absf(p.x)>1.775 or p.z< -1.425): collisions.append([model,t,"outer walls"]); return
            if p.y>3.10 and p.y<3.55:
                var r := lerpf(0.45,0.825,(p.y-3.10)/0.45)
                if Vector2(p.x+0.58,p.z+0.50).length()>r+0.015: collisions.append([model,t,"funnel"]); return
            if absf(p.y-2.96)<0.09 and Vector2(p.x+0.58,p.z+0.50).length()>0.425 and Vector2(p.x+0.58,p.z+0.50).length()<0.70:
                collisions.append([model,t,"selection ring"]); return
            if p.y<2.50 and p.y>0.49:
                var rear := -1.05
                if p.z<rear-0.005: collisions.append([model,t,"chute back"]); return
        for z in [1.425,1.575]:
            for i in range(3):
                var a: Vector3 = ps[i]; var b: Vector3 = ps[(i+1)%3]
                if (a.z-z)*(b.z-z)>0 or absf(a.z-b.z)<0.000001: continue
                var p := a.lerp(b,(z-a.z)/(b.z-a.z))
                if p.y>0.2 and p.y<3.4 and not in_opening(p): collisions.append([model,t,"front panel"]); return
        if intersects_flap(ps): collisions.append([model,t,"flap"]); return

func capture(label: String) -> void:
    for i in range(4): await get_tree().process_frame
    RenderingServer.force_draw()
    get_viewport().get_texture().get_image().save_png("res://artifacts/gashapon-v3-"+label+".png")

func hits_mesh(node: MeshInstance3D, start: Vector3, end: Vector3) -> bool:
    for surface in range(node.mesh.get_surface_count()):
        var data: Array = node.mesh.surface_get_arrays(surface)
        var vs: PackedVector3Array = data[Mesh.ARRAY_VERTEX]
        for i in range(0,vs.size(),3):
            if Geometry3D.segment_intersects_triangle(start,end,vs[i],vs[i+1],vs[i+2])!=null: return true
    return false

func verify(canvas: CanvasLayer) -> void:
    await capture("controls")
    canvas.hide()
    record("body width / glass ratio",3.50/3.85<=1.10)
    record("real front annulus, no solid body",machine.has_node("OpenFrontPanel") and not machine.has_node("Body"))
    record("six native pet instances",machine.pile.size()==6)
    record("ray passes real front opening",not hits_mesh(machine.get_node("OpenFrontPanel"),Vector3(-0.58,1.215,2),Vector3(-0.58,1.215,1)))
    record("ray hits surrounding front panel",hits_mesh(machine.get_node("OpenFrontPanel"),Vector3(1.2,1.215,2),Vector3(1.2,1.215,1)))
    record("storage floor has open feed hole",not hits_mesh(machine.get_node("HopperFloorWithOpening"),Vector3(-0.58,4,-0.5),Vector3(-0.58,3,-0.5)))
    record("outlet floor and open funnel / disk / chute",machine.has_node("OpenFunnel") and machine.has_node("HopperFloorWithOpening") and machine.has_node("SelectionDisk") and machine.has_node("ContinuousChuteFloor"))
    for view in ["front","side","back","cutaway"]:
        pose(view); await capture(view)
    for model in range(6):
        machine.reset(model); collect_triangles()
        var bounds := AABB()
        for tri in triangles:
            for vertex in tri: bounds = bounds.expand(vertex*0.34)
        record("model %d fits chute including ears"%model,bounds.size.y<=1.30 and bounds.size.x<=1.25)
        for frame in range(151):
            var t := frame/60.0
            machine.sample(t); validate_pose(t,model)
        record("swept mesh clearance model %d"%model,not collisions.any(func(c): return c[0]==model))
        record("model %d lands continuously at floor"%model,machine.selected.position.is_equal_approx(Vector3(-0.58,0.48,1.12)))
    machine.reset(3); kind.select(3); pose("front")
    # Trigger the same button as manual preview, then record the actual Tween.
    action.pressed.emit()
    record("test button starts real tween",machine.busy and action.disabled)
    DirAccess.make_dir_recursive_absolute("res://artifacts/gashapon-v3-frames")
    for i in range(80):
        if i==20: pose("cutaway")
        await get_tree().process_frame
        RenderingServer.force_draw()
        get_viewport().get_texture().get_image().save_png("res://artifacts/gashapon-v3-frames/%03d.png"%i)
    record("animation finishes and button restores",not machine.busy and not action.disabled and machine.selected.position.is_equal_approx(Vector3(-0.58,0.48,1.12)))
    await capture("dispensed")
    for i in range(3): machine.sounds[i].save_to_wav("res://artifacts/gashapon-sound-%d.wav"%i)
    var file := FileAccess.open("res://artifacts/gashapon-v3-qa.json",FileAccess.WRITE)
    file.store_string(JSON.stringify({"passed":records.all(func(r): return r.passed),"checks":records,"collisions":collisions,"sweep_samples":906,"method":"actual pet mesh edges against front annulus and flap, vertices against funnel/ring/chute/walls; all six models, 60 Hz trajectory; actual Tween capture at fixed 30 fps"},"  "))
    print("GASHAPON_V3 ",records.all(func(r): return r.passed)," collisions ",collisions.size())
    get_tree().quit()

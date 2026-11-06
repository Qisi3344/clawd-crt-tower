class_name PetHopper
extends Node3D
const DISPLAY_KINDS := [0,1,0,1,0,1,0,1,0,1,0,1,0,2,3,4,2,5]
const DISPLAY_SCALE := 0.38
const LAYER := 1<<18
static var hulls: Dictionary = {}
var bodies: Array[RigidBody3D] = []
var visuals: Array[Node3D] = []
var shake_tween: Tween

func collider(parent: Node3D, shape: Shape3D, p: Vector3) -> void:
    var node := CollisionShape3D.new(); node.shape = shape; node.position = p; parent.add_child(node)

func _ready() -> void:
    var machine := get_parent()
    var arena := StaticBody3D.new(); arena.name = "GlassPhysicsBoundary"; arena.collision_layer = LAYER; arena.collision_mask = LAYER; add_child(arena)
    var vertices: PackedVector3Array = machine.glass_mesh().surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
    for i in range(vertices.size()): vertices[i] = vertices[i]*machine.GLASS_RADII+Vector3(0,machine.GLASS_CENTER,0)
    var glass := ConcavePolygonShape3D.new(); glass.set_faces(vertices); glass.backface_collision = true
    collider(arena,glass,Vector3.ZERO)
    var floor_shape := CylinderShape3D.new(); floor_shape.radius = machine.glass_radius(machine.GLASS_BOTTOM)-0.01; floor_shape.height = 0.12
    collider(arena,floor_shape,Vector3(0,machine.GLASS_BOTTOM-0.06,0))
    var lid := CylinderShape3D.new(); lid.radius = machine.glass_radius(machine.GLASS_TOP); lid.height = 0.12
    collider(arena,lid,Vector3(0,machine.GLASS_TOP+0.06,0))
    var rng := RandomNumberGenerator.new()
    if "--qa" in OS.get_cmdline_user_args() or "--gacha-qa" in OS.get_cmdline_user_args(): rng.seed = 1807
    else: rng.randomize()
    for i in range(DISPLAY_KINDS.size()):
        var kind: int = DISPLAY_KINDS[i]
        var body := RigidBody3D.new(); body.name = "Capsule%02d"%i
        body.collision_layer = LAYER; body.collision_mask = LAYER; body.mass = 0.22
        body.linear_damp = 2.5; body.angular_damp = 3.5
        var material := PhysicsMaterial.new(); material.friction = 0.75; material.bounce = 0.03; body.physics_material_override = material
        body.position = Vector3((i%3-1)*0.85,3.66+floori(i/9.0)*1.08,((i/3)%3-1)*0.85)
        body.rotation_degrees = Vector3(rng.randf_range(-4,4),rng.randf_range(-22,22),rng.randf_range(-4,4))
        add_child(body)
        var visual := load("res://scenes/pets/"+PetGachaStore.IDS[kind]+".tscn").instantiate() as Node3D
        visual.compact_display = true; visual.scale = Vector3.ONE*DISPLAY_SCALE; body.add_child(visual)
        if not hulls.has(kind):
            var points := PackedVector3Array()
            for mesh in visual.find_children("*","MeshInstance3D",true,false):
                var xf: Transform3D = body.global_transform.affine_inverse()*mesh.global_transform
                for surface in range(mesh.mesh.get_surface_count()):
                    for v in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: points.append(xf*v)
            var hull := ConvexPolygonShape3D.new(); hull.points = points; hulls[kind] = hull
        collider(body,hulls[kind],Vector3.ZERO)
        body.linear_velocity = Vector3(rng.randf_range(-0.04,0.04),0,rng.randf_range(-0.04,0.04))
        bodies.append(body); visuals.append(visual)

func shake() -> void:
    if shake_tween!=null and shake_tween.is_running(): return
    shake_tween = create_tween()
    shake_tween.tween_method(func(t: float):
        var wave := sin(t*TAU*3)*(1-t)
        for i in range(visuals.size()):
            visuals[i].position = Vector3(wave*0.025,0,0)
            visuals[i].rotation.z = wave*deg_to_rad(4)
    ,0.0,1.0,0.55)
    shake_tween.finished.connect(func():
        for visual in visuals: visual.position = Vector3.ZERO; visual.rotation = Vector3.ZERO
    )

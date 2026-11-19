extends Node3D

# One painted mesh per scenic group lets the cutaway dissolve a whole cabinet together.
const PAINT := preload("res://assets/shaders/club_stage.gdshader")
const RACK_MODELS := preload("res://assets/environment/crt_rack/service_racks.glb")
const RACK_PAINT := preload("res://assets/environment/crt_rack/rack.gdshader")
const SOFTEN := preload("res://assets/shaders/club_foreground.gdshader")
const FINISH := preload("res://scripts/hall_surface_finish.gd")
var emitting_materials: Array[ShaderMaterial] = []
var cutaways: Array[Dictionary] = []
var surface: SurfaceTool

func panel(at: Vector3, size: Vector3, paint: Color, radius := 0.04, pitch := 0.0) -> void:
	var arrays := Craft.rounded_mesh(size,radius).surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var basis := Basis(Vector3.RIGHT,pitch)
	for i in range(vertices.size()):
		surface.set_color(paint)
		surface.set_normal(basis*normals[i])
		surface.add_vertex(at+basis*vertices[i])

func begin_group() -> void:
	surface = SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)

func finish_group(label: String, at: Vector3, yaw := 0.0, mist := 0.0, cutaway := true, soft := false, authored_mesh: Mesh = null) -> MeshInstance3D:
	var prop := MeshInstance3D.new()
	prop.name = label
	if authored_mesh:
		prop.mesh = authored_mesh
	else:
		surface.index()
		prop.mesh = surface.commit()
	var paint := ShaderMaterial.new()
	paint.shader = RACK_PAINT if authored_mesh else PAINT
	paint.set_shader_parameter("patina_map",preload("res://assets/environment/decals/enamel_patina.png"))
	if authored_mesh:
		paint.set_shader_parameter("artwork",preload("res://assets/environment/crt_rack/service_displays.png"))
	paint.set_shader_parameter("mist",mist)
	if soft:
		var lens := ShaderMaterial.new()
		lens.shader = SOFTEN
		paint.next_pass = lens
	prop.material_override = paint
	prop.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(prop)
	prop.position = at
	prop.rotation.y = yaw
	if cutaway:
		cutaways.append({"node":prop,"paint":paint,"coverage":1.0,"bounds":prop.global_transform*prop.get_aabb()})
	return prop

func build() -> void:
	# The upper carpet ends flush with the original deck at z=23. The near aisle is lower.
	begin_group()
	panel(Vector3(0,-1.132,19.6),Vector3(9,0.025,6.8),Color("332b40"),0.009)
	for side in [-1,1]:
		for stripe in [0.0,0.17]:
			panel(Vector3(side*(4.38-stripe),-1.112,19.6),Vector3(0.035,0.008,6.7),Color("766071"),0.002)
	for z in [16.45,22.72]:
		panel(Vector3(0,-1.110,z),Vector3(8.72,0.008,0.07),Color("826978"),0.002)
	# A woven diamond repeat just inside the binding.
	for i in range(-6,7):
		for sign_x in [-1,1]:
			for sign_z in [-1,1]:
				panel(Vector3(i*0.61+sign_x*0.07,-1.109,22.46+sign_z*0.056),Vector3(0.13,0.008,0.065),Color("686071"),0.002)
	var rug := finish_group("BoundEntryCarpet",Vector3.ZERO,0,0,false)
	rug.material_override.set_shader_parameter("woven_carpet",true)

	begin_group()
	for i in range(4):
		var top := -1.15-(i+1)*0.51
		var z := 23.32+i*0.64
		panel(Vector3(0,(top-3.7)/2.0,z),Vector3(9.4,top+3.7,0.66),Color("3c3746"))
		panel(Vector3(0,top-0.04,z+0.30),Vector3(9.2,0.08,0.055),Color("756377"),0.018)
		for side in [-1,1]:
			panel(Vector3(side*4.20,top-0.20,z+0.34),Vector3(0.53,0.065,0.025),Color("a2b5a2"),0.008)
	for side in [-1,1]:
		for i in range(4):
			var x: float = side*(7.42+5.3*i)
			panel(Vector3(x,-2.43,22.72),Vector3(5.23,2.53,0.55),Color("353342"),0.1)
			panel(Vector3(x,-2.56,23.02),Vector3(4.77,1.28,0.11),Color("242937"),0.09)
			panel(Vector3(x,-1.41,23.06),Vector3(4.85,0.10,0.10),Color("789e9e") if i%2==0 else Color("99778a"),0.03)
			for v in range(3):
				panel(Vector3(x,-2.28-v*0.23,23.09),Vector3(3.69-v*0.34,0.06,0.045),Color("4a4857"),0.015)
	finish_group("EntryStepsAndFootlights",Vector3.ZERO,0,0,false)
	for side in [-1,1]:
		build_entrance_wing(side)
		build_arcade(Vector3(side*15.4,-1.15,18.4),PI+side*0.24,side)
	# Far rows sit on consoles at two depths and wrap the open corners.
	var index := 0
	var rack_models := RACK_MODELS.instantiate()
	for loc in [Vector3(-29,-3.70,32),Vector3(-13,-3.70,42),Vector3(5,-3.70,38),Vector3(22,-3.70,44),Vector3(36,-3.70,23),Vector3(-40,-3.70,13),Vector3(-3,-3.70,56),Vector3(36,-3.70,54)]:
		build_bank(loc,atan2(-loc.x,-loc.z),index,rack_models)
		index += 1
	rack_models.free()
	var ground := MeshInstance3D.new()
	ground.name = "LowerAisle"
	var plane := PlaneMesh.new()
	plane.size = Vector2(204,204)
	ground.mesh = plane
	ground.position.y = -3.71
	var tiles := ShaderMaterial.new()
	tiles.shader = preload("res://assets/shaders/club_aisle.gdshader")
	ground.material_override = tiles
	ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(ground)

func build_entrance_wing(side: int) -> void:
	begin_group()
	var metal := Color("403c4b")
	var strip := Color("80a09e") if side<0 else Color("ac8299")
	panel(Vector3(0,0.15,0),Vector3(8.5,0.30,1.18),metal,0.10)
	# Low rails can be seen from either side. The opening lines up with the steps.
	for x in [-3.85,0.0,3.85]:
		panel(Vector3(x,0.77,0),Vector3(0.28,1.30,0.64),metal,0.06)
	for height in [0.63,1.38]:
		panel(Vector3(0,height,0),Vector3(8.12,0.17,0.46),Color("554b59"))
		for face in [-1,1]:
			panel(Vector3(0,height,face*0.24),Vector3(7.85,0.048,0.03),strip,0.01)
	var post := side*2.80
	panel(Vector3(post,1.60,0),Vector3(0.37,3.20,0.63),metal)
	panel(Vector3(post,2.99,0),Vector3(3.65,0.99,0.64),Color("655a69"),0.16)
	for face in [-1,1]:
		panel(Vector3(post,3.0,face*0.32),Vector3(3.39,0.76,0.08),Color("273744"),0.11)
		panel(Vector3(post,2.68,face*0.367),Vector3(2.90,0.035,0.025),strip,0.009)
	var wing := finish_group("EntryRailWest" if side<0 else "EntryRailEast",Vector3(side*9.1,-1.15,21.85))
	var legends: Array[Label3D] = []
	for face in [-1,1]:
		var sign_text := "ARCADE" if side<0 else "ENTRY"
		var legend := Craft.label(wing,sign_text,Vector3(post,3.04,face*0.369),Color("a2b3b1"),0.013,36)
		if face<0: legend.rotation.y = PI
		legends.append(legend)
	cutaways.back()["legends"] = legends

func build_arcade(at: Vector3, yaw: float, side: int) -> void:
	begin_group()
	var enamel := Color("514554") if side<0 else Color("394d58")
	# Recessed CRT, sloped control deck, marquee hood, and thicker side cheeks.
	panel(Vector3(0,0.13,0),Vector3(2.74,0.25,1.99),Color("242b38"),0.06)
	panel(Vector3(0,1.05,0),Vector3(2.65,2.1,1.85),enamel,0.12)
	for sidewall in [-1,1]:
		panel(Vector3(sidewall*1.29,3.18,0.03),Vector3(0.16,2.20,1.65),enamel,0.06,-0.16)
		panel(Vector3(sidewall*1.38,3.18,0.14),Vector3(0.035,1.65,0.095),Color("837184"),0.014,-0.45)
	panel(Vector3(0,3.12,-0.20),Vector3(2.57,2.34,1.55),enamel,0.13)
	# The service hatch faces the entrance when the cabinet is seen from the aisle.
	panel(Vector3(0,1.25,-0.95),Vector3(2.19,1.37,0.10),Color("34323f"),0.07)
	for i in range(4):
		panel(Vector3(0.38,1.40-i*0.13,-1.015),Vector3(0.84,0.045,0.035),Color("555060"),0.012)
	panel(Vector3(-0.67,0.81,-1.015),Vector3(0.37,0.22,0.03),Color("726c77"),0.015)
	for i in range(3):
		panel(Vector3(0,3.32-i*0.13,-1.0),Vector3(1.62,0.045,0.07),Color("393947"),0.015)
	panel(Vector3(0,3.25,0.65),Vector3(2.17,1.75,0.20),Color("272936"),0.13,-0.14)
	panel(Vector3(0,3.26,0.77),Vector3(1.83,1.37,0.16),Color("455d65"),0.16,-0.14)
	panel(Vector3(0.42,3.46,0.87),Vector3(0.54,0.035,0.03),Color("668187"),0.008,-0.14)
	panel(Vector3(0,2.15,0.65),Vector3(2.85,0.31,1.24),enamel,0.10,-0.12)
	panel(Vector3(-0.67,2.48,0.88),Vector3(0.14,0.30,0.14),Color("886e82"),0.06)
	for i in range(2):
		panel(Vector3(0.40+i*0.28,2.37,0.91),Vector3(0.19,0.07,0.17),Color("779295"),0.03)
	panel(Vector3(0,4.62,0.06),Vector3(2.92,0.75,2.13),enamel,0.14)
	panel(Vector3(0,4.60,1.12),Vector3(2.56,0.40,0.055),Color("76657c"),0.045)
	for i in range(3):
		panel(Vector3(-0.64+i*0.37,4.60,1.16),Vector3(0.22,0.12,0.025),Color("9b8690"),0.012)
	panel(Vector3(0.36,1.27,0.96),Vector3(0.54,0.79,0.08),Color("34313d"),0.045)
	panel(Vector3(0.36,1.44,1.01),Vector3(0.22,0.06,0.04),Color("779295"),0.01)
	var cabinet := finish_group("EntryArcadeWest" if side<0 else "EntryArcadeEast",at,yaw,0.07,true,true)
	var paint: ShaderMaterial = cabinet.material_override
	paint.set_shader_parameter("entry_display",true)
	paint.set_shader_parameter("signals",preload("res://assets/environment/crt_rack/service_displays.png"))
	paint.set_shader_parameter("signal_tile",Vector2(1,0) if side<0 else Vector2(2,0))
	emitting_materials.append(paint)
	var patch := FINISH.contact_patch(cabinet,Vector2(2.55,1.82),0.25)
	patch.position.y = 0.008
	cutaways.back()["contact_shadow"] = patch.material_override
	# Power leaves the existing rear hatch and lands on a fixed deck outlet.
	var cable := Node3D.new()
	cabinet.add_child(cable)
	var outlet := Vector3(side*3.25,0.058,-2.88)
	Craft.box(cable,outlet,Vector3(0.42,0.10,0.33),Color("554f64"))
	Craft.box(cable,outlet+Vector3(0,0.07,0),Vector3(0.17,0.11,0.16),Color("9990a0"),0.025)
	Craft.cable(cable,PackedVector3Array([Vector3(-0.67,0.81,-1.04),Vector3(-0.67,0.79,-1.22),Vector3(-0.55,0.16,-1.36),Vector3(-0.32,0.062,-1.48),Vector3(side*1.28,0.062,-2.28),Vector3(side*2.24,0.062,-2.57),outlet+Vector3(0,0.13,0)]),Color("786c83"),0.064)
	Craft.batch_static(cable)

func build_bank(at: Vector3, yaw: float, index: int, models: Node3D) -> void:
	var mirrored := index in [1,3,5,6]
	var source := models.get_node("FarRack" if mirrored else "NearRack") as MeshInstance3D
	var mist := lerpf(0.20,0.57,smoothstep(36.0,65.0,at.length()))
	var rack := finish_group("DistantCRTBank%d"%index,at,yaw,mist,true,false,source.mesh)
	var paint: ShaderMaterial = rack.material_override
	paint.set_shader_parameter("layout_sign",-1.0 if mirrored else 1.0)
	paint.set_shader_parameter("program_shift",0 if index in [2,6] else (index+1)%5)
	emitting_materials.append(paint)
	var shadow := FINISH.contact_patch(rack,Vector2(7.44,2.48),1.0)
	cutaways.back()["contact_shadow"] = shadow.material_override

func set_energy(energy: float) -> void:
	for mat in emitting_materials: mat.set_shader_parameter("spill_energy",energy)

func update_cutaways(eye: Vector3, targets: Array[Vector3]) -> void:
	for item in cutaways:
		var bounds: AABB = item.bounds
		var center := bounds.get_center()
		var radius := bounds.size.length()*0.5
		var clearance := eye.distance_to(center)-radius
		for target in targets:
			var closest := Geometry3D.get_closest_point_to_segment(center,eye,target)
			clearance = minf(clearance,closest.distance_to(center)-radius)
		var coverage := smoothstep(0.0,3.4,clearance)
		if is_equal_approx(coverage,item.coverage): continue
		item.coverage = coverage
		item.node.visible = coverage>0.001
		item.paint.set_shader_parameter("coverage",coverage)
		if item.has("contact_shadow"): item.contact_shadow.set_shader_parameter("coverage",coverage)
		for legend in item.get("legends",[]):
			legend.modulate.a = coverage
		if item.paint.next_pass:
			item.paint.next_pass.set_shader_parameter("coverage",coverage)

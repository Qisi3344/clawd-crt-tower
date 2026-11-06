extends Node3D
# Opt-in art sample. Normal main scene never loads this script.
var changed: Array = []
var converted := {}
var original_environment: Environment
var world_environment: WorldEnvironment
var original_lights: Array = []
var additions: Node3D
var enabled := false

func cel(source: StandardMaterial3D) -> ShaderMaterial:
	var id := source.get_instance_id()
	if converted.has(id): return converted[id]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/light_cel.gdshader")
	mat.set_shader_parameter("base_color",source.albedo_color)
	mat.set_shader_parameter("textured",source.albedo_texture!=null)
	if source.albedo_texture!=null: mat.set_shader_parameter("base_texture",source.albedo_texture)
	converted[id] = mat
	return mat

func eligible(mat: Material) -> bool:
	return mat is StandardMaterial3D and mat.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not mat.emission_enabled

func prepare(game: Node) -> void:
	name = "ArcadeStyleSample"
	additions = Node3D.new()
	additions.name = "VisibleSourceLighting"
	add_child(additions)
	for child in game.shell.get_children():
		if child is WorldEnvironment: world_environment = child
		if child is DirectionalLight3D: original_lights.append(child)
	original_environment = world_environment.environment
	var arcade: Node3D = game.surroundings.zones[1].get_children().filter(func(n): return n is EnvironmentProp and n.asset_id.contains("arcade"))[0]
	var roots := [game.devices[0],game.devices[4],game.shell.get_node("GapFillers/Speaker_A"),game.shell.get_node("GapFillers/Speaker_B"),arcade]
	for target in roots:
		for node in target.find_children("*","GeometryInstance3D",true,false):
			if node.is_queued_for_deletion(): continue
			if eligible(node.material_override):
				changed.append([node,-1,node.material_override,cel(node.material_override)])
			elif node is MeshInstance3D and node.material_override==null:
				for i in range(node.mesh.get_surface_count()):
					var src: Material = node.get_active_material(i)
					if eligible(src): changed.append([node,i,node.get_surface_override_material(i),cel(src)])
	# A visible suspended fluorescent fitting, warm tube and solid metal housing.
	Craft.box(additions,Vector3(0,17.5,13.5),Vector3(7,0.22,1.0),Color("44404e"),0.04)
	Craft.box(additions,Vector3(0,17.36,13.5),Vector3(6.5,0.06,0.65),Color("f3dfbb"),0.02,1.2)
	for x in [-2.7,2.7]:
		Craft.cable(additions,PackedVector3Array([Vector3(x,17.6,13.5),Vector3(x,20.2,13.5)]),Color("38333f"),0.025)
	lamp(Vector3(0,17.1,13.5),Color("ffe5c4"),3.8,32,true)
	for device in [game.devices[0],game.devices[4]]:
		lamp(device.to_global(Vector3(0,0.2,2.02)),Color("6acdbb") if device.model==0 else Color("c996d2"),0.55,4.1,false)
	lamp(arcade.to_global(Vector3(0,3.537,0.75)),Color("67d6c8"),0.65,4.5,false)
	var sign := Craft.box(additions,arcade.to_global(Vector3(0,5.12,1.39)),Vector3(2.3,0.20,0.10),Color("384144"),0.02)
	sign.basis = arcade.global_basis.orthonormalized()
	var title := Craft.label(sign,"PLAY / 01   1 COIN",Vector3(0,0,0.058),Color("dce65b"),0.0018,30)
	title.modulate = Color("dce65b")
	# Local fluorescent source above the existing arcade, not a colored fill.
	Craft.box(additions,Vector3(18,11,5),Vector3(4,0.18,0.7),Color("44404e"),0.03)
	Craft.box(additions,Vector3(18,10.88,5),Vector3(3.7,0.045,0.5),Color("f3dfbb"),0.015,1.0)
	for x in [16.5,19.5]:
		Craft.cable(additions,PackedVector3Array([Vector3(x,11.1,5),Vector3(x,20.2,5)]),Color("38333f"),0.02)
	lamp(Vector3(18,10.7,5),Color("f9dab5"),2.0,16,false)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(10,8)
	floor.mesh = plane
	floor.position = Vector3(0,-1.095,5)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("282131")
	mat.roughness = 0.87
	mat.metallic = 0
	mat.metallic_specular = 0.18
	floor.material_override = mat
	additions.add_child(floor)
	for x in [-3.7,3.7]:
		Craft.box(additions,Vector3(x,-1.087,8.4),Vector3(0.55,0.008,0.08),Color("a8aa53"),0.001)
	additions.hide()

func lamp(p: Vector3, color: Color, energy: float, reach: float, shadows: bool) -> void:
	var light := OmniLight3D.new()
	light.position = p
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.05
	light.shadow_enabled = shadows
	additions.add_child(light)

func set_enabled(value: bool) -> void:
	enabled = value
	for item in changed:
		if item[1]==-1: item[0].material_override = item[3] if value else item[2]
		else: item[0].set_surface_override_material(item[1],item[3] if value else item[2])
	for light in original_lights: light.visible = not value
	if value:
		var env := original_environment.duplicate() as Environment
		env.background_color = Color("181221")
		env.ambient_light_color = Color("a797b8")
		env.ambient_light_energy = 0.52
		env.glow_enabled = false
		world_environment.environment = env
	else: world_environment.environment = original_environment
	additions.visible = value

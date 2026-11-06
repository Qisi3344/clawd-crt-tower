extends Node3D
# Reversible arcade art layer; geometry/layout and pixel-screen materials stay intact.
var changed: Array = []
var converted := {}
var original_environment: Environment
var world_environment: WorldEnvironment
var original_lights: Array = []
var additions: Node3D
var enabled := false
var full_scene := false
var room_occluders: Array = []
var environment_cache: Environment
var game: Node
var decorations: Node3D
var source_lights: Array = []
@export var cel_shading_enabled := true
@export var source_light_scale := 1.0
@export var decorations_enabled := true

func cel(source: StandardMaterial3D) -> ShaderMaterial:
	var id := source.get_instance_id()
	if converted.has(id): return converted[id]
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/light_cel.gdshader")
	mat.set_shader_parameter("base_color",source.albedo_color)
	mat.set_shader_parameter("textured",source.albedo_texture!=null)
	mat.set_shader_parameter("vertex_colors",source.vertex_color_use_as_albedo)
	if source.albedo_texture!=null: mat.set_shader_parameter("base_texture",source.albedo_texture)
	converted[id] = mat
	return mat

func eligible(mat: Material) -> bool:
	return mat is StandardMaterial3D and mat.shading_mode!=BaseMaterial3D.SHADING_MODE_UNSHADED and mat.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED and not mat.emission_enabled

func prepare(owner_game: Node, whole_hall := false) -> void:
	game = owner_game
	full_scene = whole_hall
	name = "ArcadeAmbience"
	process_priority = 11 # After the camera and surroundings occlusion for this frame.
	additions = Node3D.new()
	additions.name = "VisibleSourceLighting"
	add_child(additions)
	for child in game.shell.get_children():
		if child is WorldEnvironment: world_environment = child
		if child is DirectionalLight3D: original_lights.append(child)
	original_environment = world_environment.environment
	var arcade: Node3D = game.surroundings.zones[1].get_children().filter(func(n): return n is EnvironmentProp and n.asset_id.contains("arcade"))[0]
	var roots: Array = [game.devices[0],game.devices[4],game.shell.get_node("GapFillers/Speaker_A"),game.shell.get_node("GapFillers/Speaker_B"),arcade]
	if full_scene: roots = [game.shell]
	for target in roots:
		for node in target.find_children("*","GeometryInstance3D",true,false):
			if node.is_queued_for_deletion() or is_ancestor_of(node): continue
			if eligible(node.material_override):
				var replacement: Material = cel(node.material_override)
				if full_scene and node is MeshInstance3D and node.get_aabb().size.x>20 and node.global_position.y< -1.1:
					replacement = floor_material()
				changed.append([node,-1,node.material_override,replacement])
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
	for device in (game.devices if full_scene else [game.devices[0],game.devices[4]]):
		lamp(device.to_global(Vector3(0,0.2,2.02)),Color("6acdbb") if device.model==0 else Color("c996d2"),0.30 if full_scene else 0.55,3.6 if full_scene else 4.1,false)
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
	if full_scene:
		build_hall()
	else:
		var floor := MeshInstance3D.new()
		var plane := PlaneMesh.new()
		plane.size = Vector2(10,8)
		floor.mesh = plane
		floor.position = Vector3(0,-1.095,5)
		floor.material_override = floor_material()
		additions.add_child(floor)
	additions.hide()

func lamp(p: Vector3, color: Color, energy: float, reach: float, shadows: bool) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = p
	light.light_color = color
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.05
	light.shadow_enabled = shadows
	additions.add_child(light)
	light.set_meta("source_energy",energy)
	source_lights.append(light)
	return light

func set_enabled(value: bool) -> void:
	enabled = value
	for item in changed:
		if not is_instance_valid(item[0]): continue
		if item[1]==-1: item[0].material_override = item[3] if value and cel_shading_enabled else item[2]
		else: item[0].set_surface_override_material(item[1],item[3] if value and cel_shading_enabled else item[2])
	for light in original_lights: light.visible = not value
	if environment_cache==null:
		environment_cache = original_environment.duplicate() as Environment
		environment_cache.background_color = Color("181221")
		environment_cache.ambient_light_color = Color("a797b8")
		environment_cache.ambient_light_energy = 0.52
		environment_cache.glow_enabled = false
	world_environment.environment = environment_cache if value else original_environment
	additions.visible = value
	if decorations!=null: decorations.visible = decorations_enabled
	for light in source_lights: light.light_energy = float(light.get_meta("source_energy"))*maxf(source_light_scale,0)

func floor_material() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://assets/shaders/arcade_floor.gdshader")
	return mat

func fluorescent(p: Vector3, width: float, energy: float, reach: float) -> void:
	Craft.box(additions,p,Vector3(width,0.18,0.7),Color("44404e"),0.03)
	Craft.box(additions,p+Vector3(0,-0.12,0),Vector3(width-0.3,0.045,0.5),Color("f3dfbb"),0.015,1)
	for x in [-width*0.36,width*0.36]:
		Craft.cable(additions,PackedVector3Array([p+Vector3(x,0.1,0),Vector3(p.x+x,20.2,p.z)]),Color("38333f"),0.02)
	lamp(p+Vector3(0,-0.3,0),Color("f9dab5"),energy,reach,false)

func wall(p: Vector3, size: Vector3) -> MeshInstance3D:
	var mesh := Craft.box(decorations,p,size,Color("312a3b"),0.03)
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	room_occluders.append({"node":mesh,"bounds":mesh.global_transform*mesh.get_aabb()})
	return mesh

func build_hall() -> void:
	decorations = Node3D.new()
	decorations.name = "RoomAndDecoration"
	additions.add_child(decorations)
	# Three quiet enclosure surfaces turn the existing installation into a room.
	var rear := wall(Vector3(0,9.55,-24.85),Vector3(52,21.4,0.18))
	wall(Vector3(-25.8,9.55,-8),Vector3(0.18,21.4,34))
	wall(Vector3(25.8,9.55,-8),Vector3(0.18,21.4,34))
	wall(Vector3(0,20.3,-5),Vector3(52,0.2,40))
	fluorescent(Vector3(0,17.5,-15),5,1.8,27)
	fluorescent(Vector3(-18,11,5),4,1.7,16)
	# Existing arcade screens provide the local colored light, not floating fills.
	for display in game.surroundings.zones[1].displays:
		if display.node.get_parent().position.x>0:
			lamp(display.node.to_global(Vector3(0,0,0.22)),Color("ba8fc9"),0.4,4.5,false)
	var back_sign := Craft.box(rear,Vector3(0,6.1,0.15),Vector3(12,1.2,0.12),Color("35303e"),0.04)
	Craft.label(back_sign,"CRT CLUB / 1999",Vector3(0,0,0.075),Color("d4e1cb"),0.017,40)
	Craft.box(back_sign,Vector3(-5.7,0,0.08),Vector3(0.08,0.9,0.025),Color("c4ca63"),0.005,0.3)
	var sign_light := lamp(Vector3(0,15.7,-24.55),Color("a5cfc1"),0.6,7.5,false)
	sign_light.reparent(back_sign,true)
	# User-marked central wall rectangle, underneath the existing club sign.
	var mural := Craft.sticker(rear,"no_signal_wall",Vector3(0,1.20,0.105),16.5)
	mural.name = "MainNoSignalMural"
	mural.mesh.size = Vector2(16.5,8.8)
	mural.material_override.emission_enabled = true
	mural.material_override.emission_texture = mural.material_override.albedo_texture
	mural.material_override.emission = Color("eedce8")
	mural.material_override.emission_energy_multiplier = 0.08
	for spec in [["Left",-13.5,0.45,5.4,"crt_poster"],["Right",14.0,-1.15,4.6,"archive_link"]]:
		var poster := Craft.sticker(rear,spec[4],Vector3(spec[1],spec[2],0.145),spec[3])
		poster.name = "BackWallPoster"+spec[0]
		var height: float = poster.mesh.size.y
		Craft.box(rear,Vector3(spec[1],spec[2],0.08),Vector3(spec[3]+0.18,height+0.18,0.12),Color("65545f"),0.025)
		# Low-output backlit poster case, plus a visible external picture lamp.
		poster.material_override.emission_enabled = true
		poster.material_override.emission_texture = poster.material_override.albedo_texture
		poster.material_override.emission = Color("f3dfcc")
		poster.material_override.emission_energy_multiplier = 0.12
		var fixture := Craft.box(rear,Vector3(spec[1],spec[2]+height/2+0.35,0.35),Vector3(1.8,0.12,0.45),Color("57505d"),0.025)
		Craft.box(fixture,Vector3(0,-0.078,0.05),Vector3(1.55,0.035,0.28),Color("f4dfb9"),0.009,0.9)
		for x in [-0.6,0.6]: Craft.box(fixture,Vector3(x,0,-0.16),Vector3(0.07,0.08,0.35),Color("57505d"),0.009)
		var wash := lamp(rear.to_global(Vector3(spec[1],spec[2]+height/2+0.24,0.45)),Color("f3d6b3"),1.1,7.5,false)
		wash.name = "PosterWash"+spec[0]
		wash.reparent(fixture,true)
		if spec[0]=="Left":
			var badge := Craft.box(rear,Vector3(spec[1]+1.3,spec[2]-height/2-0.5,0.16),Vector3(2.3,0.55,0.10),Color("454047"),0.02)
			Craft.label(badge,"REPLAY / 01",Vector3(0,0,0.06),Color("cbd18c"),0.004,30)
	# A small wall graphic and floor route, deliberately away from the core pile.
	Craft.sticker(rear,"claws",Vector3(-10,-5.7,0.105),1.5)
	for spec in [[-11.0,6.0,"01"],[11.0,6.0,"02"],[6.0,-16.0,"03 / POWER"]]:
		var tag := Craft.label(decorations,spec[2],Vector3(spec[0],-1.097 if absf(spec[1])<12 else -1.147,spec[1]),Color("9b958f"),0.005,32)
		tag.rotation_degrees.x = -90
		for i in range(3):
			for side in [-1,1]:
				var chevron := Craft.box(decorations,Vector3(spec[0]+side*0.09,-1.095 if absf(spec[1])<12 else -1.145,spec[1]+0.5+i*0.24),Vector3(0.23,0.004,0.05),Color("96954d"),0.001)
				chevron.rotation_degrees.y = side*35
	var repair: Node3D = game.surroundings.zones[0]
	var note := Craft.box(decorations,repair.to_global(Vector3(-1.5,3.128,0.9)),Vector3(0.42,0.015,0.35),Color("c6bd9e"),0.003)
	Craft.box(note,Vector3(0,0.011,0),Vector3(0.25,0.01,0.025),Color("726872"),0.001)
	# Sparse chair/foot traffic scuffs, confined to the two work areas.
	for wear in [[-18.5,4.0,-1.147],[18.0,2.8,-1.097]]:
		for i in range(3):
			var scratch := Craft.box(decorations,Vector3(wear[0]+i*0.15,wear[2],wear[1]+i*0.12),Vector3(0.55-i*0.08,0.002,0.025),Color("44364a"),0.0005)
			scratch.rotation_degrees.y = 18-i*13
			scratch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	connect_floor_zones()
	# Additions are independent of the reversible material selection above.
	for node in additions.find_children("*","GeometryInstance3D",true,false):
		if not node.is_queued_for_deletion() and eligible(node.material_override) and node not in room_occluders.map(func(o): return o.node):
			if not node is MeshInstance3D or not node.mesh is PlaneMesh: node.material_override = cel(node.material_override)

func connect_floor_zones() -> void:
	var links := Node3D.new()
	links.name = "ZoneConnections"
	decorations.add_child(links)
	# Physical cables connect an existing strip and arcade cabinet via floor edges.
	var arcade: Node3D = game.surroundings.zones[1]
	var machine: EnvironmentProp = arcade.get_children().filter(func(n): return n is EnvironmentProp and n.asset_id.contains("arcade"))[0]
	var bounds := AABB()
	var first := true
	for mesh in machine.meshes:
		var local: AABB = machine.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds = local if first else bounds.merge(local)
		first = false
	var socket := Vector3(bounds.get_center().x,bounds.position.y+0.2,bounds.position.z-0.04)
	var plug := Craft.box(links,machine.to_global(socket),Vector3(0.16,0.15,0.12),Color("4d6260"),0.015)
	plug.basis = machine.global_basis.orthonormalized()
	var endpoint: Vector3 = machine.to_global(socket+Vector3(0,0,-0.08))
	var start: Vector3 = game.devices[1].cable_anchor()
	Craft.cable(links,PackedVector3Array([Vector3(-6.6,-0.70,6.8),Vector3(-8.8,-1.055,7.0),Vector3(-12.1,-1.055,5.8),Vector3(-12.9,-1.105,4.8),Vector3(-16.0,-1.105,2.2)]),Color("6b526d"),0.045)
	var service_plug := Craft.box(links,Vector3(-16,-1.105,2.2),Vector3(0.18,0.09,0.24),Color("64576a"),0.012)
	for x in [-0.035,0.035]: Craft.box(service_plug,Vector3(x,0,-0.14),Vector3(0.025,0.03,0.07),Color("a49e87"),0.004)
	Craft.cable(links,PackedVector3Array([start,Vector3(start.x,-1.055,start.z),Vector3(2.6,-1.055,2.2),Vector3(5.0,-1.055,2.2),Vector3(8.9,-1.055,2.4),Vector3(12.1,-1.055,2.4),Vector3(12.9,-1.105,1.8),Vector3(12.9,-1.105,-4.5),Vector3(endpoint.x,-1.105,endpoint.z-0.4),endpoint]),Color("4d746f"),0.045)
	for spec in [[-14.0,4.6,"01 / SERVICE"],[14.0,4.6,"02 / PLAY"],[0.0,10.3,"00 / CORE"]]:
		var label := Craft.label(links,spec[2],Vector3(spec[0],-1.097 if absf(spec[0])<12 else -1.147,spec[1]),Color("a8b4a0"),0.007,32)
		label.rotation_degrees.x = -90
	# One two-tone can and two coins, deliberately kept on peripheral floor surfaces.
	var can := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.13; cylinder.bottom_radius = 0.13
	cylinder.height = 0.42; cylinder.radial_segments = 16
	can.mesh = cylinder
	can.name = "CornerDrinkCan"
	can.position = arcade.to_global(Vector3(5,0.21,3.6))
	can.material_override = Craft.material(Color("9a7b92"))
	links.add_child(can)
	var lid := MeshInstance3D.new()
	var cap := CylinderMesh.new()
	cap.top_radius = 0.13; cap.bottom_radius = 0.13; cap.height = 0.02; cap.radial_segments = 16
	lid.mesh = cap; lid.position.y = 0.21
	lid.material_override = Craft.material(Color("b2b0a2"))
	can.add_child(lid)
	Craft.box(can,Vector3(0,0.226,0),Vector3(0.07,0.012,0.04),Color("625f68"),0.004)
	for i in range(2):
		var coin := MeshInstance3D.new()
		var disc := CylinderMesh.new()
		disc.top_radius = 0.08;disc.bottom_radius = 0.08;disc.height = 0.018;disc.radial_segments = 12
		coin.mesh = disc;coin.position = Vector3(-15+i*0.2,-1.141,4.3+i*0.1)
		coin.material_override = Craft.material(Color("ab9b6c"))
		links.add_child(coin)
	Craft.batch_static(links)

func _process(_delta: float) -> void:
	if not enabled or game==null: return
	var from: Vector3 = game.director.camera.global_position
	for item in room_occluders:
		var bounds: AABB = item.bounds
		var axis := 0
		if bounds.size.y<bounds.size[axis]: axis = 1
		if bounds.size.z<bounds.size[axis]: axis = 2
		var middle: float = bounds.get_center()[axis]
		# A cutaway must protect peripheral machines too, not only tower center rays.
		var hidden := (from[axis]-middle)*(Vector3(0,6,0)[axis]-middle)<0 or bounds.has_point(from)
		for target in game.surroundings._targets():
			if EnvironmentSurroundings.segment_hits(bounds,from,target): hidden = true; break
		item.node.visible = not hidden

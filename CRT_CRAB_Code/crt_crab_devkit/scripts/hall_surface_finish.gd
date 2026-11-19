extends Node3D

const CONTACT := preload("res://assets/environment/crt_rack/contact.gdshader")
const DISPLAY_ATLAS := preload("res://assets/environment/crt_rack/service_displays.png")
var receivers: Dictionary = {}
var shader_variants: Dictionary = {}
var light_scale := 1.0

static func contact_patch(parent: Node3D, footprint: Vector2, feet: float) -> MeshInstance3D:
	var shadow := MeshInstance3D.new()
	var sheet := PlaneMesh.new()
	var feather := clampf(minf(footprint.x,footprint.y)*0.30,0.12,0.90)
	sheet.size = footprint+Vector2.ONE*feather*4.6
	var ink := ShaderMaterial.new()
	ink.shader = CONTACT
	ink.set_shader_parameter("footprint",footprint)
	ink.set_shader_parameter("sheet_size",sheet.size)
	ink.set_shader_parameter("feet",feet)
	shadow.mesh = sheet
	shadow.material_override = ink
	shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(shadow)
	return shadow

func follow_visibility(detail: Node3D, owners: Array) -> void:
	var update := func():
		detail.visible = owners.all(func(host): return host.is_visible_in_tree())
	for host in owners: host.visibility_changed.connect(update)
	update.call()

func contact(host: Node3D, center: Vector3, size: Vector2, feet: float) -> MeshInstance3D:
	var patch := contact_patch(self,size,feet)
	patch.global_position = center
	patch.rotation.y = host.global_rotation.y
	follow_visibility(patch,[host])
	return patch

func local_bounds(prop: EnvironmentProp) -> AABB:
	var bounds := AABB()
	for mesh in prop.meshes:
		var part: AABB = prop.global_transform.affine_inverse()*mesh.global_transform*mesh.get_aabb()
		bounds = part if not bounds.has_volume() else bounds.merge(part)
	return bounds

func equipment_shadows(game: Node) -> void:
	var tiles: Dictionary = preload("res://assets/environment/crt_rack/contact_slots.json").data
	for zone in game.surroundings.zones.slice(0,3):
		for prop in zone.get_children():
			if not prop is EnvironmentProp or not tiles.has(prop.asset_id): continue
			var bounds := local_bounds(prop)
			var size := Vector2(bounds.size.x,bounds.size.z)
			var center: Vector3 = prop.to_global(Vector3(bounds.get_center().x,0,bounds.get_center().z))
			if zone == game.surroundings.zones[0] and prop.position.y>2.9:
				# Desk GLB top is at local y=3.10. Restrict each footprint to its stand.
				center.y = zone.global_position.y+3.108
			else:
				center.y = -1.093 if zone == game.surroundings.zones[1] and absf(prop.position.x)<5.5 else -1.143
			var patch := contact(prop,center,size,0.0)
			patch.mesh.size = size/0.70
			var tile: Array = tiles[prop.asset_id]
			patch.material_override.set_shader_parameter("tile",Vector2(tile[0],tile[1]))
			patch.material_override.set_shader_parameter("masks",preload("res://assets/environment/crt_rack/contact_masks.png"))
	var gacha: Node3D = game.surroundings.zones[1].get_node("PetGashaponMachine")
	var shoe: MeshInstance3D = gacha.get_node("Foot")
	var base: Vector3 = shoe.global_position
	base.y = -1.092
	contact(gacha,base,Vector2(shoe.get_aabb().size.x,shoe.get_aabb().size.z),0.18)
	for i in range(4):
		var device: MonitorDevice = game.devices[i]
		var stand := monitor_base(device)
		var loc := stand.global_position
		loc.y = -1.092
		var extent := stand.get_aabb().size*stand.global_basis.get_scale().abs()
		contact(device,loc,Vector2(extent.x,extent.z),0.24)

func monitor_base(device: MonitorDevice) -> MeshInstance3D:
	return device.get_node("IntegralBase") if device.has_node("IntegralBase") else device.get_node("Foot")

func build(game: Node, changes: Array) -> void:
	equipment_shadows(game)
	var repair: Node3D = game.surroundings.zones[0]
	var terminal: Node3D = repair.get_node("repair_terminal")
	var screen := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(1.89,1.15)
	screen.mesh = quad
	screen.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var phosphor := ShaderMaterial.new()
	phosphor.shader = preload("res://assets/shaders/service_terminal.gdshader")
	phosphor.set_shader_parameter("atlas",DISPLAY_ATLAS)
	screen.material_override = phosphor
	add_child(screen)
	screen.global_transform = terminal.global_transform*Transform3D(Basis(Vector3.RIGHT,deg_to_rad(-8.0)),Vector3(0,0.874,0.009))
	follow_visibility(screen,[terminal])
	receivers[repair] = emitter(screen,quad.size,Color("70b49a"))
	var arcade: Node3D = game.surroundings.zones[1]
	var glass: MeshInstance3D = arcade.displays[0].node
	receivers[arcade] = emitter(glass,glass.mesh.size,Color("c782ab"))
	for i in range(game.devices.size()):
		var device: MonitorDevice = game.devices[i]
		var source := emitter(device.screen,device.screen.mesh.size,Color("74bccc"))
		source["monitor"] = device
		if i+4<game.devices.size():
			source["overhead"] = monitor_base(game.devices[i+4])
		receivers[device] = source
	for item in changes:
		if not item[3] is ShaderMaterial or item[3].get_shader_parameter("base_color")==null: continue
		var host: Node = item[0]
		while host and not receivers.has(host): host = host.get_parent()
		if host: item[3] = receiver_material(item[3],host)
	connect_equipment(game,repair,arcade)
	for device in game.devices:
		device.display_texture_changed.connect(update_picture.bind(device))
		update_picture(device)

func emitter(glass: MeshInstance3D, size: Vector2, tint: Color) -> Dictionary:
	var basis := glass.global_basis
	var right := basis.x.normalized()
	var up := basis.y.normalized()
	var source := {"glass":glass,"center":glass.global_position,
		"right":Vector4(right.x,right.y,right.z,size.x*basis.x.length()*0.5),
		"up":Vector4(up.x,up.y,up.z,size.y*basis.y.length()*0.5),
		"color":Vector3(tint.r,tint.g,tint.b),"materials":[]}
	glass.visibility_changed.connect(refresh_emitter.bind(source))
	return source

func receiver_material(original: ShaderMaterial, host: Node) -> ShaderMaterial:
	var cache: Dictionary = shader_variants.get_or_add(host,{})
	if cache.has(original): return cache[original]
	var mat := original.duplicate(false) as ShaderMaterial
	var src: Dictionary = receivers[host]
	mat.set_shader_parameter("spill_center",src.center)
	mat.set_shader_parameter("spill_right",src.right)
	mat.set_shader_parameter("spill_up",src.up)
	mat.set_shader_parameter("spill_color",src.color)
	if src.has("overhead"):
		var support: MeshInstance3D = src.overhead
		var bounds := support.get_aabb()
		var base := support.to_global(Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))
		var axis := support.global_basis.x.normalized()
		var span := bounds.size*support.global_basis.get_scale().abs()
		mat.set_shader_parameter("overhead_base",base)
		mat.set_shader_parameter("overhead_foot",Vector4(axis.x,axis.z,span.x*0.5,span.z*0.5))
	src.materials.append(mat)
	cache[original] = mat
	return mat

func update_picture(device: MonitorDevice) -> void:
	var tex: Texture2D = device.screen_material.get_shader_parameter("screen_texture")
	var region: Vector4 = device.screen_material.get_shader_parameter("screen_region")
	for mat in receivers[device].materials:
		mat.set_shader_parameter("picture_enabled",true)
		mat.set_shader_parameter("picture",tex)
		mat.set_shader_parameter("picture_region",region)

func set_energy(energy: float) -> void:
	light_scale = energy
	for src in receivers.values(): refresh_emitter(src)

func refresh_emitter(src: Dictionary) -> void:
	var energy := light_scale if src.glass.is_visible_in_tree() else 0.0
	for mat in src.materials: mat.set_shader_parameter("spill_energy",energy)

# Socket locations and path guides are expressed in the participating machines' frames.
func lead(a: Node3D, socket_a: Vector3, normal_a: Vector3, b: Node3D, socket_b: Vector3, normal_b: Vector3, guides: PackedVector3Array, tint: Color) -> void:
	var loom := Node3D.new()
	add_child(loom)
	var plugs: Array[Vector3] = []
	for end in [[a,socket_a,normal_a],[b,socket_b,normal_b]]:
		var normal: Vector3 = (end[0].global_basis*end[2]).normalized()
		var port: Vector3 = end[0].to_global(end[1])
		var plug := Craft.box(loom,port+normal*0.035,Vector3(0.20,0.16,0.17),Color("626070"),0.035)
		plug.quaternion = Quaternion(Vector3.BACK,normal)
		plugs.append(port+normal*0.12)
	var route := PackedVector3Array([plugs[0]])
	route.append_array(guides)
	route.append(plugs[1])
	Craft.cable(loom,route,tint,0.052)
	Craft.batch_static(loom)
	follow_visibility(loom,[a,b])

func connect_equipment(game: Node, repair: Node3D, arcade: Node3D) -> void:
	var monitor: Node3D = repair.get_node("repair_terminal")
	var keyboard: Node3D = repair.get_node("repair_keyboard")
	lead(keyboard,Vector3(-0.51,0.09,-0.29),Vector3.FORWARD,monitor,Vector3(-0.47,0.36,-0.12),Vector3.FORWARD,
		PackedVector3Array([repair.to_global(Vector3(0.14,3.18,0.35)),repair.to_global(Vector3(-0.49,3.18,0.13)),repair.to_global(Vector3(-0.55,3.18,-0.55)),repair.to_global(Vector3(0.16,3.27,-0.78))]),Color("73677b"))
	var servers: Array = game.surroundings.zones[2].get_children().filter(func(n): return n is EnvironmentProp and n.asset_id.contains("fortified"))
	for i in range(2):
		var height := 1.35+i*0.65
		var a: Node3D = servers[0]
		var b: Node3D = servers[1]
		var start := a.to_global(Vector3(0.60,height,1.82))
		var end := b.to_global(Vector3(-0.52,height+0.65,1.82))
		var mid := start.lerp(end,0.53)+Vector3(0,-0.78,0.80)
		lead(a,Vector3(0.60,height,1.82),Vector3.BACK,b,Vector3(-0.52,height+0.65,1.82),Vector3.BACK,
			PackedVector3Array([start+Vector3(0,-0.03,0.24),start.lerp(mid,0.44)+Vector3(0,-0.20,0.09),mid,end.lerp(mid,0.42)+Vector3(0,-0.18,0.11),end+Vector3(0,-0.04,0.23)]),Color("68868c") if i==0 else Color("83687e"))
	var cabinet: EnvironmentProp = arcade.get_node("arcade_cabinet")
	var vending: EnvironmentProp = arcade.get_node("vending_machine")
	var port_a := Vector3(local_bounds(cabinet).size.x*0.46,0.46,-0.33)
	var port_b := Vector3(-local_bounds(vending).size.x*0.48,0.45,0.2)
	var pa := cabinet.to_global(port_a)
	var pb := vending.to_global(port_b)
	lead(cabinet,port_a,Vector3.RIGHT,vending,port_b,Vector3.LEFT,
		PackedVector3Array([pa+cabinet.global_basis.x*0.19,Vector3(pa.x+0.38,-1.03,pa.z+0.18),Vector3(pb.x-0.45,-1.03,pb.z+0.55),pb-vending.global_basis.x*0.20]),Color("756982"))
	for pair in [[3,7],[6,10],[5,9]]:
		var lower: MonitorDevice = game.devices[pair[0]]
		var upper: MonitorDevice = game.devices[pair[1]]
		var low_port := Vector3(2.595,0.21,-0.56)
		var high_port := Vector3(2.595,-0.75,-0.61)
		var low := lower.to_global(low_port)+lower.global_basis.x.normalized()*0.30
		var high := upper.to_global(high_port)+upper.global_basis.x.normalized()*0.30
		lead(lower,low_port,Vector3.RIGHT,upper,high_port,Vector3.RIGHT,
			PackedVector3Array([low,low.lerp(high,0.26)+Vector3.DOWN*0.48+lower.global_basis.x*0.20,
			low.lerp(high,0.63)+Vector3.DOWN*0.33+upper.global_basis.x*0.22,high]),Color("847386"))

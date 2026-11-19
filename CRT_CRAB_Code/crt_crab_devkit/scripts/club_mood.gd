extends Node3D

var dust_fields: Array[GPUParticles3D] = []
var shafts: Array[ShaderMaterial] = []
var dim_tube: MeshInstance3D
var dim_material: StandardMaterial3D
var dim_light: OmniLight3D
var elapsed := 0.0
var light_scale := 1.0

func build(repair: Node3D, gacha: Node3D) -> void:
	# A failing short tube beside the intact rear fitting.
	Craft.box(self,Vector3(3.5,17.5,-15),Vector3(1.7,0.18,0.7),Color("44404e"))
	dim_tube = Craft.box(self,Vector3(3.5,17.38,-15),Vector3(1.45,0.05,0.5),Color("8d9aa8"),0.01,0.25)
	dim_material = dim_tube.material_override.duplicate()
	dim_tube.material_override = dim_material
	dim_light = OmniLight3D.new()
	dim_light.position = dim_tube.position - Vector3.UP*0.15
	dim_light.light_color = Color("adc7d5")
	dim_light.omni_range = 4.0
	add_child(dim_light)
	var turn_marker := Craft.box(self,gacha.to_global(Vector3(1.01,3.12,1.63)),Vector3(0.12,0.045,0.025),Color("ffae9e"),0.012,1.2)
	turn_marker.global_basis = gacha.global_basis

	# A low-contrast loop at the near lip frames the title camera from below.
	var foreground := Node3D.new()
	add_child(foreground)
	var lead := PackedVector3Array()
	for i in range(27):
		var t := float(i) / 26.0
		lead.append(Vector3(3.0+t*12.0,-1.10+0.016*sin(PI*t),14.4-sin(PI*t)*1.1+0.7*t))
	Craft.cable(foreground,lead,Color("494153"),0.065)
	Craft.batch_static(foreground)

	var nook := Node3D.new()
	add_child(nook)
	nook.global_transform = repair.global_transform
	# Folded cloth inside a loose service-lead loop, sized against the keyboard.
	var pad := Craft.box(nook,Vector3(-2.7,0.09,1.35),Vector3(1.12,0.12,0.73),Color("8e7489"),0.055)
	pad.rotation.y = -0.17
	Craft.box(pad,Vector3(-0.39,0.09,0),Vector3(0.25,0.16,0.65),Color("b69da6"),0.07)
	var loop := PackedVector3Array([Vector3(-5,0.08,2.3)])
	for i in range(14):
		var a := i*0.43
		loop.append(Vector3(-2.7+cos(a)*0.93,0.07,1.35+sin(a)*0.64))
	Craft.cable(nook,loop,Color("716375"),0.038)
	for i in range(5):
		var print_mark := Craft.sticker(nook,"claws",Vector3(-4.1+i*0.29,0.035,3.2-i*0.31),0.22)
		print_mark.rotation_degrees = Vector3(-90,(-16 if i%2 else 12),0)
	for i in range(2):
		var cell := Craft.box(nook,Vector3(-2.0+i*0.29,0.11,2.35),Vector3(0.15,0.14,0.36),Color("789c9a"),0.06)
		cell.rotation.y = 0.35+i*0.7
		Craft.box(cell,Vector3(0,0,0.18),Vector3(0.09,0.08,0.045),Color("cbb586"),0.015)
	var note := Craft.box(nook,Vector3(-0.8,3.15,1.02),Vector3(0.54,0.035,0.38),Color("dbb870"),0.012,0.25)
	var mark := Craft.sticker(note,"claws",Vector3(0,0.022,0),0.22)
	mark.rotation_degrees.x = -90
	Craft.batch_static(nook)

func build_shafts(tubes: Array[MeshInstance3D]) -> PackedVector4Array:
	var footprints := PackedVector4Array()
	var volume := CylinderMesh.new()
	volume.top_radius = 1.0
	volume.bottom_radius = 1.0
	volume.height = 1.0
	volume.radial_segments = 32
	for tube in tubes:
		var bounds := tube.get_aabb()
		var source := tube.to_global(Vector3.DOWN*bounds.size.y*0.5)
		var drop := source.y+1.15
		var mouth := Vector2(bounds.size.x,bounds.size.z)*0.48
		var footprint := mouth + Vector2(0.23,0.22)*drop
		footprints.append(Vector4(source.x,source.z,footprint.x,footprint.y))
		var tint := Color("ffb7c8") if source.x>10 else Color("bcdfe9")
		var haze := ShaderMaterial.new()
		haze.shader = preload("res://assets/shaders/club_shaft.gdshader")
		haze.set_shader_parameter("tint",tint)
		haze.set_shader_parameter("mouth",mouth)
		haze.set_shader_parameter("footprint",footprint)
		haze.set_shader_parameter("drop",drop)
		shafts.append(haze)
		var shaft := MeshInstance3D.new()
		shaft.name = "LampCone%d"%shafts.size()
		shaft.mesh = volume
		shaft.material_override = haze
		shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		shaft.custom_aabb = AABB(Vector3(-footprint.x,-drop,-footprint.y),Vector3(2.0*footprint.x,drop,2.0*footprint.y))
		add_child(shaft)
		shaft.global_position = source
		if source.z>0: add_dust(source-Vector3.UP*drop*0.5,tint)
	return footprints

func add_dust(center: Vector3, tint: Color) -> void:
	var dots := GPUParticles3D.new()
	dots.position = center
	dots.amount = 16
	dots.lifetime = 9.0
	dots.preprocess = 9.0
	dots.visibility_aabb = AABB(Vector3(-3,-5,-3),Vector3(6,10,6))
	var drift := ParticleProcessMaterial.new()
	drift.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	drift.emission_box_extents = Vector3(1.3,3.2,1.3)
	drift.gravity = Vector3.ZERO
	drift.direction = Vector3(0.3,1.0,-0.1)
	drift.initial_velocity_min = 0.045
	drift.initial_velocity_max = 0.12
	dots.process_material = drift
	var grain := QuadMesh.new()
	grain.size = Vector2(0.035,0.035)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint.darkened(0.45)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	grain.material = mat
	dots.draw_pass_1 = grain
	dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dust_fields.append(dots)
	add_child(dots)

func configure(active: bool, motion: bool, scale_value: float) -> void:
	light_scale = scale_value
	for haze in shafts: haze.set_shader_parameter("strength",0.054*light_scale)
	set_process(active and motion)
	for dots in dust_fields:
		dots.visible = active and motion
		dots.emitting = active and motion
	update_tube(0.0)

func _process(delta: float) -> void:
	elapsed += delta
	var pulse := smoothstep(0.76,1.0,cos(elapsed*0.83))
	update_tube(pulse * (0.65 + 0.35*cos(elapsed*5.0)))

func update_tube(pulse: float) -> void:
	dim_material.emission_energy_multiplier = 0.18 + pulse*0.22
	dim_light.light_energy = (0.19 + pulse*0.16)*light_scale

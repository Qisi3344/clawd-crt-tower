class_name MonitorDevice
extends Node3D

var screen: MeshInstance3D
var screen_material: ShaderMaterial
var indicator: MeshInstance3D
var screen_id := ""
var computer_id := ""
var device_index := 0
var model := 0
var has_keyboard := true
var accent := Color("52d5b1")
var status := "SLEEP"
var status_label: Label3D
var rear_z := -1.97

func _ready() -> void:
	var colors := [Color("aba897"),Color("87958d"),Color("293340"),Color("916c84")]
	var shell: Color = colors[model]
	var case_size := Vector3(5.2,4.55,2.4 if model==2 else 3.4)
	var case_center := Vector3(0,0,0.25 if model==2 else -0.25)
	var case_radius := 0.13 if model==2 else (0.4 if model==3 else 0.25)
	var body := Craft.box(self,case_center,case_size,shell,case_radius)
	body.name = "Case"
	if model==2: rear_z = -0.98
	Craft.crt_bezel(self,shell,0.18 if model==2 else (0.36 if model==3 else 0.26))

	screen = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(4.16,3.12)
	screen.mesh = quad
	screen.position = Vector3(0,0.2,1.71)
	add_child(screen)
	screen_material = ShaderMaterial.new()
	screen_material.shader = load("res://assets/shaders/crt.gdshader")
	screen.material_override = screen_material
	set_texture(_standby_texture())
	indicator = Craft.box(self,Vector3(1.82,-1.89,1.882),Vector3(0.13,0.09,0.018),accent,0.01,0.5)
	Craft.box(self,Vector3(1.46,-1.9,1.875),Vector3(0.24,0.18,0.045),shell.darkened(0.4),0.025)
	Craft.sticker(self,["crt_crab","boot_ok","claws","404"][model],Vector3(-1.35,-1.88,1.884),0.55 if model==2 else 0.95)
	for i in range(6):
		Craft.box(self,Vector3(0.35+i*0.11,-1.9,1.882),Vector3(0.04,0.18,0.012),shell.darkened(0.43),0.004)
	for side in [-1,1]:
		for i in range(9):
			Craft.box(self,Vector3(side*2.604,0.7-i*0.12,-0.05 if model==2 else -0.4),Vector3(0.018,0.046,0.85 if model==2 else 1.25),shell.darkened(0.32),0.008)
	var foot := Craft.box(self,Vector3(0,-2.42,-0.1),Vector3(3.7,0.38,2.4),shell.darkened(0.16),0.1)
	foot.name = "Foot"
	if model == 0:
		var base := Craft.box(self,Vector3(0,-2.77,0.9),Vector3(5.0,0.42,3.7),shell.darkened(0.08),0.12)
		base.name = "IntegralBase"
		Craft.box(self,Vector3(0,-2.77,2.78),Vector3(4.75,0.25,0.08),shell,0.02)
		Craft.box(self,Vector3(1.3,-2.77,2.83),Vector3(1.5,0.07,0.02),Color("495957"),0.01)
	if has_keyboard and model != 2:
		_build_keyboard(shell)
	if model == 2:
		Craft.sticker(self,"boot_ok",Vector3(-1.55,2.00,1.884),0.68)
		for x in [-0.65,0.05,0.75]:
			var knob := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.14
			cylinder.bottom_radius = 0.14
			cylinder.height = 0.13
			cylinder.radial_segments = 12
			knob.mesh = cylinder
			knob.material_override = Craft.material(Color("b7bdb0"))
			knob.rotation_degrees.x = 90
			knob.position = Vector3(x,-1.9,1.89)
			add_child(knob)
	elif model == 1:
		scale = Vector3(0.88,1.08,0.92)
		Craft.box(self,Vector3(-1.65,-2.4,1.71),Vector3(1.1,0.1,0.04),Color("273335"),0.01)
		Craft.box(self,Vector3(0,-2.27,0.9),Vector3(4.2,0.65,1.6),shell.darkened(0.05),0.10)
		Craft.box(self,Vector3(0.65,-2.22,1.71),Vector3(1.6,0.1,0.04),Color("273335"),0.01)
	elif model==3:
		scale = Vector3.ONE*0.88
		# Carry handle folds against the rear; the case roof stays a bearing surface.
		for x in [-1.3,1.3]: Craft.box(self,Vector3(x,0.65,-1.98),Vector3(0.25,0.6,0.25),Color("313a43"),0.06)
		Craft.box(self,Vector3(0,0.9,-2.02),Vector3(2.8,0.25,0.25),Color("313a43"),0.06)
	# Flush fasteners sit on the planar front, inside the rounded outer perimeter.
	for x in [-2.32,2.32]:
		for y in [-1.85,1.90]:
			var screw := MeshInstance3D.new()
			var cylinder := CylinderMesh.new()
			cylinder.top_radius = 0.04
			cylinder.bottom_radius = 0.04
			cylinder.height = 0.012
			cylinder.radial_segments = 12
			screw.mesh = cylinder
			screw.rotation_degrees.x = 90
			screw.position = Vector3(x,y,1.88)
			screw.material_override = Craft.material(shell.darkened(0.28))
			add_child(screw)
	Craft.box(self,Vector3(0,1.1,rear_z),Vector3(3.3,0.04,0.03),shell.darkened(0.4),0.005)
	Craft.box(self,Vector3(0,-0.8,rear_z),Vector3(0.9,0.35,0.12),Color("263640"),0.025)
	for x in [-0.3,0,0.3]: Craft.box(self,Vector3(x,-0.8,rear_z-0.07),Vector3(0.12,0.1,0.03),Color("9ca58f"),0.008)
	var rear_label := Craft.sticker(self,"archive_link" if model==2 else "no_signal",Vector3(0,0.1,-0.953 if model==2 else -1.953),0.95)
	rear_label.rotation_degrees.y = 180
	status_label = Craft.label(self,"",Vector3(0,2.15,1.886),accent,0.002,28)
	var screen_aspect: float = (4.0/3.0)*absf(scale.x/scale.y)
	var fit := Vector2(1,screen_aspect/(4.0/3.0)) if screen_aspect<4.0/3.0 else Vector2((4.0/3.0)/screen_aspect,1)
	screen_material.set_shader_parameter("content_scale",fit)
	Craft.batch_static(self,[indicator])

func cable_anchor() -> Vector3:
	return to_global(Vector3(0,-0.8,rear_z-0.08))

func set_status(value: String) -> void:
	status = value
	var colors := {"ACTIVE":"54cfc3","CONNECTED":"dce65b","READY":"dce65b","REPAIRED":"54cfc3","UNLOCKING":"efd58a","CORRUPTED":"ea5985","LOCKED":"52686b","SLEEP":"52686b"}
	var color := Color(colors.get(status,"52686b"))
	indicator.material_override = Craft.material(color,0.5)
	status_label.text = screen_id+" / "+status if status not in ["SLEEP","LOCKED"] else ""
	status_label.modulate = color

func _build_keyboard(shell: Color) -> void:
	var keyboard := Node3D.new()
	keyboard.name = "Keyboard"
	keyboard.position = Vector3(0,-2.46,2.15) if model==0 else Vector3(0,-2.51,2.6)
	keyboard.rotation_degrees.x = 0
	add_child(keyboard)
	Craft.box(keyboard,Vector3.ZERO,Vector3(3.8,0.2,1.12),shell.darkened(0.07),0.06)
	for row in range(4):
		for col in range(12):
			if row == 3 and col > 2 and col < 8:
				continue
			Craft.box(keyboard,Vector3(-1.65+col*0.30,0.13,-0.36+row*0.24),Vector3(0.23,0.08,0.16),shell.lightened(0.12),0.025)
	Craft.box(keyboard,Vector3(-0.1,0.13,0.36),Vector3(1.36,0.08,0.16),shell.lightened(0.12),0.02)

func focus_point() -> Vector3:
	return to_global(Vector3(0,0.2,1.72))

func focus_position() -> Vector3:
	var rect := get_viewport().get_visible_rect().size
	var aspect: float = rect.x / maxf(rect.y,1)
	var distance: float = 6.4 * maxf(1,1.35/aspect)
	return to_global(Vector3(0.18,0.58,1.72+distance))

func set_texture(texture: Texture2D) -> void:
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		var size := atlas.atlas.get_size()
		screen_material.set_shader_parameter("screen_texture",atlas.atlas)
		screen_material.set_shader_parameter("screen_region",Vector4(atlas.region.position.x/size.x,atlas.region.position.y/size.y,atlas.region.size.x/size.x,atlas.region.size.y/size.y))
	else:
		screen_material.set_shader_parameter("screen_texture",texture)
		screen_material.set_shader_parameter("screen_region",Vector4(0,0,1,1))

func _standby_texture() -> Texture2D:
	return load("res://assets/pixel/standby_%d.png"%device_index)

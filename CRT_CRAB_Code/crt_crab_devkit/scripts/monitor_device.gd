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
	if model==2:
		Craft.box(self,Vector3(0,0,0.25),Vector3(5.2,4.55,2.4),shell,0.13)
		rear_z = -0.98
	else:
		Craft.box(self,Vector3(0,0,-0.25),Vector3(5.2,4.55,3.4),shell,0.25 if model!=3 else 0.4)
	Craft.box(self,Vector3(0,0,1.48),Vector3(4.78,3.85,0.3),shell.darkened(0.22),0.18)
	# Four separate front bezel pieces leave a genuine recessed screen opening.
	for side in [-1,1]:
		Craft.box(self,Vector3(side*2.34,0.2,1.66),Vector3(0.52,3.6,0.4),shell,0.09)
		Craft.box(self,Vector3(0,side*1.78+0.2,1.66),Vector3(4.75,0.43,0.4),shell,0.07)
	Craft.box(self,Vector3(0,-1.9,1.65),Vector3(4.72,0.48,0.36),shell,0.08)
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
	indicator = Craft.box(self,Vector3(1.82,-1.89,1.87),Vector3(0.13,0.09,0.04),accent,0.01,0.5)
	Craft.box(self,Vector3(1.46,-1.9,1.89),Vector3(0.24,0.18,0.10),shell.darkened(0.4),0.025)
	Craft.label(self,"CRT / %02d"%device_index,Vector3(-1.45,-1.9,1.875),Color("404d53"),0.0028,34)
	for i in range(6):
		Craft.box(self,Vector3(0.35+i*0.11,-1.9,1.86),Vector3(0.04,0.18,0.04),shell.darkened(0.43),0.004)
	for side in [-1,1]:
		for i in range(9):
			Craft.box(self,Vector3(side*2.604,0.7-i*0.12,-0.4),Vector3(0.018,0.046,1.25),shell.darkened(0.32),0.008)
	Craft.box(self,Vector3(0,-2.42,-0.1),Vector3(3.7,0.38,2.4),shell.darkened(0.16),0.1)
	if model == 0:
		Craft.box(self,Vector3(0,-2.77,0.9),Vector3(5.0,0.42,3.7),shell.darkened(0.08),0.12)
		Craft.box(self,Vector3(0,-2.77,2.78),Vector3(4.75,0.25,0.08),shell,0.02)
		Craft.box(self,Vector3(1.3,-2.77,2.83),Vector3(1.5,0.07,0.02),Color("495957"),0.01)
	if has_keyboard and model != 2:
		_build_keyboard(shell)
	if model == 2:
		Craft.box(self,Vector3(-1.8,1.97,1.89),Vector3(0.5,0.2,0.04),Color("d4e852"),0.02)
		Craft.label(self,"ISLE",Vector3(-1.8,1.97,1.92),Color("252d35"),0.0012,28)
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
			knob.position = Vector3(x,-1.9,1.96)
			add_child(knob)
	elif model == 1:
		scale = Vector3(0.88,1.08,0.92)
		Craft.box(self,Vector3(-1.65,-2.72,1.65),Vector3(1.1,0.1,0.1),Color("273335"),0.01)
		Craft.box(self,Vector3(0,-2.27,0.9),Vector3(4.2,0.65,1.6),shell.darkened(0.05),0.10)
		Craft.box(self,Vector3(0.65,-2.22,1.73),Vector3(1.6,0.1,0.04),Color("273335"),0.01)
	elif model==3:
		scale = Vector3.ONE*0.88
		for x in [-1.3,1.3]: Craft.box(self,Vector3(x,2.43,-0.25),Vector3(0.25,0.6,0.4),Color("313a43"),0.06)
		Craft.box(self,Vector3(0,2.69,-0.25),Vector3(2.8,0.25,0.4),Color("313a43"),0.06)
		Craft.box(self,Vector3(-1.3,-1.9,1.89),Vector3(1.3,0.26,0.04),Color("54cfc3"),0.02)
	# Original silk-screen labels, fasteners, tape, case seams, and rear socket.
	for x in [-2.2,2.2]:
		for y in [-1.62,1.91]: Craft.box(self,Vector3(x,y,1.89),Vector3(0.08,0.08,0.025),Color("a0aaa0"),0.012)
	Craft.box(self,Vector3(-1.5,1.8,1.9),Vector3(0.8,0.28,0.025),Color("dce65b"),0.01)
	Craft.label(self,"PORT_%02d"%device_index,Vector3(-1.5,1.8,1.92),Color("293340"),0.0015,28)
	var tape := Craft.box(self,Vector3(1.6,1.82,1.91),Vector3(0.6,0.17,0.025),Color("d5c7a8"),0.004)
	tape.rotation_degrees.z = -14
	Craft.box(self,Vector3(0,1.1,rear_z),Vector3(3.3,0.04,0.03),shell.darkened(0.4),0.005)
	Craft.box(self,Vector3(0,-0.8,rear_z),Vector3(0.9,0.35,0.12),Color("263640"),0.025)
	for x in [-0.3,0,0.3]: Craft.box(self,Vector3(x,-0.8,rear_z-0.07),Vector3(0.12,0.1,0.03),Color("9ca58f"),0.008)
	var rear_label := Craft.label(self,"DATA / %02d"%device_index,Vector3(0,-0.25,rear_z-0.08),Color("bdc5af"),0.003,28)
	rear_label.rotation_degrees.y = 180
	status_label = Craft.label(self,"",Vector3(0,2.15,1.86),accent,0.002,28)
	var screen_aspect: float = (4.0/3.0)*absf(scale.x/scale.y)
	var fit := Vector2(1,screen_aspect/(4.0/3.0)) if screen_aspect<4.0/3.0 else Vector2((4.0/3.0)/screen_aspect,1)
	screen_material.set_shader_parameter("content_scale",fit)
	Craft.batch_static(self,[indicator])

func cable_anchor() -> Vector3:
	return to_global(Vector3(0,-0.8,rear_z-0.08))

func set_status(value: String) -> void:
	status = value
	var color := Color("54cfc3") if status=="ACTIVE" else (Color("dce65b") if status=="CONNECTED" else Color("52686b"))
	indicator.material_override = Craft.material(color,0.5)
	status_label.text = screen_id+" / "+status if status in ["ACTIVE","CONNECTED"] else ""
	status_label.modulate = color

func _build_keyboard(shell: Color) -> void:
	var keyboard := Node3D.new()
	keyboard.name = "Keyboard"
	keyboard.position = Vector3(0,-3.12,2.15)
	keyboard.rotation_degrees.x = 9
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
	screen_material.set_shader_parameter("screen_texture",texture)

func _standby_texture() -> Texture2D:
	return load("res://assets/pixel/standby_%d.png"%device_index)

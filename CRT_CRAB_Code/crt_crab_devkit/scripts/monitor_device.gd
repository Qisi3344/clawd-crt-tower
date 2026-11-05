class_name MonitorDevice
extends Node3D

var screen: MeshInstance3D
var screen_material: ShaderMaterial
var indicator: MeshInstance3D
var screen_id := ""
var device_index := 0
var model := 0
var has_keyboard := true
var accent := Color("52d5b1")

func _ready() -> void:
	var colors := [Color("363f42"),Color("626b61"),Color("252d35")]
	var shell: Color = colors[model]
	Craft.box(self,Vector3(0,0,-0.25),Vector3(5.2,4.55,3.4),shell,0.25)
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
	Craft.batch_static(self,[indicator])

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
	var distance: float = 7.88 * maxf(1,1.2/aspect)
	return to_global(Vector3(0.18,0.58,1.72+distance))

func set_texture(texture: Texture2D) -> void:
	screen_material.set_shader_parameter("screen_texture",texture)

func _standby_texture() -> ImageTexture:
	var image := Image.create(256,192,false,Image.FORMAT_RGB8)
	image.fill(Color("182134"))
	var base: Color = [Color("52d5b1"),Color("ad92e7"),Color("ef609d"),Color("ebc269")][device_index%4]
	for y in range(192):
		for x in range(256):
			var col := Color("182134")
			match device_index%4:
				0:
					if x%24 < 1 or y%24 < 1: col = base.darkened(0.74)
					if x > 42 and x < 212 and y > 70 and y < 117: col = base.darkened(0.40)
				1:
					if int(sqrt(pow(x-128,2)+pow(y-96,2)))%26 < 3: col = base.darkened(0.24)
				2:
					if (x/16+y/16+device_index)%7 == 0: col = base.darkened(0.56)
				3:
					if y > 32 and y < 160 and y%14 < 3 and x > 30 and x < 55+(y*17)%160: col = base.darkened(0.35)
			image.set_pixel(x,y,col)
	# Every device carries its own pixel signature, including sleeping devices.
	for i in range(8):
		if (device_index+1) & (1 << i):
			image.fill_rect(Rect2i(18+i*8,170,5,7),base)
	return ImageTexture.create_from_image(image)

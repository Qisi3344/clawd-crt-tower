extends Node3D

@export_enum("repair","arcade","power","overhead") var zone := "repair"
var animated: Array[Node3D] = []
var displays: Array[Dictionary] = []

func _ready() -> void:
	match zone:
		"repair": _repair()
		"arcade": _arcade()
		"power": _power()
		"overhead": _overhead()

func _model(scene: String, p: Vector3, yaw: float = 0) -> EnvironmentProp:
	var object := (load("res://scenes/environment/"+scene+".tscn") as PackedScene).instantiate() as EnvironmentProp
	object.position = p
	object.rotation_degrees.y = yaw
	add_child(object)
	return object

func _sign(parent: Node3D, text: String, p: Vector3, size: Vector2, color: Color) -> void:
	Craft.box(parent,p,Vector3(size.x,size.y,0.12),Color("27333d"),0.04)
	Craft.box(parent,p+Vector3(-size.x/2+0.08,0,0.075),Vector3(0.09,size.y-0.18,0.025),color,0.01,0.1)
	Craft.label(parent,text,p+Vector3(0,0,0.08),color,0.0085,36)

func _decal(parent: Node3D, asset: String, p: Vector3, width: float) -> MeshInstance3D:
	var texture := load("res://assets/environment/decals/user/"+asset+".png") as Texture2D
	var mesh := QuadMesh.new()
	mesh.size = Vector2(width,width*texture.get_height()/float(texture.get_width()))
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = p
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = Color(0.72,0.72,0.72,1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1
	node.material_override = material
	parent.add_child(node)
	return node

func _repair() -> void:
	_model("repair_workbench",Vector3(0,0,0),0)
	_model("repair_shelf",Vector3(-4.5,0,-2.1),12)
	_model("repair_chair",Vector3(1,0,3.2),-30)
	_model("repair_terminal",Vector3(0.7,3.12,-0.4),0)
	_model("repair_keyboard",Vector3(0.7,3.12,0.8),0)
	_model("parts_box",Vector3(-4.2,0,1.2),-12)
	_model("parts_box",Vector3(-3,0,-2.0),15)
	_model("repair_lamp",Vector3(-2,3.12,0.8),0)
	var hammer := _model("repair_hammer",Vector3(-0.8,3.28,0.6),70)
	hammer.rotation_degrees.z = 90
	_sign(self,"REPAIR BAY 07",Vector3(-0.7,5.8,-2.4),Vector2(6.0,1.0),Color("dce65b"))
	for x in [-3.1,1.7]: Craft.box(self,Vector3(x,2.75,-2.5),Vector3(0.1,5.5,0.15),Color("40515a"),0.02)
	# A backed service board, with original paper notes and cable hooks.
	Craft.box(self,Vector3(0,3.5,-2.35),Vector3(4.6,1.7,0.12),Color("4d6267"),0.03)
	for i in range(3):
		var note := Craft.box(self,Vector3(-1.4+i*1.25,3.5,-2.26),Vector3(0.85,0.95,0.025),Color("c5c7ae"),0.005)
		note.rotation_degrees.z = (i-1)*5
	Craft.label(self,"CRT SERVICE / UNIT 07",Vector3(0,3.5,-2.22),Color("27333d"),0.0025,28)
	_decal(self,"no_signal",Vector3(-1.4,3.5,-2.14),1.05)
	# Swing-arm lamp: foot, two real pivots and a connected head.
	Craft.cable(self,PackedVector3Array([Vector3(2.1,3.12,-0.8),Vector3(2.1,4.2,-0.8),Vector3(0.8,4.8,-0.8)]),Color("6c817c"),0.08)
	Craft.box(self,Vector3(0.8,4.75,-0.8),Vector3(1.0,0.25,0.65),Color("a8b5a3"),0.05)
	Craft.box(self,Vector3(0.8,4.60,-0.8),Vector3(0.8,0.03,0.45),Color("c4ddd2"),0.01,0.25)
	var lamp := OmniLight3D.new()
	lamp.position = Vector3(0.7,3.8,-0.2)
	lamp.light_color = Color("b7d2cf")
	lamp.light_energy = 0.45
	lamp.omni_range = 5
	add_child(lamp)
	# Low-detail parts have explicit shelves or work surfaces beneath them.
	for i in range(3):
		Craft.box(self,Vector3(-1.25+i*0.42,3.16,0.7),Vector3(0.32,0.09,0.45),Color("527f72"),0.01)
	var fan := Node3D.new()
	fan.position = Vector3(-1.5,3.8,-0.6)
	add_child(fan)
	Craft.box(self,Vector3(-1.5,3.30,-0.6),Vector3(0.75,0.35,0.5),Color("344954"),0.05)
	Craft.box(self,Vector3(-1.5,3.62,-0.6),Vector3(0.10,0.35,0.10),Color("607a80"),0.02)
	for angle in [0,120,240]:
		var blade := Craft.box(fan,Vector3(-sin(deg_to_rad(angle))*0.22,cos(deg_to_rad(angle))*0.22,0),Vector3(0.12,0.48,0.06),Color("91aba4"),0.04)
		blade.rotation_degrees.z = angle
	animated.append(fan)

func _screen(parent: Node3D, p: Vector3, size: Vector2, index: int, pitch: float = 0) -> void:
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = size
	node.mesh = quad
	node.position = p
	node.rotation_degrees.x = pitch
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_texture = load("res://assets/environment/decals/arcade_%d.png"%index)
	mat.albedo_color = Color(0.48,0.48,0.48,1)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	node.material_override = mat
	parent.add_child(node)
	displays.append({"node":node,"material":mat,"index":index})

func _arcade() -> void:
	var a := _model("arcade_cabinet",Vector3(-2.0,0,0),-8)
	var b := _model("arcade_cabinet",Vector3(2.5,0,-1.8),17)
	_decal(a,"crt_crab",Vector3(0,0.85,1.34),1.25)
	_decal(b,"boot_ok",Vector3(0,0.85,1.34),1.7)
	var vending := _model("vending_machine",Vector3(6.1,0,-3.8),-4)
	# A shallow, stocked insert sits in front of the imported curved glass.
	Craft.box(vending,Vector3(-0.325,4.13,2.12),Vector3(2.5,3.7,0.08),Color("1d3038"),0.04)
	var can_mesh := CylinderMesh.new()
	can_mesh.top_radius = 0.18
	can_mesh.bottom_radius = 0.18
	can_mesh.height = 0.62
	can_mesh.radial_segments = 8
	for row in range(3):
		var y := 2.65+row*1.1
		Craft.box(vending,Vector3(-0.325,y,2.3),Vector3(2.45,0.09,0.4),Color("53616b"),0.015)
		for col in range(3):
			var can := MeshInstance3D.new()
			can.mesh = can_mesh
			can.position = Vector3(-1.1+col*0.77,y+0.36,2.3)
			can.material_override = Craft.material([Color("648e89"),Color("986e8c"),Color("939969")][row])
			vending.add_child(can)
	for x in [-1.6,0.95]:
		Craft.box(vending,Vector3(x,4.13,2.3),Vector3(0.08,3.8,0.4),Color("53616b"),0.015)
	_model("ticket_machine",Vector3(-5,0,0.7),12)
	# Display overlays and marquees are authored locally; these are scenery only.
	for i in range(2):
		var machine := a if i==0 else b
		# Match the imported glass slope (normal 0, .316, .949), with a small depth offset.
		_screen(machine,Vector3(0,3.537,0.553),Vector2(2.38,1.48),i,-18.435)
		_sign(machine,"AFTER HOURS" if i==0 else "IDLE / 02",Vector3(0,5.55,1.39),Vector2(2.75,0.5),Color("ad7298"))
	_sign(self,"BYTE SODA",Vector3(6.1,6.8,-3.1),Vector2(3.3,0.8),Color("54cfc3"))
	for x in [4.8,7.4]: Craft.box(self,Vector3(x,3.35,-3.2),Vector3(0.08,6.7,0.1),Color("3a4b55"),0.015)
	Craft.box(self,Vector3(0,-0.025,0.7),Vector3(11,0.05,7.3),Color("292f43"),0.08)
	for i in range(7):
		Craft.box(self,Vector3(-4.6+i*1.4,0.01,3.7),Vector3(0.7,0.018,0.1),Color("82627b"),0.005)

func _power() -> void:
	var server_a := _model("server_cabinet",Vector3(-3.4,0,0),0)
	var server_b := _model("server_cabinet",Vector3(1.0,0,-1.2),0)
	for server in [server_a,server_b]: server.imported.scale = Vector3(0.70,1,0.45)
	var distribution := _model("distribution_box",Vector3(6.1,0,0.4),0)
	distribution.imported.scale = Vector3(0.65,0.9,0.45)
	_sign(self,"POWER / STORAGE",Vector3(0.5,7.5,-1.9),Vector2(8.7,1),Color("bccf68"))
	for x in [-3.6,4.6]: Craft.box(self,Vector3(x,3.7,-2),Vector3(0.1,7.4,0.15),Color("40515a"),0.02)
	# Drive sleds and indicator rows give the real imported machinery a server role.
	for server in [server_a,server_b]:
		for i in range(7):
			Craft.box(server,Vector3(0,0.7+i*0.65,1.75),Vector3(2.3,0.37,0.14),Color("25313c"),0.025)
			var led := Craft.box(server,Vector3(0.87,0.7+i*0.65,1.84),Vector3(0.10,0.07,0.03),Color("a9c476"),0.008,0.15)
			led.set_meta("server_led",i)
			animated.append(led)
	_model("pipe_valve",Vector3(8.3,1.6,0.2),90)
	_model("pipe_bend",Vector3(8.5,6.0,-1.8),0)
	Craft.box(self,Vector3(9.1,3.3,-1.5),Vector3(0.16,6.6,0.2),Color("40545a"),0.02)
	Craft.box(self,Vector3(8.7,2.6,-0.5),Vector3(0.8,0.12,2.0),Color("40545a"),0.02)
	Craft.cable(self,PackedVector3Array([Vector3(7,2.6,0.2),Vector3(8.3,2.6,0.2),Vector3(8.3,6.8,-1.7),Vector3(-5,6.8,-1.7)]),Color("52686b"),0.19)

func _overhead() -> void:
	for z in [-17.5,-9.5]:
		# Paired flanges and web form actual beams, with posts outside the tower.
		for x in [-23,23]:
			Craft.box(self,Vector3(x,9.7,z),Vector3(0.6,21.6,0.65),Color("293642"),0.05)
			Craft.box(self,Vector3(x,-0.8,z),Vector3(1.6,0.55,1.5),Color("354550"),0.06)
		for y in [20.1,20.8]: Craft.box(self,Vector3(0,y,z),Vector3(46.4,0.18,0.8),Color("35434b"),0.025)
		Craft.box(self,Vector3(0,20.45,z),Vector3(46.4,0.6,0.15),Color("25323c"),0.015)
	for x in [-17,17]:
		Craft.box(self,Vector3(x,19.7,-13.5),Vector3(0.4,0.35,9),Color("405059"),0.03)
		for z in [-16,-12,-10]:
			Craft.box(self,Vector3(x,19.45,z),Vector3(2.4,0.25,0.8),Color("3d5157"),0.04)
			Craft.box(self,Vector3(x,19.29,z),Vector3(2.0,0.04,0.5),Color("9eb7ad"),0.01,0.18)
	# An open ladder-style cable tray, with a supported rail at either side.
	for x in [-0.5,0.5]: Craft.box(self,Vector3(x,18.9,-18),Vector3(0.08,0.3,14),Color("5b6a6d"),0.012)
	for i in range(17): Craft.box(self,Vector3(0,18.8,-24+i*0.75),Vector3(1.05,0.08,0.1),Color("566569"),0.012)

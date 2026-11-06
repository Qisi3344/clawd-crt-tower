extends Node3D

func orb(p: Vector3, size: Vector3, color: Color, parent: Node3D = null) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1; mesh.height = 2; mesh.radial_segments = 16; mesh.rings = 8
	var n := MeshInstance3D.new()
	n.mesh = mesh; n.position = p; n.scale = size
	n.material_override = Craft.material(color)
	(parent if parent!=null else self).add_child(n)
	return n

func _ready() -> void:
	name = "PetGashaponMachine"
	set_meta("scenery_group",true)
	var cream := Color("d4b49d")
	var teal := Color("437e76")
	var pink := Color("c77b9d")
	var dark := Color("332b3b")
	Craft.box(self,Vector3(0,0.17,0),Vector3(3.25,0.34,2.65),dark,0.12)
	Craft.box(self,Vector3(0,1.57,0),Vector3(3.15,2.5,2.5),teal,0.20)
	Craft.box(self,Vector3(0,1.69,1.21),Vector3(2.85,2.15,0.17),cream,0.15)
	# Real hollow dispensing recess: back, floor, side cheeks and a lintel.
	Craft.box(self,Vector3(-0.35,0.76,1.33),Vector3(1.15,0.88,0.10),dark,0.08)
	Craft.box(self,Vector3(-0.35,0.34,1.50),Vector3(1.2,0.12,0.62),pink,0.05)
	for x in [-1.01,0.31]: Craft.box(self,Vector3(x,0.76,1.58),Vector3(0.16,1.0,0.48),cream,0.06)
	Craft.box(self,Vector3(-0.35,1.27,1.58),Vector3(1.48,0.16,0.48),cream,0.06)
	orb(Vector3(0.73,1.96,1.35),Vector3(0.47,0.47,0.16),pink)
	Craft.box(self,Vector3(0.73,1.96,1.55),Vector3(0.64,0.16,0.16),pink.lightened(0.12),0.06)
	Craft.box(self,Vector3(-0.83,2.21,1.34),Vector3(0.88,0.65,0.13),teal,0.05)
	Craft.box(self,Vector3(-0.83,2.21,1.42),Vector3(0.72,0.48,0.03),dark,0.03)
	var price := Craft.label(self,"◇ 100",Vector3(-0.83,2.21,1.45),Color("9ad8c5"),0.004,36)
	price.name = "CrystalPrice"
	for i in range(3): Craft.box(self,Vector3(1.02,0.78+i*0.13,1.32),Vector3(0.51,0.047,0.04),dark,0.018)
	for x in [-1.1,1.1]: Craft.box(self,Vector3(x,0.18,1.34),Vector3(0.64,0.05,0.04),pink,0.02,0.5)
	# Side paw relief and rear service hatch remain visible in a 360-degree view.
	for side in [-1,1]:
		orb(Vector3(side*1.58,1.48,0.02),Vector3(0.035,0.28,0.29),cream)
		for z in [-0.25,0,0.25]: orb(Vector3(side*1.59,1.88,z),Vector3(0.035,0.12,0.09),cream)
	Craft.box(self,Vector3(0,1.48,-1.26),Vector3(2.35,1.75,0.10),cream,0.12)
	for x in [-0.98,0.98]:
		for y in [0.82,2.13]: orb(Vector3(x,y,-1.33),Vector3.ONE*0.055,dark)
	for y in [0.95,1.09,1.23]: Craft.box(self,Vector3(0,y,-1.33),Vector3(0.8,0.045,0.025),dark,0.01)
	orb(Vector3(0,2.92,0),Vector3(1.64,0.22,1.31),cream)
	var glass := orb(Vector3(0,5.05,0),Vector3(2.55,2.13,2.01),Color.WHITE)
	glass.name = "ClearHopper"
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.96,0.99,1.0,0.035)
	mat.roughness = 0.10
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var top := Node3D.new()
	top.name = "TopCap"
	top.position.y = 7.15
	top.scale = Vector3.ONE*0.5
	add_child(top)
	orb(Vector3.ZERO,Vector3(1.65,0.43,1.30),cream,top)
	orb(Vector3(0,0.41,0),Vector3(0.47,0.10,0.40),teal,top)
	# Low-poly cat-ear prisms are reused from the pet geometry.
	var ears := Node3D.new()
	ears.position = Vector3(0,-2.07,0)
	PetCapsule.cat_ear(ears,-1,cream,pink,false); PetCapsule.cat_ear(ears,1,cream,pink,false)
	top.add_child(ears)
	# Entire plate sits in front of the curved lid; the old plate intersected its tip.
	var title := Craft.box(top,Vector3(0,0.05,1.40),Vector3(2.25,0.46,0.16),dark,0.15)
	title.name = "TitlePlate"
	Craft.label(top,"PET GASHAPON",Vector3(0,0.05,1.50),Color("dd98bd"),0.0034,32)
	for side in [-1,1]:
		for y in [-0.10,0.04,0.18]: Craft.box(top,Vector3(side*1.32,y,1.13),Vector3(0.28,0.035,0.045),dark,0.01)
	# A real downward-facing lamp under the lid, with its fixture visible through glass.
	Craft.box(self,Vector3(0,6.98,0),Vector3(0.48,0.12,0.44),dark,0.04)
	Craft.box(self,Vector3(0,6.90,0),Vector3(0.40,0.03,0.36),Color("eedab1"),0.015,0.45)
	var lamp := SpotLight3D.new()
	lamp.name = "HopperLamp"
	lamp.position = Vector3(0,6.87,0)
	lamp.rotation_degrees.x = -90
	lamp.light_color = Color("ffe6bf")
	lamp.light_energy = 0.75
	lamp.spot_range = 5
	lamp.spot_angle = 44
	lamp.shadow_enabled = false
	add_child(lamp)
	# Restrained glass glints follow the enlarged ellipsoid, away from faces.
	for side in [-1,1]:
		var points := PackedVector3Array()
		for i in range(5):
			var y := 0.20+i*0.075
			var x: float = side*0.78
			points.append(Vector3(x*2.55,5.05+y*2.13,sqrt(1-x*x-y*y)*2.025))
		Craft.cable(self,points,Color("aabec0"),0.018)
	# Existing user stickers plus a few paint chips and a service note.
	Craft.sticker(self,"boot_ok",Vector3(-0.85,1.62,1.31),0.43)
	var note := Craft.box(self,Vector3(0.88,1.34,1.32),Vector3(0.52,0.25,0.018),Color("c8b89c"),0.012)
	Craft.label(note,"SERVICE 07",Vector3(0,0,0.013),dark,0.0012,24)
	for p in [Vector3(-1.25,0.48,1.31),Vector3(1.29,2.55,1.31),Vector3(1.59,0.55,0.65)]:
		Craft.box(self,p,Vector3(0.14,0.025,0.012),Color("a5978d"),0.006)
	var pets := ["cat","dog","hamster","rabbit","bear","hidden_cat"]
	for i in range(6):
		var pet := load("res://scenes/pets/"+pets[i]+".tscn").instantiate() as Node3D
		pet.position = Vector3((i%3-1)*1.08,3.14+floori(i/3.0)*1.66,0.36 if i<3 else -0.10)
		pet.scale = Vector3.ONE*0.50
		add_child(pet)

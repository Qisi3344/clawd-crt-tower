extends Node3D

func orb(p: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = 1; mesh.height = 2; mesh.radial_segments = 16; mesh.rings = 8
	var n := MeshInstance3D.new()
	n.mesh = mesh; n.position = p; n.scale = size
	n.material_override = Craft.material(color)
	add_child(n)
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
	Craft.label(self,"¥100",Vector3(-0.83,2.21,1.45),Color("eee0b7"),0.004,36)
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
	var glass := orb(Vector3(0,4.16,0),Vector3(1.70,1.42,1.34),Color.WHITE)
	glass.name = "ClearHopper"
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.9,0.86,0.93,0.12)
	mat.roughness = 0.25
	glass.material_override = mat
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	orb(Vector3(0,5.58,0),Vector3(1.65,0.43,1.30),cream)
	orb(Vector3(0,5.99,0),Vector3(0.47,0.10,0.40),teal)
	# Low-poly cat-ear prisms are reused from the pet geometry.
	var ears := Node3D.new()
	ears.position = Vector3(0,3.51,0)
	PetCapsule.cat_ear(ears,-1,cream,pink,false); PetCapsule.cat_ear(ears,1,cream,pink,false)
	add_child(ears)
	Craft.box(self,Vector3(0,5.63,1.19),Vector3(2.25,0.46,0.16),dark,0.15)
	Craft.label(self,"PET GASHAPON",Vector3(0,5.63,1.29),Color("dd98bd"),0.0034,32)
	for side in [-1,1]:
		for y in [5.48,5.62,5.76]: Craft.box(self,Vector3(side*1.32,y,1.13),Vector3(0.28,0.035,0.045),dark,0.01)
	var pets := ["cat","dog","hamster","rabbit","bear","hidden_cat"]
	for i in range(6):
		var pet := load("res://scenes/pets/"+pets[i]+".tscn").instantiate() as Node3D
		pet.position = Vector3((i%3-1)*0.88,3.0+floori(i/3.0)*1.0,0.36 if i<3 else -0.10)
		pet.scale = Vector3.ONE*0.40
		add_child(pet)

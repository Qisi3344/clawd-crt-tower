class_name ExteriorDressing
extends RefCounted

static func build(shell: Node3D, devices: Array[MonitorDevice]) -> void:
	var metal := Color("35424b")
	var yellow := Color("dce65b")
	# Industrial base: edge rails, fasteners, inset light strips and caution tape.
	for side in [-1,1]:
		Craft.box(shell,Vector3(side*11.9,-1.04,0),Vector3(0.18,0.15,23.5),metal,0.025)
		Craft.box(shell,Vector3(0,-1.04,side*11.9),Vector3(23.5,0.15,0.18),metal,0.025)
		for i in range(-5,6):
			Craft.box(shell,Vector3(i*2.1,-1.055,side*12.15),Vector3(0.12,0.07,0.12),Color("8b9c9a"),0.02)
		for i in range(10):
			var tape := Craft.box(shell,Vector3(side*10.8+i*0.035,-1.07,-2.4+i*0.48),Vector3(0.55,0.025,0.24),yellow if i%2 else Color("161e25"),0.005)
			tape.rotation_degrees.y = -30
		Craft.box(shell,Vector3(side*9.8,-1.06,7),Vector3(0.10,0.035,2.6),Color("54cfc3"),0.01,0.3)
	for x in [-9.5,9.5]:
		Craft.box(shell,Vector3(x,-1.76,0),Vector3(1.1,0.9,23),Color("121b24"),0.10)
	# Power strip lies on the platform; plugs are at real cable endpoints.
	var strip_position := Vector3(-6.6,-0.9,6.8)
	Craft.box(shell,strip_position,Vector3(2.8,0.4,0.68),Color("d3cbb5"),0.05)
	for i in range(4):
		Craft.box(shell,strip_position+Vector3(-0.95+i*0.62,0.21,0),Vector3(0.38,0.06,0.28),Color("35424b"),0.03)
	Craft.box(shell,strip_position+Vector3(1.1,0.22,0),Vector3(0.18,0.06,0.3),yellow,0.02)
	for i in range(4):
		var device: MonitorDevice = devices[i]
		var start := device.cable_anchor()
		var end := strip_position+Vector3(-0.95+i*0.62,0.28,0)
		_bundle(shell,start,end,0.045,Color("1c2932"),i*0.06)
	# Four visible data links join actual rear sockets; none crosses display glass.
	for pair in [[0,4],[4,8],[1,5],[2,6]]:
		var a: MonitorDevice = devices[pair[0]]
		var b: MonitorDevice = devices[pair[1]]
		_bundle(shell,a.cable_anchor(),b.cable_anchor(),0.055,Color("667d76"),0)
		_bundle(shell,a.cable_anchor()+Vector3(0.12,0,0),b.cable_anchor()+Vector3(0.12,0,0),0.028,Color("bdad69"),0.2)
	# Original cassette deck, reels, floppy case, communication hub and mounted sign.
	var deck := Node3D.new()
	deck.position = Vector3(-8.3,-0.35,7.8)
	deck.rotation_degrees.y = 16
	shell.add_child(deck)
	Craft.box(deck,Vector3.ZERO,Vector3(3.1,1.5,1.1),Color("7e948b"),0.12)
	Craft.box(deck,Vector3(0,0.1,0.58),Vector3(1.35,0.78,0.07),Color("24323f"),0.06)
	for x in [-0.38,0.38]: _disc(deck,Vector3(x,0.15,0.66),0.19,Color("a9b9ae"))
	for x in [-1.15,1.15]:
		_disc(deck,Vector3(x,0.05,0.58),0.33,Color("24323f"))
	for i in range(5): Craft.box(deck,Vector3(-0.7+i*0.35,-0.52,0.59),Vector3(0.24,0.11,0.13),yellow if i==4 else Color("bcc7b8"),0.02)
	Craft.label(deck,"SIDE A / SIGNAL",Vector3(0,0.55,0.64),Color("e1dfc4"),0.0017,28)
	for i in range(3):
		var floppy := Craft.box(shell,Vector3(-7.2+i*0.65,-1.04,9.2),Vector3(0.65,0.12,0.7),Color("94718e"),0.025)
		Craft.box(floppy,Vector3(0,0.07,-0.12),Vector3(0.4,0.015,0.24),Color("c6c6b6"),0.003)
	var hub := Craft.box(shell,Vector3(0,11.225,0),Vector3(2.3,0.65,1.3),Color("52536e"),0.08)
	for i in range(5): Craft.box(hub,Vector3(-0.8+i*0.38,0.08,0.67),Vector3(0.1,0.08,0.04),Color("54cfc3"),0.01,0.4)
	# The former sign post is a flush user decal on the existing portable CRT.
	var sign := Craft.sticker(devices[10],"crt_crab",Vector3(0,1.2,-1.953),1.3)
	sign.rotation_degrees.y = 180
	Craft.label(shell,"01 / MEMORY DECK",Vector3(5,-0.99,10.4),Color("a6b095"),0.008,32).rotation_degrees.x = -90

static func _disc(parent: Node3D, p: Vector3, radius: float, color: Color) -> void:
	var node := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = 0.06
	cylinder.radial_segments = 16
	node.mesh = cylinder
	node.material_override = Craft.material(color)
	node.rotation_degrees.x = 90
	node.position = p
	parent.add_child(node)

static func _bundle(parent: Node3D, a: Vector3, b: Vector3, radius: float, color: Color, sag: float) -> void:
	var points := PackedVector3Array()
	for i in range(13):
		var t := float(i)/12
		points.append(a.lerp(b,t)+Vector3(0,-sin(PI*t)*(0.7+sag),-sin(PI*t)*0.55))
	Craft.cable(parent,points,color,radius)

# Floor-standing decorative equipment only; none of these units supports a CRT.
static func build_fillers(shell: Node3D) -> void:
	var root := Node3D.new()
	root.name = "GapFillers"
	shell.add_child(root)
	for spec in [["Speaker_A",-3.3,3.6,1.25,1.55,5.0],["Speaker_B",3.3,3.5,1.15,1.5,5.0],["Speaker_C",-2.5,-2.4,1.15,1.5,5.6],["Tower_A",-3.6,-3.4,0.95,1.75,4.1],["Tower_B",3.1,-3.2,0.95,1.75,4.6]]:
		var unit := Node3D.new()
		unit.name = spec[0]
		unit.position = Vector3(spec[1],-1.1,spec[2])
		root.add_child(unit)
		var w: float = spec[3]; var d: float = spec[4]; var h: float = spec[5]
		# Four short rubber feet have a real flat underside at ground height.
		for x in [-w*0.32,w*0.32]:
			for z in [-d*0.3,d*0.3]: Craft.box(unit,Vector3(x,0.09,z),Vector3(0.18,0.18,0.24),Color("16191c"),0.025)
		if str(spec[0]).begins_with("Speaker"):
			_speaker_case(unit,w,d,h)
		else:
			_tower_case(unit,w,d,h,Color("b9b3a1") if spec[0]=="Tower_A" else Color("89918e"))
		Craft.batch_static(unit)

static func _speaker_case(unit: Node3D, w: float, d: float, h: float) -> void:
	var front := d/2-0.16
	Craft.box(unit,Vector3(0,(h+0.16)/2,-0.06),Vector3(w-0.06,h-0.16,d-0.2),Color("272b32"),0.07)
	Craft.box(unit,Vector3(0,h/2,front-0.02),Vector3(w-0.16,h-0.34,0.08),Color("10171e"),0.025)
	for y in [h*0.30,h*0.62]: _driver(unit,Vector3(0,y,front+0.045),w*0.36)
	_driver(unit,Vector3(0,h*0.86,front+0.045),w*0.19)
	# Bass-reflex opening has a recessed dark throat and a rounded rim.
	_disc(unit,Vector3(0,h*0.12,front+0.04),w*0.15,Color("060b11"))
	for x in [-w*0.36,w*0.36]:
		for y in [0.34,h-0.2]: _disc(unit,Vector3(x,y,front+0.035),0.025,Color("747870"))
	Craft.sticker(unit,"boot_ok",Vector3(0,h*0.045+0.16,front+0.025),w*0.40)
	# Side cabinet join and rear terminal cup remain visible from side/back views.
	for x in [-w/2+0.025,w/2-0.025]:
		Craft.box(unit,Vector3(x,h/2,-d*0.22),Vector3(0.012,h-0.5,0.035),Color("141a22"),0.003)
	Craft.box(unit,Vector3(0,0.7,-d/2+0.035),Vector3(w*0.55,0.55,0.05),Color("131920"),0.02)
	for x in [-0.15,0.15]:
		Craft.box(unit,Vector3(x,0.72,-d/2+0.005),Vector3(0.10,0.13,0.035),Color("a36e59") if x<0 else Color("636e72"),0.015)

static func _driver(unit: Node3D, p: Vector3, r: float) -> void:
	var rim := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = r*0.80
	torus.outer_radius = r
	torus.rings = 24
	torus.ring_segments = 8
	rim.mesh = torus
	rim.material_override = Craft.material(Color("3b4249"))
	rim.rotation_degrees.x = 90
	rim.position = p
	unit.add_child(rim)
	var cone := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r*0.30
	mesh.bottom_radius = r*0.82
	mesh.height = r*0.22
	mesh.radial_segments = 24
	mesh.cap_top = false
	mesh.cap_bottom = false
	cone.mesh = mesh
	cone.rotation_degrees.x = 90
	cone.position = p-Vector3(0,0,r*0.07)
	var paper := Craft.material(Color("1b232d")).duplicate() as StandardMaterial3D
	paper.cull_mode = BaseMaterial3D.CULL_DISABLED
	cone.material_override = paper
	unit.add_child(cone)
	var cap := MeshInstance3D.new()
	var dome := SphereMesh.new()
	dome.radius = r*0.28
	dome.height = r*0.56
	dome.radial_segments = 16
	dome.rings = 8
	cap.mesh = dome
	cap.scale.z = 0.35
	cap.position = p-Vector3(0,0,0.015)
	cap.material_override = Craft.material(Color("515962"))
	unit.add_child(cap)

static func _tower_case(unit: Node3D, w: float, d: float, h: float, shell: Color) -> void:
	var front := d/2-0.09
	Craft.box(unit,Vector3(0,(h+0.16)/2,-0.04),Vector3(w-0.02,h-0.16,d-0.10),shell.darkened(0.08),0.055)
	Craft.box(unit,Vector3(0,(h+0.2)/2,front-0.015),Vector3(w-0.06,h-0.26,0.09),shell,0.045)
	# CD drawer, floppy slot, eject key and separate power/reset controls.
	for y in [h-0.45,h-0.88]:
		Craft.box(unit,Vector3(0,y,front+0.035),Vector3(w*0.77,0.27,0.035),shell.darkened(0.20),0.012)
		Craft.box(unit,Vector3(-0.04,y,front+0.056),Vector3(w*0.54,0.028,0.016),Color("283239"),0.003)
		Craft.box(unit,Vector3(w*0.29,y-0.07,front+0.055),Vector3(0.065,0.035,0.018),shell.lightened(0.10),0.004)
	_disc(unit,Vector3(w*0.23,h*0.57,front+0.045),0.075,shell.darkened(0.3))
	Craft.box(unit,Vector3(w*0.23,h*0.57-0.18,front+0.04),Vector3(0.035,0.025,0.015),Color("73c4a3"),0.004,0.2)
	for y in range(8):
		Craft.box(unit,Vector3(0,0.50+y*0.13,front+0.04),Vector3(w*0.63,0.035,0.018),shell.darkened(0.48),0.004)
	for x in [-w/2+0.007,w/2-0.007]:
		for i in range(7):
			Craft.box(unit,Vector3(x,h*0.52+i*0.11,-d*0.2),Vector3(0.014,0.028,d*0.4),shell.darkened(0.42),0.004)
	Craft.sticker(unit,"crt_crab",Vector3(-0.13,h*0.57,front+0.05),w*0.38)
	Craft.box(unit,Vector3(0,h*0.65,-d/2+0.025),Vector3(w*0.65,h*0.38,0.03),Color("525d61"),0.015)
	for i in range(4):
		Craft.box(unit,Vector3(0,0.55+i*0.18,-d/2+0.008),Vector3(w*0.62,0.045,0.025),Color("3c464b"),0.005)
	for x in [-w*0.24,w*0.24]:
		Craft.box(unit,Vector3(x,h*0.67,-d/2+0.003),Vector3(0.12,0.32,0.025),Color("28383d"),0.008)

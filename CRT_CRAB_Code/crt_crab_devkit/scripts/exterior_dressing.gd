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
	var hub := Craft.box(shell,Vector3(-0.8,8.025,0),Vector3(2.3,0.65,1.3),Color("52536e"),0.08)
	for i in range(5): Craft.box(hub,Vector3(-0.8+i*0.38,0.08,0.67),Vector3(0.1,0.08,0.04),Color("54cfc3"),0.01,0.4)
	var sign := Node3D.new()
	sign.position = devices[10].to_global(Vector3(0,2.275,-0.25))+Vector3(0,0.8,0)
	shell.add_child(sign)
	Craft.box(sign,Vector3.ZERO,Vector3(4.5,1.0,0.14),Color("dce65b"),0.05)
	Craft.label(sign,"CRAB LINK / 01",Vector3(0,0,0.09),Color("1b252c"),0.004,36)
	Craft.box(sign,Vector3(0,-0.8,-0.05),Vector3(0.1,0.8,0.12),metal,0.01)
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

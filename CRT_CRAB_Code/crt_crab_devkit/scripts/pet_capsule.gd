class_name PetCapsule
extends Node3D

enum Kind { CAT, DOG, HAMSTER, RABBIT, BEAR, HIDDEN_CAT }
@export var kind: Kind = Kind.CAT
const TITLES := ["猫猫 / CAT", "狗狗 / DOG", "仓鼠 / HAMSTER", "兔兔 / RABBIT", "小熊 / BEAR", "隐藏猫猫 / SECRET"]
const RARITIES := ["COMMON", "COMMON", "RARE", "RARE", "RARE", "HIDDEN"]
static var shapes: Dictionary = {}

func part(label: String, mesh: Mesh, p: Vector3, size: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.position = p
	n.scale = size
	n.material_override = Craft.material(color,glow)
	add_child(n)
	return n

func ball(label: String, p: Vector3, size: Vector3, color: Color, glow := 0.0) -> MeshInstance3D:
	if not shapes.has("ball"):
		var sphere := SphereMesh.new()
		sphere.radius = 1; sphere.height = 2
		sphere.radial_segments = 12; sphere.rings = 8
		shapes.ball = sphere
	return part(label,shapes.ball,p,size,color,glow)

static func hemisphere(top: bool) -> ArrayMesh:
	var key := "top" if top else "bottom"
	if shapes.has(key): return shapes[key]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(8):
		for col in range(24):
			var points: Array[Vector3] = []
			for ij in [Vector2i(col,row),Vector2i(col+1,row),Vector2i(col+1,row+1),Vector2i(col,row+1)]:
				var a: float = TAU*ij.x/24.0
				var b: float = PI*0.5*ij.y/8.0
				points.append(Vector3(cos(a)*cos(b),sin(b)*(1 if top else -1),sin(a)*cos(b)))
			for tri in [[0,1,2],[0,2,3]]:
				var normal := (points[tri[1]]-points[tri[0]]).cross(points[tri[2]]-points[tri[0]])
				if normal.dot(points[tri[0]])>0: tri.reverse()
				for i in tri:
					st.set_normal(points[i]); st.add_vertex(points[i])
	shapes[key] = st.commit()
	return shapes[key]

func face(x: float, y: float, lift := 0.0) -> Vector3:
	return Vector3(x,y,sqrt(maxf(0.01,1-x*x-pow(y-1.0,2)))+0.018+lift)

func line(points: Array, color: Color, thickness := 0.021) -> void:
	var path := PackedVector3Array()
	for p in points: path.append(face(p.x,p.y,0.06 if kind in [Kind.DOG,Kind.HAMSTER,Kind.BEAR] and absf(p.x)<0.32 else 0.012))
	Craft.cable(self,path,color,thickness)

static func cat_ear(parent: Node3D, side: float, coat: Color, inner: Color, glowing: bool) -> void:
	# Triangular low-poly prism with a smaller inset pink triangle.
	var pts := PackedVector3Array([Vector3(-0.28,0,0),Vector3(0.28,0,0),Vector3(0.04,0.65,0)])
	for layer in range(2):
		var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var p: Array[Vector3] = []
		for z in [0.14,-0.14]:
			for v in pts: p.append((v*0.64+Vector3(0,0.08,0.155)) if layer==1 else v+Vector3(0,0,z))
		var indices := [0,2,1] if layer==1 else [0,2,1,3,4,5,0,1,4,0,4,3,1,2,5,1,5,4,2,0,3,2,3,5]
		for i in indices: st.add_vertex(p[i])
		st.generate_normals()
		var ear := MeshInstance3D.new()
		ear.name = "Ear_%s_%s"%[side,layer]
		ear.mesh = st.commit()
		ear.position = Vector3(side*0.59,2.13,0.02)
		ear.material_override = Craft.material(coat if layer==0 else inner,0.5 if glowing and layer==0 else 0.0)
		parent.add_child(ear)
		# Thin prism winding is visible from either viewing side.
		ear.material_override = ear.material_override.duplicate()
		ear.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED

func droop_ear(side: float) -> void:
	var key := "dog_drop_"+str(side)
	if not shapes.has(key):
		var centers := [Vector3(side*0.52,1.79,0.39),Vector3(side*0.70,1.72,0.46),Vector3(side*0.87,1.48,0.53),Vector3(side*0.92,1.24,0.58),Vector3(side*0.88,1.15,0.60)]
		var widths := [0.10,0.18,0.17,0.12,0.015]
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for row in range(centers.size()-1):
			for col in range(12):
				var points: Array[Vector3] = []
				for ij in [Vector2i(row,col),Vector2i(row,col+1),Vector2i(row+1,col+1),Vector2i(row+1,col)]:
					var a: float = TAU*ij.y/12.0
					points.append(centers[ij.x]+Vector3(cos(a)*widths[ij.x],0,sin(a)*widths[ij.x]*0.65))
				var order := [0,1,2,0,2,3]
				for index in order: st.add_vertex(points[index])
		for row in [0,centers.size()-1]:
			for col in range(12):
				st.add_vertex(centers[row])
				for index in ([col+1,col] if row==0 else [col,col+1]):
					var angle: float = TAU*index/12.0
					st.add_vertex(centers[row]+Vector3(cos(angle)*widths[row],0,sin(angle)*widths[row]*0.65))
		st.generate_normals()
		shapes[key] = st.commit()
	var ear := part("DroopEar",shapes[key],Vector3.ZERO,Vector3.ONE,Color("a67653"))
	ear.material_override = ear.material_override.duplicate()
	ear.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED

func _ready() -> void:
	var coats := [Color("e8dfc9"),Color("bd8d60"),Color("c69d70"),Color("e8dfc9"),Color("966c59"),Color("e5b94f")]
	var shells := [Color("cbbba1"),Color("b6b2b1"),Color("65ada4"),Color("bd789d"),Color("559b92"),Color("d5af59")]
	var coat: Color = coats[kind]
	var pink := Color("d98d9f")
	var ink := Color("3b2d39")
	var hidden := kind==Kind.HIDDEN_CAT
	part("LowerShell",hemisphere(false),Vector3(0,1,0),Vector3.ONE,shells[kind])
	# The animal is the opaque upper half of the ball, not a toy inside glass.
	var upper := part("AnimalUpperShell",hemisphere(true),Vector3(0,1,0),Vector3.ONE,coat)
	if kind==Kind.CAT:
		if not shapes.has("cat_upper"):
			var arrays := hemisphere(true).surface_get_arrays(0)
			var colors := PackedColorArray()
			for v in arrays[Mesh.ARRAY_VERTEX]:
				colors.append(Color("8c858b") if v.x>0.15 and v.y>0.45 and v.z>0.15 else coat)
			arrays[Mesh.ARRAY_COLOR] = colors
			var patch_mesh := ArrayMesh.new()
			patch_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
			shapes.cat_upper = patch_mesh
		upper.mesh = shapes.cat_upper
		upper.material_override = Craft.material(Color.WHITE).duplicate()
		upper.material_override.vertex_color_use_as_albedo = true
	var ring := TorusMesh.new()
	ring.inner_radius = 0.985; ring.outer_radius = 1.012
	ring.rings = 24; ring.ring_segments = 6
	part("SeamRim",ring,Vector3(0,1,0),Vector3.ONE,shells[kind].lightened(0.15),0.22 if hidden else 0.0)
	var pointed_ears := Node3D.new()
	# Base corners follow the head silhouette; the shared machine-ear helper is unchanged.
	pointed_ears.position.y = -1.1625
	pointed_ears.scale.y = 1.25
	add_child(pointed_ears)
	for side in [-1.0,1.0]:
		match kind:
			Kind.CAT,Kind.HIDDEN_CAT: cat_ear(pointed_ears,side,Color("e9bf60") if hidden else coat,pink,hidden)
			Kind.DOG: droop_ear(side)
			Kind.RABBIT:
				ball("LongEar",Vector3(side*0.40,2.28,-0.05),Vector3(0.23,0.62,0.19),coat)
				ball("LongInnerEar",Vector3(side*0.40,2.32,0.10),Vector3(0.14,0.46,0.07),pink)
			_:
				ball("RoundEar",Vector3(side*0.64,1.93,-0.04),Vector3(0.25,0.28,0.20),coat)
				ball("RoundInnerEar",Vector3(side*0.64,1.95,0.13),Vector3(0.16,0.18,0.06),pink if kind==Kind.HAMSTER else Color("cead8e"))
		ball("Blush",face(side*0.55,1.23,0.004),Vector3(0.105,0.075,0.025),pink)
		ball("Eye",face(side*0.36,1.43,0.004),Vector3(0.065,0.068,0.035),ink)
		ball("EyeShine",face(side*0.36-0.015,1.45,0.033),Vector3.ONE*0.013,Color("fff3dc"))
	if kind in [Kind.DOG,Kind.HAMSTER,Kind.BEAR]:
		ball("CreamMuzzle",face(0,1.27,0.008),Vector3(0.22,0.13,0.045),Color("eddbc0"))
	var nose_color := Color("926127") if hidden else ink
	ball("Nose",face(0,1.31,0.055),Vector3(0.045,0.033,0.026),nose_color)
	line([Vector2(0,1.285),Vector2(0,1.22)],nose_color,0.010)
	line([Vector2(-0.065,1.22),Vector2(0,1.195),Vector2(0.065,1.22)],nose_color,0.010)
	if kind in [Kind.CAT,Kind.HAMSTER,Kind.RABBIT,Kind.HIDDEN_CAT]:
		for side in [-1,1]:
			for y in [1.27,1.34]: line([Vector2(side*0.61,y),Vector2(side*0.74,y+0.015)],ink,0.010)

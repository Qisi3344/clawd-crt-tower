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
	return Vector3(x,y,0.77*sqrt(maxf(0.04,1-pow(x/0.80,2)-pow((y-1.57)/0.79,2)))+0.025+lift)

func line(points: Array, color: Color, thickness := 0.021) -> void:
	var path := PackedVector3Array()
	for p in points: path.append(face(p.x,p.y,0.12 if kind in [Kind.DOG,Kind.HAMSTER,Kind.BEAR] and absf(p.x)<0.32 else 0.012))
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

func _ready() -> void:
	var coats := [Color("e8dfc9"),Color("bd8d60"),Color("c69d70"),Color("e5b3c8"),Color("966c59"),Color("40304e")]
	var shells := [Color("cbbba1"),Color("c5b49b"),Color("65ada4"),Color("bd789d"),Color("559b92"),Color("d5af59")]
	var coat: Color = coats[kind]
	var pink := Color("d98d9f")
	var ink := Color("3b2d39")
	var hidden := kind==Kind.HIDDEN_CAT
	part("LowerShell",hemisphere(false),Vector3(0,1,0),Vector3.ONE,shells[kind])
	var dome := part("ClearDome",hemisphere(true),Vector3(0,1,0),Vector3.ONE*1.015,Color.WHITE)
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.86,0.84,0.96,0.18)
	glass.roughness = 0.24
	glass.cull_mode = BaseMaterial3D.CULL_BACK
	glass.no_depth_test = false
	dome.material_override = glass
	dome.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var ring := TorusMesh.new()
	ring.inner_radius = 0.96; ring.outer_radius = 1.035
	ring.rings = 24; ring.ring_segments = 6
	part("SeamRim",ring,Vector3(0,1.015,0),Vector3.ONE,shells[kind].lightened(0.15),0.22 if hidden else 0.0)
	ball("PetHead",Vector3(0,1.57,0),Vector3(0.80,0.79,0.77),coat)
	for side in [-1.0,1.0]:
		match kind:
			Kind.CAT,Kind.HIDDEN_CAT: cat_ear(self,side,Color("e9bf60") if hidden else coat,pink,hidden)
			Kind.DOG:
				var ear := ball("DroopEar",Vector3(side*0.73,1.76,0.34),Vector3(0.23,0.48,0.22),Color("a67653"))
				ear.rotation_degrees.z = side*-15
			Kind.RABBIT:
				ball("LongEar",Vector3(side*0.38,2.55,-0.05),Vector3(0.23,0.65,0.19),coat)
				ball("LongInnerEar",Vector3(side*0.38,2.59,0.10),Vector3(0.14,0.48,0.07),pink)
			_:
				ball("RoundEar",Vector3(side*0.56,2.20,-0.04),Vector3(0.31,0.32,0.20),coat)
				ball("RoundInnerEar",Vector3(side*0.56,2.22,0.13),Vector3(0.20,0.21,0.06),pink if kind==Kind.HAMSTER else Color("cead8e"))
		ball("Blush",face(side*0.47,1.49,0.008),Vector3(0.12,0.075,0.028),pink)
		if not hidden:
			ball("Eye",face(side*0.27,1.73),Vector3(0.060,0.073,0.036),ink)
			ball("EyeShine",face(side*0.27-0.015,1.755,0.035),Vector3.ONE*0.014,Color("fff3dc"))
	if kind==Kind.CAT:
		ball("GrayPatch",Vector3(0.33,1.99,0.36),Vector3(0.31,0.33,0.30),Color("8c858b"))
	if kind in [Kind.DOG,Kind.HAMSTER,Kind.BEAR]:
		ball("CreamMuzzle",face(0,1.45,0.02),Vector3(0.31,0.20,0.07),Color("eddbc0"))
	if hidden:
		var gold := Color("f2cf69")
		for side in [-1,1]:
			for cell in [Vector2(-1,0),Vector2(1,0),Vector2(-1,1),Vector2(1,1),Vector2(0,2)]:
				Craft.box(self,face(side*0.28+cell.x*0.037,1.68+cell.y*0.037,0.025),Vector3.ONE*0.035,gold,0.002,0.6)
		line([Vector2(-0.17,1.46),Vector2(-0.10,1.39),Vector2(0,1.46),Vector2(0.10,1.39),Vector2(0.17,1.46)],gold,0.025)
	else:
		ball("Nose",face(0,1.54,0.10),Vector3(0.067,0.044,0.033),ink)
		line([Vector2(-0.16,1.43),Vector2(-0.09,1.38),Vector2(0,1.43),Vector2(0.09,1.38),Vector2(0.16,1.43)],ink)
		if kind==Kind.DOG: ball("Tongue",face(0.055,1.32,0.16),Vector3(0.065,0.08,0.025),pink)
		if kind==Kind.HAMSTER:
			for x in [-0.04,0.04]: Craft.box(self,face(x,1.32,0.16),Vector3(0.065,0.105,0.04),Color("fff0d8"),0.012)
		if kind in [Kind.CAT,Kind.HAMSTER,Kind.RABBIT]:
			for side in [-1,1]:
				for y in [1.49,1.57]: line([Vector2(side*0.54,y),Vector2(side*0.67,y+0.025)],ink,0.014)
	# Small painted glass glints, kept off the eyes and mouth.
	for side in [-1,1]:
		ball("GlassGlint",Vector3(side*0.87,1.39,0.38),Vector3(0.023,0.16,0.025),Color("dfd8df"))

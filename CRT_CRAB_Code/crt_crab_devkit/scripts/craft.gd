class_name Craft
extends RefCounted

static var meshes: Dictionary = {}
static var materials: Dictionary = {}

static func material(color: Color, glow: float = 0.0) -> StandardMaterial3D:
	var key := str(color) + ":" + str(glow)
	if materials.has(key):
		return materials[key]
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.86
	if glow > 0:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = glow
	materials[key] = mat
	return mat

static func rounded_mesh(size: Vector3, radius: float) -> ArrayMesh:
	var key := str(size) + ":" + str(radius)
	if meshes.has(key):
		return meshes[key]
	var half := size / 2.0
	var r: float = minf(radius, minf(half.x, minf(half.y, half.z)) * 0.95)
	var inner := half - Vector3.ONE * r
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for axis in range(3):
		var u: int = (axis + 1) % 3
		var v: int = (axis + 2) % 3
		for side in [-1.0, 1.0]:
			var us := [-half[u], -inner[u], inner[u], half[u]]
			var vs := [-half[v], -inner[v], inner[v], half[v]]
			for i in range(3):
				for j in range(3):
					var points: Array[Vector3] = []
					var normals: Array[Vector3] = []
					for ij in [Vector2i(i,j),Vector2i(i+1,j),Vector2i(i+1,j+1),Vector2i(i,j+1)]:
						var p := Vector3.ZERO
						p[axis] = half[axis] * side
						p[u] = us[ij.x]
						p[v] = vs[ij.y]
						var clamped := p.clamp(-inner, inner)
						var n := (p - clamped).normalized()
						points.append(clamped + n * r)
						normals.append(n)
					# Godot uses clockwise winding for front faces.
					var order := [0,2,1,0,3,2] if side > 0 else [0,1,2,0,2,3]
					for idx in order:
						st.set_normal(normals[idx])
						st.add_vertex(points[idx])
	var result := st.commit()
	meshes[key] = result
	return result

static func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, bevel: float = 0.04, glow: float = 0.0) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = rounded_mesh(size, bevel)
	node.material_override = material(color, glow)
	node.position = pos
	parent.add_child(node)
	return node

static func solid(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	box(body, Vector3.ZERO, size, color, 0.06)
	var shape := CollisionShape3D.new()
	var cube := BoxShape3D.new()
	cube.size = size
	shape.shape = cube
	body.add_child(shape)
	return body

static func label(parent: Node3D, text: String, pos: Vector3, color: Color, pixels: float = 0.006, size: int = 36) -> Label3D:
	var node := Label3D.new()
	node.text = text
	node.position = pos
	node.pixel_size = pixels
	node.font_size = size
	node.modulate = color
	node.outline_size = 0
	node.no_depth_test = false
	parent.add_child(node)
	return node

static func cable(parent: Node3D, points: PackedVector3Array, color: Color, radius: float = 0.04) -> void:
	var key := "cable:"+str(radius)
	var mesh: CylinderMesh
	if meshes.has(key): mesh = meshes[key]
	else:
		mesh = CylinderMesh.new()
		mesh.top_radius = radius
		mesh.bottom_radius = radius
		mesh.height = 1.0
		mesh.radial_segments = 6
		meshes[key] = mesh
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i+1]
		var segment := MeshInstance3D.new()
		segment.mesh = mesh
		segment.material_override = material(color)
		parent.add_child(segment)
		segment.position = (a + b) / 2
		segment.scale.y = a.distance_to(b)
		var direction := (b - a).normalized()
		if absf(direction.dot(Vector3.UP)) < 0.999:
			segment.quaternion = Quaternion(Vector3.UP, direction)

static func batch_static(root: Node3D, exclude: Array = []) -> void:
	# Batch repeated keys, vents and trim per device, preserving device visibility.
	var groups: Dictionary = {}
	for node in root.find_children("*","MeshInstance3D",true,false):
		if node in exclude or not node.is_visible_in_tree() or not node.material_override is StandardMaterial3D:
			continue
		var key: String = str(node.mesh.get_rid().get_id())+":"+str(node.material_override.get_rid().get_id())
		if not groups.has(key): groups[key] = []
		groups[key].append(node)
	for group in groups.values():
		if group.size() < 2: continue
		var batch := MultiMeshInstance3D.new()
		var mesh := MultiMesh.new()
		mesh.transform_format = MultiMesh.TRANSFORM_3D
		mesh.mesh = group[0].mesh
		mesh.instance_count = group.size()
		batch.multimesh = mesh
		batch.material_override = group[0].material_override
		root.add_child(batch)
		for i in range(group.size()):
			mesh.set_instance_transform(i,root.global_transform.affine_inverse()*group[i].global_transform)
			group[i].queue_free()

# One watertight annular shell: outer shoulder, rounded nose, inner reveal, rear.
# All loops share vertex order, so corners have no overlapping bars or caps.
static func crt_bezel(parent: Node3D, color: Color, radius: float) -> MeshInstance3D:
	var profiles := [
		[Vector2(5.20,4.55),radius,Vector2.ZERO,1.43],
		[Vector2(5.20,4.55),radius,Vector2.ZERO,1.77],
		[Vector2(5.18,4.53),radius,Vector2.ZERO,1.82],
		[Vector2(5.13,4.48),radius,Vector2.ZERO,1.86],
		[Vector2(5.04,4.39),radius,Vector2.ZERO,1.88],
		[Vector2(4.43,3.39),0.20,Vector2(0,0.2),1.88],
		[Vector2(4.36,3.32),0.16,Vector2(0,0.2),1.86],
		[Vector2(4.30,3.26),0.12,Vector2(0,0.2),1.82],
		[Vector2(4.20,3.16),0.02,Vector2(0,0.2),1.69],
		[Vector2(4.20,3.16),0.02,Vector2(0,0.2),1.43],
	]
	var loops: Array[PackedVector3Array] = []
	for profile in profiles:
		var points := PackedVector3Array()
		var half: Vector2 = profile[0]/2
		var r: float = profile[1]
		for corner in range(4):
			var center: Vector2 = Vector2(1 if corner in [0,1] else -1,1 if corner in [1,2] else -1)*(half-Vector2.ONE*r)+profile[2]
			for step in range(9):
				var angle := deg_to_rad(-90+corner*90+step*90.0/8)
				var xy: Vector2 = center+Vector2(cos(angle),sin(angle))*r
				points.append(Vector3(xy.x,xy.y,profile[3]))
		loops.append(points)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var count := loops[0].size()
	for k in range(loops.size()):
		var next := (k+1)%loops.size()
		for i in range(count):
			var j := (i+1)%count
			for vertex in [Vector2i(k,i),Vector2i(next,j),Vector2i(k,j),Vector2i(k,i),Vector2i(next,i),Vector2i(next,j)]:
				var row: int = vertex.x
				var col: int = vertex.y
				var tangent := loops[row][(col+1)%count]-loops[row][(col+count-1)%count]
				var across := loops[(row+1)%loops.size()][col]-loops[(row+loops.size()-1)%loops.size()][col]
				st.set_normal(tangent.cross(across).normalized())
				st.add_vertex(loops[row][col])
	var node := MeshInstance3D.new()
	node.name = "ContinuousBezel"
	node.mesh = st.commit()
	node.material_override = material(color)
	parent.add_child(node)
	return node

static func sticker(parent: Node3D, asset: String, pos: Vector3, width: float) -> MeshInstance3D:
	var texture := load("res://assets/environment/decals/user/"+asset+".png") as Texture2D
	var node := MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2(width,width*texture.get_height()/float(texture.get_width()))
	node.mesh = quad
	node.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = texture
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.roughness = 0.95
	node.material_override = mat
	parent.add_child(node)
	return node

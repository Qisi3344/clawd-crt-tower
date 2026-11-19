extends RefCounted
## Material variants are shared by source, surface sidedness and outline profile.
## No scene-wide depth/normal buffer, mesh duplication or per-frame traversal.
const CEL = preload("res://assets/shaders/light_cel.gdshader")
const OUTLINE = preload("res://assets/shaders/cel_outline.gdshader")
var converted := {}
var outlines := {}
var shaders := {}
var hull_meshes := {}

func supports_hull(mesh: Mesh) -> bool:
	var key := mesh.get_instance_id()
	if hull_meshes.has(key): return hull_meshes[key]
	# An inverted hull needs a closed, consistently wound surface. Open cardboard
	# flaps can have coplanar front/back triangles whose "outline" covers the paint.
	# Weld split normals/UV seams by position before checking the edge topology.
	var vertices := {}
	var edges := {}
	for surface in range(mesh.get_surface_count()):
		if mesh is ArrayMesh and mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			hull_meshes[key] = false; return false
		var arrays := mesh.surface_get_arrays(surface)
		var points: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var ids: Array[int] = []
		for p in points:
			var position := Vector3i(roundi(p.x * 100000), roundi(p.y * 100000), roundi(p.z * 100000))
			if not vertices.has(position): vertices[position] = vertices.size()
			ids.append(vertices[position])
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		if indices.is_empty():
			for i in range(points.size()): indices.append(i)
		for i in range(0, indices.size(), 3):
			var a := ids[indices[i]]; var b := ids[indices[i+1]]; var c := ids[indices[i+2]]
			if a == b or b == c or c == a: continue
			for pair in [Vector2i(a,b), Vector2i(b,c), Vector2i(c,a)]:
				var edge := Vector2i(mini(pair.x,pair.y), maxi(pair.x,pair.y))
				var counts: Vector2i = edges.get(edge, Vector2i.ZERO)
				counts.x += 1; counts.y += 1 if pair.x < pair.y else -1
				edges[edge] = counts
	var closed := not edges.is_empty()
	for counts in edges.values():
		if counts.x != 2 or counts.y != 0: closed = false; break
	hull_meshes[key] = closed
	return closed

func profile(node: GeometryInstance3D) -> int:
	if not node is MeshInstance3D or node.mesh is PlaneMesh or node.mesh is QuadMesh: return 0
	# Batched keys/vents, thin trim, wall panels and the floor never get hulls.
	var size: Vector3 = node.get_aabb().size * node.global_basis.get_scale().abs()
	var thin := minf(size.x, minf(size.y, size.z))
	var large := maxf(size.x, maxf(size.y, size.z))
	if thin < 0.12 or large < 0.55 or large > 12.0: return 0
	if not supports_hull(node.mesh): return 0
	return 1 if large < 1.5 else 2

func convert(source: StandardMaterial3D, node: GeometryInstance3D = null) -> ShaderMaterial:
	var ink := profile(node) if node != null and source.cull_mode == BaseMaterial3D.CULL_BACK else 0
	var key := "%d:%d" % [source.get_instance_id(), ink]
	if converted.has(key): return converted[key]
	var mat := ShaderMaterial.new()
	if source.cull_mode == BaseMaterial3D.CULL_BACK:
		mat.shader = CEL
	else:
		# Preserve open funnels and the back of animal ears.
		if not shaders.has(source.cull_mode):
			var variant := Shader.new()
			var mode := "cull_disabled" if source.cull_mode == BaseMaterial3D.CULL_DISABLED else "cull_front"
			variant.code = CEL.code.replace("render_mode specular_disabled, ambient_light_disabled;", "render_mode specular_disabled, ambient_light_disabled, " + mode + ";")
			shaders[source.cull_mode] = variant
		mat.shader = shaders[source.cull_mode]
	mat.set_shader_parameter("patina_map",preload("res://assets/environment/decals/enamel_patina.png"))
	mat.set_shader_parameter("base_color", source.albedo_color)
	mat.set_shader_parameter("textured", source.albedo_texture != null)
	mat.set_shader_parameter("vertex_colors", source.vertex_color_use_as_albedo)
	mat.set_shader_parameter("uv_scale", source.uv1_scale)
	mat.set_shader_parameter("uv_offset", source.uv1_offset)
	mat.set_shader_parameter("double_sided", source.cull_mode == BaseMaterial3D.CULL_DISABLED)
	if source.albedo_texture != null: mat.set_shader_parameter("base_texture", source.albedo_texture)
	# Vertex-colored capsule animals use matte coats, rather than plastic glints.
	if source.vertex_color_use_as_albedo:
		mat.set_shader_parameter("patina_strength", 0.0)
		mat.set_shader_parameter("highlight_strength", 0.025)
		mat.set_shader_parameter("rim_strength", 0.035)
	if ink > 0:
		if not outlines.has(ink):
			var outline := ShaderMaterial.new()
			outline.shader = OUTLINE
			outline.set_shader_parameter("outline_width", 0.80 if ink == 1 else 1.15)
			outline.set_shader_parameter("max_world_width", 0.012 if ink == 1 else 0.025)
			outlines[ink] = outline
		mat.next_pass = outlines[ink]
	converted[key] = mat
	return mat

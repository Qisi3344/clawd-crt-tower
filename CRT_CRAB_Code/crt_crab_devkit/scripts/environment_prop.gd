class_name EnvironmentProp
extends Node3D

@export var asset_id := ""
var imported: Node3D
var meshes: Array[MeshInstance3D] = []
static var shaded_materials: Dictionary = {}

func _ready() -> void:
	var path := "res://assets/environment/optimized/"+asset_id+".glb"
	var packed := load(path) as PackedScene
	if packed == null:
		push_error("Environment asset missing: "+path)
		return
	imported = packed.instantiate()
	imported.name = "ImportedModel"
	add_child(imported)
	imported.process_mode = Node.PROCESS_MODE_DISABLED
	for node in imported.find_children("*","MeshInstance3D",true,false):
		meshes.append(node)
		for surface in range(node.mesh.get_surface_count()):
			var source := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if source==null: continue
			var id := source.get_instance_id()
			if not shaded_materials.has(id):
				var mat := source.duplicate() as StandardMaterial3D
				mat.albedo_color *= Color(0.62,0.67,0.70,1)
				mat.roughness = 0.95
				mat.metallic = 0
				mat.emission_enabled = false
				shaded_materials[id] = mat
			node.set_surface_override_material(surface,shaded_materials[id])
		# Small background props need depth and shading, not another shadow map.
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_meta("asset_id",asset_id)

func world_bounds() -> AABB:
	var result := AABB()
	var first := true
	# Include local shelves/screens added to an imported prop before registration.
	for mesh in find_children("*","MeshInstance3D",true,false):
		var box: AABB = mesh.global_transform*mesh.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result

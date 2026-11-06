class_name EnvironmentSurroundings
extends Node3D

var director: ShellDirector
var devices: Array[MonitorDevice] = []
var occluders: Array[Dictionary] = []
var zones: Array[Node3D] = []
var micro_motion := true
var clock := 0.0
var animation_tick := 0.0
var registered_model_count := 0
var imported_triangle_count := 0
var hidden_count := 0
var occlusion_enabled := true

func _ready() -> void:
	process_priority = 10 # Run after ShellDirector has placed this frame's camera.
	name = "Surroundings"
	var configs := [
		["repair_bay",Vector3(-18.4,-1.1,1),18.0],
		["arcade_corner",Vector3(17.6,-1.1,-1),-15.0],
		["power_storage",Vector3(0,-1.1,-19.4),0.0],
		["overhead_structures",Vector3.ZERO,0.0]
	]
	for config in configs:
		var zone := (load("res://scenes/environment/"+str(config[0])+".tscn") as PackedScene).instantiate() as Node3D
		zone.position = config[1]
		zone.rotation_degrees.y = config[2]
		add_child(zone)
		zones.append(zone)
	_build_stage()
	# Bounds describe actual imported geometry, not assumed primitive placeholders.
	for node in find_children("*","Node3D",true,false):
		if node.has_meta("scenery_group"):
			var bounds := AABB()
			var first := true
			for mesh in node.find_children("*","MeshInstance3D",true,false):
				var box: AABB = mesh.global_transform*mesh.get_aabb()
				bounds = box if first else bounds.merge(box)
				first = false
			occluders.append({"node":node,"bounds":bounds.grow(0.12)})
		elif node is EnvironmentProp:
			registered_model_count += 1
			occluders.append({"node":node,"bounds":node.world_bounds().grow(0.12)})
			for mesh in node.meshes:
				for surface in range(mesh.mesh.get_surface_count()):
					var arrays: Array = mesh.mesh.surface_get_arrays(surface)
					imported_triangle_count += arrays[Mesh.ARRAY_INDEX].size()/3 if arrays[Mesh.ARRAY_INDEX]!=null and not arrays[Mesh.ARRAY_INDEX].is_empty() else arrays[Mesh.ARRAY_VERTEX].size()/3
		elif node is MeshInstance3D:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var ancestor := node.get_parent()
			var in_model := false
			while ancestor!=self and ancestor!=null:
				if ancestor is EnvironmentProp or ancestor.has_meta("scenery_group"): in_model = true
				ancestor = ancestor.get_parent()
			if not in_model:
				occluders.append({"node":node,"bounds":(node.global_transform*node.get_aabb()).grow(0.08)})

func _build_stage() -> void:
	Craft.box(self,Vector3(0,-1.43,-1),Vector3(52,0.56,48),Color("19232e"),0.35)
	# Perimeter only; the foreground is kept clear as the default camera approach.
	for side in [-1,1]:
		Craft.box(self,Vector3(side*25.5,-0.98,-2),Vector3(0.18,0.15,44),Color("35444c"),0.02)
		Craft.box(self,Vector3(0,-0.98,-24),Vector3(51,0.15,0.18),Color("35444c"),0.02)
	for x in [-21,-15,15,21]:
		Craft.box(self,Vector3(x,-1.13,0),Vector3(0.035,0.02,36),Color("39464d"),0.001)
	for z in [-20,-13,13,19]:
		Craft.box(self,Vector3(0,-1.13,z),Vector3(48,0.02,0.035),Color("39464d"),0.001)
	for side in [-1,1]:
		for z in [-16,-8]:
			var panel := _model("background_panel",Vector3(side*25.5,-1.1,z),side*90)
			panel.scale = Vector3(1.7,2.5,1)
	for poster in [[-13,1.9,2.8,"404"],[-5,2.7,2.3,"crt_poster"],[5,2.2,2.1,"claws"],[13,2.5,2.5,"archive_link"]]:
		var x: float = poster[0]
		var panel := _model("background_panel",Vector3(x,-1.1,-24.5),0)
		panel.scale = Vector3(1.9,2.2,1)
		# Share the panel's visibility; preserve the original world size and position.
		var decal: MeshInstance3D = zones[3]._decal(zones[3],poster[3],Vector3(x,poster[1],-24.20),poster[2])
		decal.name = "MountedPoster"
		decal.reparent(panel,true)
	# Cable trays connect at both ends: rear CRT socket -> power cabinet socket.
	var cables := [
		PackedVector3Array([Vector3(0,0.3,-10.9),Vector3(0,-0.9,-13.0),Vector3(7,-0.9,-13.0),Vector3(7,1.5,-18.1)]),
		PackedVector3Array([Vector3(-3.6,5.4,-2.5),Vector3(-7,3,-9),Vector3(-7,-0.9,-17),Vector3(-3.4,1.5,-18.0)])
	]
	# Actual source endpoints are bound when configure() receives MonitorDevice nodes.
	for i in range(cables.size()):
		var anchor := Node3D.new()
		anchor.name = "PowerCable_%d"%i
		add_child(anchor)
		anchor.set_meta("points",cables[i])
	Craft.label(self,"REPAIR BAY / 07",Vector3(-18,-1.10,8),Color("849280"),0.013,36).rotation_degrees.x = -90
	Craft.label(self,"AFTER HOURS",Vector3(18,-1.10,8),Color("856379"),0.014,36).rotation_degrees.x = -90

func _model(scene: String, p: Vector3, yaw: float) -> EnvironmentProp:
	var node := (load("res://scenes/environment/"+scene+".tscn") as PackedScene).instantiate() as EnvironmentProp
	node.position = p
	node.rotation_degrees.y = yaw
	add_child(node)
	return node

func configure(camera_director: ShellDirector, monitors: Array[MonitorDevice]) -> void:
	director = camera_director
	devices = monitors
	for i in range(2):
		var anchor := get_node("PowerCable_%d"%i) as Node3D
		var points: PackedVector3Array = anchor.get_meta("points")
		points[0] = monitors[2 if i==0 else 6].cable_anchor()
		# Drop behind the casing before travelling across the floor.
		points.insert(1,Vector3(points[0].x,-0.9,points[0].z))
		Craft.cable(anchor,points,Color("465956") if i==0 else Color("292c32"),0.075 if i==0 else 0.10)
		for node in anchor.find_children("*","MeshInstance3D",true,false): node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _process(delta: float) -> void:
	if director==null or director.active==null: return
	_update_occlusion()
	if not micro_motion: return
	clock += delta
	animation_tick += delta
	for zone in zones:
		for node in zone.animated:
			if node.has_meta("server_led"):
				if not node.get_parent().is_visible_in_tree(): continue
				if animation_tick>0.5: node.visible = (int(clock*1.2)+int(node.get_meta("server_led")))%5!=0
			elif node.is_visible_in_tree(): node.rotation.z += delta*0.7
		if animation_tick>0.5:
			for display in zone.displays:
				var index: int = (int(clock/4)+int(display.index))%2
				display.material.albedo_texture = load("res://assets/environment/decals/arcade_%d.png"%index)
	if animation_tick>0.5: animation_tick = 0

func set_micro_motion(value: bool) -> void:
	micro_motion = value
	if not value:
		for zone in zones:
			for node in zone.animated:
				if node.has_meta("server_led"): node.visible = true

func _targets() -> Array[Vector3]:
	if director.overview:
		return [Vector3(0,7,0),Vector3(-6,3,0),Vector3(6,3,0),Vector3(0,14,0),Vector3(0,5,6),Vector3(0,5,-6)]
	var active := director.active
	var points: Array[Vector3] = [active.focus_point()]
	for x in [-2.08,2.08]:
		for y in [-1.36,1.76]: points.append(active.to_global(Vector3(x,y,1.72)))
	return points

func _update_occlusion() -> void:
	var origin := director.camera.global_position
	var targets := _targets()
	hidden_count = 0
	for item in occluders:
		var hide := false
		if occlusion_enabled:
			for target in targets:
				if segment_hits(item.bounds,origin,target):
					hide = true
					break
		item.node.visible = not hide
		if hide: hidden_count += 1

static func segment_hits(box: AABB, from: Vector3, to: Vector3) -> bool:
	var d := to-from
	var lower := 0.0
	var upper := 0.985
	for axis in range(3):
		if absf(d[axis])<0.00001:
			if from[axis]<box.position[axis] or from[axis]>box.end[axis]: return false
		else:
			var a: float = (box.position[axis]-from[axis])/d[axis]
			var b: float = (box.end[axis]-from[axis])/d[axis]
			lower = maxf(lower,minf(a,b))
			upper = minf(upper,maxf(a,b))
			if lower>upper: return false
	return upper>0.001

extends SceneTree

var game: Node
var checks: Array = []

func check(label: String, passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: push_error(label)

func vertex_key(p: Vector3) -> String:
	return "%d,%d,%d"%[roundi(p.x*100000),roundi(p.y*100000),roundi(p.z*100000)]

func mesh_check(mesh: Mesh) -> Dictionary:
	var arrays := mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var edges := {}
	var bad_normals := 0
	var degenerate := 0
	for i in range(0,verts.size(),3):
		var geometric := (verts[i+1]-verts[i]).cross(verts[i+2]-verts[i])
		if geometric.length()<0.0000001: degenerate += 1
		if geometric.dot(normals[i]+normals[i+1]+normals[i+2])>=0: bad_normals += 1
		for j in range(3):
			if not normals[i+j].is_finite() or absf(normals[i+j].length()-1)>0.0001: bad_normals += 1
			var a := vertex_key(verts[i+j]); var b := vertex_key(verts[i+(j+1)%3])
			var key := a+"/"+b if a<b else b+"/"+a
			edges[key] = edges.get(key,0)+1
	var open_edges := 0
	for count in edges.values():
		if count!=2: open_edges += 1
	return {"triangles":verts.size()/3,"open_or_nonmanifold_edges":open_edges,"bad_normals_or_winding":bad_normals,"degenerate_triangles":degenerate}


func _initialize() -> void:
	_run.call_deferred()

func hull(node: MeshInstance3D, top: bool) -> Array:
	var arrays := node.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var points := PackedVector2Array()
	var sign_y := 1.0 if top else -1.0
	for i in range(verts.size()):
		if normals[i].y*sign_y>0.9999:
			var p: Vector3 = node.transform*verts[i]
			points.append(Vector2(p.x,p.z))
	var outline := Geometry2D.convex_hull(points)
	var result: Array = []
	for i in range(outline.size()-1): result.append([outline[i].x,outline[i].y])
	return result

func part(node: MeshInstance3D, relative: Transform3D, part_name: String) -> Dictionary:
	var box: AABB = relative*node.get_aabb()
	return {"name":part_name,"poly":[[box.position.x,box.position.z],[box.end.x,box.position.z],[box.end.x,box.end.z],[box.position.x,box.end.z]],"low":box.position.y,"high":box.end.y}

func _run() -> void:
	root.size = Vector2i(1600,1000)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	for child in game.get_children():
		if child.get_script()!=null and child.get_script().resource_path=="res://tests/sideview_qa.gd":
			game.remove_child(child)
			child.free()
	game.hud.hide()
	game.audio.enabled = false
	game.world.enabled = false
	game.director.busy = true
	game.director.overview = true
	game.surroundings.set_micro_motion(false)
	for i in range(5): await process_frame
	var devices: Array = []
	var geometry_checks: Array = []
	for device in game.devices:
		var bezel: MeshInstance3D = device.get_node("ContinuousBezel")
		var stats := mesh_check(bezel.mesh)
		geometry_checks.append({"index":device.device_index,"model":device.model,"bezel":stats})
		check("%02d continuous closed bezel with outward normals"%device.device_index,stats.open_or_nonmanifold_edges==0 and stats.bad_normals_or_winding==0 and stats.degenerate_triangles==0)
		check("%02d unchanged 4.16 x 3.12 glass, shader and inset depth"%device.device_index,device.screen.mesh.size==Vector2(4.16,3.12) and device.screen.position==Vector3(0,0.2,1.71) and device.screen_material.shader.resource_path=="res://assets/shaders/crt.gdshader" and bezel.mesh.get_aabb().end.z>device.screen.position.z+0.16)
		check("%02d functional status text stays flush and visible"%device.device_index,device.status_label.position.z>bezel.mesh.get_aabb().end.z and device.status_label.position.z-bezel.mesh.get_aabb().end.z<0.01)
		var body: MeshInstance3D = device.get_node("Case")
		var foot: MeshInstance3D = device.get_node("IntegralBase" if device.model==0 else "Foot")
		var top_box: AABB = body.transform*body.get_aabb()
		var bottom_box: AABB = foot.transform*foot.get_aabb()
		var parts: Array = []
		for node in device.find_children("*","MeshInstance3D",true,false):
			if node==device.screen or node.mesh is QuadMesh: continue
			parts.append(part(node,device.global_transform.affine_inverse()*node.global_transform,str(node.name)))
		for batch in device.find_children("*","MultiMeshInstance3D",true,false):
			var proxy := MeshInstance3D.new()
			proxy.mesh = batch.multimesh.mesh
			for i in range(batch.multimesh.instance_count):
				parts.append(part(proxy,device.global_transform.affine_inverse()*batch.global_transform*batch.multimesh.get_instance_transform(i),str(batch.name)+"/"+str(i)))
			proxy.free()
		var mass := 0.0
		var mass_center := Vector3.ZERO
		for node in [body,device.get_node("Foot"),device.get_node_or_null("IntegralBase")]:
			if node==null: continue
			var box: AABB = node.transform*node.get_aabb()
			var volume := box.get_volume()
			mass_center += box.get_center()*volume
			mass += volume
		mass_center /= mass
		var top_poly := hull(body,true)
		var bottom_poly := hull(foot,false)
		for poly in [top_poly,bottom_poly]:
			for point in poly:
				point[0] *= device.scale.x
				point[1] *= device.scale.z
		for p in parts:
			p.low *= device.scale.y; p.high *= device.scale.y
			for point in p.poly:
				point[0] *= device.scale.x; point[1] *= device.scale.z
		devices.append({"computer_id":device.computer_id,"top_polygon":top_poly,"bottom_polygon":bottom_poly,"top_y":top_box.end.y*device.scale.y,"bottom_y":bottom_box.position.y*device.scale.y,"mass":mass*device.scale.x*device.scale.y*device.scale.z,"mass_center":[mass_center.x*device.scale.x,mass_center.z*device.scale.z],"parts":parts})
	var filler_units: Array = game.shell.get_node("GapFillers").get_children()
	var filler_records: Array = []
	check("three 3D speakers and two 3D towers are present",filler_units.size()==5)
	for unit in filler_units:
		var parts: Array = []
		for node in unit.find_children("*","MeshInstance3D",true,false):
			if not node.mesh is QuadMesh: parts.append(part(node,node.global_transform,str(node.get_path())))
		for batch in unit.find_children("*","MultiMeshInstance3D",true,false):
			var proxy := MeshInstance3D.new()
			proxy.mesh = batch.multimesh.mesh
			for i in range(batch.multimesh.instance_count):
				parts.append(part(proxy,batch.global_transform*batch.multimesh.get_instance_transform(i),str(batch.get_path())+"/"+str(i)))
			proxy.free()
		var bottom: float = parts.map(func(p): return p.low).min()
		check(str(unit.name)+" detailed 3D geometry rests on the platform",absf(bottom+1.1)<0.0001 and parts.size()>20 and unit.find_children("*","PhysicsBody3D",true,false).is_empty())
		filler_records.append({"name":str(unit.name),"parts":parts})
	# A tighter array must still expose every screen and front control when focused.
	var occluder_units: Array = []
	occluder_units.append_array(game.devices)
	occluder_units.append_array(filler_units)
	for device in game.devices:
		var blocked := 0
		var targets := [Vector3(0,0.2,1.72),Vector3(-1.95,-1.20,1.72),Vector3(1.95,-1.20,1.72),Vector3(-1.95,1.60,1.72),Vector3(1.95,1.60,1.72),Vector3(-1.35,-1.88,1.89),Vector3(1.46,-1.9,1.90),Vector3(1.82,-1.89,1.90)]
		for other in occluder_units:
			if other==device: continue
			for node in other.find_children("*","MeshInstance3D",true,false):
				for target in targets:
					if node.get_aabb().intersects_segment(node.to_local(device.focus_position()),node.to_local(device.to_global(target)))!=null: blocked += 1
			for batch in other.find_children("*","MultiMeshInstance3D",true,false):
				for i in range(batch.multimesh.instance_count):
					var inverse: Transform3D = (batch.global_transform*batch.multimesh.get_instance_transform(i)).affine_inverse()
					for target in targets:
						if batch.multimesh.mesh.get_aabb().intersects_segment(inverse*device.focus_position(),inverse*device.to_global(target))!=null: blocked += 1
		check("%02d focus view exposes glass corners, sticker, button and indicator"%device.device_index,blocked==0)
	var exterior_parts: Array = []
	for node in game.shell.find_children("*","MeshInstance3D",true,false):
		if game.surroundings.is_ancestor_of(node): continue
		if game.devices.any(func(d): return d.is_ancestor_of(node)): continue
		var bounds: AABB = node.global_transform*node.get_aabb()
		if bounds.end.y<0 or bounds.size.x<0.3 or bounds.size.y<0.3 or bounds.size.z<0.3: continue
		if absf(bounds.get_center().x)>10 or absf(bounds.get_center().z)>10: continue
		exterior_parts.append(part(node,node.global_transform,str(node.get_path())))
	if DisplayServer.get_name()!="headless":
		var camera_clips := 0
		for step in range(72):
			var a := step*TAU/72
			game.director.camera.position = Vector3(sin(a)*34,17,cos(a)*34)
			game.director.camera.look_at(Vector3(0,6.4,0))
			game.surroundings._update_occlusion()
			for device in game.devices:
				for node in device.find_children("*","MeshInstance3D",true,false):
					if node.get_aabb().has_point(node.to_local(game.director.camera.global_position)): camera_clips += 1
			RenderingServer.force_draw()
			await process_frame
		check("72 angles through full 360 degrees keep overview camera clear",camera_clips==0)
		for shot in [["front",Vector3(0,17,34)],["right",Vector3(34,17,0)],["back",Vector3(0,17,-34)],["left",Vector3(-34,17,0)]]:
			game.director.camera.position = shot[1]
			game.director.camera.look_at(Vector3(0,6.4,0))
			game.surroundings._update_occlusion()
			for i in range(3): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://artifacts/crt-"+shot[0]+".png")
		for model in range(4):
			var device: MonitorDevice = game.devices.filter(func(d): return d.model==model)[0]
			game.director.overview = false
			game.director.camera.position = device.to_global(Vector3(4.5,2.8,11))
			game.director.camera.look_at(device.focus_point())
			game.surroundings._update_occlusion()
			for i in range(3): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://artifacts/crt-model-%d.png"%model)
	if DisplayServer.get_name()!="headless":
		game.set_process(false)
		if is_instance_valid(game.ambience): game.ambience.set_enabled(false)
		# Inspection fixture only: reveal all five native models without the CRTs.
		# Normal four-direction gameplay captures above retain the complete scene.
		for child in game.shell.get_children():
			if child is WorldEnvironment or child is Light3D or child.name=="GapFillers": continue
			if child is MeshInstance3D and child.position.y < -1.1: continue
			if child is Node3D: child.hide()
		game.surroundings.process_mode = Node.PROCESS_MODE_DISABLED
		for shot in [["front",Vector3(11,7,15)],["back",Vector3(-11,7,-15)]]:
			game.director.camera.position = shot[1]
			game.director.camera.look_at(Vector3(0,1.5,0))
			for i in range(3): await process_frame
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png("res://artifacts/fillers-detail-"+shot[0]+".png")
	var file := FileAccess.open("res://artifacts/crt-geometry.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"devices":devices,"filler_units":filler_records,"exterior_parts":exterior_parts,"mesh_checks":geometry_checks,"checks":checks,"passed":checks.all(func(c): return c.passed)},"\t"))
	file.close()
	game.audio.stop_all()
	OS.delay_msec(80)
	print("CRT_GEOMETRY_EXPORTED 12 devices / ",checks.size()," checks; passed=",checks.all(func(c): return c.passed))
	quit(0 if checks.all(func(c): return c.passed) else 1)

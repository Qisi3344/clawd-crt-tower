extends RefCounted

func run(qa: Node) -> void:
	var game: Node = qa.game
	var environment: EnvironmentSurroundings = game.surroundings
	qa.check("environment has four independent zones",environment.zones.size()==4)
	var props := environment.find_children("*","Node3D",true,false).filter(func(node): return node is EnvironmentProp)
	qa.check("real GLB instances are loaded",props.size()==26 and props.all(func(prop): return is_instance_valid(prop.imported) and not prop.meshes.is_empty()))
	qa.check("surroundings add no physical gameplay bodies",environment.find_children("*","PhysicsBody3D",true,false).is_empty() and environment.find_children("*","CharacterBody2D",true,false).is_empty())
	qa.check("scenery displays do not create more SubViewports",environment.find_children("*","SubViewport",true,false).is_empty())
	qa.check("actual cross-screen camera path stays clear of scenery",qa.transition_samples>0 and qa.transition_camera_clips==0)
	var triangles := 0
	for mesh in environment.find_children("*","MeshInstance3D",true,false):
		for i in range(mesh.mesh.get_surface_count()):
			var data: Array = mesh.mesh.surface_get_arrays(i)
			triangles += data[Mesh.ARRAY_INDEX].size()/3 if data[Mesh.ARRAY_INDEX]!=null and not data[Mesh.ARRAY_INDEX].is_empty() else data[Mesh.ARRAY_VERTEX].size()/3
	qa.check("all added geometry remains under 60k triangles",triangles<=60000)
	game.hud.set_paused(false)
	game.director.overview = true
	game.director.busy = true
	game._control_state()
	game.hud.overview_panel.hide()
	# Deliberately put an obstruction across the protected active glass, then clear it.
	game.director.overview = false
	game.director.focus(game._device("ARCHIVE"),true)
	game.director.busy = true
	var camera: Camera3D = game.director.camera
	var middle := camera.position.lerp(game._device("ARCHIVE").focus_point(),0.4)
	var blocker := Craft.box(environment,middle,Vector3(3,3,0.4),Color("e08080"))
	var record := {"node":blocker,"bounds":blocker.global_transform*blocker.get_aabb()}
	environment.occluders.append(record)
	environment._update_occlusion()
	qa.check("a prop placed across active glass is hidden immediately",not blocker.visible)
	blocker.position = Vector3(80,0,80)
	record.bounds = blocker.global_transform*blocker.get_aabb()
	environment._update_occlusion()
	qa.check("a cleared prop becomes visible again",blocker.visible)
	environment.occluders.erase(record)
	blocker.queue_free()
	game.director.overview = true
	var clipped := 0
	for step in range(72):
		var angle: float = step*TAU/72
		camera.position = Vector3(sin(angle)*35,20,cos(angle)*35)
		camera.look_at(Vector3(0,6,0))
		environment._update_occlusion()
		for item in environment.occluders:
			if item.node.visible and item.bounds.has_point(camera.position): clipped += 1
	qa.check("360-degree observation never leaves camera inside a visible prop",clipped==0)
	# Micro-motion has an explicit user control and does not depend on a random seed.
	environment.occlusion_enabled = false
	environment._update_occlusion()
	var fan: Node3D = environment.zones[0].animated[0]
	var motion_toggle: CheckButton
	for button in game.hud.find_children("*","CheckButton",true,false):
		if button.text=="环境微动态": motion_toggle = button
	motion_toggle.button_pressed = false
	var angle := fan.rotation.z
	await qa.frames(12)
	qa.check("micro-motion switch stops the repair fan",is_equal_approx(fan.rotation.z,angle))
	motion_toggle.button_pressed = true
	await qa.frames(12)
	qa.check("repair fan resumes when enabled",not is_equal_approx(fan.rotation.z,angle))
	environment.occlusion_enabled = true
	if qa.visual:
		game.hud.set_paused(true)
		game.hud.credits_button.pressed.emit()
		await qa.frames(4)
		qa.check("pause menu opens readable material credits",game.hud.credits_dialog.visible and game.hud.credits_dialog.dialog_text.contains("Kenney"))
		await qa.capture("environment-credits")
		game.hud.credits_dialog.hide()
		game.hud.set_paused(false)
		var views := [
			["front",Vector3(27,23,36),Vector3(0,6,0)],
			["back",Vector3(-27,23,-36),Vector3(0,6,0)],
			["left",Vector3(-36,22,12),Vector3(0,6,0)],
			["right",Vector3(36,22,-12),Vector3(0,6,0)],
			["top",Vector3(0.01,48,0.01),Vector3(0,6,0)]
		]
		for view in views:
			camera.position = view[1]
			camera.look_at(view[2])
			await qa.frames(8)
			await qa.capture("environment-"+str(view[0]))
			if view[0] in ["front","back","left"]:
				environment.hide()
				await qa.frames(3)
				await qa.capture("environment-compare-"+str(view[0])+"-before")
				environment.show()
		for view in [
			["repair",Vector3(-27,10,12),Vector3(-18.4,2,1)],
			["arcade",Vector3(27,10,8),Vector3(18,2,-2)],
			["power",Vector3(14,10,-10),Vector3(1,2,-19)]
		]:
			environment.occlusion_enabled = false
			camera.position = view[1]
			camera.look_at(view[2])
			await qa.frames(8)
			await qa.capture("environment-detail-"+str(view[0]))
			environment.occlusion_enabled = true
	# Return the game to its actual active CRT, not a detached beauty camera.
	game.director.busy = false
	game.director.focus(game._device(game.active_id),true)
	game._control_state()
	var report := {"models_instanced":environment.registered_model_count,"imported_triangles":environment.imported_triangle_count,"total_added_triangles":triangles,"occlusion_items":environment.occluders.size(),"observation_samples":72,"transition_samples":qa.transition_samples,"transition_camera_clips":qa.transition_camera_clips,"physical_bodies_added":0}
	var file := FileAccess.open("res://artifacts/environment-metrics-"+("visual" if qa.visual else "headless")+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	file.close()

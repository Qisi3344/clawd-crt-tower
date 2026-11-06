extends Node3D
# Separate preview entry: no changes to normal gameplay, rewards or saved progress.
var game: Node
var pets: Array[Node3D] = []
var angle := 0.0

func _ready() -> void:
	get_tree().root.size = Vector2i(1600,1000)
	game = load("res://scenes/main.tscn").instantiate()
	add_child(game)
	game.set_process(false)
	game.set_process_input(false)
	game.set_process_unhandled_input(false)
	game.front_end.hide()
	game.front_end.set_process(false)
	game.hud.hide()
	game.audio.enabled = false
	game.audio.music_enabled = false
	game.director.busy = true
	game.surroundings.set_micro_motion(false)
	for i in range(8): await get_tree().process_frame
	game.ambience.set_enabled(true)
	var bench := Node3D.new()
	bench.position = Vector3(0,-1.1,15.5)
	add_child(bench)
	Craft.box(bench,Vector3(0,0.70,0),Vector3(17,0.18,3.0),Color("665569"),0.07)
	for x in [-7.7,7.7]: Craft.box(bench,Vector3(x,0.32,0),Vector3(0.3,0.64,2.3),Color("514452"),0.03)
	var names := ["cat","dog","hamster","rabbit","bear","hidden_cat"]
	for i in range(6):
		var pet := load("res://scenes/pets/"+names[i]+".tscn").instantiate() as Node3D
		pet.position = Vector3((i-2.5)*2.65,0.79,0)
		bench.add_child(pet)
		pets.append(pet)
		var tint := Color("e6c980") if i==5 else Color("9ac6bb") if i>=2 else Color("e7d2c2")
		Craft.label(bench,PetCapsule.TITLES[i],pet.position+Vector3(0,-0.28,1.53),tint,0.005,32)
		Craft.label(bench,PetCapsule.RARITIES[i],pet.position+Vector3(0,-0.48,1.53),tint,0.0035,28)
	Craft.label(bench,"CRT CRAB  /  PET GACHA SERIES",Vector3(0,4.20,0),Color("e4a8c5"),0.008,38)
	Craft.label(bench,"拖动鼠标旋转六款模型  /  Esc 退出预览",Vector3(0,-0.82,1.54),Color("c1b4bf"),0.0035,28)
	# Existing visible ceiling fluorescent illuminates the preview table.
	game.director.camera.position = Vector3(0,5.5,37)
	game.director.camera.look_at(Vector3(0,1.35,15.5))
	game.director.camera.fov = 35
	for i in range(8): await get_tree().process_frame
	if "--pet-check" in OS.get_cmdline_user_args(): await verify()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE: get_tree().quit()
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		angle += event.relative.x*0.01
		for pet in pets: pet.rotation.y = angle

func verify() -> void:
	var checks: Array = []
	for i in range(pets.size()):
		var pet := pets[i]
		checks.append({"model":PetCapsule.TITLES[i],"passed":pet.kind==i and pet.has_node("LowerShell") and pet.has_node("AnimalUpperShell") and pet.has_node("SeamRim") and not pet.has_node("ClearDome") and not pet.has_node("PetHead"),"meshes":pet.find_children("*","MeshInstance3D",true,false).size()})
		checks.append({"model":PetCapsule.TITLES[i]+" opaque matching hemisphere halves", "passed":pet.find_children("*","MeshInstance3D",true,false).all(func(n): return n.material_override.transparency==BaseMaterial3D.TRANSPARENCY_DISABLED) and pet.get_node("AnimalUpperShell").position.is_equal_approx(pet.get_node("LowerShell").position) and pet.get_node("AnimalUpperShell").scale.is_equal_approx(Vector3.ONE) and absf(pet.get_node("AnimalUpperShell").get_aabb().size.y-1)<0.001 and absf(pet.get_node("LowerShell").get_aabb().position.y+1)<0.001})
	var hamster: Node3D = pets[2]
	var colors: PackedColorArray = hamster.get_node("AnimalUpperShell").mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	checks.append({"model":"hamster two solid coat colors", "passed":colors.has(Color("f1e2c6")) and colors.has(Color("c69d70")) and hamster.get_node("AnimalUpperShell").material_override.vertex_color_use_as_albedo})
	checks.append({"model":"hamster pink triangle without bear muzzle", "passed":hamster.has_node("PinkTriangleNose") and not hamster.has_node("CreamMuzzle")})
	checks.append({"model":"hamster larger round cheeks", "passed":hamster.get_node("HamsterCheekLeft").get_aabb().size.x>0.35 and hamster.get_node("HamsterCheekRight").get_aabb().size.y>0.35})
	for view in [["front",0.0],["side",PI/2],["back",PI]]:
		for pet in pets: pet.rotation.y = view[1]
		for i in range(4): await get_tree().process_frame
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("res://artifacts/pet-capsules-"+view[0]+".png")
	for pet in pets:
		pet.rotation.y = 0
		pet.visible = pet==hamster
	game.director.camera.position = Vector3(-1.325,1.25,22.5)
	game.director.camera.look_at(Vector3(-1.325,0.80,15.5))
	game.director.camera.fov = 25
	for i in range(4): await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://artifacts/hamster-face-closeup.png")
	var result := {"passed":checks.size()==15 and checks.all(func(c): return c.passed),"checks":checks,"renderer":RenderingServer.get_video_adapter_name()}
	var file := FileAccess.open("res://artifacts/pet-capsules-qa.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("PET_QA ",result.passed)
	get_tree().quit(0 if result.passed else 1)

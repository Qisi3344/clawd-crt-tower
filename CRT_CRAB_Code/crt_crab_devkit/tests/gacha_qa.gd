extends SceneTree
var checks: Array = []
var game: Node
var histogram := [0,0,0,0,0,0]
var native_steps := 0
func _initialize() -> void: run.call_deferred()
func check(name: String, passed: bool) -> void:
    checks.append({"test":name,"passed":passed})
    if not passed: push_error(name)
func frames(n: int) -> void:
    for i in range(n): await process_frame
func capture(name: String) -> void:
    await frames(4); RenderingServer.force_draw(); root.get_texture().get_image().save_png("res://artifacts/gacha-"+name+".png")
func click(pos: Vector2) -> void:
    var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.position = pos; event.pressed = true; root.push_input(event,true)
    await frames(1)
    event = event.duplicate(); event.pressed = false; root.push_input(event,true)
    await frames(2)
func touch(pos: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new(); event.index = 0; event.position = pos; event.pressed = pressed; root.push_input(event,true)
    await frames(1)
func drag_knob(panel: PetGachaPanel, angle: float) -> void:
    var center := panel.draw_button.get_global_rect().get_center()
    var radius := panel.draw_button.size.x*0.38
    var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.position = center+Vector2(radius,0); event.pressed = true; root.push_input(event,true)
    for step in range(1,7):
        var motion := InputEventMouseMotion.new(); motion.position = center+Vector2(cos(angle*step/6),sin(angle*step/6))*radius; root.push_input(motion,true)
    event = event.duplicate(); event.position = center+Vector2(cos(angle),sin(angle))*radius; event.pressed = false; root.push_input(event,true)
    await frames(2)
func run() -> void:
    var store := PetGachaStore.new(); store.storage.enabled = false; store.rng.seed = 720253
    for i in range(100000): histogram[store.roll_kind(store.rng.randf())] += 1
    check("base 72/25/3 probabilities without pity",absf((histogram[0]+histogram[1])/100000.0-0.72)<0.006 and absf((histogram[2]+histogram[3]+histogram[4])/100000.0-0.25)<0.006 and absf(histogram[5]/100000.0-0.03)<0.004)
    check("uniform common and rare species pools",abs(histogram[0]-histogram[1])<1200 and maxi(histogram[2],maxi(histogram[3],histogram[4]))-mini(histogram[2],mini(histogram[3],histogram[4]))<1000)
    store.data.hidden_misses = 12; check("13th hidden chance is 8 percent",is_equal_approx(store.hidden_chance(),0.08))
    store.data.hidden_misses = 18; check("19th hidden chance is 38 percent",is_equal_approx(store.hidden_chance(),0.38))
    store.data.hidden_misses = 19; check("20th always hidden",store.roll_kind(0.999999)==5)
    store.data.hidden_misses = 0; store.data.rare_misses = 3
    check("hidden tested before rare pity",store.roll_kind(0.01)==5)
    check("fourth forces rare or better",store.roll_kind(0.99999) in [2,3,4])
    store.storage.data = PetGachaStore.fresh()
    var max_common := 0; var max_nonhidden := 0
    for i in range(10000):
        var award := store.draw()
        max_common = maxi(max_common,store.data.rare_misses); max_nonhidden = maxi(max_nonhidden,store.data.hidden_misses)
        if not award.ok: check("all simulated transactions",false); break
    check("10000 draws preserve four and twenty pity",max_common<=3 and max_nonhidden<=19)
    check("all six awarded with duplicates",store.data.owned.values().all(func(v): return v>1) and store.data.total==10000 and PetGachaStore.valid(store.data))
    var path := "user://qa-pet-gacha-%d.json"%OS.get_process_id()
    var disk := PetGachaStore.new(); disk.storage.path = path; disk.rng.seed = 88
    for i in range(25): disk.draw()
    check("25 durable awards committed",disk.data.total==25)
    var restarted := PetGachaStore.new(); restarted.storage.path = path
    check("restart restores counts pity and recent history",restarted.load_collection() and restarted.data==disk.data)
    var failed := PetGachaStore.new(); failed.storage.path = "user://nonexistent-gacha-dir-%d/fail.json"%OS.get_process_id()
    var before := failed.data.duplicate(true)
    check("failed atomic write awards nothing",not failed.draw().ok and failed.data==before)
    var broken := FileAccess.open(path,FileAccess.WRITE); broken.store_string("broken"); broken.close()
    var corrupt := PetGachaStore.new(); corrupt.storage.path = path
    check("corrupt collection is not overwritten",not corrupt.load_collection() and not corrupt.draw().ok and FileAccess.get_file_as_string(path)=="broken")
    DirAccess.remove_absolute(path)
    root.size = Vector2i(1600,1000)
    game = load("res://scenes/main.tscn").instantiate(); root.add_child(game)
    for child in game.get_children():
        if child.get_script()!=null and child.get_script().resource_path.begins_with("res://tests/"): game.remove_child(child); child.free()
    game.audio.enabled = false; game.audio.music_enabled = false
    await frames(450)
    var machine: Node = game.surroundings.zones[1].get_node("PetGashaponMachine")
    check("thirty larger display models with rarity mix",machine.pile.size()==30 and machine.hopper.DISPLAY_KINDS.count(0)+machine.hopper.DISPLAY_KINDS.count(1)==21 and machine.hopper.DISPLAY_KINDS.count(5)==1 and machine.pile.all(func(p): return p.scale.is_equal_approx(Vector3.ONE*0.38)))
    var outside := 0; var asleep := 0; var near_glass := 0
    for body in machine.hopper.bodies:
        if body.sleeping: asleep += 1
        var xf: Transform3D = machine.global_transform.affine_inverse()*body.global_transform
        var nearest := 0.0
        for shape in body.get_children():
            if not shape is CollisionShape3D: continue
            for p in shape.shape.points:
                var v: Vector3 = xf*p
                var ellipsoid: Vector3 = (v-Vector3(0,machine.GLASS_CENTER,0))/machine.GLASS_RADII
                nearest = maxf(nearest,ellipsoid.length())
                if v.y<3.50 or v.y>6.29 or ellipsoid.length()>1.035: outside += 1
        if nearest>0.967: near_glass += 1
    check("outer capsules touch inner glass",near_glass>=4)
    check("all hulls stay inside glass and floor",outside==0)
    check("display bodies naturally sleep",asleep==30)
    var menu_button: Button
    for n in game.front_end.column.get_children():
        if n is Button and n.text=="宠物扭蛋": menu_button = n
    check("real main menu entry",menu_button!=null)
    menu_button.pressed.emit(); await frames(5)
    var panel: PetGachaPanel = game.gacha_panel
    check("minimal machine UI pauses gameplay",game.input_mode==game.InputMode.PAUSED and panel.draw_button.text.is_empty() and panel.result.text=="转动旋钮" and not panel.panel.visible)
    check("six locked silhouette icons",panel.icons.size()==6 and panel.icons.all(func(icon): return not icon.get_child(0).material.get_shader_parameter("owned")))
    await click(panel.help_button.get_global_rect().get_center())
    check("question reveals probability and pity only on demand",panel.panel.visible and panel.pity.text.contains("累计") and panel.draw_button.disabled)
    await capture("help")
    var escape := InputEventAction.new(); escape.action = "pause"; escape.pressed = true; root.push_input(escape,true); await frames(2)
    check("escape dismisses help before leaving machine",is_instance_valid(game.gacha_panel) and not panel.panel.visible and not panel.draw_button.disabled)
    await drag_knob(panel,0.65)
    check("small drag cancels without award",panel.store.data.total==0 and not panel.drawing and is_zero_approx(machine.knob.rotation.z))
    await capture("contents")
    var frame_id := 0
    for rarity in range(3):
        panel.store.storage.data = PetGachaStore.fresh()
        var chosen_seed := 0
        for seed in range(10000):
            panel.store.rng.seed = seed
            var k := panel.store.roll_kind(panel.store.rng.randf())
            if (2 if k==5 else 1 if k>=2 else 0)==rarity: chosen_seed = seed; break
        panel.store.rng.seed = chosen_seed
        if rarity==0: await click(panel.draw_button.get_global_rect().get_center())
        elif rarity==1: await drag_knob(panel,PI/2)
        else:
            panel.draw_button.grab_focus()
            var key := InputEventKey.new(); key.keycode = KEY_ENTER; key.pressed = true; root.push_input(key,true)
            key = key.duplicate(); key.pressed = false; root.push_input(key,true); await frames(2)
        check("rarity %d persists before animation"%rarity,panel.store.data.total==1 and machine.busy and panel.drawing)
        panel.draw_button.pressed.emit(); panel.draw_button.pressed.emit()
        check("rarity %d duplicate click guarded"%rarity,panel.store.data.total==1)
        var directory := "res://artifacts/gacha-demo-%d"%rarity
        DirAccess.make_dir_recursive_absolute(directory)
        for frame in range(96):
            await process_frame
            if frame%2==0:
                RenderingServer.force_draw(); root.get_texture().get_image().save_png(directory+"/%03d.png"%(frame/2))
        check("rarity %d finishes with thirty display models"%rarity,not machine.busy and not panel.draw_button.disabled and machine.pile.size()==30 and panel.last_award.rarity==rarity and machine.reward.position.is_equal_approx(Vector3(-0.58,0.48,1.93)))
        check("awarded icon lights after exit %d"%rarity,panel.icons[panel.last_award.kind].get_child(0).material.get_shader_parameter("owned"))
        check("rarity %d flap restored"%rarity,absf(machine.flap.rotation.x)<0.001 and machine.flap.position.is_equal_approx(Vector3(-0.58,1.95,1.49)))
        await capture(["common","rare","hidden"][rarity])
    panel.draw_button.pressed.emit(); await frames(20)
    var granted := panel.store.data.duplicate(true)
    var granted_kind: int = panel.last_award.kind
    panel.close(); await frames(2); game.open_gacha(); await frames(3)
    check("closing mid animation preserves award and restores interface",game.pet_gacha.data==granted and not game.gacha_panel.drawing and not machine.busy and game.gacha_panel.result.text=="转动旋钮" and game.gacha_panel.icons[granted_kind].get_child(0).material.get_shader_parameter("owned"))
    root.size = Vector2i(720,1280); await frames(5)
    panel = game.gacha_panel
    var bounds := root.get_visible_rect()
    check("portrait collection and knob remain visible",bounds.encloses(panel.collection.get_global_rect()) and bounds.encloses(panel.draw_button.get_global_rect()))
    await capture("mobile")
    var total: int = panel.store.data.total
    var center := panel.draw_button.get_global_rect().get_center()
    await touch(center,true); await touch(center,false)
    check("touch knob grants exactly once",panel.store.data.total==total+1 and panel.drawing)
    await frames(96)
    await click(panel.help_button.get_global_rect().get_center())
    check("portrait help stays inside viewport",bounds.encloses(panel.panel.get_global_rect()))
    await capture("mobile-help")
    panel.help_button.button_pressed = false
    panel.close_button.grab_focus(); await frames(4)
    check("keyboard return remains visible",bounds.encloses(panel.close_button.get_global_rect()))

    game.gacha_panel.close(); await frames(2)
    check("return restores main menu",game.in_menu and game.front_end.visible and not is_instance_valid(game.gacha_panel))
    game.begin_adventure(false)
    if game.story.playing: game.story.skip(); await frames(2)
    game.hud.set_paused(true)
    game.hud.gacha_requested.emit(); await frames(2)
    check("pause entry freezes player",is_instance_valid(game.gacha_panel) and not game.world.enabled and game.hud.paused)
    game.gacha_panel.close(); await frames(2)
    check("close returns to paused adventure",not game.in_menu and game.hud.visible and game.hud.paused and not game.world.enabled)
    game.hud.set_paused(false)
    check("resume restores playable world",game.world.enabled and game.world.player.enabled)
    var report := {"passed":checks.all(func(c): return c.passed),"checks":checks,"base_probability_samples":100000,"base_kind_counts":histogram,"pity_sequence_samples":10000,"max_consecutive_common":max_common,"max_without_hidden":max_nonhidden,"near_glass_bodies":near_glass,"sleeping_bodies":asleep,"hull_vertices_outside":outside}
    var file := FileAccess.open("res://artifacts/pet-gacha-qa.json",FileAccess.WRITE); file.store_string(JSON.stringify(report,"  "))
    print("PET_GACHA_QA ",report.passed," checks ",checks.size())
    quit(0 if report.passed else 1)

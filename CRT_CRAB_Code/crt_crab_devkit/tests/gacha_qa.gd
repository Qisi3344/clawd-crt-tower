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
    check("free UI pauses gameplay and shows free price",game.input_mode==game.InputMode.PAUSED and machine.get_node("CrystalPrice").text=="免费测试" and panel.draw_button.text=="免费抽取一次")
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
        panel.draw_button.pressed.emit()
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
        check("rarity %d flap restored"%rarity,absf(machine.flap.rotation.x)<0.001 and machine.flap.position.is_equal_approx(Vector3(-0.58,1.95,1.49)))
        await capture(["common","rare","hidden"][rarity])
    panel.draw_button.pressed.emit(); await frames(20)
    var granted := panel.store.data.duplicate(true)
    panel.close(); await frames(2); game.open_gacha(); await frames(3)
    check("closing mid animation preserves award and restores interface",game.pet_gacha.data==granted and not game.gacha_panel.drawing and not machine.busy and game.gacha_panel.result.text.begins_with("最近获得"))
    root.size = Vector2i(720,1280); await frames(5)
    var rect: Rect2 = game.gacha_panel.panel.get_global_rect()
    check("mobile panel stays inside viewport",rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=root.get_visible_rect().size.x+1 and rect.end.y<=root.get_visible_rect().size.y+1 and game.gacha_panel.panel.anchor_top>0.5)
    await capture("mobile")
    game.gacha_panel.close_button.grab_focus(); await frames(4)
    var return_rect: Rect2 = game.gacha_panel.close_button.get_global_rect()
    check("keyboard focus scrolls return button into view",return_rect.position.y>=rect.position.y and return_rect.end.y<=rect.end.y)

    game.gacha_panel.close(); await frames(2)
    check("return restores main menu",game.in_menu and game.front_end.visible and not is_instance_valid(game.gacha_panel))
    game.begin_adventure(false); game.hud.set_paused(true)
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

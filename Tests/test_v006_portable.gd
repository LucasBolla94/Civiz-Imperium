extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(ProjectSettings.get_setting("application/config/version") == "0.0.6")
	var slots=root.get_node("IslandSaves")
	slots.directory="user://portable-v006-"+slots.token()
	slots.open_catalog()
	assert(slots.begin_new(0,"Ilha portátil"))
	var music=root.get_node("Music")
	assert(music.stream.clip_count==4 and music.player.bus=="Music")
	for i in 4: assert(music.stream.get_clip_stream(i).get_length()>40)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused = true
	for frame in range(8): await process_frame
	var food = game.add_building("food",Vector2i(42,23),true)
	assert(not game.gardens_unlocked() and game.place_job("garden",Vector2i(58,29)) == null)
	food.level = 2
	game.rebuild_navigation()
	var garden = game.place_job("garden",Vector2i(58,29))
	assert(garden != null)
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(10)
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(4)
	game.simulation_paused = false
	garden._process(60)
	game.simulation_paused = true
	game.select_entity(garden)
	root.get_node("Localization").choose("pt")
	game.hud.refresh()
	assert(game.hud.title_label.text == "Horta 2 × 2")
	assert(game.saves.save_file())
	assert(game.saves.load_file())
	assert(game.gardens.size() == 1 and game.gardens[0].remaining == 15)
	game.simulation_paused = true
	game.select_entity(game.gardens[0])
	assert(game.entities.z_index == 1 and game.gardens[0].z_index == -1)
	var texture_lifetime: WeakRef = weakref(game.DATA.resource_texture("produce",true))
	assert(texture_lifetime.get_ref() != null)
	assert(game.DATA.resource_texture("produce",true).get_size() == Vector2(16,16))
	game.logistics.drop(Vector2i(57,32),"produce",5)
	game.logistics.drop(Vector2i(60,32),"produce",5)
	for frame in range(12): await process_frame
	game.hud.open_game_menu()
	assert(game.hud.game_menu.visible and game.camera.input_blocked())
	assert(game.hud.menu_save_button.text == "Salvar jogo" and game.hud.menu_quit_button.text == "Fechar jogo")
	game.hud.game_menu.hide()
	assert(game.simulation_paused)
	# Exported build must contain the new sparse geometry and its save support.
	var repair_cell := Vector2i(62,32)
	game.land.erase_cell(repair_cell)
	game.rebuild_navigation()
	game.expansion_brush_size = 1
	assert(game.can_place_job("expand",repair_cell))
	var repair = game.place_job("expand",repair_cell)
	assert(repair.cells == [repair_cell] and repair.materials.required == {"stone":2,"wood":1})
	assert(game.saves.save_file() and game.saves.load_file())
	repair = game.jobs.filter(func(job): return job.kind == "expand")[0]
	assert(repair.cells == [repair_cell] and repair.brush_size == 1)
	repair.materials.delivered = repair.materials.required.duplicate()
	repair.build(repair.duration)
	assert(game.is_walkable(repair_cell))
	game.camera.zoom = Vector2.ONE*2
	game.camera.smooth_zoom(1.12)
	assert(game.camera.zoom.x == 2)
	game.camera.advance_zoom(1.0/60.0)
	assert(game.camera.zoom.x > 2 and game.camera.zoom.x < 2.24)
	game.camera.reset_view()
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	assert(tree.request_cut() and not tree.cut_started and tree.remaining == 50)
	assert(game.saves.save_file() and game.saves.load_file())
	tree = game.sources.filter(func(s): return s.cut_requested)[0]
	assert(tree.cancel_cut() and tree.remaining == 50)
	game.expansion_brush_size = 3
	game.base.stored.wood = 100
	game.base.stored.stone = 100
	assert(game.place_job("expand",Vector2i(39,26),false,true) != null)
	var coastal = game.place_job("expand",Vector2i(39,28),false,true)
	assert(coastal != null and coastal.cells.size() == 6)
	game.cancel_placement()
	food = game.buildings.filter(func(b): return b.kind == "food")[0]
	food.level = 1
	game.select_entity(food)
	assert(game.hud.garden_button.disabled and game.hud.detail_label.text.contains("hortas"))
	# Occupied construction sites must be cleared in the actual packaged game.
	var site_cell := Vector2i(59,24)
	game.logistics.drop(site_cell+Vector2i.ONE,"axe",8)
	game.workers[0].position = game.cell_center(site_cell+Vector2i(2,1))
	var house = game.place_building("house",site_cell)
	assert(house != null and house.preparing_site)
	assert(game.saves.save_file() and game.saves.load_file())
	house = game.buildings.filter(func(b): return b.kind == "house")[0]
	game.simulation_paused = false
	for worker in game.workers: worker.assign_to("builder",game.base)
	for step in 1600:
		game._process(0.1)
		for worker in game.workers: worker._process(0.1)
		if house.completed: break
	assert(house.completed and not house.preparing_site)
	assert(not game.logistics.piles.any(func(p): return house.footprint().has(p.cell)))
	assert(not game.workers.any(func(w): return house.footprint().has(game.world_cell(w.position))))
	game.simulation_paused = true
	game.select_entity(house)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		var capture_path := OS.get_environment("CIVIZ_CAPTURE")
		if capture_path.is_empty(): capture_path="res://Tests/v006_portable.png"
		root.get_texture().get_image().save_png(capture_path)
	print("Portable V0.0.6: version, gameplay, assets, language and save/load passed")
	game.free()
	quit()

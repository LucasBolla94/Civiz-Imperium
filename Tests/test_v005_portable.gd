extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(ProjectSettings.get_setting("application/config/version") == "0.0.5")
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused = true
	for frame in range(8): await process_frame
	game.add_building("food",Vector2i(42,23),true)
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
	game.select_entity(game.gardens[0])
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OS.get_environment("CIVIZ_CAPTURE"))
	print("Portable V0.0.5: version, gameplay, assets, language and save/load passed")
	game.free()
	quit()

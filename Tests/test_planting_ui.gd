extends "res://Tests/test_v003_ui.gd"
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.simulation_paused = true
	for zoom in [1.0, 0.8, 1.2]:
		game.center_camera()
		game.camera.change_zoom(zoom)
		game.camera.pan(Vector2.RIGHT, 0.1)
		game.camera.force_update_scroll()
		game.select_entity(game.base)
		await process_frame
		await process_frame
		await click(game.hud.plant_button.get_global_rect().get_center())
		check(game.action_mode == "plant", "Plant button enters planting mode")
		var candidate := Vector2i(-999,-999)
		var pointer := Vector2.ZERO
		for cell in game.land.get_used_cells():
			var point: Vector2 = game.get_global_transform_with_canvas() * game.cell_center(cell + Vector2i(1,1))
			if root.get_visible_rect().has_point(point) and not game.hud.blocks_world_input(point) and game.can_place_job("plant",cell):
				candidate = cell
				pointer = point
				break
		check(candidate != Vector2i(-999,-999), "Open planting ground is visible")
		var motion := InputEventMouseMotion.new()
		motion.position = pointer
		root.push_input(motion,true)
		await process_frame
		await process_frame
		check(game.preview_valid and game.preview_cell == candidate, "Preview matches actual mouse position after camera movement")
		var before: int = game.jobs.size()
		await click(pointer)
		check(game.jobs.size() == before + 1, "Map click creates planting site")
		if game.jobs.size() > before: check(game.jobs[-1].origin == candidate, "Site matches preview")
	print("Planting UI: %d checks; %d failures" % [checks,failures])
	game.free()
	quit(1 if failures else 0)

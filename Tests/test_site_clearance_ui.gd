extends "res://Tests/test_v003_ui.gd"
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.simulation_paused = true
	game.camera.zoom = Vector2.ONE*1.6
	game.camera.position = game.cell_center(Vector2i(57,29))
	game.camera.force_update_scroll()
	game.base.stored.wood = 100
	game.base.stored.stone = 100
	var cell := Vector2i(59,24)
	game.workers[0].position = game.cell_center(cell+Vector2i(1,2))
	game.logistics.drop(cell+Vector2i.ONE,"axe",13)
	var locale = root.get_node("Localization")
	locale.choose("en")
	game.begin_placement("house")
	var point: Vector2 = game.get_global_transform_with_canvas() * game.cell_center(cell+game.placement_offset())
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion,true)
	for frame in 4: await process_frame
	check(game.preview_valid,"Preview allows a resident and loose resources")
	check(game.hud.detail_label.text.contains("Loose materials will be moved"),"English preview explains automatic clearing")
	await capture("site_clearance_preview_en")
	await click(point)
	var house = game.buildings.filter(func(b): return b.kind == "house")[0]
	check(house.preparing_site and game.selection == house,"Real click marks occupied site")
	check(game.hud.detail_label.text.contains("Clearing the site"),"Context shows preparation instead of construction progress")
	await capture("site_clearance_marked_en")
	locale.choose("pt")
	game.hud.refresh()
	check(game.hud.detail_label.text.contains("Liberando terreno"),"Portuguese clearing state is translated")
	await capture("site_clearance_marked_pt")
	game.simulation_paused = false
	var captured := false
	for step in 1200:
		game._process(0.1)
		for worker in game.workers: worker._process(0.1)
		if not captured and game.workers.any(func(w): return w.clear_site_id == house.entity_id and w.cargo > 0):
			game.simulation_paused = true
			game.hud.refresh()
			await capture("site_clearance_carrying_pt")
			game.simulation_paused = false
			captured = true
		if house.completed: break
	check(captured and house.completed,"Normal worker simulation clears and completes the clicked building")
	game.simulation_paused = true
	game.hud.refresh()
	await capture("site_clearance_completed_pt")
	print("Site clearance UI: ",checks," checks; ",failures," failures")
	game.free()
	quit(1 if failures else 0)

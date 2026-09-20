extends "res://Tests/test_v003_ui.gd"
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	await process_frame
	game.simulation_paused = true
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	check(not game.hud.progress.visible, "No tree status before selection")
	var point: Vector2 = game.get_global_transform_with_canvas() * game.cell_center(tree.origin + Vector2i(1,1))
	await click(point)
	check(game.selection == tree, "Clicking canopy selects tree")
	check(game.hud.progress.visible and not game.hud.construction_menu.visible, "Selected tree gets dedicated status panel")
	check(game.hud.detail_label.text.contains("Estágio 5/7") and game.hud.detail_label.text.contains("80 frutas"), "Stage and fruit stock visible together")
	tree.take(5,"food")
	game.hud.refresh()
	check(game.hud.detail_label.text.contains("75 frutas"), "Fruit counter updates after harvest")
	await capture("tree_selected_status")
	tree.set_stage(2)
	game.hud.refresh()
	check(game.hud.detail_label.text.contains("Estágio 3/7") and game.hud.detail_label.text.contains("ainda não produz"), "Growing tree shows stage and unavailable fruit")
	tree.set_stage(6)
	game.hud.refresh()
	check(game.hud.detail_label.text.contains("Frutas: 0") and game.hud.detail_label.text.contains("30 madeiras"), "Stump displays remaining wood without phantom fruit")
	game.select_entity(null)
	check(not game.hud.progress.visible and not game.hud.detail_header.visible, "Deselecting hides status")
	print("Tree status: %d checks; %d failures" % [checks,failures])
	game.free()
	quit(1 if failures else 0)

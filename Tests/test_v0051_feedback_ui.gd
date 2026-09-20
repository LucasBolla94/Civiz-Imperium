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
	for worker in game.workers: worker.assign_to("idle",game.base)
	var workshop = game.add_building("workshop",Vector2i(59,25),true)
	workshop.order_tool("axe")
	workshop.stored.wood = 2
	workshop.stored.stone = 1
	var food = game.add_building("food",Vector2i(42,23),true)
	var locale = root.get_node("Localization")
	locale.choose("pt")
	game.hud.refresh()
	await process_frame
	var bubble: Vector2 = game.get_global_transform_with_canvas() * workshop.warning_sprite.global_position
	await click(bubble)
	check(game.selection == workshop,"Clicking actual bubble opens the affected building")
	check(game.hud.detail_label.text.contains("Falta trabalhador"),"Bubble click shows actual cause")
	await capture("v0051_workshop_warning_pt")
	await click(game.hud.warning_button.get_global_rect().get_center())
	check(game.hud.workforce_panel.visible,"Actual shortcut click opens workforce menu")
	game.hud.toggle_workforce()
	for language in ["en","pt"]:
		locale.choose(language)
		game.select_entity(food)
		await capture("v0051_garden_unlock_"+language)
		var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
		game.select_entity(tree)
		await capture("v0051_cut_tree_"+language)
		if not tree.cut_requested:
			await click(game.hud.cut_button.get_global_rect().get_center())
			check(tree.cut_requested and not tree.cut_started,"Actual cut button queues work without instant loss")
			await click(game.hud.cut_button.get_global_rect().get_center())
			check(not tree.cut_requested and tree.remaining == 50,"Actual cancel button preserves all fruit")
	print("V0051 feedback UI: ",checks," checks; ",failures," failures")
	game.free()
	quit(1 if failures else 0)

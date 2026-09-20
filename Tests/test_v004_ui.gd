extends "res://Tests/test_v003_ui.gd"
func settle() -> void:
	for frame in range(8): await process_frame
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.simulation_paused = true
	await settle()
	var shop = game.add_building("workshop",Vector2i(58,23),true)
	game.rebuild_navigation()
	game.select_entity(shop)
	await settle()
	check(not game.hud.tools_box.visible and game.hud.order_buttons[0].visible, "Level one exposes manual orders only")
	await click(game.hud.order_buttons[0].get_global_rect().get_center())
	check(shop.tool_orders.axe == 1, "Real order click creates axe order")
	await click(game.hud.order_buttons[1].get_global_rect().get_center())
	check(shop.tool_orders.axe == 0, "Real cancel click removes pending order")
	await capture("v004_workshop_manual")
	shop.level = 2
	game.hud.refresh()
	await settle()
	check(game.hud.tools_box.visible, "Workshop upgrade exposes targets")
	await capture("v004_workshop_targets")
	game.select_entity(game.base)
	await settle()
	await click(game.hud.policy_button.get_global_rect().get_center())
	await settle()
	check(game.hud.policy_window.visible and game.camera.input_blocked(), "Plan button opens modal and blocks map input")
	game.hud.policy_controls.stone.value = 75
	check(game.automation.stock_targets.stone == 75, "Plan controls update policies")
	await capture("v004_plans")
	game.hud.policy_window.hide()
	var tree = game.sources.filter(func(s): return s.is_tree)[0]
	game.select_entity(tree)
	await settle()
	await click(game.hud.orchard_button.get_global_rect().get_center())
	check(game.automation.orchards.has(tree.origin), "Tree click enables automatic renewal")
	var depot = game.add_building("stone",Vector2i(42,23),true)
	game.rebuild_navigation()
	game.select_entity(depot)
	await settle()
	check(game.hud.survey_button.disabled, "Survey button communicates level gate")
	depot.level = 2
	game.hud.refresh()
	await click(game.hud.survey_button.get_global_rect().get_center())
	check(game.action_mode == "survey", "Survey button activates terrain selection")
	game.cancel_placement()
	var report
	for cell in game.land.get_used_cells():
		if game.can_place_job("survey",cell): report = game.place_job("survey",cell); break
	check(report != null, "Survey can be placed")
	if report != null:
		report.build(100)
		game.select_entity(report)
		await settle()
		check(game.hud.quarry_button.visible and game.hud.detail_label.text.contains("stone"), "Survey report shows reserve and opening action")
		await click(game.hud.quarry_button.get_global_rect().get_center())
		check(report.kind == "quarry" and not report.completed, "Opening button creates excavation work")
		report.materials.delivered = report.materials.required.duplicate()
		report.build(100)
		game.select_entity(game.sources[-1])
		await capture("v004_quarry")
	for size in [Vector2i(640,360),Vector2i(1920,1200)]:
		root.size = size
		game.select_entity(shop)
		await settle()
		check(Rect2(Vector2.ZERO,root.get_visible_rect().size).encloses(game.hud.bottom_panel.get_global_rect()), "Workshop panel fits resized viewport")
		game.select_entity(game.base)
		game.hud.policy_button.pressed.emit()
		await settle()
		check(Rect2i(Vector2i.ZERO,Vector2i(root.get_visible_rect().size)).encloses(Rect2i(game.hud.policy_window.position,game.hud.policy_window.size)), "Policies fit resized viewport")
		game.hud.policy_window.hide()
	print("V004 UI: %d checks; %d failures" % [checks,failures])
	game.free()
	quit(0 if failures == 0 else 1)

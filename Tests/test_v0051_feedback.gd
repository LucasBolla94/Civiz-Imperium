extends "res://Tests/test_v003.gd"
func run() -> void:
	fresh()
	stop_workers()
	var locale = root.get_node("Localization")
	locale.choose("pt")
	var workshop = game.add_building("workshop",Vector2i(59,25),true)
	workshop.order_tool("axe")
	workshop.stored.wood = 2
	workshop.stored.stone = 1
	workshop.update_warning()
	check(workshop.warning.get("action") == "inhabitants" and workshop.warning.text == "Falta trabalhador.","Workshop with inputs and demand points to Inhabitants")
	game.select_entity(workshop)
	game.hud.open_warning_action()
	check(game.hud.workforce_panel.visible,"Worker warning shortcut opens allocation menu")
	game.hud.toggle_workforce()
	workshop.stored.wood = 59
	workshop.update_warning()
	check(workshop.warning.get("action") == "building" and workshop.warning.text.contains("cheio"),"Full workshop correctly prioritizes storage over staffing")
	game.select_entity(workshop)
	check(not game.hud.warning_button.text.contains("Habitantes") and not game.hud.detail_label.text.contains("Aloque"),"Full storage never instructs more staffing")
	workshop.stored.wood = 0
	workshop.stored.stone = 0
	workshop.update_warning()
	check(workshop.warning.get("action") == "building" and workshop.warning.text.contains("madeira"),"Missing input warning is distinct from no worker")
	workshop.stored.wood = 2
	workshop.stored.stone = 1
	var worker = game.workers[0]
	worker.assign_to("workshop",workshop)
	workshop.update_warning()
	check(workshop.warning.is_empty() and not workshop.warning_sprite.visible,"Warning disappears when cause is resolved")
	worker.state = "resting"
	workshop.update_warning()
	check(workshop.warning.text.contains("descansando"),"Resting workers are not reported as missing")
	worker.state = "idle"
	var assignment: Array = game.workers.map(func(w): return w.assignment)
	var targets: Dictionary = game.automation.stock_targets.duplicate()
	game.hud.refresh()
	check(game.workers.map(func(w): return w.assignment) == assignment and game.automation.stock_targets == targets,"Feedback never changes assignments or targets")
	var food = game.add_building("food",Vector2i(42,23),true)
	game.select_entity(food)
	check(game.hud.detail_label.text.contains("200 → 300") and game.hud.detail_label.text.contains("hortas"),"Food upgrade benefit shown before spending")
	locale.choose("en")
	game.hud.refresh()
	check(game.hud.detail_label.text.contains("storage capacity 200 → 300") and game.hud.detail_label.text.contains("Unlocks new gardens"),"Food benefit translated into English")
	check(game.hud.garden_button.tooltip_text == "Upgrade a food store to level 2 to create gardens.","Garden gate is fully translated")
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	game.select_entity(tree)
	check(not game.hud.detail_label.text.contains("Produce: 0"),"Fruit-bearing tree never shows contradictory zero count")
	check(game.hud.cut_button.text == "Cut down now" and game.hud.detail_label.text.contains("loses 50 Produce"),"Cut action shows exact fruit loss in English")
	tree.request_cut()
	check(game.hud.cut_button.text == "Cancel cutting" and game.hud.detail_label.text.contains("cancellable before"),"Pending order displays cancel contract")
	tree.start_cut()
	check(game.hud.cut_button.disabled and game.hud.cut_button.text == "Cutting started","Started order cannot be cancelled through UI")
	for level in [1,2,3]:
		game.village_level = level
		game.select_entity(game.base)
		check(not game.hud.evolve_button.tooltip_text.contains("Nível"),"Village benefit translated at level %d" % level)
	finish()

extends SceneTree
var game
var failures := 0
var checks := 0
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.simulation_paused = true
	await process_frame
	var stone = game.add_building("stone",Vector2i(47,33),true)
	var wood = game.add_building("wood",Vector2i(60,34),true)
	game.rebuild_navigation()
	game.stock = {"food":0,"stone":4,"wood":2}
	stone.stored.stone = 6
	wood.stored.wood = 2
	game.select_entity(game.base)
	game.hud.refresh()
	check(game.hud.expand_button.disabled,"One missing wood blocks expansion")
	check(game.hud.expand_button.text.contains("Falta: 1 madeira"),"Expansion explains exact shortage")
	game.begin_action("expand")
	check(game.action_mode.is_empty(),"Direct action also validates available funds")
	wood.stored.wood += 1
	game.hud.refresh()
	check(game.stock == {"food":0,"stone":10,"wood":5},"HUD balance aggregates all depots")
	check(not game.hud.expand_button.disabled,"Last delivered wood unlocks expansion with split stocks")
	game.hud.expand_button.pressed.emit()
	check(game.action_mode == "expand","Enabled expansion starts placement")
	var job = game.place_job("expand",Vector2i(71,27))
	check(job != null,"Exact aggregate cost buys coastal expansion")
	check(game.stock.stone == 0 and game.stock.wood == 0,"Expansion pays exactly once across depots")
	check(game.hud.expand_button.disabled,"Spending refreshes action immediately")
	game.stock = {"food":20,"stone":10,"wood":0}
	stone.stored.stone = 15
	wood.stored.wood = 15
	game.hud.refresh()
	check(game.planted_count == 0 and game.expansion_count == 0,"No completed milestones in fixture")
	check(not game.hud.evolve_button.disabled,"Exact distributed funds unlock evolution without hidden milestones")
	game.hud.evolve_button.pressed.emit()
	check(game.village_level == 2 and game.population_limit() == 10,"Evolution button changes level and capacity")
	check(game.stock == {"food":0,"stone":0,"wood":0},"Evolution debits all resources exactly")
	check(not game.upgrade_village() and game.village_level == 2,"Repeated request cannot overspend")
	game.stock = {"food":0,"stone":0,"wood":0}
	stone.stored.stone = 20
	game.select_entity(null)
	game.hud.refresh()
	check(not game.hud.build_buttons.food.disabled,"Building cost accepts resources stored outside base")
	check(game.place_building("food",Vector2i(59,25)) != null,"Building placement accepts exact stored cost")
	check(game.stock.stone == 0,"Building payment matches displayed cost")
	print("Resource regression: ",checks," checks; ",failures," failures")
	game.free()
	quit(0 if failures == 0 else 1)

extends "res://Tests/test_v003.gd"

func tick(seconds: float) -> void:
	for i in range(ceili(seconds / 0.1)):
		game._process(0.1)
		for source in game.sources.duplicate(): source._process(0.1)
		for garden in game.gardens.duplicate(): garden._process(0.1)
		for worker in game.workers.duplicate(): worker._process(0.1)

func garden_site():
	for cell in game.land.get_used_cells():
		if game.can_place_garden(cell): return game.place_job("garden", cell)
	return null

func pile_total(resource: String) -> int:
	var amount := 0
	for pile in game.logistics.piles: amount += pile.stored.get(resource,0)
	return amount

func run() -> void:
	root.size = Vector2i(1280,720)
	fresh()
	stop_workers()
	check(game.stock.produce == 18 and not game.stock.has("fruit"), "Shared Produce replaces fruit everywhere")
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	check(tree.remaining == 50, "Adult tree starts with exactly 50 Produce")
	tree._process(500)
	check(tree.stage == 4 and tree.remaining == 50, "Adult tree never expires by time")
	check(tree.take(49,"food") == 49 and tree.stage == 4 and tree.remaining == 1, "Partial harvest leaves the tree adult")
	check(tree.take(1,"food") == 1 and tree.stage == 6 and tree.remaining == 30, "Final Produce switches directly to wood")
	check(tree.take(1,"food") == 0, "A food claim cannot harvest wood")
	tree.set_stage(0)
	tree._process(179.9)
	check(tree.stage < 4 and tree.remaining == 0, "Tree cannot produce before 180 simulation seconds")
	tree._process(0.11)
	check(tree.stage == 4 and tree.remaining == 50, "Tree produces exactly 50 at maturity")
	game.village_level = 3
	tree.set_stage(4)
	check(tree.remaining == 50, "Village level never adds tree output")
	tree.set_stage(0)
	game.simulation_paused = true
	tree._process(500)
	check(tree.age == 0 and tree.stage == 0, "Pause stops tree growth")
	game.simulation_paused = false
	game.simulation_speed = 2
	tree._process(90)
	check(tree.stage == 4, "Double speed grows tree in 90 wall seconds")
	game.simulation_speed = 1
	# Order reservations and construction cancellation before/after first work.
	fresh()
	stop_workers()
	var house = site("house")
	check(house != null, "House can be ordered")
	check(game.available_stock().wood == 0 and game.stock.wood == 20, "Marked order immediately reserves its wood")
	check(not game.can_afford({"wood":1}), "Payments share the available resource calculation")
	var builder = game.workers[0]
	house.materials.delivered.stone = 8
	game.base.stored.stone -= 8
	var ticket: Dictionary = game.logistics.reserve(builder,game.base,house,"stone",3,true)
	builder.ticket = ticket
	builder.cargo = game.logistics.pickup(ticket)
	builder.cargo_resource = "stone"
	builder.state = "to_deliver"
	var stored_before: int = game.stock.stone
	check(game.cancel_construction(house), "Unstarted building can be cancelled")
	check(pile_total("stone") == 11 and game.stock.stone == stored_before, "Cancel preserves eight delivered plus three in transit")
	check(game.logistics.tickets.is_empty() and game.available_stock().wood == 20, "Cancel releases reservations without inventory refund")
	house = site("house")
	# The second order may reuse the salvaged pile's cell; clear it physically first.
	for step in 600:
		if not house.preparing_site: break
		tick(0.1)
	house.materials.delivered = house.materials.required.duplicate()
	house.build(0.1)
	check(house.work_started and not house.completed, "First actual work persists the expenditure milestone")
	var before: int = pile_total("wood")
	check(game.cancel_construction(house) and pile_total("wood") == before, "Cancellation after work loses delivered materials")
	check(not game.base.request_demolition() and not game.cancel_construction(game.base), "Main base protected in game logic")
	# Storage demolition preserves stock, stops tasks and releases land.
	fresh()
	stop_workers()
	var depot = game.add_building("warehouse",Vector2i(42,23),true)
	depot.stored.stone = 12
	depot.stored.wood = 5
	game.rebuild_navigation()
	check(depot.request_demolition() and game.buildings.has(depot), "Demolition request does not instantly remove depot")
	check(depot.cancel_demolition() and not depot.demolition_requested, "Demolition can be cancelled before first strike")
	depot.request_demolition()
	depot.build(0)
	check(not depot.demolition_started, "Arrival or zero elapsed work is not first strike")
	depot.build(0.1)
	check(not depot.cancel_demolition(), "Demolition cannot be cancelled after first strike")
	check(game.saves.save_file("res://Tests/v005_demolition.save") and game.saves.load_file("res://Tests/v005_demolition.save"), "Demolition saves and reloads")
	depot = game.buildings[-1]
	check(depot.demolition_started and is_equal_approx(depot.demolition_progress,0.1) and not depot.cancel_demolition(), "Reload preserves irreversible demolition milestone")
	depot.build(9.9)
	check(not game.buildings.has(depot) and pile_total("stone") == 12 and pile_total("wood") == 5, "Depot demolition preserves exact stock without building refund")
	check(game.is_walkable(Vector2i(42,23)), "Demolition releases occupied land")
	# Workshop input and unfinished recipe preservation, profession fallback.
	var shop = game.add_building("workshop",Vector2i(42,23),true)
	shop.stored.wood = 5
	shop.stored.stone = 4
	shop.order_tool("axe")
	shop.craft(2)
	game.workers[1].assign_to("workshop",shop)
	shop.request_demolition()
	shop.build(10)
	check(pile_total("wood") == 10 and pile_total("stone") == 16, "Unfinished workshop recipe and unused inputs are preserved")
	check(game.workers[1].assignment == "workshop" and game.workers[1].assigned_home == game.base, "Removed workplace preserves profession with safe base fallback")
	# Housing: wait, reserve all destinations, walk, cancel and resume.
	fresh()
	stop_workers()
	house = game.add_building("house",Vector2i(42,23),true)
	game.rebuild_navigation()
	var resident = game.spawn_worker("idle",game.base,game.cell_center(house.door()))
	check(resident.residence == house, "New resident receives house vacancy")
	house.request_demolition()
	check(not house.demolition_ready() and resident.residence == house and not is_instance_valid(resident.move_destination), "Occupied demolition waits without making resident homeless")
	var destination = game.add_building("house",Vector2i(58,23),true)
	game.rebuild_navigation()
	game.settlement.tick_moves()
	check(resident.move_destination == destination and resident.residence == house, "Relocation reserves destination before changing residence")
	check(house.cancel_demolition() and resident.move_destination == null and resident.residence == house, "Cancelling demolition stabilizes unfinished move")
	house.request_demolition()
	check(game.saves.save_file("res://Tests/v005_move.save") and game.saves.load_file("res://Tests/v005_move.save"), "Relocation saves and reloads")
	house = game.buildings[1]
	destination = game.buildings[2]
	resident = game.workers[-1]
	check(resident.move_destination == destination and resident.residence == house, "Reload preserves both source home and reserved destination")
	tick(25)
	check(resident.residence == destination and house.demolition_ready(), "Resident physically moves before demolition starts")
	check(house.cancel_demolition() and resident.residence == destination, "Cancelling keeps already completed move")
	# A colony can exceed the former seven-resident cap, but not real vacancies.
	game.base.stored.produce = 60
	while game.workers.size() < 8: game.spawn_worker("idle",game.base,game.cell_center(game.base.door()))
	check(game.workers.all(func(w): return is_instance_valid(w.residence)), "More than seven residents can have homes")
	check(game.immigration.blocked_reason() == "" and game.settlement.healthy_for_arrival(), "Further arrivals follow vacancies instead of an arbitrary population target")
	# Garden construction, physical supplies, growth, yield and repeat cycles.
	fresh()
	var food = game.add_building("food",Vector2i(42,23),true)
	food.level = 2
	game.rebuild_navigation()
	var garden = garden_site()
	check(garden != null and garden.cells.size() == 4, "Food depot creates a fixed 2 by 2 garden")
	if garden == null: finish(); return
	check(garden.materials.required == {"wood":10} and garden.activity == "builder", "Builder installs fence with ten wood")
	check(garden.cells.all(func(c): return game.is_walkable(c)), "Adjacent gardens remain walkable")
	check(not game.can_place_garden(garden.origin), "Garden footprint cannot be overlapped")
	tick(80)
	check(garden.completed and garden.phase in ["growing","ripe","empty","planting"], "Workers physically supply and install garden")
	check(garden.phase != "planting", "Food worker physically plants after fence installation")
	stop_workers()
	for worker in game.workers: worker.interrupt_task()
	garden.phase = "growing"
	garden.age = 0
	garden.remaining = 0
	garden._process(59.9)
	check(not garden.harvestable("food") and garden.remaining == 0, "No garden harvest before 60 seconds")
	garden._process(0.11)
	check(garden.remaining == 15 and garden.harvestable("food"), "Garden supplies exactly fifteen units per whole plot")
	check(garden.take(14,"food") == 14 and garden.remaining == 1 and garden.phase == "ripe", "Partial garden harvest preserves remaining food")
	check(game.saves.save_file("res://Tests/v005_garden.save") and game.saves.load_file("res://Tests/v005_garden.save"), "Garden partial harvest saves and reloads")
	garden = game.gardens[0]
	check(garden.phase == "ripe" and garden.remaining == 1, "Reload never duplicates garden yield")
	garden.take(1,"food")
	garden._process(10)
	check(garden.phase == "empty", "Auto-replant is off by default")
	game.base.stored.produce = 0
	garden.auto_replant = true
	garden._process(10)
	check(garden.phase == "empty", "Automatic renewal waits for food reserves")
	game.base.stored.produce = 30
	garden._process(0.1)
	check(garden.phase == "planting" and garden.materials.required == {"produce":2}, "Renewal only pays planting cost, never a second fence")
	garden.auto_replant = false
	check(garden.phase == "planting", "Turning renewal off keeps an already requested cycle")
	# Localization operates on presentation only, including dynamic values.
	var locale = root.get_node("Localization")
	locale.choose("en")
	game.select_entity(garden)
	game.hud.refresh()
	check(game.hud.title_label.text == "Garden 2 × 2", "Garden interface is translated to English")
	check(locale.text("Precisamos de moradia para 2 pessoas") == "Housing needed for 2 residents", "Dynamic housing message translated")
	check(game.hud.resource_labels.produce.icon.tooltip_text.contains("Available to spend"), "Resource tooltip translated with per-resource breakdown")
	var state_before: Dictionary = game.saves.snapshot()
	locale.choose("pt")
	game.hud.refresh()
	check(game.hud.title_label.text == "Horta 2 × 2" and game.hud.resource_labels.produce.icon.tooltip_text.contains("Hortifruti"), "Language switches live to Portuguese")
	check(game.saves.snapshot() == state_before, "Language change does not alter saved game state")
	locale.choose("en")
	# Art dimensions and first atlas cells are a strict contract.
	check(game.DATA.resource_texture("produce").get_size() == Vector2(32,32), "Produce UI icon has contracted 32 by 32 size")
	for resource in game.DATA.RESOURCES:
		check(game.DATA.resource_texture(resource,true).get_size() == Vector2(16,16), "Native ground sprite: " + resource)
	var zoom_before: float = game.camera.zoom.x
	var key := InputEventKey.new()
	key.keycode = KEY_E
	key.pressed = true
	game._unhandled_input(key)
	game.camera.advance_zoom(1.0/60.0)
	check(game.camera.zoom.x > zoom_before or game.camera.zoom.x == 5, "E zooms in")
	key.keycode = KEY_Q
	game._unhandled_input(key)
	game.camera.advance_zoom(1.0)
	check(game.camera.zoom.x < 5, "Q zooms out")
	finish()

func finish() -> void:
	print("V0.0.5: %d checks; %d failures" % [checks,failures.size()])
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)

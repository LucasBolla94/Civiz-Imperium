extends SceneTree
var game
var failures: Array[String] = []
var assertions := 0
func check(value: bool, description: String) -> void:
	assertions += 1
	if not value:
		failures.append(description)
		push_error(description)
func tick(seconds: float) -> void:
	for step in range(ceili(seconds / 0.1)):
		game._process(0.1)
		for building in game.buildings.duplicate(): building._process(0.1)
		for worker in game.workers.duplicate():
			worker._process(0.1)
			if not game.is_walkable(game.world_cell(worker.position)): check(false, "Worker left terrain")
func _initialize() -> void: call_deferred("run")
func run() -> void:
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	check(game.buildings.size() == 1 and game.base.kind == "base", "Single initial base")
	check(game.base.sprite.texture == game.DATA.CATALOG.entry("Building-6").texture, "Initial base uses Building-6")
	check(game.base.grid_size == Vector2i(9,9) and game.base.footprint().size() == 81, "Large base footprint matches example bounds")
	check(game.is_walkable(game.base.door()), "Large base entrance remains accessible")
	check(game.sources.size() == 2, "Sources load from examples without Fruit or Stone in world")
	for number in range(1,7):
		check(game.DATA.CATALOG.entries.has("Building-%d" % number), "All six building examples registered")
	for cell in game.base.footprint():
		if game.is_walkable(cell): check(false, "Base footprint must block navigation")
	check(game.workers.size() == 1 and game.activity_count("builder") == 1, "Initial worker builds")
	check(game.stock == {"food": 20, "stone": 60}, "Initial reserves")
	check(not game.change_allocation("food", 1), "Requires completed workplace")
	check(not game.can_place("base", Vector2i(43,24)), "Cannot duplicate base")
	for cell in [Vector2i(0,0), Vector2i(50,27), Vector2i(64,27), Vector2i(50,30)]:
		check(not game.can_place("food", cell), "Protect water, buildings, sources and doors")
	var food = game.place_building("food", Vector2i(59,25))
	var stone = game.place_building("stone", Vector2i(47,33))
	check(food != null and stone != null, "Valid works")
	check(food.grid_size == Vector2i(2,3) and stone.grid_size == Vector2i(3,3), "Activity footprints follow authored examples")
	if food == null or stone == null:
		finish()
		return
	check(game.base.stored.stone == 15, "Construction debits real storage")
	tick(2)
	game.change_allocation("builder", -1)
	check(food.reserved_by == null, "Changing builder releases reservation")
	var previous: float = food.progress
	tick(15)
	check(food.progress == previous, "No builders pauses work")
	game.change_allocation("builder", 1)
	tick(70)
	check(food.completed and stone.completed, "Reassigned builder completes works")
	check(not food.enqueue() and not stone.enqueue(), "Only base recruits")
	check(game.base.enqueue() and game.base.enqueue(), "Base queues generic workers")
	check(game.stock == {"food": 12, "stone": 11}, "Central recruitment costs")
	game.simulation_paused = true
	tick(10)
	check(game.workers.size() == 1 and game.base.train_progress == 0, "Pause freezes recruitment")
	game.simulation_paused = false
	tick(13)
	check(game.workers.size() == 3 and game.activity_count("idle") == 2, "Recruits arrive free")
	check(game.change_allocation("food", 1) and game.change_allocation("stone", 1), "Assign both activities")
	check(not game.change_allocation("food", 1), "No over-allocation")
	tick(110)
	check(food.stored.food > 0 and stone.stored.stone > 0, "Local depots store deliveries")
	check(game.stock.food == game.base.stored.food + food.stored.food, "Global inventory totals local stores")
	check(game.objective_complete, "Production objective completes")
	var collector = null
	for worker in game.workers:
		if worker.assignment == "food": collector = worker
	for step in range(500):
		if collector.cargo > 0: break
		tick(0.1)
	check(collector.cargo > 0, "Carrier observed")
	var carried: int = collector.cargo
	var deposited: int = food.delivered
	game.change_allocation("food", -1)
	game.change_allocation("stone", 1)
	check(game.activity_count("stone") == 2 and game.activity_count("food") == 0, "Counts change immediately")
	check(collector.kind == "food" and collector.home == food, "Cargo keeps previous delivery destination")
	tick(50)
	check(food.delivered == deposited + carried, "Last cargo delivered exactly once")
	check(collector.kind == "stone" and collector.home == stone, "Destination changes after delivery")
	game.change_allocation("stone", -1)
	game.change_allocation("food", 1)
	tick(900)
	check(game.total_delivered.food == 80 and game.total_delivered.stone == 160, "Finite resources conserved across reassignment")
	for source in game.sources: check(source.remaining == 0, "Source exhausted")
	var count := 0
	for activity in game.DATA.ACTIVITIES: count += game.activity_count(activity)
	check(count == game.workers.size(), "Population conserved")
	game.stock = {"food": 0, "stone": 0}
	food.stored.food = 2
	stone.stored.stone = 2
	check(not game.base.enqueue(), "Cannot pay partial recruitment")
	check(food.stored.food == 2 and stone.stored.stone == 2, "Failed payment leaves stores unchanged")
	food.stored.food = 4
	check(game.base.enqueue(), "Recruit using local depot stores")
	check(food.stored.food == 0 and stone.stored.stone == 0, "Local stores debited")
	game.base.cancel_last()
	check(game.stock == {"food": 4, "stone": 2}, "Refund returns reserves")
	game.stock = {"food": 100, "stone": 100}
	for i in range(5): check(game.base.enqueue(), "Accept five queued recruits")
	var balance: Dictionary = game.stock.duplicate()
	check(not game.base.enqueue() and game.stock == balance, "Sixth rejected without payment")
	game.base._process(1)
	game.base.cancel_last()
	check(game.base.queue_count == 4 and game.base.train_progress == 1, "Cancel last preserves current progress")
	while game.base.queue_count > 0: game.base.cancel_last()
	check(game.base.train_progress == 0 and game.stock == {"food": 100, "stone": 100}, "Queue completely refunded")
	var other = game.place_building("food", Vector2i(43,24))
	tick(60)
	check(other != null and other.completed, "Additional activity depot")
	game.base.enqueue()
	tick(7)
	game.change_allocation("food", 1)
	check(game.workers[-1].assigned_home == other, "Choose least staffed matching depot")
	finish()
func finish() -> void:
	print("SIMULATION TESTS: ", assertions, " checks, ", failures.size(), " failures")
	game.free()
	quit(0 if failures.is_empty() else 1)

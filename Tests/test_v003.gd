extends SceneTree
var game
var checks := 0
var failures: Array[String] = []
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)
func fresh() -> void:
	if is_instance_valid(game): game.free()
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.process_mode = Node.PROCESS_MODE_DISABLED
func tick(seconds: float) -> void:
	for i in range(ceili(seconds / 0.1)):
		game._process(0.1)
		for source in game.sources.duplicate(): source._process(0.1)
		for worker in game.workers.duplicate(): worker._process(0.1)
func stop_workers() -> void:
	for worker in game.workers: worker.assign_to("idle", game.base)
func site(kind: String):
	for cell in game.land.get_used_cells():
		if game.can_place(kind, cell): return game.place_building(kind, cell)
	return null
func run() -> void:
	root.size = Vector2i(1280,800)
	fresh()
	check(game.workers.size() == 3, "Starts with 3 residents")
	check(game.workers.filter(func(w): return w.person.is_king).size() == 1, "Exactly one King")
	check(game.population_limit() == 3 and game.workers.all(func(w): return w.residence == game.base), "Founders have assigned base residence")
	check(not game.stock.has("food") and game.stock.produce == 18, "Fruit is an independent resource")
	check(game.workplace_for("carrier") == null, "Carrier gated before evolution")
	check(not game.base.enqueue(), "No immigration without housing")
	var house = site("house")
	check(house != null, "House fits initial island")
	if house == null: finish(); return
	var initial: Dictionary = game.stock.duplicate()
	check(house.materials.delivered.is_empty() and game.stock == initial, "Placement does not consume inventory")
	house.build(100)
	check(not house.completed, "Construction waits for material delivery")
	tick(100)
	check(house.completed and house.materials.ready(), "Founders supply and build house without carrier")
	check(game.population_limit() == 7, "Housing determines population capacity")
	check(game.immigration.arrivals == 0, "No instant settlers")
	game.base.store("produce",30)
	check(game.immigration.prepare_expedition(), "Healthy colony can prepare expedition")
	var count: int = game.workers.size()
	check(game.workers.size() == count, "Expedition never spawns immediately")
	tick(36)
	check(game.immigration.sailing, "Boat visibly sails before arrival")
	tick(14)
	check(game.workers.size() == count + 1 and game.workers[-1].residence == house, "Settler disembarks with specific residence")
	var resident = game.workers[-1]
	resident.person.energy = 5
	for step in range(300):
		tick(0.1)
		if resident.state == "resting": break
	check(resident.state == "resting" and not resident.visible and game.world_cell(resident.position) == house.door(), "Tired resident enters own house and hides")
	var energy: float = resident.person.energy
	resident.wake()
	check(resident.visible and resident.complaint_time > 0 and resident.person.energy == energy, "Early wake complains without penalty")
	resident.person.energy = 5
	resident.needs.wake_grace = 0
	tick(55)
	check(resident.person.energy > 90 and resident.visible, "Rest restores energy and returns worker")
	check(house.upgrade(), "House upgrade requested")
	tick(130)
	check(house.level == 2 and game.population_limit() == 9, "House improvement physically supplied")
	# Paused state and tree regression.
	game.simulation_paused = true
	var nutrition: float = resident.person.nutrition
	var age: float = game.sources[1].age
	tick(10)
	check(resident.person.nutrition == nutrition and game.sources[1].age == age, "Pause freezes survival and trees")
	game.simulation_paused = false
	var tree = game.sources[1]
	tree.set_stage(4)
	check(tree.harvestable("food") and not tree.harvestable("wood"), "Fruit stage cannot be cut for wood")
	tree.take(tree.remaining,"food")
	check(tree.stage == 6 and tree.blocks_ground(), "Complete harvest releases the tree for lumber")
	tree._process(161)
	check(tree.stage == 6, "Depleted tree remains wood without a white canopy")
	tree._process(21)
	check(tree.stage == 6 and tree.harvestable("wood"), "Old tree becomes lumber")
	tree.take(tree.remaining,"wood")
	check(tree.removed and game.is_walkable(tree.cells[0]), "Felling frees space")
	# Saturated storage keeps harvested resources in a physical pile.
	fresh()
	stop_workers()
	game.stock = {"stone":120}
	var worker = game.workers[0]
	worker.cargo = 5
	worker.cargo_resource = "wood"
	worker.return_home()
	check(game.base.used() == 120 and game.logistics.piles[0].stored.wood == 5, "Full warehouse preserves cargo on ground")
	tick(15)
	check(worker.state == "idle" and game.logistics.tickets.is_empty(), "Full warehouse produces no invalid logistics loop")
	game.base.stored.stone -= 10
	tick(25)
	check(game.stock.wood == 5 and game.logistics.piles.is_empty(), "Freed space automatically receives waiting resources")
	# Conflicting requests reserve each unit once; interrupted cargo is conserved.
	fresh()
	stop_workers()
	game.base.stored.wood = 5
	var a = game.add_building("house",Vector2i(42,24))
	var b = game.add_building("house",Vector2i(59,23))
	a.materials.required = {"wood":5}
	b.materials.required = {"wood":5}
	game.rebuild_navigation()
	var one = game.workers[0]
	var two = game.workers[1]
	var t1: Dictionary = game.logistics.claim(one)
	var t2: Dictionary = game.logistics.claim(two)
	check(not t1.is_empty() and t2.is_empty(), "Two jobs cannot reserve the same resources")
	check(not game.pay({"wood":1}), "Payments respect transport reservations")
	one.ticket = t1
	one.cargo = game.logistics.pickup(t1)
	one.cargo_resource = "wood"
	one.person.energy = 1
	one.go_rest()
	check(game.logistics.tickets.is_empty() and game.logistics.piles[0].stored.wood == 5, "Fatigue releases reservation and preserves picked cargo")
	check(a.reserved_by == null, "Interrupted job releases builder lock")
	# Temporary path blockage releases work and retries after reopening.
	fresh()
	stop_workers()
	worker = game.workers[0]
	var target_site = site("house")
	worker.find_job()
	check(worker.state == "to_pickup", "Worker claims a delivery")
	var blocked: Vector2i = game.world_cell(worker.path[-1])
	game.navigation.set_point_solid(blocked)
	tick(10)
	check(game.logistics.tickets.is_empty(), "Blocked route releases reservation")
	game.navigation.set_point_solid(blocked,false)
	worker.assign_to("builder",game.base)
	tick(100)
	check(target_site.completed, "Reopened path resumes construction")
	# Tools: break, replacement, no-tool efficiency, workshop automation.
	fresh()
	worker = game.workers[2]
	worker.person.tool = "axe"
	worker.person.durability = 1
	game.base.stored.axe = 1
	tick(20)
	check(worker.person.tool == "axe" and worker.person.durability > 1 and game.stock.axe == 0, "Broken tool automatically replaced from physical stock")
	check(worker.person.experience.get("wood",0) > 0, "Work awards profession XP")
	worker.person.tool = ""
	worker.person.durability = 0
	game.base.stored.axe = 0
	var xp: float = worker.person.experience.get("wood",0)
	tick(15)
	check(worker.person.experience.get("wood",0) > xp, "No tool still allows harvesting")
	fresh()
	stop_workers()
	var workshop = site("workshop")
	check(workshop != null, "Workshop fits initial island")
	if workshop != null:
		game.workers[0].assign_to("builder",game.base)
		tick(120)
		check(workshop.completed, "Workshop receives materials and completes")
		workshop.level = 2
		game.workers[1].assign_to("workshop",workshop)
		game.base.stored.axe = 0
		game.base.stored.pickaxe = 0
		game.base.store("wood",25)
		game.base.store("stone",25)
		tick(200)
		check(game.stock.axe >= 5 and game.stock.pickaxe >= 5, "Workshop maintains both tool goals with delivered inputs")
		var axes: int = game.stock.axe
		tick(30)
		check(game.stock.axe == axes, "Workshop stops at stock target")
	# Carrier unlock, independent producer logistics and physical expansion.
	fresh()
	game.base.stored = {"produce":30,"stone":40,"wood":30,"axe":2,"pickaxe":2}
	check(game.upgrade_village() and game.village_level == 2 and game.population_limit() == 3, "Evolution unlocks capacity of cargo, not magic housing")
	check(game.workplace_for("carrier") == game.base and game.carry_capacity() == 7, "Specialized carrier unlocks at level 2")
	game.workers[0].assign_to("carrier",game.base)
	tick(35)
	check(game.workers[0].person.experience.get("carrier",0) > 0, "Carrier automatically collects producer output")
	game.workers[0].assign_to("builder",game.base)
	game.base.store("stone",20)
	game.base.store("wood",10)
	var expansion = game.place_job("expand",Vector2i(71,27))
	check(expansion != null, "Coastal expansion preserved")
	# Routes and carried loads vary with the tree footprint; allow a bounded full trip.
	for second in range(90):
		if expansion.completed: break
		tick(1)
	check(expansion.completed and game.is_walkable(Vector2i(73,29)), "Expansion supplied physically and becomes walkable")
	var plant = game.place_job("plant",Vector2i(43,24))
	check(plant != null, "Planting remains available")
	for second in range(90):
		if plant.completed: break
		tick(1)
	check(plant.completed and game.planted_count == 1, "Planter uses delivered produces and plants tree")
	# Reservations for the last warehouse slot and delivery cancellation.
	fresh()
	stop_workers()
	game.stock = {"stone":119}
	game.logistics.drop(Vector2i(60,33),"wood",5)
	var first: Dictionary = game.logistics.claim(game.workers[0])
	var second: Dictionary = game.logistics.claim(game.workers[1])
	check(first.get("amount",0) == 1 and second.is_empty(), "Incoming reservations cannot overbook the last storage slot")
	game.logistics.release(game.workers[0])
	check(game.logistics.available(game.logistics.piles[0],"wood") == 5, "Cancelled pickup restores availability without duplicating units")
	# Loose resources and job entrances cannot be covered by new footprints.
	fresh()
	game.logistics.drop(Vector2i(43,24),"wood",3)
	check(not game.can_place("house",Vector2i(42,23)), "Construction cannot bury waiting cargo")
	check(not game.can_place_job("plant",Vector2i(43,24)), "Planting cannot bury waiting cargo")
	# Housing/food are revalidated when the ship arrives, not only when ordered.
	fresh()
	stop_workers()
	var dwelling = game.add_building("house",Vector2i(42,23),true)
	game.rebuild_navigation()
	check(game.immigration.prepare_expedition(), "Expedition starts with affordable safe reserves")
	tick(36)
	check(game.immigration.sailing, "Expedition enters voyage state")
	dwelling.completed = false
	tick(20)
	check(game.workers.size() == 3 and game.immigration.sailing, "Ship waits if housing capacity becomes unavailable")
	dwelling.completed = true
	game.stock = {"produce":0}
	tick(2)
	check(game.workers.size() == 3, "Ship waits if food economy fails")
	game.base.store("produce",20)
	tick(1)
	check(game.workers.size() == 4 and not game.immigration.sailing, "Ship disembarks exactly once after conditions recover")
	# Fatigue cannot keep a building job locked while home is inaccessible.
	fresh()
	var tired = game.workers[0]
	tired.person.energy = 1
	game.navigation.set_point_solid(game.base.door())
	tick(1)
	check(tired.state == "idle" and tired.status.contains("bloqueado"), "Blocked home pauses exhausted worker with feedback")
	game.navigation.set_point_solid(game.base.door(),false)
	tick(10)
	check(tired.state == "resting", "Exhausted worker retries the route to its own residence")
	# Shared workshop goals include batches already in production.
	fresh()
	var shop1 = game.add_building("workshop",Vector2i(58,23),true)
	var shop2 = game.add_building("workshop",Vector2i(42,23),true)
	game.base.stored.axe = 4
	for shop in [shop1,shop2]:
		shop.level = 2
		shop.stored.wood = 2
		shop.stored.stone = 1
		shop.tool_targets.pickaxe = 0
	shop1.craft(1)
	shop2.craft(1)
	check(shop1.crafting == "axe" and shop2.crafting == "", "Parallel workshops do not overproduce the same remaining goal")
	# Survival clock gives the player several minutes to recover; meals scale by person.
	fresh()
	stop_workers()
	var food_before: int = game.stock.produce
	for inhabitant in game.workers: inhabitant.person.nutrition = 74
	tick(0.1)
	check(game.stock.produce == food_before - 3, "Food consumption scales with population and consumes specific foods")
	game.stock = {}
	tick(300)
	check(game.workers.size() == 3 and game.workers[0].person.nutrition > game.DATA.HUNGER_SLOW, "Shortage has a forgiving initial buffer")
	tick(170)
	check(game.workers[0].needs.productivity(game.workers[0]) < 1 and game.workers.size() == 3, "Longer shortage reduces productivity before death")
	tick(300)
	check(game.settlement.extinct, "Sustained shortage can extinguish the entire civilization naturally")
	# Food thresholds, succession and extinction; no recruitment after extinction.
	fresh()
	stop_workers()
	game.stock = {}
	worker = game.workers[0]
	worker.person.nutrition = 35
	check(worker.needs.productivity(worker) < 1, "Hunger progressively reduces productivity")
	worker.person.nutrition = 10
	tick(1)
	check(worker.status.contains("fraco"), "Severe hunger stops work")
	worker.person.nutrition = 0
	worker.person.starvation = game.DATA.STARVATION_SECONDS - 0.05
	tick(0.1)
	check(game.workers.size() == 2 and game.workers[0].person.is_king and not game.settlement.extinct, "King death selects successor, no game over")
	for remaining in game.workers:
		remaining.person.nutrition = 0
		remaining.person.starvation = game.DATA.STARVATION_SECONDS - 0.05
	tick(0.1)
	game.hud.refresh()
	check(game.workers.is_empty() and game.settlement.extinct and game.simulation_paused, "Population zero triggers extinction")
	check(game.hud.extinction_panel.visible and not game.immigration.prepare_expedition(), "Game over UI and no resurrection via immigration")
	finish()
func finish() -> void:
	print("V0.0.3: ",checks," checks; ",failures.size()," failures")
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)




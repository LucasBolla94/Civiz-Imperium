extends "res://Tests/test_v003.gd"

func run() -> void:
	root.size = Vector2i(1280,800)
	# Two gatherers choose distinct productive sites rather than racing to one tree.
	fresh()
	stop_workers()
	game.spawn_tree(Vector2i(43,24),4)
	game.rebuild_navigation()
	var a = game.workers[0]
	var b = game.workers[1]
	for worker in [a,b]:
		worker.assign_to("food",game.base)
		worker.find_job()
	check(a.state == "to_source" and b.state == "to_source" and a.target != b.target, "Gatherers distribute themselves across available trees")
	var chosen = a.target
	var end: Vector2 = a.path[-1]
	tick(0.2)
	check(a.target == chosen and a.path[-1] == end, "Worker keeps its chosen job while travelling")
	tick(35)
	check(a.person.experience.get("food",0) > 0 and b.person.experience.get("food",0) > 0, "Both reserved workplaces produce real resources")
	# Last available fruit cannot lure multiple residents to an empty tree.
	fresh()
	stop_workers()
	game.sources[1].remaining = 1
	a = game.workers[0]
	b = game.workers[1]
	for worker in [a,b]:
		worker.assign_to("food",game.base)
		worker.find_job()
	check(a.state == "to_source" and b.state == "idle" and b.path.is_empty(), "Second worker waits instead of chasing the last reserved fruit")
	a.interrupt_task()
	b.find_job()
	check(b.state == "to_source", "An interrupted collection frees the work site immediately")
	game.sources[1].set_stage(5)
	b._process(0.1)
	check(b.path.is_empty() and not game.work_planner.claims.has(b), "Expired fruit source is abandoned before walking the rest of the journey")
	# A mine permits two people, but not on the same tile or the same last units.
	fresh()
	stop_workers()
	game.sources[0].remaining = 6
	a = game.workers[0]
	b = game.workers[1]
	for worker in [a,b]:
		worker.assign_to("stone",game.base)
		worker.person.tool = "pickaxe"
		worker.person.durability = 45
		worker.find_job()
	check(a.state == "to_source" and b.state == "to_source" and a.path[-1] != b.path[-1], "Miners use separate adjacent working positions")
	check(game.work_planner.reserved(game.sources[0]) == 6, "Collection reservations do not exceed the actual mineral stock")
	tick(35)
	check(game.stock.stone == 51, "Concurrent mining conserves the six available stones")
	# Later-created stock near the job beats the original faraway base.
	fresh()
	stop_workers()
	var store = game.add_building("warehouse",Vector2i(42,29),true)
	store.stored.wood = 10
	var house = game.add_building("house",Vector2i(42,23))
	house.materials.required = {"wood":5}
	game.rebuild_navigation()
	a = game.workers[0]
	a.position = game.cell_center(Vector2i(44,32))
	var delivery: Dictionary = game.logistics.claim(a)
	check(delivery.source == store and delivery.amount == 5, "Delivery chooses the shorter complete journey, not creation order")
	game.logistics.release(a)
	store.stored.axe = 1
	a.assign_to("wood",game.base)
	a.find_tool()
	check(a.ticket.source == store, "Replacement tool comes from the nearest reachable stock")
	# Producers reserve destination space before walking with their cargo.
	fresh()
	stop_workers()
	game.stock = {"stone":118}
	a = game.workers[0]
	b = game.workers[1]
	for worker in [a,b]:
		worker.cargo = 2
		worker.cargo_resource = "wood"
		worker.return_home()
	check(a.state == "to_home" and b.state == "idle", "Only the worker with reserved storage space starts the delivery")
	check(game.logistics.incoming(game.base) == 2 and game.logistics.piles[0].stored.wood == 2, "Overflow cargo waits safely at origin instead of travelling to a full store")
	tick(15)
	check(game.stock.wood == 2 and game.base.used() == 120, "Reserved producer delivery respects storage capacity")
	# Assignment changes respect a loaded delivery already underway.
	fresh()
	stop_workers()
	a = game.workers[0]
	a.position = game.cell_center(Vector2i(61,33))
	a.cargo = 5
	a.cargo_resource = "wood"
	a.return_home()
	var ticket_id: int = a.ticket.id
	a.assign_to("stone",game.base)
	check(a.state == "to_home" and a.cargo == 5 and a.ticket.id == ticket_id, "Reassignment preserves current loaded delivery")
	tick(25)
	check(a.kind == "stone" and game.stock.wood == 25 and game.logistics.piles.is_empty(), "Worker delivers first, then changes profession without dropping cargo")
	# Changed terrain recalculates the same task instead of cancelling it.
	fresh()
	stop_workers()
	a = game.workers[0]
	a.position = game.cell_center(Vector2i(61,35))
	a.cargo = 5
	a.cargo_resource = "wood"
	a.return_home()
	ticket_id = a.ticket.id
	a.path.remove_at(0)
	var obstruction: Vector2i = game.world_cell(a.path[0])
	game.navigation.set_point_solid(obstruction)
	a._process(0.1)
	check(a.state == "to_home" and a.ticket.id == ticket_id and a.cargo == 5, "A detour keeps task, load and reservation intact")
	check(not a.path.is_empty() and not a.path.has(game.cell_center(obstruction)), "Replacement route avoids the new obstruction")
	tick(25)
	check(game.stock.wood == 25 and game.logistics.piles.is_empty(), "Detoured delivery completes without abandoning cargo")
	# Replanning halfway down a straight segment does not step backwards.
	var from: Vector2 = game.cell_center(Vector2i(61,35)) + Vector2(5,0)
	var route: PackedVector2Array = game.route_to_cell(from,Vector2i(64,35))
	check(not route.is_empty() and route[0].x >= from.x, "Path recalculation does not backtrack to the previous cell centre")
	# A short delivery may finish before routine rest, but not at exhaustion.
	fresh()
	stop_workers()
	a = game.workers[0]
	a.position = game.cell_center(game.base.door() + Vector2i.RIGHT)
	a.cargo = 2
	a.cargo_resource = "wood"
	a.person.energy = 19
	a.return_home()
	a._process(0.1)
	check(a.state == "to_home" and a.cargo == 2, "Tired resident finishes a nearby delivery before going home")
	tick(4)
	check(game.stock.wood == 22 and a.state == "resting", "Delivery completes and resident then rests at its own home")
	# Craftsmen stay with their own bench and production, not random errands.
	fresh()
	stop_workers()
	var shop = game.add_building("workshop",Vector2i(58,23),true)
	shop.level = 2
	shop.stored.wood = 6
	shop.stored.stone = 6
	game.base.stored.axe = 0
	game.base.stored.pickaxe = 0
	house = game.add_building("house",Vector2i(42,23))
	game.rebuild_navigation()
	a = game.workers[0]
	b = game.workers[1]
	for worker in [a,b]:
		worker.assign_to("workshop",shop)
		worker.find_job()
	check(a.state == "to_craft" and shop.craft_reserved_by == a, "Artisan chooses available production before unrelated construction logistics")
	check(b.state == "idle" and b.path.is_empty(), "Second artisan does not walk to an occupied bench")
	a.interrupt_task()
	b.find_job()
	check(b.state == "to_craft" and shop.craft_reserved_by == b, "Interrupted artisan frees the bench for another resident")
	# Workshops never steal inputs from one another in a transport loop.
	fresh()
	stop_workers()
	var shop1 = game.add_building("workshop",Vector2i(58,23),true)
	var shop2 = game.add_building("workshop",Vector2i(42,23),true)
	game.rebuild_navigation()
	game.base.stored.wood = 0
	for building in [shop1,shop2]:
		building.level = 2
		building.stored.stone = 2
		building.tool_targets.pickaxe = 0
	shop2.stored.wood = 10
	check(game.logistics.claim(game.workers[0],shop1).is_empty(), "Workshop buffer cannot become another workshop's supply source")
	shop1.tool_targets.axe = 0
	a = game.workers[0]
	a.assign_to("workshop",shop1)
	var before: Vector2 = a.position
	tick(8)
	check(a.position == before and a.state == "idle", "Artisan with no demand stays still rather than making empty round trips")
	# Urgent nutrition beats discretionary planting or carrying building supplies.
	fresh()
	stop_workers()
	game.base.stored.fruit = 2
	var planting = game.place_job("plant",Vector2i(43,24))
	a = game.workers[0]
	a.assign_to("food",game.base)
	a.find_job()
	check(planting != null and a.state == "to_source", "Collector replenishes critically low food before discretionary planting")
	a.interrupt_task()
	game.logistics.drop(Vector2i(61,33),"fruit",5)
	house = game.add_building("house",Vector2i(43,29))
	game.rebuild_navigation()
	var urgent: Dictionary = game.logistics.claim(a)
	check(urgent.resource == "fruit" and not urgent.material, "Transport rescues waiting food before nonessential construction supplies")
	# No phantom labour when a completed batch has no room for its output.
	fresh()
	shop = game.add_building("workshop",Vector2i(58,23),true)
	shop.crafting = "axe"
	shop.craft_progress = game.DATA.CRAFT_SECONDS
	shop.stored.wood = shop.capacity()
	check(not shop.craft(5) and shop.craft_progress == game.DATA.CRAFT_SECONDS, "Full workshop pauses completed batch instead of working forever")
	shop.stored.wood -= 1
	check(shop.craft(0.1) and shop.stored.axe == 1, "Waiting batch is released once output space becomes available")
	finish()

func finish() -> void:
	print("Worker AI: ",checks," checks; ",failures.size()," failures")
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)




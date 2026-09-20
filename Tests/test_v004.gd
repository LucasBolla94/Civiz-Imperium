extends "res://Tests/test_v003.gd"
func run() -> void:
	root.size = Vector2i(1280,720)
	fresh()
	stop_workers()
	var shop = game.add_building("workshop",Vector2i(58,23),true)
	shop.stored.wood = 20
	shop.stored.stone = 20
	game.base.stored.axe = 0
	game.base.stored.pickaxe = 0
	check(not shop.can_craft() and shop.input_demand("wood") == 0, "Level one does not produce unsolicited tools")
	shop.order_tool("axe",2)
	shop.craft(8)
	shop.craft(8)
	check(shop.stored.axe == 2 and shop.tool_orders.axe == 0 and not shop.can_craft(), "Manual batch finishes exactly two axes")
	check(shop.stored.wood == 16 and shop.stored.stone == 18, "Craft consumes real recipe materials")
	shop.order_tool("pickaxe",2)
	shop.order_tool("pickaxe",-1)
	check(shop.tool_orders.pickaxe == 1, "Unstarted order can be cancelled")
	shop.craft(8)
	check(shop.upgrade(), "Workshop supports individual upgrade")
	shop.build(100)
	check(shop.level == 1, "Upgrade waits for physical materials")
	shop.materials.delivered = shop.materials.required.duplicate()
	shop.build(100)
	var other = game.add_building("workshop",Vector2i(42,23),true)
	check(shop.level == 2 and other.level == 1, "Upgrade is local to its workshop")
	shop.tool_targets = {"axe":3,"pickaxe":1}
	shop.craft(8)
	check(shop.stored.axe == 3 and not shop.can_craft(), "Level two replenishes only missing global reserve")
	shop.level = 3
	check(shop.desired_tools("axe") == 0, "No unnecessary adaptive reserve for absent profession")
	game.workers[1].assign_to("wood",game.base)
	check(shop.desired_tools("axe") == 1, "Adaptive reserve responds to assigned inhabitants")
	# A resident must physically fetch the new tool.
	game.rebuild_navigation()
	var worker = game.workers[1]
	worker.person.tool = ""
	worker.person.durability = 0
	worker.spare_tools.clear()
	tick(20)
	check(worker.person.tool == "axe" and worker.person.durability > 0, "Resident fetches a workshop tool and uses it")
	fresh()
	stop_workers()
	var cell := Vector2i.ZERO
	check(not game.can_place_job("survey",Vector2i(58,35)), "Survey locked before stone upgrade")
	var depot = game.add_building("stone",Vector2i(42,23),true)
	depot.level = 2
	game.rebuild_navigation()
	for candidate in game.land.get_used_cells():
		if game.can_place_job("survey",candidate): cell = candidate; break
	check(cell != Vector2i.ZERO, "Valid survey area exists on island")
	var job = game.place_job("survey",cell)
	if job == null: finish(); return
	check(not game.can_place_job("survey",cell), "Survey reserves its area against duplicates")
	worker = game.workers[1]
	worker.assign_to("stone",depot)
	tick(45)
	check(job.completed and job.kind == "survey" and job.deposit > 0, "Miner travels and completes investigation")
	check(game.entity_at(cell) == job and job.reserves_ground(), "Completed report stays selectable and reserved")
	check(job.open_quarry(), "Player can open discovered deposit")
	var amount: int = game.stock.wood
	job.build(100)
	check(not job.completed and game.stock.wood == amount, "Quarry requires physical material delivery")
	game.workers[0].assign_to("builder",game.base)
	tick(100)
	var pits: Array = game.sources.filter(func(s): return s.is_quarry)
	check(job.completed and pits.size() == 1, "Workers supply and open quarry without direct inventory mutation")
	if pits.size() == 1:
		var quarry = pits[0]
		var reserve_before: int = quarry.remaining
		check(game.saves.save_file("res://Tests/v004_quarry.save") and game.saves.load_file("res://Tests/v004_quarry.save"), "Quarry world reloads with jobs and mineral reserve")
		quarry = game.sources.filter(func(s): return s.is_quarry)[0]
		job = game.jobs[0]
		check(quarry.remaining == reserve_before, "Quarry extraction is not reset by save/load")
		check(quarry.remaining < job.deposit, "Miner extracts stone after opening")
		check(not game.is_walkable(cell), "Open quarry footprint blocks crossing pit")
		quarry.take(quarry.remaining,"stone")
		check(quarry.removed and game.is_walkable(cell), "Exhausted quarry frees ground without infinite resources")
	# Targets account for carried and reserved loads, but construction can request more.
	fresh()
	stop_workers()
	game.automation.stock_targets.stone = 10
	game.base.stored.stone = 10
	var stone = game.sources.filter(func(s): return s.resource_kind == "stone")[0]
	check(game.automation.allowed_amount(stone,5) == 0, "Gathering pauses at stock goal")
	game.base.stored.stone = 8
	game.workers[0].cargo = 2
	game.workers[0].cargo_resource = "stone"
	check(game.automation.allowed_amount(stone,5) == 0, "Cargo counts toward stock goal")
	var building = game.add_building("house",Vector2i(42,23))
	check(game.automation.allowed_amount(stone,5) == 5, "Construction shortages override reserve goal")
	check(game.immigration.blocked_reason().contains("vaga"), "Housing availability explains why arrivals stop")
	# Renewal keeps the plot, but removing automation does not remove its tree.
	var tree = game.sources.filter(func(s): return s.is_tree)[0]
	game.automation.toggle_orchard(tree.origin)
	tree.set_stage(6)
	game.automation.stock_targets.wood = 1
	check(game.automation.allowed_amount(tree,5) == 5, "Orchard stump clearing bypasses wood cap")
	game.automation.toggle_orchard(tree.origin)
	check(not tree.removed and not game.automation.orchards.has(tree.origin), "Disabling renewal preserves tree")
	# Save an active delivery, a partial craft, pending upgrade and policies.
	shop = game.add_building("workshop",Vector2i(58,23),true)
	shop.order_tool("axe",2)
	shop.stored.wood = 4
	shop.stored.stone = 2
	shop.craft(3)
	game.automation.toggle_orchard(tree.origin)
	var before: Dictionary = game.saves.snapshot()
	var stock_before: Dictionary = game.stock.duplicate()
	check(game.saves.save_file("res://Tests/v004_test.save"), "Save writes complete versioned snapshot")
	game.base.stored.stone = 0
	check(game.saves.load_file("res://Tests/v004_test.save"), "Load succeeds")
	check(game.stock == stock_before and game.workers[0].cargo == 2, "Reload preserves stock and carried resources exactly once")
	shop = game.buildings.filter(func(b): return b.kind == "workshop")[0]
	check(shop.crafting == "axe" and shop.craft_progress == 3 and shop.tool_orders.axe == 1, "Reload preserves paid partial craft and remaining queue")
	check(game.automation.orchards.size() == 1 and game.automation.stock_targets.stone == 10, "Policies survive reload")
	var file := FileAccess.open("res://Tests/v004_bad.save",FileAccess.WRITE)
	file.store_var({"version":4,"payload":PackedByteArray([1,2]),"digest":"bad"})
	file.close()
	check(not game.saves.load_file("res://Tests/v004_bad.save") and game.workers.size() == 3, "Corrupt save preserves running village")
	# Urgent jobs win over closer normal jobs, including their material deliveries.
	fresh()
	stop_workers()
	var near = game.add_building("house",Vector2i(58,23))
	var urgent = game.add_building("house",Vector2i(42,23))
	urgent.priority = 2
	game.rebuild_navigation()
	worker = game.workers[0]
	worker.position = game.cell_center(near.door())
	var delivery: Dictionary = game.logistics.claim(worker)
	check(not delivery.is_empty() and delivery.destination == urgent, "Urgent site's materials win over a closer normal site")
	game.logistics.release(worker)
	for site in [near,urgent]: site.materials.delivered = site.materials.required.duplicate()
	worker.assign_to("builder",game.base)
	worker.find_job()
	check(worker.target == urgent, "Construction honors urgency before distance")
	# Automatic orchard renewal waits for safe food reserves and respects UI placement.
	fresh()
	stop_workers()
	tree = game.sources.filter(func(s): return s.is_tree)[0]
	var orchard_cell: Vector2i = tree.origin
	game.automation.toggle_orchard(orchard_cell)
	tree.set_stage(6)
	tree.take(tree.remaining,"wood")
	game.base.stored.produce = 1
	game.automation.tick(3)
	check(game.jobs.is_empty(), "Orchard will not consume the last food reserve")
	game.base.stored.produce = 30
	game.action_mode = "expand"
	game.automation.tick(3)
	check(game.jobs.size() == 1 and game.action_mode == "expand", "Renewal schedules once without cancelling player's active placement")
	game.automation.tick(3)
	check(game.jobs.size() == 1, "Repeated renewal checks do not duplicate a planting")
	game.workers[1].assign_to("food",game.base)
	tick(45)
	check(game.planted_count == 1 and game.sources.any(func(t): return t.is_tree and not t.removed and t.origin == orchard_cell), "Worker delivers seeds and replants permanent orchard")
	# A walkable but disconnected landing must trigger a different dock.
	fresh()
	game.add_building("house",Vector2i(42,23),true)
	game.base.stored.produce = 40
	game.rebuild_navigation()
	game.immigration.find_dock()
	var old_dock: Vector2i = game.immigration.dock
	for direction in game.CARDINALS:
		var neighbor: Vector2i = old_dock + direction
		if game.navigation.is_in_boundsv(neighbor): game.navigation.set_point_solid(neighbor)
	game.immigration.sailing = true
	game.immigration.voyage = game.DATA.VOYAGE_SECONDS
	game.immigration.tick(0.1)
	check(game.immigration.dock != old_dock, "Ship selects new accessible landing after route is cut")
	game.immigration.tick(0.1)
	check(game.workers.size() == 4, "Rerouted ship disembarks exactly one colonist")
	finish()

func finish() -> void:
	print("V0.0.4: %d checks; %d failures" % [checks, failures.size()])
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)

extends RefCounted
var game
var stock_targets := {"produce": 0, "wood": 0, "stone": 0}
var orchards: Array[Vector2i] = []
var timer := 0.0

func toggle_orchard(cell: Vector2i) -> void:
	if orchards.has(cell): orchards.erase(cell)
	else: orchards.append(cell)

func total_committed(resource: String) -> int:
	var amount: int = game.stock.get(resource, 0)
	for worker in game.workers:
		if worker.cargo_resource == resource: amount += worker.cargo
	for pile in game.logistics.piles: amount += pile.stored.get(resource, 0)
	for claim in game.work_planner.claims.values():
		if claim.source.resource_kind == resource: amount += claim.remaining
	return amount

func production_limit(resource: String) -> int:
	var target: int = stock_targets.get(resource, 0)
	if target == 0: return 2147483647
	if resource == "produce": target = maxi(target, (game.workers.size() + 1) * game.DATA.FOOD_RESERVE_PER_PERSON)
	var requests := 0
	for site in game.buildings + game.jobs + game.gardens:
		if site.needs_work(): requests += site.materials.missing(resource)
	for building in game.buildings:
		if building.kind == "workshop": requests += building.input_demand(resource)
	return target + requests

func allowed_amount(source, capacity: int) -> int:
	# Clear orchard stumps even when the wood goal is met, so produce renewal continues.
	if source.is_tree and source.stage == 6 and orchards.has(source.origin): return capacity
	return mini(capacity, maxi(0, production_limit(source.resource_kind) - total_committed(source.resource_kind)))

func tick(delta: float) -> void:
	timer -= delta
	if timer > 0: return
	timer = 2
	for cell in orchards:
		if game.sources.any(func(s): return not s.removed and s.origin == cell): continue
		if game.jobs.any(func(j): return j.reserves_ground() and j.origin == cell): continue
		if game.settlement.food_units() < game.workers.size() * game.DATA.FOOD_RESERVE_PER_PERSON + game.DATA.PLANT_COST.produce: continue
		if game.can_place_job("plant", cell): game.place_job("plant", cell, true)

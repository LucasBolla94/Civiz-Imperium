extends RefCounted
## Collection reservations include both a work position and an actual load.
## They do not remove resources until the resident performs the harvest.
var game
var claims: Dictionary = {}

func release(worker) -> void:
	claims.erase(worker)

func reserved(source) -> int:
	var amount := 0
	for worker in claims:
		if claims[worker].source == source: amount += claims[worker].remaining
	return amount

func available_claim(worker) -> bool:
	if not claims.has(worker): return false
	var claim: Dictionary = claims[worker]
	return is_instance_valid(claim.source) and claim.source.harvestable(worker.kind) and claim.remaining > 0

func claim_harvest(worker) -> Dictionary:
	release(worker)
	var best: Dictionary = {}
	var best_score := INF
	for source in game.sources:
		if not source.harvestable(worker.kind): continue
		var amount: int = mini(game.carry_capacity(), source.remaining - reserved(source))
		amount = game.automation.allowed_amount(source, amount)
		if amount <= 0: continue
		var occupied: Array[Vector2i] = []
		var assigned := 0
		for other in claims:
			occupied.append(claims[other].cell)
			if claims[other].source == source: assigned += 1
		var limit: int = game.DATA.TREE_WORK_SLOTS if source.is_tree else game.DATA.MINE_WORK_SLOTS
		if assigned >= limit: continue
		for spot in source.work_cells():
			if occupied.has(spot): continue
			var route: PackedVector2Array = game.route_to_cell(worker.position, spot)
			if route.is_empty(): continue
			var score := route_length(worker.position, route)
			if source == worker.preferred_source: score *= game.DATA.FAMILIAR_SOURCE_FACTOR
			if score >= best_score: continue
			best_score = score
			best = {"source": source, "cell": spot, "remaining": amount, "route": route}
	if not best.is_empty(): claims[worker] = best
	return best

func collect(worker) -> int:
	if not available_claim(worker): return 0
	var claim: Dictionary = claims[worker]
	if game.world_cell(worker.position) != claim.cell: return 0
	var amount: int = claim.source.take(1, worker.kind)
	claim.remaining -= amount
	return amount

static func route_length(from: Vector2, route: PackedVector2Array) -> float:
	var total := 0.0
	for point in route:
		total += from.distance_to(point)
		from = point
	return total


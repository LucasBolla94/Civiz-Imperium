extends RefCounted
## Tickets reserve units and destination space; only pickup/delivery move inventory.
const PILE = preload("res://Scripts/resource_pile.gd")
var game
var tickets: Array = []
var piles: Array = []
var next_id := 1

func reserved(source, resource: String) -> int:
	var total := 0
	for ticket in tickets:
		if ticket.source == source and ticket.resource == resource and not ticket.picked: total += ticket.amount
	return total

func incoming(destination, resource := "") -> int:
	var total := 0
	for ticket in tickets:
		if ticket.destination == destination and (resource == "" or ticket.resource == resource): total += ticket.amount
	return total

func available(source, resource: String) -> int:
	return maxi(0, int(source.stored.get(resource, 0)) - reserved(source, resource))

func storage_free(building) -> int:
	return maxi(0, building.capacity() - building.used() - incoming(building))

func drop(cell: Vector2i, resource: String, amount: int) -> void:
	if amount <= 0: return
	for pile in piles:
		if pile.cell == cell and pile.resource_kind == resource:
			pile.stored[resource] += amount
			return
	var pile = PILE.new()
	pile.cell = cell
	pile.position = game.cell_center(cell)
	pile.resource_kind = resource
	pile.stored[resource] = amount
	game.entities.add_child(pile)
	piles.append(pile)

func cleanup() -> void:
	for pile in piles.duplicate():
		if int(pile.stored.get(pile.resource_kind, 0)) == 0 and reserved(pile, pile.resource_kind) == 0:
			piles.erase(pile)
			if game.selection == pile: game.select_entity(null)
			pile.queue_free()

func storage_for(from: Vector2, resource: String):
	var best = null
	var shortest := 2147483647
	for building in game.buildings:
		if not building.accepts(resource) or storage_free(building) <= 0: continue
		var route: PackedVector2Array = game.route_to_cell(from, building.door())
		if not route.is_empty() and route.size() < shortest:
			best = building
			shortest = route.size()
	return best

func claim(worker, only_destination = null) -> Dictionary:
	# Explicit priority tiers; inside each tier choose a useful load with the
	# shortest complete journey, rather than whichever object was created first.
	var requests: Array = []
	if only_destination != null:
		if only_destination.has_method("input_demand") and only_destination.kind == "workshop":
			append_workshop_requests(requests, only_destination)
		elif only_destination.needs_work():
			append_material_requests(requests, only_destination)
		return choose_request(worker, requests)
	if game.settlement.food_units() < game.workers.size() * game.DATA.FOOD_RESERVE_PER_PERSON:
		var urgent := claim_piles(worker, true)
		if not urgent.is_empty(): return urgent
	for destination in game.buildings + game.jobs + game.gardens:
		if destination.needs_work(): append_material_requests(requests, destination)
	var result := choose_request(worker, requests)
	if not result.is_empty(): return result
	requests.clear()
	for destination in game.buildings:
		if destination.completed and destination.kind == "workshop": append_workshop_requests(requests, destination)
	result = choose_request(worker, requests)
	if not result.is_empty(): return result
	return claim_piles(worker)

func claim_piles(worker, only_food := false) -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	for pile in piles:
		var resource: String = pile.resource_kind
		if only_food and not game.DATA.RESOURCES[resource].has("nutrition"): continue
		var amount := available(pile, resource)
		if amount <= 0: continue
		for destination in game.buildings:
			if not destination.accepts(resource): continue
			var candidate := proposal(worker, pile, destination, resource, mini(amount, storage_free(destination)), false)
			if not candidate.is_empty() and candidate.score < best_score:
				best = candidate
				best_score = candidate.score
	return commit_proposal(worker, best)

func append_material_requests(requests: Array, destination) -> void:
	for resource in destination.materials.required:
		var demand: int = destination.materials.missing(resource) - incoming(destination, resource)
		if demand > 0: requests.append({"destination": destination, "resource": resource, "amount": demand, "material": true})

func append_workshop_requests(requests: Array, destination) -> void:
	for resource in ["wood", "stone"]:
		var demand: int = destination.input_demand(resource) - incoming(destination, resource)
		if demand > 0: requests.append({"destination": destination, "resource": resource, "amount": demand, "material": false})

func choose_request(worker, requests: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_score := INF
	var best_priority := -1
	for request in requests:
		for source in piles + game.buildings:
			if source == request.destination: continue
			# Workshop ingredients are a production buffer, not an export warehouse.
			# Otherwise two workshops continuously take each other's inputs.
			if source.has_method("craft") and source.kind == "workshop" and request.resource in ["wood", "stone"]: continue
			var amount: int = mini(request.amount, available(source, request.resource))
			if not request.material: amount = mini(amount, storage_free(request.destination))
			var candidate := proposal(worker, source, request.destination, request.resource, amount, request.material)
			if not candidate.is_empty() and (request.destination.priority > best_priority or (request.destination.priority == best_priority and candidate.score < best_score)):
				best_priority = request.destination.priority
				best = candidate
				best_score = candidate.score
	return commit_proposal(worker, best)

func proposal(worker, source, destination, resource: String, amount: int, material: bool) -> Dictionary:
	amount = mini(amount, game.carry_capacity())
	if amount <= 0: return {}
	var pickup_route: PackedVector2Array = game.route_to_cell(worker.position, source.door())
	var delivery_route: PackedVector2Array = game.route_to_cell(game.cell_center(source.door()), destination.door())
	if pickup_route.is_empty() or delivery_route.is_empty(): return {}
	var distance: float = game.work_planner.route_length(worker.position, pickup_route) + game.work_planner.route_length(game.cell_center(source.door()), delivery_route)
	return {"source": source, "destination": destination, "resource": resource, "amount": amount, "material": material, "score": (distance + 16.0) / amount}

func commit_proposal(worker, candidate: Dictionary) -> Dictionary:
	if candidate.is_empty(): return {}
	return reserve(worker, candidate.source, candidate.destination, candidate.resource, candidate.amount, candidate.material)

func reserve_cargo(worker, destination) -> Dictionary:
	var amount: int = mini(worker.cargo, storage_free(destination))
	if amount <= 0: return {}
	var ticket := {"id": next_id, "worker": worker, "source": worker, "destination": destination, "resource": worker.cargo_resource, "amount": amount, "picked": true, "material": false}
	next_id += 1
	tickets.append(ticket)
	return ticket
func reserve(worker, source, destination, resource: String, amount: int, material: bool) -> Dictionary:
	amount = mini(amount, game.carry_capacity())
	if amount <= 0: return {}
	var route: PackedVector2Array = game.route_to_cell(worker.position, source.door())
	if route.is_empty() or game.route_to_cell(game.cell_center(source.door()), destination.door()).is_empty(): return {}
	var ticket := {"id": next_id, "worker": worker, "source": source, "destination": destination, "resource": resource, "amount": amount, "picked": false, "material": material}
	next_id += 1
	tickets.append(ticket)
	return ticket

func pickup(ticket: Dictionary) -> int:
	if not tickets.has(ticket) or ticket.picked or not is_instance_valid(ticket.source): return 0
	var amount: int = mini(ticket.amount, ticket.source.stored.get(ticket.resource, 0))
	ticket.source.stored[ticket.resource] -= amount
	ticket.amount = amount
	ticket.picked = true
	return amount

func deliver(ticket: Dictionary, amount: int) -> int:
	if not tickets.has(ticket) or not ticket.picked or not is_instance_valid(ticket.destination): return 0
	var accepted := 0
	if ticket.material:
		accepted = ticket.destination.materials.receive(ticket.resource, amount)
	else:
		accepted = ticket.destination.store(ticket.resource, amount)
	return accepted

func release(worker) -> void:
	for ticket in tickets.duplicate():
		if ticket.worker == worker: tickets.erase(ticket)
	cleanup()



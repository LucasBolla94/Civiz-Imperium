extends RefCounted
const RESIDENT = preload("res://Scripts/resident.gd")
const NAMES = ["João", "Clara", "Bento", "Lia", "Tomás", "Rosa", "Duarte", "Inês", "Martim", "Eva", "Afonso", "Leonor"]
var game
var next_id := 1
## Replaceable policy: future family rules can offer a player-selected eligible adult.
var succession_policy: Callable
var extinct := false

func register(worker) -> void:
	worker.person = RESIDENT.new()
	worker.person.id = next_id
	worker.person.appearance_id = (next_id - 1) % 3
	worker.refresh_appearance()
	worker.person.display_name = NAMES[(next_id - 1) % NAMES.size()] + (" %d" % next_id if next_id > NAMES.size() else "")
	next_id += 1
	worker.person.profession = worker.assignment
	assign_residence(worker)

func assign_residence(worker) -> bool:
	if is_instance_valid(worker.residence): return true
	for building in game.buildings:
		if building.completed and not building.demolition_requested and building.housing_capacity() > reserved_residents(building):
			worker.residence = building
			worker.person.residence_id = building.entity_id
			return true
	return false

func residents(building) -> Array:
	return game.workers.filter(func(w): return w.residence == building)

func population_limit() -> int:
	var amount := 0
	for building in game.buildings:
		if building.completed:
			amount += residents(building).size() if building.demolition_requested else building.housing_capacity()
	for worker in game.workers:
		if is_instance_valid(worker.move_destination): amount -= 1
	return amount

func reserved_residents(building) -> int:
	return residents(building).size() + game.workers.filter(func(w): return w.move_destination == building and w.residence != building).size()

func cancel_moves(building) -> void:
	for worker in residents(building):
		if is_instance_valid(worker.move_destination):
			worker.move_destination = null
			worker.interrupt_task()
			worker.apply_assignment()

func tick_moves() -> void:
	for building in game.buildings:
		if not building.demolition_requested: continue
		var occupants := residents(building)
		# Revalidate targets; no slot is usable twice by moves or immigration.
		for worker in occupants:
			var destination = worker.move_destination
			if is_instance_valid(destination) and (destination.demolition_requested or not destination.completed or game.route_to_cell(worker.position, destination.door()).is_empty()):
				worker.move_destination = null
				worker.interrupt_task()
		var waiting := occupants.filter(func(w): return not is_instance_valid(w.move_destination))
		var proposals := {}
		for worker in waiting:
			for destination in game.buildings:
				if destination == building or not destination.completed or destination.demolition_requested: continue
				var booked: int = proposals.values().count(destination)
				if destination.housing_capacity() <= reserved_residents(destination) + booked: continue
				if game.route_to_cell(worker.position, destination.door()).is_empty(): continue
				proposals[worker] = destination
				break
		if proposals.size() != waiting.size(): continue
		for worker in proposals:
			if worker.state == "resting": worker.wake(false)
			worker.interrupt_task()
			worker.move_destination = proposals[worker]
			worker.state = "moving_home"

func food_units() -> int:
	var count := 0
	for resource in game.DATA.RESOURCES:
		if game.DATA.RESOURCES[resource].has("nutrition"): count += game.stock.get(resource, 0)
	return count

func healthy_for_arrival() -> bool:
	if extinct or game.workers.is_empty() or game.workers.size() >= population_limit(): return false
	if food_units() < (game.workers.size() + 1) * game.DATA.FOOD_RESERVE_PER_PERSON: return false
	return game.workers.all(func(w): return w.person.nutrition > game.DATA.HUNGER_SLOW)

func feed(worker) -> void:
	for resource in game.DATA.RESOURCES:
		var definition: Dictionary = game.DATA.RESOURCES[resource]
		if definition.has("nutrition") and game.pay({resource: 1}):
			worker.person.nutrition = minf(100, worker.person.nutrition + definition.nutrition)
			return

func remove(worker) -> void:
	if not game.workers.has(worker): return
	var was_king: bool = worker.person.is_king
	worker.interrupt_task()
	game.workers.erase(worker)
	if game.selection == worker: game.select_entity(null)
	worker.queue_free()
	if game.workers.is_empty():
		extinct = true
		game.simulation_paused = true
		game.notify("Civilização extinta — nenhum habitante sobreviveu.")
		return
	game.notify("%s morreu de fome." % worker.person.display_name)
	if was_king: choose_successor()

func choose_successor() -> void:
	var eligible: Array = game.workers.filter(func(w): return w.person.is_adult)
	if eligible.is_empty(): return
	var successor = succession_policy.call(eligible) if succession_policy.is_valid() else eligible[0]
	if not eligible.has(successor): successor = eligible[0]
	for worker in game.workers:
		worker.person.is_king = worker == successor
		worker.refresh_appearance()
		worker.queue_redraw()
	game.notify("%s assume a coroa. A civilização continua." % successor.person.display_name)


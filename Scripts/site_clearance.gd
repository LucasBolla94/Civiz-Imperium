extends RefCounted
## Construction reserves its footprint immediately, but closes navigation only
## after physical evacuation and relocation have finished.
const NONE = Vector2i(-999,-999)
const PILE = preload("res://Scripts/resource_pile.gd")
var game

func sites() -> Array:
	return game.buildings + game.gardens

func prepare(site) -> void:
	site.preparing_site = obstructed(site)
	if not site.preparing_site: return
	var cells := area(site)
	for ticket in game.logistics.tickets.duplicate():
		if not ticket.picked and ticket.source is PILE and cells.has(ticket.source.cell):
			ticket.worker.interrupt_task(true)
	site.refresh_visual()

func description(site) -> String:
	if game.workers.any(func(w): return w.clear_site_id == site.entity_id): return "Liberando terreno: transportando materiais para um local livre."
	if game.logistics.piles.any(func(p): return area(site).has(p.cell) and p.stored.get(p.resource_kind,0) > 0):
		if not game.workers.any(func(w): return w.assignment in ["builder","carrier","idle"]): return "Limpeza aguardando construtor, transportador ou habitante livre."
		return "Liberando terreno: aguardando retirada dos materiais e espaço livre."
	return "Liberando terreno: aguardando os habitantes saírem."

func area(site) -> Array[Vector2i]:
	var cells: Array[Vector2i] = site.footprint()
	cells.append(site.door())
	return cells

func site_at(cell: Vector2i):
	for site in sites():
		if site.preparing_site and area(site).has(cell): return site
	return null

func reserved(cell: Vector2i) -> bool:
	if site_at(cell) != null: return true
	return game.workers.any(func(w): return w.clear_destination == cell)

func obstructed(site) -> bool:
	var cells := area(site)
	return game.logistics.piles.any(func(p): return cells.has(p.cell) and p.stored.get(p.resource_kind,0) > 0) or game.workers.any(func(w): return (w.visible and cells.has(game.world_cell(w.position))) or w.clear_site_id == site.entity_id)

func tick() -> void:
	var changed := false
	for site in sites():
		if site.preparing_site and not obstructed(site):
			site.preparing_site = false
			site.refresh_visual()
			changed = true
	if changed: game.rebuild_navigation()

func free_cell(cell: Vector2i, worker = null) -> bool:
	if not game.is_walkable(cell) or site_at(cell) != null: return false
	if game.buildings.any(func(b): return b.door() == cell): return false
	if game.jobs.any(func(j): return j.reserves_ground() and (j.cells.has(cell) or j.door() == cell)): return false
	if (game.sources+game.gardens).any(func(s): return not s.removed and s.cells.has(cell)): return false
	if game.logistics.piles.any(func(p): return p.cell == cell and p.stored.get(p.resource_kind,0) > 0): return false
	return not game.workers.any(func(w): return w != worker and (game.world_cell(w.position) == cell or w.clear_destination == cell or w.evacuation_destination == cell))

func destination(from: Vector2, worker = null) -> Vector2i:
	var origin: Vector2i = game.world_cell(from)
	var cells: Array[Vector2i] = game.land.get_used_cells()
	cells.sort_custom(func(a,b): return a.distance_squared_to(origin) < b.distance_squared_to(origin))
	var candidates: Array[Vector2i] = []
	# Choose randomly among nearby free reachable positions, never across the sea.
	for cell in cells:
		if cell == origin or not free_cell(cell,worker): continue
		if game.route_to_cell(from,cell).is_empty(): continue
		candidates.append(cell)
		if candidates.size() >= 8: break
	return NONE if candidates.is_empty() else candidates.pick_random()

func claim(worker) -> bool:
	if worker.kind not in ["builder","carrier","idle"] or worker.cargo > 0: return false
	for site in sites():
		if not site.preparing_site: continue
		var cells := area(site)
		for pile in game.logistics.piles:
			if not cells.has(pile.cell) or game.logistics.available(pile,pile.resource_kind) <= 0: continue
			if game.route_to_cell(worker.position,pile.cell).is_empty(): continue
			var cell := destination(game.cell_center(pile.cell),worker)
			if cell == NONE: continue
			var ticket: Dictionary = game.logistics.reserve(worker,pile,site,pile.resource_kind,game.logistics.available(pile,pile.resource_kind),false)
			if ticket.is_empty(): continue
			ticket.clearance = true
			worker.ticket = ticket
			worker.clear_destination = cell
			worker.clear_site_id = site.entity_id
			worker.target = site
			worker.state = "to_clear"
			worker.path = game.route_to_cell(worker.position,pile.cell)
			worker.status = "Retirando materiais da área de construção"
			return true
	return false

func process_worker(worker, delta: float) -> bool:
	if worker.clear_destination != NONE:
		return relocate(worker,delta)
	var site = site_at(game.world_cell(worker.position))
	if site == null:
		worker.evacuation_destination = NONE
		return false
	if worker.evacuation_destination == NONE or not free_cell(worker.evacuation_destination,worker):
		worker.interrupt_task(true)
		worker.evacuation_destination = destination(worker.position,worker)
		if worker.evacuation_destination == NONE:
			worker.status = "Aguardando espaço livre para desocupar a obra"
			return true
		worker.path = game.route_to_cell(worker.position,worker.evacuation_destination)
	worker.status = "Saindo da área de construção"
	if not worker.path.is_empty(): worker.move_along_path(delta)
	return true

func relocate(worker, delta: float) -> bool:
	var site = sites().filter(func(b): return b.entity_id == worker.clear_site_id)
	if site.is_empty() or not site[0].preparing_site:
		worker.interrupt_task()
		return true
	if worker.cargo == 0:
		if worker.ticket.is_empty() or not is_instance_valid(worker.ticket.source):
			worker.interrupt_task()
			return true
		if not worker.path.is_empty():
			worker.move_along_path(delta)
			return true
		if game.world_cell(worker.position) != worker.ticket.source.door():
			worker.interrupt_task()
			return true
		worker.cargo = game.logistics.pickup(worker.ticket)
		worker.cargo_resource = worker.ticket.resource
		if worker.cargo <= 0:
			worker.interrupt_task()
			return true
		worker.state = "clearing_cargo"
		worker.path.clear()
	if not free_cell(worker.clear_destination,worker):
		worker.clear_destination = destination(worker.position,worker)
		worker.path.clear()
		if worker.clear_destination == NONE:
			# Preserve the load; allow a later attempt when a free place appears.
			worker.interrupt_task()
			return true
	if game.world_cell(worker.position) == worker.clear_destination and worker.path.is_empty():
		game.logistics.drop(worker.clear_destination,worker.cargo_resource,worker.cargo)
		worker.cargo = 0
		worker.interrupt_task()
		return true
	if worker.path.is_empty(): worker.path = game.route_to_cell(worker.position,worker.clear_destination)
	if worker.path.is_empty():
		worker.interrupt_task()
		return true
	worker.status = "Levando materiais para um local livre"
	worker.move_along_path(delta)
	return true

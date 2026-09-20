extends Node2D
var game
var elapsed := 0.0
var expedition := false
var sailing := false
var voyage := 0.0
var dock := Vector2i.ZERO
var departure := Vector2.ZERO
var arrivals := 0

func blocked_reason() -> String:
	if game.workers.size() >= game.population_limit(): return "Precisa de uma vaga em casa concluída"
	if game.settlement.food_units() < (game.workers.size() + 1) * game.DATA.FOOD_RESERVE_PER_PERSON: return "Falta reserva de Hortifruti para mais um morador"
	if not game.settlement.healthy_for_arrival(): return "Aguardando todos os habitantes se alimentarem"
	return ""

func expedition_reason() -> String:
	if expedition or sailing: return "Já existe uma viagem em andamento"
	if blocked_reason() != "": return blocked_reason()
	if not game.can_afford(game.DATA.EXPEDITION_COST): return game.cost_status(game.DATA.EXPEDITION_COST)
	if game.settlement.food_units() - game.DATA.EXPEDITION_COST.produce < (game.workers.size() + 1) * game.DATA.FOOD_RESERVE_PER_PERSON: return "Reserve mais Hortifruti antes de abastecer a expedição"
	return ""

func prepare_expedition() -> bool:
	if expedition_reason() != "":
		game.notify(expedition_reason())
		return false
	if expedition or sailing:
		game.notify("Uma viagem já está sendo preparada.")
		return false
	if not game.settlement.healthy_for_arrival():
		game.notify("Colonos precisam de moradia livre, população alimentada e reservas de Hortifruti.")
		return false
	if game.settlement.food_units() - game.DATA.EXPEDITION_COST.produce < (game.workers.size() + 1) * game.DATA.FOOD_RESERVE_PER_PERSON:
		game.notify("Guarde comida suficiente para a população após abastecer a expedição.")
		return false
	if not game.pay(game.DATA.EXPEDITION_COST):
		game.notify(game.cost_status(game.DATA.EXPEDITION_COST))
		return false
	expedition = true
	elapsed = 0
	game.notify("Expedição abastecida. Um barco poderá chegar após a preparação.")
	return true

func find_dock() -> bool:
	# Prefer the eastern shore: the left/top coast is obscured by management panels.
	var best_score := -INF
	var found := false
	var middle: float = game.land.get_used_rect().get_center().y
	for cell in game.land.get_used_cells():
		if not game.is_walkable(cell) or game.land.get_cell_source_id(cell + Vector2i.RIGHT) >= 0: continue
		var score: float = cell.x * 1000 - absf(cell.y - middle)
		if score <= best_score: continue
		if game.route_to_cell(game.cell_center(game.base.door()), cell).is_empty(): continue
		best_score = score
		dock = cell
		departure = game.cell_center(cell + Vector2i.RIGHT * 7)
		found = true
	return found
func tick(delta: float) -> void:
	if game.settlement.extinct: return
	if sailing:
		voyage = minf(game.DATA.VOYAGE_SECONDS, voyage + delta)
		var destination: Vector2 = game.cell_center(dock)
		position = departure.lerp(destination, voyage / game.DATA.VOYAGE_SECONDS)
		if voyage >= game.DATA.VOYAGE_SECONDS and game.settlement.healthy_for_arrival():
			if not game.is_walkable(dock) or game.route_to_cell(game.cell_center(game.base.door()), dock).is_empty():
				find_dock()
				return
			if game.route_to_cell(game.cell_center(game.base.door()), dock).is_empty(): return
			var worker = game.spawn_worker("idle", game.base, game.cell_center(dock))
			if not is_instance_valid(worker.residence):
				game.workers.erase(worker)
				worker.queue_free()
				return
			arrivals += 1
			sailing = false
			expedition = false
			elapsed = 0
			game.notify("%s desembarcou e recebeu residência em %s." % [worker.person.display_name, worker.residence.display_name()])
	elif game.settlement.healthy_for_arrival():
		elapsed += delta
		var interval: float = game.DATA.EXPEDITION_SECONDS if expedition else game.DATA.IMMIGRATION_INTERVAL
		if elapsed >= interval and find_dock():
			sailing = true
			voyage = 0
			position = departure
			game.notify("Um barco de colonos se aproxima da ilha!")
	visible = sailing
	queue_redraw()

func description() -> String:
	if sailing:
		return "Barco aguardando moradia / comida / acesso" if voyage >= game.DATA.VOYAGE_SECONDS else "Barco chegando em %ds" % ceili(game.DATA.VOYAGE_SECONDS - voyage)
	if blocked_reason() != "": return blocked_reason()
	var interval: float = game.DATA.EXPEDITION_SECONDS if expedition else game.DATA.IMMIGRATION_INTERVAL
	return "%s: %ds" % ["Expedição" if expedition else "Possível chegada", ceili(interval - elapsed)]

func _draw() -> void:
	if not sailing: return
	# Tiny pixel-aligned hull and sail; existing pack has no boat.
	draw_rect(Rect2(-18,5,36,2),Color("92c6c7"))
	draw_rect(Rect2(-15,0,30,5),Color("67412e"))
	draw_rect(Rect2(-12,5,24,3),Color("47362c"))
	draw_rect(Rect2(-12,-2,24,3),Color("c29057"))
	draw_rect(Rect2(-1,-25,2,25),Color("67412e"))
	for row in range(10): draw_rect(Rect2(1,-24 + row * 2,2 + row * 2,2),Color("f2ddb2"))
	draw_rect(Rect2(-7,-9,4,6),Color("c68c68"))

extends RefCounted
const MIN_SIZE = 1
const MAX_SIZE = 9
var game

func water_cells(origin: Vector2i, size: int) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(size):
		for x in range(size):
			var cell := origin + Vector2i(x,y)
			if game.land.get_cell_source_id(cell) < 0: cells.append(cell)
	return cells

func cost(count: int) -> Dictionary:
	return {"stone": ceili(count * 10.0 / 9.0), "wood": ceili(count * 5.0 / 9.0)}

func inspect(origin: Vector2i, size: int) -> Dictionary:
	var cells := water_cells(origin,size)
	var reserved: Array[Vector2i] = []
	for job in game.jobs:
		if not job.reserves_ground(): continue
		for cell in job.cells:
			if cells.has(cell):
				reserved.append(cell)
				cells.erase(cell)
	var result := {"cells": cells, "cost": cost(cells.size()), "seconds": cells.size()*10.0/9.0,
		"reserved": reserved, "entry": Vector2i(-999,-999), "reason": "", "discovery": size == 3 and cells.size() == 9}
	if not game.get_node("Water/Water").get_used_rect().encloses(Rect2i(origin,Vector2i(size,size))):
		result.reason = "Limite da região desta versão."
		return result
	if cells.is_empty():
		result.reason = "Este trecho já está marcado para aterro." if not reserved.is_empty() else "Não há água para preencher neste pincel."
		return result
	var pending := {}
	for cell in cells:
		pending[cell] = true
		for job in game.jobs:
			if job.reserves_ground() and (job.cells.has(cell) or job.door() == cell):
				result.reason = "Já existe uma obra neste trecho de água."
				return result
		for source in game.sources + game.gardens:
			if not source.removed and source.cells.has(cell):
				result.reason = "Este espaço já pertence a uma árvore ou recurso."
				return result
	# Every disconnected water pocket needs a shore reachable from the village.
	# Land under the brush is not reserved or changed, including occupied land.
	var reachable := {}
	while not pending.is_empty():
		var flood: Array[Vector2i] = [pending.keys()[0]]
		pending.erase(flood[0])
		var access := Vector2i(-999,-999)
		while not flood.is_empty():
			var cell: Vector2i = flood.pop_back()
			for direction in game.CARDINALS:
				var neighbor: Vector2i = cell + direction
				if pending.has(neighbor):
					pending.erase(neighbor)
					flood.append(neighbor)
				elif game.is_walkable(neighbor) and access.x == -999:
					if not reachable.has(neighbor):
						reachable[neighbor] = not game.route_to_cell(game.cell_center(game.base.door()),neighbor).is_empty()
					if reachable[neighbor]: access = neighbor
		if access.x == -999:
			result.reason = "Cada trecho de água precisa de uma margem acessível pela vila."
			return result
		if result.entry.x == -999: result.entry = access
	if not game.can_afford(result.cost): result.reason = game.cost_status(result.cost)
	return result

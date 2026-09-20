extends RefCounted
## The image and the logical shore masks share this south-facing reference.
const DIRECTIONS = ["south", "west", "north", "east"]
const LABELS = ["Sul", "Oeste", "Norte", "Leste"]
const CARDINALS = [Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT, Vector2i.UP]
var game
var route_cache := {}

static func rotate(cell: Vector2i, orientation: int) -> Vector2i:
	for i in posmod(orientation,4): cell=Vector2i(4-cell.y,cell.x)
	return cell

static func layout(origin: Vector2i, orientation: int) -> Dictionary:
	var result := {"land":[],"water":[],"blocked":[],"footprint":[],"approach":[],"reserved":[]}
	for y in 5:
		for x in 5:
			var cell := origin+rotate(Vector2i(x,y),orientation)
			result.footprint.append(cell)
			result["land" if y<2 else "water"].append(cell)
			if y<2 and x!=2: result.blocked.append(cell)
	for y in range(5,7):
		for x in range(1,4): result.approach.append(origin+rotate(Vector2i(x,y),orientation))
	result.reserved=result.footprint+result.approach
	result.loading=origin+rotate(Vector2i(2,1),orientation)
	result.dock=origin+rotate(Vector2i(2,5),orientation)
	result.land_entry=origin+rotate(Vector2i(2,-1),orientation)
	result.direction=rotate(Vector2i(2,3),orientation)-Vector2i(2,2)
	return result

func reserved(cell: Vector2i, except_port=null) -> bool:
	for building in game.buildings:
		if building!=except_port and building.kind=="trading_port" and layout(building.origin,building.orientation).reserved.has(cell): return true
	return false

func water_free(cell: Vector2i, except_port=null) -> bool:
	if game.land.get_cell_source_id(cell)>=0 or game.get_node("Water/Water").get_cell_source_id(cell)<0: return false
	if reserved(cell,except_port): return false
	for job in game.jobs:
		if job.reserves_ground() and job.cells.has(cell): return false
	return true

func water_route(origin: Vector2i, orientation: int, except_port=null) -> Array[Vector2i]:
	var mask := layout(origin,orientation)
	var bounds: Rect2i=game.get_node("Water/Water").get_used_rect()
	var start: Vector2i=mask.dock
	var empty: Array[Vector2i]=[]
	if not water_free(start,except_port): return empty
	# A clear ray toward the open sea is common, and avoids flooding a huge map
	# on every placement preview. A winding coast uses the same cardinal BFS.
	var ray: Array[Vector2i]=[]
	var cell := start
	while bounds.has_point(cell) and water_free(cell,except_port):
		ray.append(cell)
		if is_edge(cell,bounds): return ray
		cell+=mask.direction
	var parents := {start:start}
	var pending: Array[Vector2i]=[start]
	var index := 0
	while index<pending.size():
		cell=pending[index]
		index+=1
		if is_edge(cell,bounds):
			var path: Array[Vector2i]=[cell]
			while cell!=start:
				cell=parents[cell]
				path.append(cell)
			path.reverse()
			return path
		for direction in CARDINALS:
			var neighbor: Vector2i=cell+direction
			if bounds.has_point(neighbor) and not parents.has(neighbor) and water_free(neighbor,except_port):
				parents[neighbor]=cell
				pending.append(neighbor)
	return empty

static func is_edge(cell: Vector2i, bounds: Rect2i) -> bool:
	return cell.x==bounds.position.x or cell.y==bounds.position.y or cell.x==bounds.end.x-1 or cell.y==bounds.end.y-1

func path_between(start: Vector2i, finish: Vector2i, except_port=null) -> Array[Vector2i]:
	var result: Array[Vector2i]=[]
	if not water_free(start,except_port) or not water_free(finish,except_port): return result
	var bounds: Rect2i=game.get_node("Water/Water").get_used_rect()
	var parents := {start:start}
	var pending: Array[Vector2i]=[start]
	var index := 0
	while index<pending.size():
		var cell: Vector2i=pending[index]
		index+=1
		if cell==finish:
			result.append(cell)
			while cell!=start:
				cell=parents[cell]
				result.append(cell)
			result.reverse()
			return result
		var directions: Array=CARDINALS.duplicate()
		directions.sort_custom(func(a,b): return (cell+a).distance_squared_to(finish)<(cell+b).distance_squared_to(finish))
		for direction in directions:
			var neighbor: Vector2i=cell+direction
			if bounds.has_point(neighbor) and not parents.has(neighbor) and water_free(neighbor,except_port):
				parents[neighbor]=cell
				pending.append(neighbor)
	return result

func inspect(origin: Vector2i, orientation: int) -> Dictionary:
	var mask := layout(origin,orientation)
	var result := {"reason":"","cells":{},"layout":mask,"water_route":[]}
	for cell in mask.reserved:
		var valid: bool=game.is_walkable(cell) if mask.land.has(cell) else water_free(cell)
		if game.clearance.reserved(cell): valid=false
		for building in game.buildings:
			if building.footprint().has(cell) or building.door()==cell: valid=false
		for source in game.sources+game.gardens:
			if not source.removed and source.cells.has(cell): valid=false
		for job in game.jobs:
			if job.reserves_ground() and (job.cells.has(cell) or job.door()==cell): valid=false
		result.cells[cell]=valid
	if game.buildings.any(func(b): return b.kind=="trading_port"):
		result.reason="Cada ilha pode ter apenas um porto, incluindo obras e demolições."
	elif result.cells.values().has(false):
		result.reason="O porto exige 5 × 2 células em terra, 5 × 3 em água e aproximação livre para o barco."
	if not result.reason.is_empty(): return result
	# Test the final walkable loading aisle without mutating the live grid.
	var blocked: Array=mask.blocked.duplicate()
	for building in game.buildings:
		if building.preparing_site: blocked.append_array(building.blocking_cells())
	var reachable := {mask.loading:true}
	var pending: Array[Vector2i]=[mask.loading]
	while not pending.is_empty():
		var cell: Vector2i=pending.pop_back()
		for direction in CARDINALS:
			var neighbor: Vector2i=cell+direction
			if not reachable.has(neighbor) and not blocked.has(neighbor) and game.is_walkable(neighbor):
				reachable[neighbor]=true
				pending.append(neighbor)
	if not reachable.has(game.base.door()): result.reason="O ponto de carga precisa de um caminho por terra até a vila."
	for cell in game.land.get_used_cells():
		if game.is_walkable(cell) and not blocked.has(cell) and not reachable.has(cell):
			result.reason="Este porto bloquearia a passagem dos habitantes."
			break
	for source in game.sources:
		if source.blocks_ground() and not source.work_cells().any(func(c): return reachable.has(c)):
			result.reason="Este porto impediria o acesso a um recurso."
	if not result.reason.is_empty(): return result
	var key := str(origin)+":"+str(orientation)
	if route_cache.size()>64: route_cache.clear()
	if not route_cache.has(key): route_cache[key]=water_route(origin,orientation)
	result.water_route=route_cache[key]
	if result.water_route.is_empty(): result.reason="O cais precisa de mar aberto; um lago fechado não recebe comerciantes."
	return result

func access_reason(port) -> String:
	if not is_instance_valid(port) or not port.completed: return "Aguardando a conclusão do porto."
	if game.route_to_cell(game.cell_center(game.base.door()),port.door()).is_empty(): return "Porto sem acesso por terra."
	var mask := layout(port.origin,port.orientation)
	for cell in mask.approach:
		if not water_free(cell,port): return "A aproximação do barco está bloqueada."
	if water_route(port.origin,port.orientation,port).is_empty(): return "Porto sem rota para o mar aberto."
	return ""

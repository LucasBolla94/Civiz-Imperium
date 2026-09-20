extends Node2D

const COLONY_CAMERA = preload("res://Scripts/colony_camera.gd")
const DATA = preload("res://Scripts/game_data.gd")
var port_layout=preload("res://Scripts/port_layout.gd").new()
var placement_orientation := 0
var port_preview := {}
const BUILDING = preload("res://Scripts/building.gd")
const WORKER = preload("res://Scripts/worker.gd")
const SOURCE = preload("res://Scripts/resource_source.gd")
const HUD = preload("res://Scripts/hud.gd")
const JOB = preload("res://Scripts/world_job.gd")
const PLANNER = preload("res://Scripts/work_planner.gd")
var work_planner = PLANNER.new()
var saves = preload("res://Scripts/save_game.gd").new()
var automation = preload("res://Scripts/automation.gd").new()
const SETTLEMENT = preload("res://Scripts/settlement.gd")
const LOGISTICS = preload("res://Scripts/logistics.gd")
const IMMIGRATION = preload("res://Scripts/immigration.gd")
var settlement = SETTLEMENT.new()
var logistics = LOGISTICS.new()
var clearance = preload("res://Scripts/site_clearance.gd").new()
var gold = preload("res://Scripts/gold_economy.gd").new()
var immigration
var merchant
var commerce=preload("res://Scripts/commerce.gd").new()
var jobs: Array = []
var gardens: Array = []
const GARDEN = preload("res://Scripts/garden.gd")
var action_mode := ""
var expansion_brush = preload("res://Scripts/expansion_brush.gd").new()
var expansion_brush_size := 3
var expansion_preview: Dictionary = {}
var expansion_dragging := false
var expansion_drag_point := Vector2.INF
var expansion_drag_cells := {}
var planted_count := 0
var expansion_count := 0
var village_level := 1
var initial_bounds: Rect2i
var ground_source := 0
var ground_atlas := Vector2i.ZERO
var shore_atlas: Dictionary = {}
var aid_cooldown := 0.0
const CARDINALS = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
@export var initial_base_cell := Vector2i(48, 24)
@export var initial_produce_cell := Vector2i(64, 27)
@export var initial_stone_cell := Vector2i(55, 33)
var stock: Dictionary:
	get:
		var total := DATA.empty_stock()
		for building in buildings:
			if building.kind=="trading_port": continue
			for resource in total:
				total[resource] += building.stored.get(resource, 0)
		return total
	set(value):
		for building in buildings:
			building.stored = DATA.empty_stock()
		if is_instance_valid(base):
			for resource in value: base.store(resource, value[resource])
var base
var total_delivered := {"produce": 0, "stone": 0, "wood": 0}
var buildings: Array = []
var workers: Array = []
var sources: Array = []
var land: TileMapLayer
var entities: Node2D
var navigation := AStarGrid2D.new()
var camera
var hud
var selection = null
var placement_kind := ""
var preview_cell := Vector2i.ZERO
var preview_valid := false
var placement_reason := ""
var simulation_paused := false
var simulation_speed := 1.0
var message := "Um Rei e dois trabalhadores. Replante pomares, construa moradias e cuide da alimentação."
var message_time := 10.0
var objective_complete := false
var placement_overlay: Node2D
var pointer_position := Vector2.ZERO
var preview_texture: Texture2D
var preview_check_time := 0.0

func _ready() -> void:
	commerce.game=self
	port_layout.game=self
	settlement.game = self
	automation.game = self
	saves.game = self
	work_planner.game = self
	logistics.game = self
	gold.game = self
	clearance.game = self
	expansion_brush.game = self
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	land = $Water/TileMapLayer
	initial_bounds = land.get_used_rect()
	ground_source = land.get_cell_source_id(Vector2i(60,32))
	ground_atlas = land.get_cell_atlas_coords(Vector2i(60,32))
	var p := initial_bounds.position
	var e := initial_bounds.end - Vector2i.ONE
	for sample in {"tl":p,"top":p+Vector2i.RIGHT,"tr":Vector2i(e.x,p.y),"left":p+Vector2i.DOWN,"right":Vector2i(e.x,p.y+1),"bl":Vector2i(p.x,e.y),"bottom":Vector2i(p.x+1,e.y),"br":e}:
		var coordinates: Dictionary = {"tl":p,"top":p+Vector2i.RIGHT,"tr":Vector2i(e.x,p.y),"left":p+Vector2i.DOWN,"right":Vector2i(e.x,p.y+1),"bl":Vector2i(p.x,e.y),"bottom":Vector2i(p.x+1,e.y),"br":e}
		shore_atlas[sample] = land.get_cell_atlas_coords(coordinates[sample])
	entities = Node2D.new()
	entities.name = "Simulation"
	# Ground decorations stay at terrain depth; actors keep their Y sorting above.
	entities.z_index = 1
	entities.y_sort_enabled = true
	add_child(entities)
	# Examples are the visual catalog; world only supplies terrain and water.
	for definition in [{"key": "Stone", "cell": initial_stone_cell, "kind": "stone"}]:
		var layer: TileMapLayer = DATA.CATALOG.resource_layer(definition.key, definition.cell)
		var source = SOURCE.new()
		entities.add_child(source)
		source.setup(self, layer, layer.get_used_cells(), definition.kind)
		sources.append(source)
		layer.free()
	spawn_tree(initial_produce_cell, 4)
	spawn_tree(Vector2i(66,34), 6)
	gold.restore({})
	var starting_house = add_building("base", initial_base_cell, true)
	base = starting_house
	base.stored.merge(DATA.STARTING_STOCK, true)
	var start: Vector2 = $Water/CharacterBody2D.position
	$Water/CharacterBody2D.queue_free()
	rebuild_navigation()
	if not is_walkable(world_cell(start)):
		start = cell_center(starting_house.door())
	var king = spawn_worker("builder", starting_house, start)
	king.person.is_king = true
	king.refresh_appearance()
	var occupied_cells: Array[Vector2i] = [world_cell(start)]
	for activity in ["food", "wood"]:
		var spawn_cell: Vector2i = starting_house.door()
		for offset in [Vector2i(2,0), Vector2i(-2,0), Vector2i(0,2), Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i.ZERO]:
			var candidate: Vector2i = starting_house.door() + offset
			if is_walkable(candidate) and not occupied_cells.has(candidate) and not route_to_cell(start, candidate).is_empty():
				spawn_cell = candidate
				break
		occupied_cells.append(spawn_cell)
		spawn_worker(activity, starting_house, cell_center(spawn_cell))
	immigration = IMMIGRATION.new()
	immigration.game = self
	immigration.z_index = 10
	add_child(immigration)
	immigration.hide()
	merchant=preload("res://Scripts/merchant.gd").new()
	merchant.game=self
	add_child(merchant)
	placement_overlay = Node2D.new()
	placement_overlay.z_index = 100
	add_child(placement_overlay)
	placement_overlay.draw.connect(draw_placement)
	camera = COLONY_CAMERA.new()
	camera.game = self
	add_child(camera)
	center_camera()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	hud = HUD.new()
	hud.game = self
	canvas.add_child(hud)
	select_entity(null)
	get_viewport().size_changed.connect(func(): center_camera.call_deferred())
	center_camera.call_deferred()
	if get_tree().has_meta("continue_game"):
		get_tree().remove_meta("continue_game")
		open_saved_island.call_deferred()
	elif get_node("/root/IslandSaves").pending_index >= 0:
		saves.save_file.call_deferred()

func open_saved_island() -> void:
	if not saves.load_file():
		# A failed load must never allow autosave to overwrite that island with a fresh world.
		simulation_paused = true
		get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")

func connected_groups(input: Array[Vector2i]) -> Array:
	var unvisited: Dictionary = {}
	for cell in input:
		unvisited[cell] = true
	var groups: Array = []
	while not unvisited.is_empty():
		var group: Array[Vector2i] = []
		var pending: Array[Vector2i] = [unvisited.keys()[0]]
		unvisited.erase(pending[0])
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			group.append(cell)
			for direction in CARDINALS:
				var neighbor: Vector2i = cell + direction
				if unvisited.has(neighbor):
					unvisited.erase(neighbor)
					pending.append(neighbor)
		groups.append(group)
	return groups

func spawn_timber_tree(cell: Vector2i, stage := 0):
	var tree = SOURCE.new()
	entities.add_child(tree)
	tree.setup_timber(self, cell, stage)
	sources.append(tree)
	return tree

func spawn_tree(cell: Vector2i, stage := 0):
	var tree = SOURCE.new()
	entities.add_child(tree)
	tree.setup_tree(self, cell, stage)
	sources.append(tree)
	return tree

func population_limit() -> int: return settlement.population_limit()

func gardens_unlocked() -> bool:
	return buildings.any(func(b): return b.kind == "food" and b.completed and b.level >= 2 and not b.demolition_requested)

func can_place_garden(cell: Vector2i) -> bool:
	placement_reason = ""
	if not gardens_unlocked():
		placement_reason = "Melhore um depósito de comida para o nível 2 para criar hortas."
		return false
	if not can_afford(DATA.GARDEN_COST):
		placement_reason = cost_status(DATA.GARDEN_COST)
		return false
	var rect := Rect2i(cell, Vector2i(2,2))
	for y in range(2):
		for x in range(2):
			if not is_walkable(cell + Vector2i(x,y)) or clearance.reserved(cell + Vector2i(x,y)) or port_layout.reserved(cell+Vector2i(x,y)):
				placement_reason = "A horta exige terra livre e acessível."
				return false
	for source in sources + gardens:
		if not source.removed and source.cells.any(func(c): return rect.has_point(c)):
			placement_reason = "Este terreno já está ocupado."
			return false
	for job in jobs:
		if job.reserves_ground() and (job.cells.any(func(c): return rect.has_point(c)) or rect.has_point(job.door())):
			placement_reason = "Não bloqueie a entrada de uma obra."
			return false
	for building in buildings:
		if rect.has_point(building.door()):
			placement_reason = "Não bloqueie a entrada de outro prédio."
			return false
	if route_to_cell(cell_center(base.door()), cell).is_empty():
		placement_reason = "A horta exige terra livre e acessível."
		return false
	return true

func cancel_construction(building) -> bool:
	if not buildings.has(building) or building.completed or building.kind == "base": return false
	remove_building(building, true)
	return true

func detach_building_tasks(building, removing: bool) -> void:
	for worker in workers:
		var references_ticket: bool = not worker.ticket.is_empty() and (worker.ticket.source == building or worker.ticket.destination == building)
		if worker.target == building or worker.clear_site_id == building.entity_id or references_ticket or (worker.home == building and worker.state in ["to_craft", "crafting", "to_home"]):
			var finish_delivery: bool=removing and worker.assigned_home==building
			worker.interrupt_task(finish_delivery)
			if finish_delivery and worker.cargo>0: worker.return_home()
		if removing:
			if worker.home == building: worker.home = base
			if worker.assigned_home == building:
				worker.assign_to("idle",base)
			if worker.move_destination == building: worker.move_destination = null
	for ticket in logistics.tickets.duplicate():
		if ticket.source == building or ticket.destination == building: logistics.tickets.erase(ticket)
	building.reserved_by = null
	building.craft_reserved_by = null

func remove_building(building, cancelled: bool) -> void:
	if building == base or not buildings.has(building): return
	if not cancelled and (not building.demolition_started or not settlement.residents(building).is_empty()): return
	commerce.before_removal(building)
	var salvage: Dictionary = building.stored.duplicate()
	if cancelled and not building.work_started:
		for resource in building.materials.delivered:
			salvage[resource] = salvage.get(resource, 0) + building.materials.delivered[resource]
	if building.crafting != "":
		if building.craft_progress >= DATA.CRAFT_SECONDS:
			salvage[building.crafting] = salvage.get(building.crafting, 0) + 1
		else:
			for resource in DATA.RECIPES[building.crafting]:
				salvage[resource] = salvage.get(resource, 0) + DATA.RECIPES[building.crafting][resource]
	buildings.erase(building)
	if building.kind=="trading_port" and is_instance_valid(merchant):
		merchant.port_id=0
		merchant.next_attempt=-1.0
	detach_building_tasks(building, true)
	if selection == building: select_entity(null)
	if hud.residence_filter == building: hud.close_residents(); hud.residence_filter = null
	building.stored = DATA.empty_stock()
	rebuild_navigation()
	# Separate resources spatially so every pile remains selectable and accessible.
	var spots: Array[Vector2i] = building.footprint()
	spots.append(building.door())
	if building.kind=="trading_port": spots.assign(port_layout.layout(building.origin,building.orientation).land)
	var index := 0
	for resource in salvage:
		if salvage[resource] <= 0: continue
		logistics.drop(spots[index % spots.size()], resource, salvage[resource])
		index += 1
	building.queue_free()
	notify("Obra cancelada." if cancelled else "Demolição concluída. Estoque preservado no chão.")

func carry_capacity() -> int: return 5 if village_level == 1 else 7

func begin_action(mode: String) -> void:
	if mode == "expand":
		placement_kind = ""
		action_mode = mode
		select_entity(null)
		update_expansion_preview()
		notify("Ctrl + roda ajusta o pincel; Shift + arraste marca o percurso; Esc cancela. Só a água será aterrada.")
		return
	if mode == "garden":
		if not gardens_unlocked():
			notify("Melhore um depósito de comida para o nível 2 para criar hortas.")
			return
		placement_kind = ""
		action_mode = mode
		preview_check_time = 0
		notify("Marque uma horta 2 × 2. Cercado: 10 madeiras; plantio: 2 Hortifruti.")
		return
	if mode not in ["plant", "plant_wood", "expand", "survey"]: return
	var cost: Dictionary = DATA.PLANT_COST if mode in ["plant","plant_wood"] else ({} if mode == "survey" else DATA.EXPAND_COST)
	if not can_afford(cost):
		notify(cost_status(cost))
		return
	placement_kind = ""
	action_mode = mode
	preview_check_time = 0
	notify("Marque um terreno livre para plantar a árvore de madeira." if mode == "plant_wood" else ("Marque um terreno livre para plantar." if mode == "plant" else ("Marque terra livre 3 × 3 para investigar." if mode == "survey" else "Marque um bloco de mar 3 × 3 junto à costa.")))

func job_entry(cell: Vector2i, height: int) -> Vector2i:
	for y in range(height):
		for x in range(3):
			var spot := cell + Vector2i(x,y)
			for direction in CARDINALS:
				var next: Vector2i = spot + direction
				if not Rect2i(cell, Vector2i(3,height)).has_point(next) and is_walkable(next) and not clearance.reserved(next): return next
	return Vector2i(-999,-999)

func can_place_job(mode: String, cell: Vector2i) -> bool:
	if mode == "expand":
		expansion_preview = expansion_brush.inspect(cell,expansion_brush_size)
		placement_reason = expansion_preview.reason
		return placement_reason.is_empty()
	if mode == "garden": return can_place_garden(cell)
	placement_reason = ""
	if mode=="survey":
		placement_reason=gold.survey_reason(cell)
		if not placement_reason.is_empty(): return false
	var planting := mode != "expand"
	if mode == "survey" and not buildings.any(func(b): return b.kind == "stone" and b.completed and b.level >= 2):
		placement_reason = "Melhore um depósito de pedra para o nível 2."
		return false
	var cost: Dictionary = DATA.PLANT_COST if mode in ["plant","plant_wood"] else ({} if mode == "survey" else DATA.EXPAND_COST)
	if not can_afford(cost):
		placement_reason = cost_status(cost)
		return false
	if mode == "plant" and not is_instance_valid(workplace_for("food")):
		placement_reason = "Construa um depósito de comida."
		return false
	if mode == "plant_wood" and not buildings.any(func(b): return b.kind == "wood" and b.completed and not b.demolition_requested):
		placement_reason = "Construa um depósito de madeira."
		return false
	var height := 4 if mode in ["plant","plant_wood"] else 3
	var rect := Rect2i(cell,Vector2i(3,height))
	if not $Water/Water.get_used_rect().encloses(rect):
		placement_reason = "Limite da região desta versão."
		return false
	for y in range(height):
		for x in range(3):
			var spot := cell + Vector2i(x,y)
			if port_layout.reserved(spot):
				placement_reason="Este espaço está reservado para o porto e seus acessos."
				return false
			if clearance.reserved(spot):
				placement_reason = "Este espaço está reservado para retirar materiais de uma obra."
				return false
			if (planting and not is_walkable(spot)) or (not planting and land.get_cell_source_id(spot) >= 0):
				placement_reason = "Plantio exige terra livre; expansão exige um bloco inteiramente no mar."
				return false
			for job in jobs:
				if job.reserves_ground() and job.cells.has(spot): return false
	for source in sources + gardens:
		if not source.removed and source.cells.any(func(spot): return rect.has_point(spot)):
			placement_reason = "Este espaço já pertence a uma árvore ou recurso."
			return false
	for pile in logistics.piles:
		if rect.has_point(pile.cell):
			placement_reason = "Há materiais aguardando transporte neste terreno."
			return false
	for worker in workers:
		if rect.has_point(world_cell(worker.position)): return false
	for building in buildings:
		if rect.has_point(building.door()): return false
	for job in jobs:
		if job.reserves_ground() and rect.has_point(job.door()): return false
	var entry := job_entry(cell,height)
	if not is_walkable(entry):
		placement_reason = "Precisa de acesso por terra junto à costa ou ao plantio."
		return false
	# Temporarily reserve planting cells to reject enclosed paths before charging.
	if planting:
		for y in range(height):
			for x in range(3): navigation.set_point_solid(cell + Vector2i(x,y))
		var valid := true
		for spot in land.get_used_cells():
			if is_walkable(spot) and navigation.get_id_path(entry,spot).is_empty():
				valid = false
				break
		for source in sources:
			if source.blocks_ground() and route_to_source(cell_center(entry),source).is_empty(): valid = false
		for y in range(height):
			for x in range(3): navigation.set_point_solid(cell + Vector2i(x,y), false)
		if not valid:
			placement_reason = "Este pomar bloquearia a circulação."
			return false
	return true

func place_job(mode: String, cell: Vector2i, automatic := false, repeat := false):
	if not can_place_job(mode,cell):
		notify(placement_reason)
		return null
	if mode == "garden":
		var garden = GARDEN.new()
		garden.setup_garden(self, cell)
		entities.add_child(garden)
		gardens.append(garden)
		clearance.prepare(garden)
		if not automatic and not repeat: cancel_placement()
		select_entity(garden)
		return garden
	var job = JOB.new()
	if mode == "expand": job.setup_expansion(self,cell,expansion_brush_size,expansion_preview)
	else: job.setup(self,mode,cell,job_entry(cell,4 if mode in ["plant","plant_wood"] else 3))
	if mode=="survey": gold.register_survey(job)
	entities.add_child(job)
	jobs.append(job)
	rebuild_navigation()
	if not automatic and not repeat: cancel_placement()
	notify("Plantio marcado: aloque um trabalhador em Comida." if mode == "plant" else ("Plantio de madeira marcado: aloque um lenhador." if mode == "plant_wood" else ("Investigação marcada: aloque um mineiro." if mode == "survey" else "Aterro marcado: aloque um construtor.")))
	return job

func complete_job(job) -> void:
	if job.kind == "survey":
		notify("Investigação concluída: %d %s. Selecione a área para abrir a jazida." % [job.deposit,DATA.RESOURCES[job.deposit_resource].name])
		return
	if job.kind == "quarry":
		var source = SOURCE.new()
		entities.add_child(source)
		source.setup_quarry(self, job.origin, job.deposit)
		source.resource_kind=job.deposit_resource
		gold.mark(job.origin,"opened")
		sources.append(source)
		rebuild_navigation()
		notify("Jazida de ouro aberta. Aloque mineiros no posto de mineração." if job.deposit_resource=="gold_ore" else "Pedreira aberta. Mineiros extraem e transportam a pedra.")
		return
	if job.kind == "plant_wood":
		spawn_timber_tree(job.origin)
		planted_count += 1
		notify("Muda de madeira plantada. Ela nunca frutifica: quando amadurecer, lenhadores cortam %d madeiras." % DATA.TIMBER_STOCK)
	elif job.kind == "plant":
		spawn_tree(job.origin)
		planted_count += 1
		notify("Muda plantada. Acompanhe os estágios clicando na árvore.")
	else:
		for cell in job.cells: land.set_cell(cell,ground_source,ground_atlas)
		refresh_shoreline()
		if job.discovery_eligible: expansion_count += 1
		var discovered: bool = job.discovery_eligible and expansion_count % 2 == 0
		if discovered:
			var layer: TileMapLayer = DATA.CATALOG.resource_layer("Stone", job.origin)
			var source = SOURCE.new()
			entities.add_child(source)
			source.setup(self,layer,layer.get_used_cells(),"stone")
			source.remaining = 120
			source.initial_reserve = 120
			sources.append(source)
			layer.free()
			gold.discoveries[source.origin]={"resource":"stone","reserve":120,"state":"opened"}
			for spot in source.cells: gold.surveyed_cells[spot]=source.origin
		notify("Território ampliado!" + (" Uma jazida de 120 pedras foi descoberta." if discovered else " Mais espaço para sua vila."))
	rebuild_navigation()

func refresh_shoreline() -> void:
	for cell in land.get_used_cells():
		var top := land.get_cell_source_id(cell + Vector2i.UP) < 0
		var bottom := land.get_cell_source_id(cell + Vector2i.DOWN) < 0
		var left := land.get_cell_source_id(cell + Vector2i.LEFT) < 0
		var right := land.get_cell_source_id(cell + Vector2i.RIGHT) < 0
		var key := ""
		if top: key = "tl" if left else ("tr" if right else "top")
		elif bottom: key = "bl" if left else ("br" if right else "bottom")
		elif left: key = "left"
		elif right: key = "right"
		land.set_cell(cell,ground_source,shore_atlas.get(key,ground_atlas))

func upgrade_cost() -> Dictionary:
	return {"produce":20,"stone":25,"wood":15} if village_level == 1 else {"produce":40,"stone":40,"wood":30}

func upgrade_ready() -> bool:
	return village_level < 3 and can_afford(upgrade_cost())

func upgrade_village() -> bool:
	if not upgrade_ready():
		notify("A vila já atingiu o nível máximo desta versão." if village_level >= 3 else cost_status(upgrade_cost()))
		return false
	pay(upgrade_cost())
	village_level += 1
	notify("Vila nível %d! Moradia: %d habitantes. Transporte especializado liberado; carga 7." % [village_level,population_limit()])
	return true

func coastal_aid() -> bool:
	if aid_cooldown > 0: return false
	var accepted: int = base.store("produce", mini(4, logistics.storage_free(base)))
	if accepted == 0:
		notify("Reserva da base cheia. Libere espaço ou amplie depósitos.")
		return false
	aid_cooldown = 60
	notify("Coleta costeira: +%d Hortifruti. Disponível novamente em 60s." % accepted)
	return true

func progression_text() -> String:
	if village_level>=3: return gold.progression_text()
	if upgrade_ready(): return "Evolução disponível! Abra Vila: expandir / evoluir para chegar ao nível %d." % (village_level + 1)
	if total_delivered.produce < 10 or total_delivered.stone < 10: return "Abasteça a vila: Hortifruti %d/10 · pedra %d/10" % [mini(10,total_delivered.produce),mini(10,total_delivered.stone)]
	if village_level == 3: return "Vila próspera! Continue expandindo e renovando seus pomares."
	return "Sugestão: renove os pomares e amplie a costa. Evolução: " + cost_status(upgrade_cost())

func add_building(kind: String, cell: Vector2i, ready_now := false, orientation := 0):
	var building = BUILDING.new()
	entities.add_child(building)
	building.setup(self, kind, cell, ready_now, orientation)
	buildings.append(building)
	return building

func spawn_worker(kind: String, home, start: Vector2):
	var worker = WORKER.new()
	entities.add_child(worker)
	worker.setup(self, kind, home, start)
	workers.append(worker)
	settlement.register(worker)
	return worker

func rebuild_navigation() -> void:
	port_layout.route_cache.clear()
	navigation.region = land.get_used_rect()
	navigation.cell_size = Vector2(16, 16)
	navigation.offset = Vector2(8, 8)
	navigation.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	navigation.update()
	for cell in all_map_cells():
		navigation.set_point_solid(cell, land.get_cell_source_id(cell) < 0)
	for source in sources:
		if source.blocks_ground():
			for cell in source.blocking_cells():
				if navigation.is_in_boundsv(cell):
					navigation.set_point_solid(cell)
	for building in buildings:
		if building.preparing_site: continue
		for cell in building.blocking_cells():
			if navigation.is_in_boundsv(cell):
				navigation.set_point_solid(cell)
	for job in jobs:
		if job.reserves_ground():
			for cell in job.cells:
				if navigation.is_in_boundsv(cell): navigation.set_point_solid(cell)

func all_map_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var bounds := land.get_used_rect()
	for y in range(bounds.position.y, bounds.end.y):
		for x in range(bounds.position.x, bounds.end.x):
			result.append(Vector2i(x, y))
	return result

func is_walkable(cell: Vector2i) -> bool:
	return navigation.is_in_boundsv(cell) and not navigation.is_point_solid(cell)

func world_cell(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / 16), floori(point.y / 16))

func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell * 16) + Vector2(8, 8)

func route_to_cell(from: Vector2, destination: Vector2i) -> PackedVector2Array:
	var start := world_cell(from)
	if not is_walkable(start) or not is_walkable(destination):
		return PackedVector2Array()
	var route := navigation.get_point_path(start, destination)
	# A recalculation halfway along a straight segment must not send the resident
	# back to the cell centre before walking forward again. Preserve actual turns.
	if route.size() > 1:
		var segment: Vector2 = route[1] - route[0]
		var offset := from - route[0]
		if absf(segment.cross(offset)) < 0.01 and offset.dot(segment) > 0 and offset.length() < segment.length():
			route.remove_at(0)
	return route

func route_to_source(from: Vector2, source) -> PackedVector2Array:
	var best := PackedVector2Array()
	for neighbor in source.work_cells():
		var route := route_to_cell(from, neighbor)
		if not route.is_empty() and (best.is_empty() or route.size() < best.size()): best = route
	return best

func can_afford(cost: Dictionary) -> bool:
	return missing_resources(cost).is_empty()

func available_stock() -> Dictionary:
	var available := DATA.empty_stock()
	for building in buildings:
		if building.kind=="trading_port": continue
		for resource in available: available[resource] += logistics.available(building, resource)
	# Outstanding orders reserve their unfunded balance immediately, even before
	# a worker claims a delivery. Cargo already withdrawn is not reserved twice.
	for site in buildings + jobs + gardens:
		if site.needs_work():
			for resource in site.materials.required:
				available[resource] -= maxi(0, site.materials.missing(resource) - logistics.incoming(site, resource))
	for resource in available: available[resource] = maxi(0, available[resource])
	return available

func resource_breakdown(resource: String) -> Dictionary:
	var stored: int = stock.get(resource, 0)
	var available: int = available_stock().get(resource, 0)
	var carried := 0
	for worker in workers:
		if worker.cargo_resource == resource: carried += worker.cargo
	carried+=commerce.extra_transit(resource)
	for pile in logistics.piles: carried+=pile.stored.get(resource,0)
	return {"available": available, "stored": stored, "reserved": stored - available, "carried": carried}

func missing_resources(cost: Dictionary) -> Dictionary:
	var available := available_stock()
	var missing := {}
	for resource in cost:
		var deficit: int = int(cost[resource]) - int(available.get(resource, 0))
		if deficit > 0: missing[resource] = deficit
	return missing

func cost_status(cost: Dictionary) -> String:
	var missing := missing_resources(cost)
	return "Recursos disponíveis" if missing.is_empty() else "Falta: " + DATA.cost_text(missing)

func pay(cost: Dictionary) -> bool:
	if not can_afford(cost):
		return false
	for resource in cost:
		var remaining: int = cost[resource]
		for building in buildings:
			var amount: int = mini(remaining, logistics.available(building, resource))
			building.stored[resource] -= amount
			remaining -= amount
	return true

func refund(cost: Dictionary) -> void:
	for resource in cost:
		var remaining: int = cost[resource]
		for building in buildings:
			if building.accepts(resource): remaining -= building.store(resource, mini(remaining, logistics.storage_free(building)))
		if remaining > 0: logistics.drop(base.door(), resource, remaining)

func activity_count(activity: String) -> int:
	var count := 0
	for worker in workers:
		if worker.assignment == activity:
			count += 1
	return count

func workplace_count(building, activity := "") -> int:
	return workers.filter(func(w): return w.assigned_home==building and (activity.is_empty() or w.assignment==activity)).size()

func workplace_capacity(building, activity: String) -> int:
	if not is_instance_valid(building) or not building.completed or building.demolition_requested: return 0
	if activity=="carrier" and village_level<2: return 0
	if activity in ["gold_mining","smelter"] and village_level<3: return 0
	if building.kind=="gold_mining" and activity=="gold_mining": return DATA.ECONOMY.GOLD_POST_WORKERS
	if building.kind=="smelter" and activity=="smelter": return DATA.ECONOMY.SMELTER_WORKERS
	if building.kind==activity or (building==base and activity in ["idle","builder","food","wood","stone","carrier"]): return 2147483647
	return 0

func workplace_for(activity: String, from := Vector2.INF):
	if activity == "carrier": return base if village_level >= 2 else null
	if activity in ["idle", "builder"]:
		return base
	var best = null
	var least := INF
	var distance := INF
	if from==Vector2.INF: from=cell_center(base.door())
	for building in buildings:
		if building.kind != activity or not building.completed or building.demolition_requested:
			continue
		var capacity := workplace_capacity(building,activity)
		var assigned := workplace_count(building,activity)
		if capacity<=assigned: continue
		var route := route_to_cell(from,building.door())
		if route.is_empty(): continue
		var occupancy := float(assigned) if capacity==2147483647 else float(assigned)/capacity
		var length := work_planner.route_length(from,route)
		if occupancy<least or (is_equal_approx(occupancy,least) and length<distance):
			least = occupancy
			distance=length
			best = building
	return best if best != null else (base if activity in ["food", "stone", "wood"] else null)

func allocation_available(activity: String) -> bool:
	for worker in workers:
		if worker.assignment!="idle": continue
		var destination=workplace_for(activity,worker.position)
		if is_instance_valid(destination) and workplace_capacity(destination,activity)>workplace_count(destination,activity) and not route_to_cell(worker.position,destination.door()).is_empty(): return true
	return false

func allocation_reason(activity: String) -> String:
	if activity_count("idle")==0: return "Sem trabalhadores livres. Reduza outra atividade ou atraia colonos."
	if activity in ["gold_mining","smelter"] and village_level<3: return "Evolua a base para o nível 3."
	if activity=="carrier" and village_level<2: return "Desbloqueia na vila nível 2"
	if activity in ["gold_mining","smelter"]:
		var posts: Array=buildings.filter(func(b): return b.kind==activity and b.completed and not b.demolition_requested)
		if not posts.is_empty() and posts.all(func(b): return workplace_count(b,activity)>=workplace_capacity(b,activity)): return "Todos os postos desta atividade estão lotados."
	return "" if allocation_available(activity) else "Sem posto acessível com vaga para esta atividade."

func change_allocation(activity: String, change: int, local_building=null) -> bool:
	if not DATA.ACTIVITIES.has(activity) or activity == "idle" or change == 0:
		return false
	var from_activity := "idle" if change > 0 else activity
	var to_activity := activity if change > 0 else "idle"
	# Prefer a worker without cargo; a carrier finishes its current delivery first.
	var candidate = null
	var destination = null
	for worker in workers:
		if worker.assignment == from_activity and (change>0 or local_building==null or worker.assigned_home==local_building):
			var target_building=local_building if change>0 and local_building!=null else workplace_for(to_activity,worker.position)
			if not is_instance_valid(target_building) or workplace_capacity(target_building,to_activity)<=workplace_count(target_building,to_activity): continue
			if change>0 and route_to_cell(worker.position,target_building.door()).is_empty(): continue
			candidate = worker
			destination=target_building
			if worker.cargo == 0:
				break
	if candidate == null:
		if activity_count(from_activity)>0: notify("Sem posto acessível com vaga para esta atividade.")
		else: notify("Sem trabalhadores livres. Reduza outra atividade ou atraia colonos." if change > 0 else "Não há trabalhadores nesta atividade.")
		return false
	candidate.assign_to(to_activity, destination)
	notify("Distribuição atualizada. Quem já está entregando termina a viagem antes de trocar de função.")
	return true

func can_place(kind: String, origin: Vector2i) -> bool:
	placement_reason = ""
	if not kind in DATA.CONSTRUCTIBLE:
		return false
	if kind in ["gold_mining","smelter","trading_port"] and village_level<3:
		placement_reason="Evolua a base para o nível 3."
		return false
	if kind=="trading_port":
		port_preview=port_layout.inspect(origin,placement_orientation)
		placement_reason=port_preview.reason
		if placement_reason.is_empty() and not can_afford(DATA.ECONOMY.PORT_COST): placement_reason=cost_status(DATA.ECONOMY.PORT_COST)
		return placement_reason.is_empty()
	if not can_afford(DATA.BUILDINGS[kind].cost):
		placement_reason = cost_status(DATA.BUILDINGS[kind].cost)
		return false
	var footprint: Array[Vector2i] = []
	var reserved_footprints := {}
	for building in buildings:
		if building.preparing_site:
			for cell in building.footprint(): reserved_footprints[cell] = true
	var grid_size := DATA.building_size(kind)
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var cell := origin + Vector2i(x, y)
			if port_layout.reserved(cell):
				placement_reason="Este espaço está reservado para o porto e seus acessos."
				return false
			if land.get_cell_source_id(cell) < 0:
				placement_reason = "Há água sob a construção. Aterre toda a área de %d × %d células." % [grid_size.x,grid_size.y]
				return false
			if not is_walkable(cell):
				placement_reason = "Este terreno está ocupado por um prédio, recurso ou obra."
				return false
			footprint.append(cell)
	for source in sources + gardens:
		if not source.removed and source.cells.any(func(spot): return footprint.has(spot)):
			placement_reason = "Não construa sobre uma árvore ou recurso."
			return false
	for building in buildings:
		if building.footprint().any(func(c): return footprint.has(c)):
			placement_reason = "Este terreno está ocupado por um prédio, recurso ou obra."
			return false
	if footprint.any(func(c): return workers.any(func(w): return w.clear_destination == c)):
		placement_reason = "Este espaço está reservado para retirar materiais de uma obra."
		return false
	for job in jobs:
		if job.reserves_ground() and (footprint.has(job.door()) or job.cells.any(func(c): return footprint.has(c))):
			placement_reason = "Não bloqueie a entrada de uma obra."
			return false
	var door := origin + DATA.building_door(kind)
	if not is_walkable(door) or clearance.reserved(door) or port_layout.reserved(door):
		placement_reason = "A entrada precisa de um quadrado livre na frente."
		return false
	for building in buildings:
		if footprint.has(building.door()):
			placement_reason = "Não bloqueie a entrada de outro prédio."
			return false
	# Preserva circulação, entradas e acesso a recursos após cada obra.
	var reachable := {door: true}
	var pending: Array[Vector2i] = [door]
	while not pending.is_empty():
		var cell: Vector2i = pending.pop_back()
		for direction in CARDINALS:
			var neighbor: Vector2i = cell + direction
			if not reachable.has(neighbor) and not footprint.has(neighbor) and not reserved_footprints.has(neighbor) and is_walkable(neighbor):
				reachable[neighbor] = true
				pending.append(neighbor)
	for cell in land.get_used_cells():
		if is_walkable(cell) and not footprint.has(cell) and not reserved_footprints.has(cell) and not reachable.has(cell):
			placement_reason = "Este local bloquearia a passagem dos habitantes."
			return false
	for source in sources:
		if not source.blocks_ground():
			continue
		var accessible := false
		for cell in source.work_cells():
			if reachable.has(cell): accessible = true
		if not accessible:
			placement_reason = "Este local impediria o acesso a um recurso."
			return false
	return true

func place_building(kind: String, origin: Vector2i, repeat := false):
	if not can_place(kind, origin):
		notify(placement_reason)
		return null
	var building = add_building(kind, origin, false, placement_orientation if kind=="trading_port" else 0)
	clearance.prepare(building)
	rebuild_navigation()
	if not repeat: placement_kind = ""
	select_entity(building)
	notify("Obra marcada. Materiais serão transportados antes do trabalho do construtor.")
	return building

func begin_placement(kind: String) -> void:
	action_mode = ""
	if not kind in DATA.CONSTRUCTIBLE:
		return
	if placement_kind == kind:
		cancel_placement()
		return
	placement_kind = kind
	preview_texture = DATA.port_texture(placement_orientation) if kind=="trading_port" else DATA.building_texture(kind)
	preview_check_time = 0
	# Switching from surveying must not briefly present its old error as a
	# construction restriction, even while the simulation is paused.
	preview_cell = world_cell(get_global_transform_with_canvas().affine_inverse() * pointer_position) - placement_offset()
	preview_valid = can_place(kind, preview_cell)
	select_entity(null)
	notify("Escolha onde construir. Verde = permitido. Esc ou botão direito cancela.")

func cancel_placement() -> void:
	end_expansion_drag()
	action_mode = ""
	placement_kind = ""
	placement_overlay.queue_redraw()
	if is_instance_valid(hud):
		hud.refresh()

func select_entity(entity) -> void:
	if is_instance_valid(selection):
		selection.selected = false
		selection.queue_redraw()
	selection = entity
	if is_instance_valid(selection):
		selection.selected = true
		selection.queue_redraw()
	if is_instance_valid(hud):
		hud.refresh()

func notify(text: String) -> void:
	message = text
	message_time = 7.0
	if is_instance_valid(hud):
		hud.refresh()

func center_camera() -> void:
	if is_instance_valid(camera): camera.reset_view()

func _input(event: InputEvent) -> void:
	if event is InputEventMouse:
		pointer_position = event.position
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		end_expansion_drag()
	if event is InputEventKey and event.keycode == KEY_SHIFT and not event.pressed:
		end_expansion_drag()
	if event is InputEventMouseMotion and expansion_dragging:
		if not event.shift_pressed or not event.button_mask & MOUSE_BUTTON_MASK_LEFT or camera.input_blocked() or action_mode != "expand":
			end_expansion_drag()
		else:
			drag_expansion(event.position)
			get_viewport().set_input_as_handled()
			return
	if event is InputEventMouseButton and event.pressed and event.ctrl_pressed and action_mode == "expand" and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
		if camera.input_blocked() or hud.blocks_world_input(event.position): return
		expansion_brush_size = clampi(expansion_brush_size + (1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1),expansion_brush.MIN_SIZE,expansion_brush.MAX_SIZE)
		expansion_drag_point = Vector2.INF
		expansion_drag_cells.clear()
		update_expansion_preview()
		get_viewport().set_input_as_handled()
		return
	# Cancellation also works when the pointer is over a GUI panel.
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_placement()
		get_viewport().set_input_as_handled()

func entity_at(cell: Vector2i):
	for worker in workers:
		if worker.visible and Rect2(worker.position + Vector2(-8,-28), Vector2(16,32)).has_point(cell_center(cell)): return worker
	for pile in logistics.piles:
		if pile.cell == cell: return pile
	for job in jobs:
		if job.reserves_ground() and job.cells.has(cell): return job
	for index in range(buildings.size() - 1, -1, -1):
		if buildings[index].footprint().has(cell):
			return buildings[index]
	for source in sources + gardens:
		if not source.removed and source.cells.has(cell):
			return source
	return null

func rotate_port() -> void:
	if placement_kind!="trading_port": return
	placement_orientation=(placement_orientation+1)%4
	preview_texture=DATA.port_texture(placement_orientation)
	preview_valid=can_place(placement_kind,preview_cell)
	preview_check_time=0.1
	hud.refresh()
	placement_overlay.queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if event.echo: return
		# Native dialogs consume Esc themselves; never open another menu beneath one.
		for child in hud.get_children():
			if child is Window and child.visible: return
		if hud.residents_window.visible: hud.close_residents()
		elif hud.workforce_panel.visible: hud.toggle_workforce()
		elif not action_mode.is_empty() or not placement_kind.is_empty() or is_instance_valid(selection):
			cancel_placement()
			select_entity(null)
		else: hud.open_game_menu()
		get_viewport().set_input_as_handled()
		return
	if hud.residents_window.visible: return
	if camera.input_blocked(): return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_R: rotate_port()
			KEY_1: begin_placement("food")
			KEY_2: begin_placement("stone")
			KEY_3: begin_placement("wood")
			KEY_SPACE: simulation_paused = true if settlement.extinct else not simulation_paused
			KEY_HOME: center_camera()
			KEY_E: camera.smooth_zoom(1.12)
			KEY_Q: camera.smooth_zoom(1.0 / 1.12)
	if event is InputEventMouseMotion and event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
		camera.position -= event.relative / camera.zoom
	if event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: camera.change_zoom(1.12)
			MOUSE_BUTTON_WHEEL_DOWN: camera.change_zoom(1.0 / 1.12)
			MOUSE_BUTTON_RIGHT: cancel_placement()
			MOUSE_BUTTON_LEFT:
				if hud.blocks_world_input(event.position):
					return
				var cell := world_cell(get_global_transform_with_canvas().affine_inverse() * event.position)
				if action_mode.is_empty() and placement_kind.is_empty():
					var point: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
					for building in buildings:
						if building.warning_hit(point):
							select_entity(building)
							return
				if not action_mode.is_empty():
					if action_mode == "expand" and event.shift_pressed:
						expansion_dragging = true
						expansion_drag_point = Vector2.INF
						expansion_drag_cells.clear()
						drag_expansion(event.position)
						return
					place_job(action_mode, cell - action_offset(), false, event.shift_pressed)
					return
				var entity = entity_at(cell)
				if not placement_kind.is_empty():
					place_building(placement_kind, cell - placement_offset(), event.shift_pressed)
				elif is_instance_valid(entity):
					select_entity(entity)
				else:
					select_entity(null)

func _process(delta: float) -> void:
	if expansion_dragging and (camera.input_blocked() or not get_window().has_focus()): end_expansion_drag()
	if not simulation_paused and not settlement.extinct:
		clearance.tick()
		aid_cooldown = maxf(0, aid_cooldown - delta * simulation_speed)
		settlement.tick_moves()
		automation.tick(delta * simulation_speed)
		if process_mode != Node.PROCESS_MODE_DISABLED: saves.tick(delta)
		immigration.tick(delta * simulation_speed)
		commerce.tick()
		merchant.tick(delta * simulation_speed)
	message_time = maxf(0, message_time - delta)
	if not placement_kind.is_empty():
		var pointer_world := get_global_transform_with_canvas().affine_inverse() * pointer_position
		var next_cell := world_cell(pointer_world) - placement_offset()
		preview_check_time -= delta
		if next_cell != preview_cell or preview_check_time <= 0:
			preview_cell = next_cell
			preview_valid = can_place(placement_kind, preview_cell)
			preview_check_time = 0.1
	if not objective_complete and total_delivered.produce >= 10 and total_delivered.stone >= 10:
		objective_complete = true
		notify("Objetivo concluído! Sua vila já coleta e entrega comida e pedra automaticamente.")
	placement_overlay.queue_redraw()
	if not action_mode.is_empty():
		var next_cell := world_cell(get_global_transform_with_canvas().affine_inverse() * pointer_position) - action_offset()
		preview_check_time -= delta
		if next_cell != preview_cell or preview_check_time <= 0:
			preview_cell = next_cell
			preview_valid = can_place_job(action_mode, preview_cell)
			preview_check_time = 0.1
			if action_mode == "expand": hud.refresh()

func action_offset() -> Vector2i:
	return Vector2i(expansion_brush_size / 2,expansion_brush_size / 2) if action_mode == "expand" else Vector2i.ONE

func end_expansion_drag() -> void:
	expansion_dragging = false
	expansion_drag_point = Vector2.INF
	expansion_drag_cells.clear()

func drag_expansion(point: Vector2) -> void:
	if hud.blocks_world_input(point):
		expansion_drag_point = Vector2.INF
		return
	var start := point if expansion_drag_point == Vector2.INF else expansion_drag_point
	var steps := maxi(1,ceili(start.distance_to(point) / maxf(1.0,4.0 * camera.zoom.x)))
	var transform := get_global_transform_with_canvas().affine_inverse()
	for step in range(steps + 1):
		var sample := start.lerp(point,float(step)/steps)
		if hud.blocks_world_input(sample): continue
		var cell := world_cell(transform * sample) - action_offset()
		if expansion_drag_cells.has(cell): continue
		expansion_drag_cells[cell] = true
		# Invalid positions update the preview, without a notification per frame.
		if can_place_job("expand",cell): place_job("expand",cell,false,true)
	expansion_drag_point = point
	update_expansion_preview()

func update_expansion_preview() -> void:
	preview_cell = world_cell(get_global_transform_with_canvas().affine_inverse() * pointer_position) - action_offset()
	preview_valid = can_place_job("expand",preview_cell)
	preview_check_time = 0.1
	placement_overlay.queue_redraw()
	hud.refresh()

func placement_offset() -> Vector2i:
	var size := DATA.building_size(placement_kind)
	return Vector2i(size.x / 2, size.y / 2)

func draw_placement() -> void:
	if not action_mode.is_empty():
		if not hud.blocks_world_input(pointer_position):
			var color := Color("a6d887") if preview_valid else Color("f2847c")
			if action_mode == "expand":
				for cell in expansion_preview.get("cells",[]):
					var rect := Rect2(Vector2(cell*16),Vector2(16,16))
					placement_overlay.draw_rect(rect,Color(color,0.4))
					placement_overlay.draw_rect(rect,color,false,0.5)
				placement_overlay.draw_rect(Rect2(Vector2(preview_cell*16),Vector2.ONE*expansion_brush_size*16),color,false,1)
				return
			placement_overlay.draw_rect(Rect2(Vector2(preview_cell * 16), Vector2(32,32) if action_mode == "garden" else Vector2(48,64 if action_mode in ["plant","plant_wood"] else 48)), Color(color,0.4))
		return
	if placement_kind.is_empty() or hud.blocks_world_input(pointer_position):
		return
	var color := Color("a6d887") if preview_valid else Color("f2847c")
	var origin := Vector2(preview_cell * 16)
	if placement_kind=="trading_port":
		if preview_texture!=null: placement_overlay.draw_texture_rect(preview_texture,DATA.building_art_rect(placement_kind,preview_cell,preview_texture),false,Color(1,1,1,0.7))
		for cell in port_preview.get("cells",{}):
			var valid: bool=port_preview.cells[cell]
			var cell_color := Color("a6d887") if valid else Color("f2847c")
			var rect := Rect2(Vector2(cell*16),Vector2(16,16))
			placement_overlay.draw_rect(rect,Color(cell_color,0.22))
			placement_overlay.draw_rect(rect,cell_color,false,0.5)
		var mask: Dictionary=port_layout.layout(preview_cell,placement_orientation)
		var start := cell_center(mask.loading)
		var end := cell_center(mask.dock)
		placement_overlay.draw_line(start,end,Color("ffeab5"),1)
		placement_overlay.draw_circle(start,4,Color("ffeab5"))
		var direction: Vector2=Vector2(mask.direction)
		var side := Vector2(-direction.y,direction.x)
		placement_overlay.draw_line(end,end-direction*6+side*4,Color("ffeab5"),1)
		placement_overlay.draw_line(end,end-direction*6-side*4,Color("ffeab5"),1)
		return
	var grid_size := DATA.building_size(placement_kind)
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var rect := Rect2(origin + Vector2(x, y) * 16, Vector2(16, 16))
			var cell := preview_cell + Vector2i(x,y)
			var occupied := not is_walkable(cell)
			occupied = occupied or buildings.any(func(b): return b.footprint().has(cell))
			occupied = occupied or workers.any(func(w): return w.clear_destination == cell)
			for source in sources + gardens:
				if not source.removed and source.cells.has(cell): occupied = true
			var cell_color := Color("f2847c") if occupied else Color("a6d887")
			if not occupied and (logistics.piles.any(func(p): return p.cell == cell) or workers.any(func(w): return world_cell(w.position) == cell)): cell_color = Color("e8be78")
			placement_overlay.draw_rect(rect, Color(cell_color, 0.28))
			placement_overlay.draw_rect(rect, Color(cell_color, 0.8), false, 0.5)
	var entry := cell_center(preview_cell + DATA.building_door(placement_kind))
	if preview_texture != null:
		placement_overlay.draw_texture_rect(preview_texture,DATA.building_art_rect(placement_kind,preview_cell,preview_texture),false,Color(color,0.7))
	var entry_color := Color("a6d887") if is_walkable(preview_cell + DATA.building_door(placement_kind)) else Color("f2847c")
	placement_overlay.draw_rect(Rect2(entry-Vector2(8,8),Vector2(16,16)),entry_color,false,1)
	placement_overlay.draw_circle(entry, 4, entry_color)
	placement_overlay.draw_line(entry + Vector2(0, 3), entry + Vector2(0, 10), entry_color, 1)

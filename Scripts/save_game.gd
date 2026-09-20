extends RefCounted
const PATH = "user://civilization_v005.save"
var game
var autosave_elapsed := 0.0

func fields(object, names: Array) -> Dictionary:
	var result := {}
	for name in names: result[name] = object.get(name)
	return result

func snapshot() -> Dictionary:
	var data := {"version": 5, "land": [], "buildings": [], "sources": [], "jobs": [], "workers": [], "piles": [], "gardens": []}
	data.merge(fields(game, ["village_level", "planted_count", "expansion_count", "aid_cooldown", "total_delivered", "objective_complete"]))
	data.policy = fields(game.automation, ["stock_targets", "orchards"])
	data.gold=game.gold.snapshot()
	data.merchant=game.merchant.snapshot()
	data.commerce=game.commerce.snapshot()
	data.immigration = fields(game.immigration, ["elapsed", "expedition", "sailing", "voyage", "dock", "departure", "arrivals", "position"])
	data.camera = {"position": game.camera.position, "zoom": game.camera.zoom}
	data.next_id = game.settlement.next_id
	for cell in game.land.get_used_cells(): data.land.append([cell, game.land.get_cell_source_id(cell), game.land.get_cell_atlas_coords(cell), game.land.get_cell_alternative_tile(cell)])
	for building in game.buildings:
		var item := fields(building, ["kind", "origin", "completed", "progress", "stored", "delivered", "level", "upgrading", "tool_targets", "tool_orders", "craft_progress", "crafting", "priority", "entity_id", "work_started", "preparing_site", "demolition_requested", "demolition_started", "demolition_progress"])
		item.materials = {"required": building.materials.required, "delivered": building.materials.delivered}
		item.smelting_batches=building.smelting_batches.duplicate(true)
		if building.kind=="trading_port": item.orientation=building.orientation
		for batch in item.smelting_batches: batch.worker=0
		data.buildings.append(item)
	for source in game.sources: data.sources.append(fields(source, ["is_tree", "is_timber", "is_quarry", "resource_kind", "origin", "stage", "age", "remaining", "removed", "initial_reserve", "cut_requested", "cut_started"]))
	for job in game.jobs:
		var item := fields(job, ["kind", "origin", "entry_cell", "activity", "completed", "progress", "duration", "priority", "deposit", "released"])
		item.deposit_resource=job.deposit_resource
		if job.kind == "expand": item.merge(fields(job,["cells","brush_size","discovery_eligible"]))
		item.materials = {"required": job.materials.required, "delivered": job.materials.delivered}
		data.jobs.append(item)
	for garden in game.gardens:
		var item := fields(garden, ["origin", "phase", "preparing_site", "entity_id", "activity", "age", "remaining", "progress", "priority", "auto_replant", "first_plant_pending", "completed"])
		item.materials = {"required": garden.materials.required, "delivered": garden.materials.delivered}
		data.gardens.append(item)
	for worker in game.workers:
		var item := fields(worker, ["position", "assignment", "cargo", "cargo_resource", "spare_tools", "clear_destination", "clear_site_id"])
		item.trade_id=worker.trade_id
		item.trade_leg=worker.trade_leg
		item.home = game.buildings.find(worker.assigned_home)
		item.residence = game.buildings.find(worker.residence)
		item.move_destination = game.buildings.find(worker.move_destination)
		item.person = fields(worker.person, ["id", "appearance_id", "display_name", "profession", "experience", "energy", "nutrition", "starvation", "residence_id", "is_king", "is_adult", "tool", "durability"])
		data.workers.append(item)
	for pile in game.logistics.piles: data.piles.append({"cell": pile.cell, "resource": pile.resource_kind, "amount": pile.stored[pile.resource_kind],"trade_id":pile.trade_id,"trade_leg":pile.trade_leg})
	return data

func save_file(path := "") -> bool:
	if path.is_empty():
		var slots = game.get_node("/root/IslandSaves")
		var saved: bool = slots.save_active(snapshot())
		game.notify("Partida salva." if saved else slots.error)
		return saved
	var payload := var_to_bytes(snapshot())
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		game.notify("Não foi possível salvar a partida.")
		return false
	file.store_var({"version": 5, "payload": payload, "digest": payload.hex_encode().sha256_text()})
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"): DirAccess.remove_absolute(path + ".bak")
		if DirAccess.rename_absolute(path, path + ".bak") != OK: return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		if FileAccess.file_exists(path + ".bak"): DirAccess.rename_absolute(path + ".bak", path)
		return false
	game.notify("Partida salva.")
	return true

func load_file(path := "") -> bool:
	if path.is_empty():
		var slots = game.get_node("/root/IslandSaves")
		var data: Dictionary = slots.load_active()
		if data.is_empty():
			game.notify(slots.error)
			return false
		restore(data)
		game.notify("Partida restaurada. Os habitantes reorganizam suas tarefas.")
		return true
	if not FileAccess.file_exists(path):
		game.notify("Nenhuma partida salva.")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var envelope = file.get_var(false)
	file.close()
	if not envelope is Dictionary or envelope.get("version") != 5 or not envelope.get("payload") is PackedByteArray: return invalid_save()
	var payload: PackedByteArray = envelope.payload
	if envelope.get("digest") != payload.hex_encode().sha256_text(): return invalid_save()
	var data = bytes_to_var(payload)
	if not valid(data): return invalid_save()
	restore(data)
	game.notify("Partida restaurada. Os habitantes reorganizam suas tarefas.")
	return true

func invalid_save() -> bool:
	game.notify("Arquivo de partida inválido. A vila atual foi preservada.")
	return false

func valid(data) -> bool:
	if not data is Dictionary or data.get("version") != 5: return false
	if data.has("gold") and not valid_gold(data.gold): return false
	if data.has("merchant") and not preload("res://Scripts/merchant.gd").valid(data.merchant): return false
	if data.has("commerce") and not preload("res://Scripts/commerce.gd").valid(data.commerce): return false
	for key in ["land", "buildings", "sources", "jobs", "workers", "piles", "gardens"]:
		if not data.get(key) is Array: return false
	for key in ["village_level", "planted_count", "expansion_count", "next_id"]:
		if not data.get(key) is int: return false
	for key in ["aid_cooldown"]:
		if not (data.get(key) is float or data.get(key) is int): return false
	if not data.get("total_delivered") is Dictionary: return false
	if not data.get("objective_complete") is bool: return false
	if data.land.is_empty() or data.land.size()>262144: return false
	for tile in data.land:
		if not tile is Array or tile.size()!=4 or not tile[0] is Vector2i or not tile[1] is int or not tile[2] is Vector2i or not tile[3] is int: return false
	for collection in ["buildings","sources","jobs","workers","piles","gardens"]:
		for item in data[collection]:
			if not item is Dictionary: return false
	for collection in ["buildings","jobs","gardens"]:
		for item in data[collection]:
			if not item.get("materials") is Dictionary: return false
			for field in ["required","delivered"]:
				if not item.materials.get(field) is Dictionary: return false
	for item in data.sources:
		if not item.get("origin") is Vector2i or not item.get("stage") is int or item.stage<0 or item.stage>6: return false
		if not item.get("is_tree") is bool or not item.get("is_quarry") is bool: return false
	for item in data.piles:
		if not item.get("cell") is Vector2i or not preload("res://Scripts/game_data.gd").RESOURCES.has(item.get("resource")) or not item.get("amount") is int: return false
		if item.has("trade_id") and (not item.trade_id is int or item.trade_id<0 or item.get("trade_leg") not in ["","input","receipt"]): return false
	for key in ["policy","immigration","camera"]:
		if not data.get(key) is Dictionary: return false
	if not data.policy.get("orchards") is Array or not data.policy.get("stock_targets") is Dictionary: return false
	if not data.camera.get("position") is Vector2 or not data.camera.get("zoom") is Vector2: return false
	if data.buildings.is_empty() or data.buildings[0].get("kind") != "base": return false
	if data.has("merchant") and data.merchant.state!="waiting":
		if not data.buildings.any(func(b): return b.get("kind")=="trading_port" and b.get("entity_id")==data.merchant.port_id and b.get("completed",false)): return false
	for item in data.sources:
		if not item is Dictionary: return false
		for field in ["cut_requested","cut_started","is_timber"]:
			if item.has(field) and not item[field] is bool: return false
		if item.get("cut_started",false) and (not item.get("cut_requested",false) or item.get("stage") != 6): return false
		if item.get("cut_requested",false) and (not item.get("is_tree",false) or item.get("stage") not in [4,6]): return false
		if item.get("is_timber",false) and (not item.get("is_tree",false) or item.get("cut_requested",false) or item.get("stage") > preload("res://Scripts/game_data.gd").TIMBER_MATURE_STAGE): return false
	for item in data.buildings:
		if not preload("res://Scripts/game_data.gd").BUILDINGS.has(item.get("kind", "")) or not item.get("origin") is Vector2i or not item.get("stored") is Dictionary: return false
		if item.get("kind")=="trading_port":
			if not item.get("orientation") is int or item.orientation<0 or item.orientation>3: return false
			if data.buildings.filter(func(b): return b.get("kind")=="trading_port").size()>1: return false
		for resource in ["gold_ore","gold_bar"]:
			if item.stored.has(resource) and (not item.stored[resource] is int or item.stored[resource]<0): return false
		if item.get("kind")=="smelter":
			if not item.get("smelting_batches") is Array or item.smelting_batches.size()!=2: return false
			var active := 0
			for batch in item.smelting_batches:
				if not batch is Dictionary or not batch.get("active") is bool: return false
				if not batch.get("worker") is int or batch.worker<0: return false
				if not (batch.get("progress") is int or batch.get("progress") is float): return false
				if not is_finite(batch.progress) or batch.progress<0 or batch.progress>=15: return false
				if not batch.active and batch.progress!=0: return false
				if batch.active: active+=1
			for resource in preload("res://Scripts/economy_data.gd").SMELTER_CAPS:
				if item.stored.get(resource,0)+(active if resource=="gold_bar" else 0)>preload("res://Scripts/economy_data.gd").SMELTER_CAPS[resource]: return false
		if item.get("kind") == "base" and item.get("demolition_requested", false): return false
		if item.has("preparing_site") and (not item.preparing_site is bool or (item.preparing_site and item.get("completed",false))): return false
	for item in data.jobs:
		if not item is Dictionary: return false
		if item.get("kind") == "expand" and item.has("cells"):
			var size: int = item.get("brush_size",3)
			if size < 1 or size > 9 or not item.get("origin") is Vector2i: return false
			if not item.cells is Array or item.cells.is_empty() or item.cells.size() > size*size: return false
			var seen := {}
			for cell in item.cells:
				if not cell is Vector2i or seen.has(cell) or not Rect2i(item.origin,Vector2i(size,size)).has_point(cell): return false
				seen[cell] = true
	for item in data.gardens:
		if not item is Dictionary or not item.get("origin") is Vector2i: return false
		if item.get("phase") not in ["installing", "planting", "growing", "ripe", "empty"]: return false
		if not item.get("materials") is Dictionary: return false
		if not item.materials.get("required") is Dictionary or not item.materials.get("delivered") is Dictionary: return false
		if item.get("remaining", -1) < 0 or item.remaining > preload("res://Scripts/game_data.gd").GARDEN_YIELD: return false
	for item in data.workers:
		if not item.get("position") is Vector2 or not item.get("residence") is int: return false
		if item.has("trade_id") and (not item.trade_id is int or item.trade_id<0 or item.get("trade_leg") not in ["","input","receipt"]): return false
		if not preload("res://Scripts/game_data.gd").ACTIVITIES.has(item.get("assignment", "")) or not item.get("person") is Dictionary: return false
		if not item.person.get("appearance_id") is int: return false
		if item.get("home", -1) < 0 or item.home >= data.buildings.size(): return false
		if item.has("clear_destination") and not item.clear_destination is Vector2i: return false
		if item.has("clear_site_id") and not item.clear_site_id is int: return false
	return data.has("policy") and data.has("immigration") and data.has("camera") and data.has("next_id")

func valid_gold(data) -> bool:
	if not data is Dictionary or not data.get("rng_state") is int or not data.get("discoveries") is Dictionary: return false
	if data.has("rng_seed") and not data.rng_seed is int: return false
	if not data.get("initial_stones") is int or data.initial_stones<0 or data.initial_stones>3 or not data.get("protection_used") is bool: return false
	for origin in data.discoveries:
		var record=data.discoveries[origin]
		if not origin is Vector2i or not record is Dictionary: return false
		if record.get("resource") not in ["stone","gold_ore"] or not record.get("reserve") is int or record.reserve<0: return false
		if record.get("state") not in ["surveyed","opened","released","exhausted"]: return false
	return true

func apply(object, values: Dictionary, except: Array = []) -> void:
	for key in values:
		if not except.has(key): object.set(key, values[key])

func restore(data: Dictionary) -> void:
	game.select_entity(null)
	game.cancel_placement()
	game.hud.close_residents()
	game.hud.policy_window.hide()
	game.hud.trade_window.hide()
	game.work_planner.claims.clear()
	game.logistics.tickets.clear()
	game.commerce.orders.clear()
	game.commerce.requests.clear()
	game.commerce.transfer_targets.clear()
	for collection in [game.workers, game.buildings, game.sources, game.jobs, game.gardens, game.logistics.piles]:
		for node in collection: node.free()
		collection.clear()
	game.land.clear()
	for tile in data.land: game.land.set_cell(tile[0], tile[1], tile[2], tile[3])
	for key in ["village_level", "planted_count", "expansion_count", "aid_cooldown", "total_delivered", "objective_complete"]: game.set(key, data[key])
	for item in data.buildings:
		var building = game.add_building(item.kind, item.origin, true, item.get("orientation",0))
		apply(building, item, ["materials"])
		for batch in building.smelting_batches: batch.worker=0
		for resource in game.DATA.RESOURCES:
			if not building.stored.has(resource): building.stored[resource]=0
		apply(building.materials, item.materials)
		building.refresh_visual()
	game.base = game.buildings[0]
	for item in data.sources:
		var source = game.SOURCE.new()
		game.entities.add_child(source)
		if item.get("is_timber",false): source.setup_timber(game, item.origin, item.stage)
		elif item.is_tree: source.setup_tree(game, item.origin, item.stage)
		elif item.is_quarry: source.setup_quarry(game, item.origin, item.initial_reserve)
		else:
			var layer = preload("res://Scripts/game_data.gd").CATALOG.resource_layer("Stone", item.origin)
			source.setup(game, layer, layer.get_used_cells(), "stone")
			layer.free()
		apply(source, item)
		if source.removed: source.terrain_visual.hide()
		game.sources.append(source)
	for item in data.jobs:
		var job = game.JOB.new()
		job.setup(game, item.kind, item.origin, item.entry_cell)
		apply(job, item, ["materials","cells"])
		if item.has("cells"): job.cells.assign(item.cells)
		apply(job.materials, item.materials)
		game.entities.add_child(job)
		game.jobs.append(job)
	for item in data.get("gardens", []):
		var garden = game.GARDEN.new()
		garden.setup_garden(game, item.origin)
		apply(garden, item, ["materials"])
		apply(garden.materials, item.materials)
		game.entities.add_child(garden)
		game.gardens.append(garden)
	game.rebuild_navigation()
	for item in data.workers:
		var worker = game.spawn_worker(item.assignment, game.buildings[item.home], item.position)
		apply(worker, item, ["home", "person", "residence", "move_destination"])
		apply(worker.person, item.person)
		worker.residence = game.buildings[item.residence] if item.residence >= 0 and item.residence < game.buildings.size() else null
		worker.move_destination = game.buildings[item.move_destination] if item.get("move_destination", -1) >= 0 and item.move_destination < game.buildings.size() else null
		worker.refresh_appearance()
	for item in data.piles: game.logistics.drop(item.cell, item.resource, item.amount,item.get("trade_id",0),item.get("trade_leg",""))
	game.gold.restore(data.get("gold",{}))
	game.merchant.restore(data.get("merchant",{}))
	game.commerce.restore(data.get("commerce",{}))
	game.settlement.next_id = data.next_id
	game.settlement.extinct = game.workers.is_empty()
	apply(game.automation, data.policy, ["orchards"])
	game.automation.orchards.assign(data.policy.orchards)
	apply(game.immigration, data.immigration)
	apply(game.camera, data.camera)
	game.camera.zoom_target = -1.0
	game.hud.extinct_shown = false
	game.hud.extinction_panel.hide()
	game.hud.residents_shade.hide()
	game.simulation_paused = game.settlement.extinct
	game.hud.refresh()

func tick(delta: float) -> void:
	autosave_elapsed += delta
	if autosave_elapsed >= 120:
		autosave_elapsed = 0
		save_file()

extends RefCounted
const PATH = "user://civilization_v004.save"
var game
var autosave_elapsed := 0.0

func fields(object, names: Array) -> Dictionary:
	var result := {}
	for name in names: result[name] = object.get(name)
	return result

func snapshot() -> Dictionary:
	var data := {"version": 4, "land": [], "buildings": [], "sources": [], "jobs": [], "workers": [], "piles": []}
	data.merge(fields(game, ["village_level", "planted_count", "expansion_count", "aid_cooldown", "total_delivered", "objective_complete"]))
	data.policy = fields(game.automation, ["stock_targets", "population_target", "orchards"])
	data.immigration = fields(game.immigration, ["elapsed", "expedition", "sailing", "voyage", "dock", "departure", "arrivals", "position"])
	data.camera = {"position": game.camera.position, "zoom": game.camera.zoom}
	data.next_id = game.settlement.next_id
	for cell in game.land.get_used_cells(): data.land.append([cell, game.land.get_cell_source_id(cell), game.land.get_cell_atlas_coords(cell), game.land.get_cell_alternative_tile(cell)])
	for building in game.buildings:
		var item := fields(building, ["kind", "origin", "completed", "progress", "stored", "delivered", "level", "upgrading", "tool_targets", "tool_orders", "craft_progress", "crafting", "priority"])
		item.materials = {"required": building.materials.required, "delivered": building.materials.delivered}
		data.buildings.append(item)
	for source in game.sources: data.sources.append(fields(source, ["is_tree", "is_quarry", "origin", "stage", "age", "remaining", "removed", "initial_reserve"]))
	for job in game.jobs:
		var item := fields(job, ["kind", "origin", "entry_cell", "activity", "completed", "progress", "duration", "priority", "deposit", "released"])
		item.materials = {"required": job.materials.required, "delivered": job.materials.delivered}
		data.jobs.append(item)
	for worker in game.workers:
		var item := fields(worker, ["position", "assignment", "cargo", "cargo_resource", "spare_tools"])
		item.home = game.buildings.find(worker.assigned_home)
		item.residence = game.buildings.find(worker.residence)
		item.person = fields(worker.person, ["id", "appearance_id", "display_name", "profession", "experience", "energy", "nutrition", "starvation", "residence_id", "is_king", "is_adult", "tool", "durability"])
		data.workers.append(item)
	for pile in game.logistics.piles: data.piles.append({"cell": pile.cell, "resource": pile.resource_kind, "amount": pile.stored[pile.resource_kind]})
	return data

func save_file(path := PATH) -> bool:
	var payload := var_to_bytes(snapshot())
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		game.notify("Não foi possível salvar a partida.")
		return false
	file.store_var({"version": 4, "payload": payload, "digest": payload.hex_encode().sha256_text()})
	file.close()
	if FileAccess.file_exists(path):
		if FileAccess.file_exists(path + ".bak"): DirAccess.remove_absolute(path + ".bak")
		if DirAccess.rename_absolute(path, path + ".bak") != OK: return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		if FileAccess.file_exists(path + ".bak"): DirAccess.rename_absolute(path + ".bak", path)
		return false
	game.notify("Partida salva.")
	return true

func load_file(path := PATH) -> bool:
	if not FileAccess.file_exists(path):
		game.notify("Nenhuma partida salva.")
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return false
	var envelope = file.get_var(false)
	file.close()
	if not envelope is Dictionary or envelope.get("version") != 4 or not envelope.get("payload") is PackedByteArray: return invalid_save()
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
	if not data is Dictionary or data.get("version") != 4: return false
	for key in ["land", "buildings", "sources", "jobs", "workers", "piles"]:
		if not data.get(key) is Array: return false
	if data.buildings.is_empty() or data.buildings[0].get("kind") != "base": return false
	for item in data.buildings:
		if not game.DATA.BUILDINGS.has(item.get("kind", "")) or not item.get("origin") is Vector2i or not item.get("stored") is Dictionary: return false
	for item in data.workers:
		if not game.DATA.ACTIVITIES.has(item.get("assignment", "")) or not item.get("person") is Dictionary: return false
		if item.get("home", -1) < 0 or item.home >= data.buildings.size(): return false
	return data.has("policy") and data.has("immigration") and data.has("camera") and data.has("next_id")

func apply(object, values: Dictionary, except: Array = []) -> void:
	for key in values:
		if not except.has(key): object.set(key, values[key])

func restore(data: Dictionary) -> void:
	game.select_entity(null)
	game.cancel_placement()
	game.hud.close_residents()
	game.hud.policy_window.hide()
	game.work_planner.claims.clear()
	game.logistics.tickets.clear()
	for collection in [game.workers, game.buildings, game.sources, game.jobs, game.logistics.piles]:
		for node in collection: node.free()
		collection.clear()
	game.land.clear()
	for tile in data.land: game.land.set_cell(tile[0], tile[1], tile[2], tile[3])
	for key in ["village_level", "planted_count", "expansion_count", "aid_cooldown", "total_delivered", "objective_complete"]: game.set(key, data[key])
	for item in data.buildings:
		var building = game.add_building(item.kind, item.origin, true)
		apply(building, item, ["materials"])
		apply(building.materials, item.materials)
		building.refresh_visual()
	game.base = game.buildings[0]
	for item in data.sources:
		var source = game.SOURCE.new()
		game.entities.add_child(source)
		if item.is_tree: source.setup_tree(game, item.origin, item.stage)
		elif item.is_quarry: source.setup_quarry(game, item.origin, item.initial_reserve)
		else:
			var layer = game.DATA.CATALOG.resource_layer("Stone", item.origin)
			source.setup(game, layer, layer.get_used_cells(), "stone")
			layer.free()
		apply(source, item)
		if source.removed: source.terrain_visual.hide()
		game.sources.append(source)
	for item in data.jobs:
		var job = game.JOB.new()
		job.setup(game, item.kind, item.origin, item.entry_cell)
		apply(job, item, ["materials"])
		apply(job.materials, item.materials)
		game.entities.add_child(job)
		game.jobs.append(job)
	game.rebuild_navigation()
	for item in data.workers:
		var worker = game.spawn_worker(item.assignment, game.buildings[item.home], item.position)
		apply(worker, item, ["home", "person", "residence"])
		apply(worker.person, item.person)
		worker.residence = game.buildings[item.residence] if item.residence >= 0 and item.residence < game.buildings.size() else null
		worker.refresh_appearance()
	for item in data.piles: game.logistics.drop(item.cell, item.resource, item.amount)
	game.settlement.next_id = data.next_id
	game.settlement.extinct = game.workers.is_empty()
	apply(game.automation, data.policy, ["orchards"])
	game.automation.orchards.assign(data.policy.orchards)
	apply(game.immigration, data.immigration)
	apply(game.camera, data.camera)
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

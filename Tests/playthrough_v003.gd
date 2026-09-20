extends SceneTree
var game
var requested := {}
var errors: Array[String] = []
var seconds := 0
var rested: Dictionary = {}
var captured_boat := false
var captured_rest := false
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
	if not value:
		errors.append(text)
		push_error(text)
func tick(amount: float) -> void:
	for i in range(ceili(amount / 0.1)):
		game._process(0.1)
		for source in game.sources.duplicate(): source._process(0.1)
		for worker in game.workers.duplicate():
			worker._process(0.1)
			if worker.state == "resting": rested[worker.person.id] = true
func construct(kind: String) -> void:
	if requested.has(kind) or not game.can_afford(game.DATA.BUILDINGS[kind].cost): return
	for cell in game.land.get_used_cells():
		if game.can_place(kind,cell):
			requested[kind] = game.place_building(kind,cell)
			print(seconds,"s: order ",kind," at ",cell)
			return
func plant_orchard() -> void:
	if not game.can_afford(game.DATA.PLANT_COST): return
	var growing := 0
	for source in game.sources:
		if source.is_tree and not source.removed and source.stage < 6: growing += 1
	for job in game.jobs:
		if job.kind == "plant" and not job.completed: growing += 1
	if growing >= 3: return
	for cell in game.land.get_used_cells():
		if game.can_place_job("plant",cell):
			game.place_job("plant",cell)
			game.automation.toggle_orchard(cell)
			return
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	game.hud.refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	for step in range(240):
		seconds = step * 5
		construct("house")
		construct("warehouse")
		construct("food")
		construct("workshop")
		plant_orchard()
		if requested.has("workshop") and requested.workshop.completed:
			var workshop = requested.workshop
			if workshop.level == 1 and game.can_afford(workshop.upgrade_cost()): workshop.upgrade()
			for tool in ["axe", "pickaxe"]:
				if workshop.level == 1 and game.stock[tool] == 0 and workshop.tool_orders[tool] == 0: workshop.order_tool(tool,2)
		for worker in game.workers:
			if worker.assignment != "idle": continue
			if game.activity_count("stone") == 0: worker.assign_to("stone",game.workplace_for("stone"))
			elif game.activity_count("workshop") == 0 and game.workplace_for("workshop") != null: worker.assign_to("workshop",game.workplace_for("workshop"))
			elif game.village_level >= 2 and game.activity_count("carrier") == 0: worker.assign_to("carrier",game.base)
			else: worker.assign_to("food",game.workplace_for("food"))
		if game.upgrade_ready() and game.planted_count >= 2:
			game.upgrade_village()
			print(seconds,"s: evolved to ",game.village_level)
		if game.village_level >= 2 and game.expansion_count < 4 and game.can_afford(game.DATA.EXPAND_COST):
			var pending: Array = game.jobs.filter(func(j): return j.kind == "expand" and not j.completed)
			if pending.is_empty():
				var locations := [Vector2i(71,27),Vector2i(74,27),Vector2i(71,30),Vector2i(74,30)]
				game.place_job("expand",locations[game.expansion_count])
		if requested.has("house") and requested.house.completed and game.workers.size() == game.population_limit() and game.can_afford(game.DATA.HOUSE_UPGRADE_COST): requested.house.upgrade()
		tick(5)
		for worker in game.workers:
			check(game.is_walkable(game.world_cell(worker.position)), "Resident remains on walkable ground")
		for building in game.buildings:
			check(building.used() <= building.capacity(), "Storage never overflows")
		if seconds % 120 == 0: print(seconds,"s: pop=",game.workers.size()," stock=",game.stock," planted=",game.planted_count)
		if game.immigration.sailing and not captured_boat:
			captured_boat = true
			game.select_entity(game.base)
			await capture("v003_boat")
		if not captured_rest:
			for worker in game.workers:
				if worker.state == "resting":
					captured_rest = true
					game.select_entity(worker.residence)
					game.hud.open_residents(worker.residence)
					await capture("v003_rest")
					game.hud.close_residents()
					break
		if seconds == 300:
			game.select_entity(requested.get("house"))
			await capture("v003_colony")
		if game.settlement.extinct: break
	game.select_entity(null)
	await capture("v003_village")
	check(not rested.is_empty(), "Natural work cycle includes automatic rest")
	check(game.village_level == 3, "Natural economy reaches level 3")
	check(game.workers.size() >= 6, "Natural immigration grows population")
	check(game.expansion_count >= 2 and game.planted_count >= 5, "Tree renewal and expansion remain sustainable")
	check(requested.has("workshop") and requested.workshop.completed and game.stock.axe > 0, "Working workshop maintains tools")
	print("20-minute natural playthrough: level=",game.village_level," population=",game.workers.size()," expansions=",game.expansion_count," orchards=",game.planted_count," rested=",rested.size()," errors=",errors.size())
	for worker in game.workers: print(worker.person.display_name," ",worker.state," ",worker.status," energy=",worker.person.energy)
	game.free()
	quit(0 if errors.is_empty() else 1)


extends "res://Tests/test_site_clearance.gd"

func run() -> void:
	fresh()
	stop_workers()
	rich()
	var cell := Vector2i(59,24)
	var pile_cell := cell + Vector2i.ONE
	game.logistics.drop(pile_cell,"axe",4)
	game.logistics.drop(pile_cell,"pickaxe",9)
	var worker = game.workers[0]
	worker.assign_to("builder",game.base)
	var pile = game.logistics.piles[0]
	worker.ticket = game.logistics.reserve(worker,pile,game.base,"axe",4,false)
	worker.state = "to_pickup"
	worker.path = game.route_to_cell(worker.position,pile_cell)
	var house = game.place_building("house",cell)
	check(worker.ticket.is_empty(),"Old unpicked reservations are released for site clearing")
	var a: int = total("axe")
	var p: int = total("pickaxe")
	for step in 700:
		tick(0.1)
		if not house.preparing_site: break
	check(not house.preparing_site and total("axe") == a and total("pickaxe") == p,"Multiple resource stacks on one cell are preserved")
	check(game.logistics.piles.all(func(item): return not house.footprint().has(item.cell)),"All stacks cleared before ground closes")
	# Save while pickup is still uncollected, then complete through the normal loop.
	fresh()
	stop_workers()
	rich()
	game.logistics.drop(pile_cell,"axe",11)
	house = game.place_building("house",cell)
	worker = game.workers[1]
	worker.assign_to("builder",game.base)
	worker.find_job()
	check(worker.clear_site_id == house.entity_id and worker.cargo == 0,"Clearance task can wait before pickup")
	a = total("axe")
	check(game.saves.save_file("res://Tests/clearance_edge.save") and game.saves.load_file("res://Tests/clearance_edge.save"),"Unpicked clearing task reloads safely")
	house = game.buildings.filter(func(b): return b.kind == "house")[0]
	tick(150)
	check(house.completed and total("axe") == a,"Loaded clearing task resumes and construction completes without duplicates")
	# A tired resident leaves and resumes rest; no profession change.
	fresh()
	stop_workers()
	rich()
	worker = game.workers[0]
	worker.position = game.cell_center(cell+Vector2i(1,1))
	worker.person.energy = 2
	house = game.place_building("house",cell)
	tick(15)
	check(not house.preparing_site and not house.footprint().has(game.world_cell(worker.position)),"Exhausted resident still exits the reserved footprint")
	check(worker.assignment == "idle","Evacuation preserves idle allocation")
	# Gardens also relocate loose materials without altering tree/stone source rules.
	fresh()
	stop_workers()
	rich()
	var food = game.add_building("food",Vector2i(42,23),true)
	food.level = 2
	cell = Vector2i(58,29)
	game.logistics.drop(cell,"axe",9)
	game.workers[0].position = game.cell_center(cell+Vector2i.ONE)
	check(game.can_place_garden(cell),"Garden can be marked over loose items and a resident")
	var garden = game.place_job("garden",cell)
	check(garden != null and garden.preparing_site,"Garden waits for physical preparation")
	check(not game.can_place_job("plant",cell),"Tree job cannot overlap a preparing garden")
	a = total("axe")
	game.workers[1].assign_to("builder",game.base)
	game.workers[2].assign_to("food",food)
	check(game.saves.save_file("res://Tests/clearance_edge.save") and game.saves.load_file("res://Tests/clearance_edge.save"),"Preparing garden survives save/load")
	garden = game.gardens[0]
	check(garden.preparing_site and garden.entity_id < 0,"Garden clearance keeps its distinct site identity")
	tick(120)
	check(not garden.preparing_site and garden.completed and total("axe") == a,"Garden preparation finishes before installation with conserved items")
	check(game.saves.save_file("res://Tests/clearance_edge.save") and game.saves.load_file("res://Tests/clearance_edge.save"),"Prepared garden round-trip remains compatible")
	var source = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	check(not game.can_place("food",source.origin),"Trees remain fixed obstacles")
	source = game.sources.filter(func(s): return not s.is_tree)[0]
	check(not game.can_place("food",source.origin),"Stone deposits remain fixed obstacles")
	finish()

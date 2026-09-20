extends "res://Tests/test_v005.gd"

func rich() -> void:
	game.base.stored.wood = 300
	game.base.stored.stone = 300
	game.base.stored.produce = 100

func total(resource: String) -> int:
	var amount: int = game.stock[resource] + pile_total(resource)
	for worker in game.workers:
		if worker.cargo_resource == resource: amount += worker.cargo
		if worker.person.tool == resource: amount += 1
		if worker.spare_tools.has(resource): amount += 1
	for building in game.buildings: amount += building.materials.delivered.get(resource,0)
	return amount

func run() -> void:
	fresh()
	stop_workers()
	rich()
	var cell := Vector2i(59,24)
	var pile_cell := cell + Vector2i(1,1)
	var occupant = game.workers[0]
	occupant.assign_to("wood",game.base)
	occupant.position = game.cell_center(cell+Vector2i(2,1))
	occupant.cargo = 3
	occupant.cargo_resource = "pickaxe"
	game.logistics.drop(pile_cell,"axe",13)
	check(game.can_place("house",cell),"House allowed over loose materials and resident")
	var wood: int = game.available_stock().wood
	var axes: int = total("axe")
	var picks: int = total("pickaxe")
	var house = game.place_building("house",cell)
	check(house != null and house.preparing_site,"Occupied site enters preparation")
	check(game.available_stock().wood == wood-20,"Construction cost reserved during preparation")
	check(game.is_walkable(pile_cell),"Preparation stays accessible for pickup and evacuation")
	check(not game.can_place("food",cell),"Another building cannot overlap reserved preparation")
	house.materials.delivered = house.materials.required.duplicate()
	house.build(100)
	check(not house.completed and house.progress == 0,"Construction cannot skip clearing even with delivered materials")
	var original_position: Vector2 = occupant.position
	occupant._process(0.1)
	check(occupant.position != original_position and occupant.position.distance_to(original_position) <= game.DATA.WALK_SPEED*0.1+0.01,"Resident walks out physically, without teleport")
	check(occupant.assignment == "wood" and occupant.cargo == 3,"Evacuation preserves profession and carried items")
	game.workers[1].assign_to("builder",game.base)
	var saw_carried := false
	var saw_drop := false
	var conserved := true
	for step in 1200:
		tick(0.1)
		for worker in game.workers:
			if worker.clear_site_id == house.entity_id and worker.cargo > 0: saw_carried = true
		for pile in game.logistics.piles:
			if pile.resource_kind == "axe" and not game.clearance.area(house).has(pile.cell): saw_drop = true
		conserved = conserved and total("axe") == axes and total("pickaxe") == picks
		if house.completed: break
	check(saw_carried and saw_drop,"Worker physically picks up and places loose resources outside the site")
	check(conserved,"No resource loss or duplication during clearing")
	check(house.completed and not house.preparing_site,"Construction completes after clearance")
	check(not game.workers.any(func(w): return house.footprint().has(game.world_cell(w.position))),"No resident enclosed in completed building")
	check(not game.logistics.piles.any(func(p): return house.footprint().has(p.cell)),"No pile left beneath the building")
	check(occupant.assignment == "wood","Evacuation never switches profession")
	# Save during a loaded relocation; cancel afterwards; resources remain conserved.
	fresh()
	stop_workers()
	rich()
	game.logistics.drop(pile_cell,"axe",12)
	house = game.place_building("house",cell)
	var worker = game.workers[1]
	worker.assign_to("builder",game.base)
	for step in 500:
		worker._process(0.1)
		if worker.cargo > 0 and worker.clear_site_id == house.entity_id: break
	check(worker.cargo > 0 and worker.clear_destination != game.clearance.NONE,"Relocation cargo is in transit before saving")
	axes = total("axe")
	check(game.saves.save_file("res://Tests/clearance.save") and game.saves.load_file("res://Tests/clearance.save"),"Preparation and relocation load save/load")
	house = game.buildings.filter(func(b): return b.kind == "house")[0]
	check(house.preparing_site and total("axe") == axes,"Loaded preparation preserves all resources")
	var carrier = game.workers.filter(func(w): return w.clear_site_id == house.entity_id)[0]
	check(carrier.cargo > 0,"Loaded worker retains transported stack")
	check(game.cancel_construction(house),"Preparing construction remains cancellable")
	check(total("axe") == axes and carrier.clear_site_id == 0,"Cancellation releases reservations and preserves loaded resources")
	# No free target: wait; retry when land is freed. No deletion or instant movement.
	fresh()
	stop_workers()
	rich()
	game.logistics.drop(pile_cell,"axe",7)
	house = game.place_building("house",cell)
	var original: Array = game.logistics.piles.duplicate()
	for spot in game.land.get_used_cells():
		if game.clearance.site_at(spot) == null: game.logistics.drop(spot,"pickaxe",1)
	worker = game.workers[1]
	check(not game.clearance.claim(worker) and house.preparing_site,"No free position waits without consuming resources")
	for pile in game.logistics.piles.duplicate():
		if not original.has(pile): game.logistics.piles.erase(pile); pile.free()
	check(game.clearance.claim(worker),"Clearance resumes when a destination becomes available")
	check(game.clearance.free_cell(worker.clear_destination,worker),"Chosen destination is free and reachable")
	finish()

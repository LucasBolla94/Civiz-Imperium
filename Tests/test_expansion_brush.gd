extends "res://Tests/test_v003.gd"

func rich() -> void:
	game.base.stored.stone = 1000
	game.base.stored.wood = 1000
	game.base.stored.produce = 1000

func run() -> void:
	fresh()
	stop_workers()
	rich()
	for example in [[1,2,1],[4,5,3],[9,10,5],[25,28,14],[81,90,45]]:
		check(game.expansion_brush.cost(example[0]) == {"stone":example[1],"wood":example[2]},"Proportional rounded cost for %d water cells" % example[0])
	game.expansion_brush_size = 3
	check(game.can_place_job("expand",Vector2i(71,27)),"Original 3x3 coastal expansion still accepted")
	var plan: Dictionary = game.expansion_preview
	check(plan.cells.size() == 9 and plan.seconds == 10.0 and plan.discovery,"Original price, work and discovery preserved")
	game.expansion_brush_size = 9
	check(game.can_place_job("expand",Vector2i(71,27)),"Largest connected brush accepted")
	check(game.expansion_preview.cells.size() == 81 and game.expansion_preview.seconds == 90.0,"Largest brush uses all water cells and proportional work")
	check(not game.can_place_job("expand",Vector2i(-999,-999)),"Brush cannot leave map limits")
	check(not game.can_place_job("expand",Vector2i(82,27)),"Remote water cannot create floating land")
	# Reproduce narrow holes inside an existing saved island.
	var holes: Array[Vector2i] = [Vector2i(60,31),Vector2i(62,31)]
	for cell in holes: game.land.erase_cell(cell)
	game.refresh_shoreline()
	game.rebuild_navigation()
	game.add_building("food",Vector2i(42,23),true)
	var garden = game.place_job("garden",Vector2i(59,32))
	check(garden != null,"Existing garden near repair")
	game.logistics.drop(Vector2i(61,31),"wood",3)
	game.workers[1].position = game.cell_center(Vector2i(61,31))
	game.expansion_brush_size = 1
	check(game.can_place_job("expand",holes[0]),"One-cell enclosed hole is repairable")
	check(game.expansion_preview.cost == {"stone":2,"wood":1},"One-cell repair uses minimum price")
	check(not game.can_place_job("expand",Vector2i(61,31)),"Already dry land cannot consume materials")
	game.expansion_brush_size = 5
	check(game.can_place_job("expand",Vector2i(59,30)),"Brush may overlap existing garden, resident and material pile on land")
	check(game.expansion_preview.cells == holes,"Only the two separate water pockets are selected")
	var before: Dictionary = game.available_stock().duplicate()
	var job = game.place_job("expand",Vector2i(59,30),false,true)
	check(job != null and job.cells == holes and job.brush_size == 5,"Sparse footprint is fixed in construction order")
	check(Rect2i(59,30,5,5).has_point(job.door()),"Constructor can work from land inside brush")
	check(job.materials.required == {"stone":3,"wood":2},"No charge for existing dry land")
	check(game.available_stock().stone == before.stone-3 and game.available_stock().wood == before.wood-2,"Order reserves exact sparse cost immediately")
	check(not game.can_place_job("expand",Vector2i(59,30)),"Overlapping pending repair rejected")
	game.expansion_brush_size = 9
	check(job.cells == holes and job.materials.required.stone == 3,"Resizing brush does not alter a placed order")
	check(game.saves.save_file("res://Tests/expansion_brush.save"),"Sparse order saved")
	check(game.saves.load_file("res://Tests/expansion_brush.save"),"Sparse order loaded")
	job = game.jobs.filter(func(j): return j.kind == "expand")[0]
	check(job.cells == holes and job.brush_size == 5 and is_equal_approx(job.duration,20.0/9.0),"Saved footprint, size and work restored exactly")
	check(not job.discovery_eligible,"Repair does not generate stone deposits")
	var sources_before: int = game.sources.size()
	var land_before: int = game.land.get_used_cells().size()
	var count_before: int = game.expansion_count
	game.workers[0].assign_to("builder",game.base)
	tick(65)
	check(job.completed,"Real constructor transports materials and completes hole repair")
	check(holes.all(func(cell): return game.is_walkable(cell)),"Filled cells become traversable")
	check(game.land.get_used_cells().size() == land_before+2,"Exactly two new ground cells created")
	check(game.sources.size() == sources_before and game.expansion_count == count_before,"Repair cannot spawn blocking deposits or advance their counter")
	check(game.gardens.size() == 1 and game.gardens[0].origin == Vector2i(59,32),"Existing garden preserved")
	check(game.saves.save_file("res://Tests/expansion_brush.save") and game.saves.load_file("res://Tests/expansion_brush.save"),"Completed repair survives save/load")
	check(holes.all(func(cell): return game.is_walkable(cell)),"Filled terrain persists after load")
	# Old V005 files have no footprint fields: infer the original 3x3 job.
	fresh()
	stop_workers()
	rich()
	game.expansion_brush_size = 3
	job = game.place_job("expand",Vector2i(71,27))
	job.materials.delivered = job.materials.required.duplicate()
	job.progress = 4.0
	var old: Dictionary = game.saves.snapshot()
	for item in old.jobs:
		item.erase("cells")
		item.erase("brush_size")
		item.erase("discovery_eligible")
	check(game.saves.valid(old),"Legacy V005 expansion payload remains valid")
	game.saves.restore(old)
	job = game.jobs[0]
	check(job.cells.size() == 9 and job.duration == 10.0 and job.progress == 4.0 and job.discovery_eligible,"Legacy expansion retains original progress and discovery")
	job.build(6)
	check(job.completed and game.land.get_cell_source_id(Vector2i(73,29)) >= 0,"Legacy pending expansion finishes")
	var bad: Dictionary = game.saves.snapshot()
	bad.jobs[0].cells.append(Vector2i(-100,-100))
	check(not game.saves.valid(bad),"Malformed footprint cannot paint outside its saved brush")
	# A large brush must also survive an in-progress save and paint its full area.
	fresh()
	stop_workers()
	rich()
	game.expansion_brush_size = 9
	job = game.place_job("expand",Vector2i(71,27))
	job.materials.delivered = job.materials.required.duplicate()
	job.build(40)
	check(not job.completed and job.cells.size() == 81,"Large brush uses proportional work, not the old ten-second timer")
	check(game.saves.save_file("res://Tests/expansion_brush.save") and game.saves.load_file("res://Tests/expansion_brush.save"),"Large order reloads mid-construction")
	job = game.jobs[0]
	check(job.brush_size == 9 and job.cells.size() == 81 and job.progress == 40,"Large order preserves full footprint and progress")
	land_before = game.land.get_used_cells().size()
	job.build(50)
	check(job.completed and game.land.get_used_cells().size() == land_before+81,"Large order fills exactly 81 cells")
	check(game.is_walkable(Vector2i(79,35)),"Far corner of completed large brush becomes navigable")
	print("Expansion brush: ",checks," checks; ",failures.size()," failures")
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)

extends "res://Tests/test_v005.gd"

func run() -> void:
	fresh()
	stop_workers()
	game.base.stored.wood = 1000
	game.base.stored.stone = 1000
	var food = game.add_building("food",Vector2i(42,23),true)
	check(not game.gardens_unlocked(),"Food level one does not unlock new gardens")
	game.begin_action("garden")
	check(game.action_mode == "" and not game.can_place_garden(Vector2i(59,32)),"Garden gate enforced at command and placement")
	game.select_entity(food)
	check(game.hud.garden_button.disabled,"Garden UI explains level requirement")
	check(game.can_place_job("plant",Vector2i(59,32)),"Tree planting still works at food level one")
	food.level = 2
	var garden = game.place_job("garden",Vector2i(59,32))
	check(garden != null,"Food level two permits garden creation")
	food.level = 1
	var old: Dictionary = game.saves.snapshot()
	for source in old.sources:
		source.erase("cut_requested")
		source.erase("cut_started")
	check(game.saves.valid(old),"V005 data without cut fields remains valid")
	game.saves.restore(old)
	garden = game.gardens[0]
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(10)
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(4)
	garden._process(60)
	check(garden.phase == "ripe" and garden.take(15,"food") == 15,"Legacy garden works despite food level one")
	check(garden.request_plant(),"Legacy garden can replant at level one")
	# Fruit reservation, pending cancellation, then physical cut and load conservation.
	fresh()
	stop_workers()
	food = game.add_building("food",Vector2i(42,23),true)
	var wood = game.add_building("wood",Vector2i(42,30),true)
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	var other = game.spawn_tree(Vector2i(59,30),4)
	var collector = game.workers[0]
	collector.assign_to("food",food)
	collector.position = game.cell_center(tree.work_cells()[0])
	collector.preferred_source = tree
	var claim: Dictionary = game.work_planner.claim_harvest(collector)
	check(claim.get("source") == tree,"Collector reserves selected fruit tree")
	collector.position = game.cell_center(claim.cell)
	collector.cargo = game.work_planner.collect(collector)
	collector.cargo_resource = "produce"
	var fruit: int = tree.remaining
	check(tree.request_cut() and tree.remaining == fruit and not tree.cut_started,"Order preserves fruit before first axe stroke")
	check(collector.cargo == 1 and not game.work_planner.available_claim(collector),"Cut releases food reservation without destroying cargo")
	check(not tree.harvestable("food") and tree.harvestable("wood") and tree.take(1,"food") == 0,"Marked tree cannot be harvested concurrently")
	check(tree.cancel_cut() and tree.remaining == fruit and tree.harvestable("food"),"Pending cancellation restores food collection")
	tree.request_cut()
	check(game.saves.save_file("res://Tests/v0051.save") and game.saves.load_file("res://Tests/v0051.save"),"Pending cut and cargo save/load")
	tree = game.sources.filter(func(s): return s.cut_requested)[0]
	check(not tree.cut_started and tree.remaining == fruit and game.workers[0].cargo == 1,"Pending cut and collected fruit restored")
	wood = game.buildings.filter(func(b): return b.kind == "wood")[0]
	var lumberjack = game.workers[1]
	lumberjack.assign_to("wood",wood)
	lumberjack.position = game.cell_center(tree.work_cells()[0])
	lumberjack.person.tool = "axe"
	lumberjack.person.durability = 45
	lumberjack.find_job()
	check(lumberjack.target == tree,"Wood worker accepts only explicitly marked fruit tree")
	lumberjack.path.clear()
	lumberjack.position = game.cell_center(game.work_planner.claims[lumberjack].cell)
	lumberjack._process(0.01)
	check(tree.cut_started and tree.stage == 6 and tree.remaining == 30 and lumberjack.cargo == 0,"First physical stroke discards fruit; no instant wood")
	check(not tree.cancel_cut(),"Cut becomes irreversible once work starts")
	check(game.sources.filter(func(s): return s.is_tree and s.origin == Vector2i(59,30))[0].stage == 4,"Unmarked fruit tree stays productive")
	check(game.saves.save_file("res://Tests/v0051.save") and game.saves.load_file("res://Tests/v0051.save"),"Started cut saves and restores")
	tree = game.sources.filter(func(s): return s.cut_requested)[0]
	check(tree.cut_started and tree.stage == 6 and tree.remaining == 30 and not tree.cancel_cut(),"Started state persists without regenerating fruit")
	# Enough storage, time, and a tool: the normal worker pipeline clears the tree.
	game.base.stored.produce = 60
	var before: int = game.stock.wood
	tick(300)
	check(tree.removed and game.stock.wood + pile_total("wood") > before,"Lumberjack physically cuts and transports wood")
	# Benefits are derived from existing numerical rules, with no fabricated bonuses.
	for kind in game.DATA.CONSTRUCTIBLE:
		var b = game.add_building(kind,Vector2i(80,50),true)
		for level in [1,2]:
			b.level = level
			var text: String = b.FEEDBACK.next_level(b)
			var current: int = b.housing_capacity() if kind == "house" else b.capacity()
			var increment: int = game.DATA.HOUSE_UPGRADE_CAPACITY if kind == "house" else game.DATA.STORAGE_UPGRADE_CAPACITY
			check(text.contains(str(current)+" → "+str(current+increment)),kind+" upgrade shows real current and future value")
	finish()

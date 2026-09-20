extends "res://Tests/test_v005.gd"
func run() -> void:
	fresh()
	stop_workers()
	var wood = game.add_building("wood",Vector2i(42,30),true)
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	tree.request_cut()
	tick(5)
	check(not tree.cut_started and tree.remaining == 50,"No wood worker means no cut and no fruit loss")
	var worker = game.workers[0]
	worker.assign_to("wood",wood)
	worker.person.tool = "axe"
	worker.person.durability = 45
	game.automation.stock_targets.wood = 1
	check(game.work_planner.claim_harvest(worker).is_empty(),"Manual cut preserves existing optional wood production target")
	game.automation.stock_targets.wood = 0
	var spots: Array = tree.work_cells()
	for cell in spots: game.navigation.set_point_solid(cell)
	check(game.work_planner.claim_harvest(worker).get("source") != tree and not tree.cut_started,"No access cannot start cutting or discard fruit")
	game.rebuild_navigation()
	worker.position = game.cell_center(tree.work_cells()[0])
	worker.preferred_source = tree
	var claim: Dictionary = game.work_planner.claim_harvest(worker)
	check(not claim.is_empty(),"Restoring access restores work availability")
	check(tree.cancel_cut() and not game.work_planner.available_claim(worker),"Cancel during approach invalidates wood reservation")
	tree.request_cut()
	claim = game.work_planner.claim_harvest(worker)
	worker.target = tree
	worker.state = "to_source"
	worker.position = game.cell_center(claim.cell)
	worker.path.clear()
	worker.person.tool = ""
	worker._process(0.01)
	check(tree.cut_started and worker.cargo == 0 and worker.status.contains("Sem ferramenta"),"Existing slower tool-less work preserved and accurately described")
	var saved: Dictionary = game.saves.snapshot()
	var item: Dictionary = saved.sources.filter(func(s): return s.cut_requested)[0]
	item.cut_started = "invalid"
	check(not game.saves.valid(saved),"Malformed cut state cannot enter save restoration")
	# An exhausted marked orchard is renewed exactly once, via existing automation.
	tree.take(30,"wood")
	worker.interrupt_task()
	worker.position = game.cell_center(game.base.door())
	game.automation.orchards.append(tree.origin)
	game.add_building("food",Vector2i(42,23),true)
	game.base.stored.produce = 60
	game.automation.timer = 0
	game.automation.tick(2)
	game.automation.tick(2)
	check(game.jobs.filter(func(j): return j.kind == "plant" and j.origin == tree.origin).size() == 1,"Orchard renewal queues one replacement after manual cut")
	if game.jobs.is_empty(): finish(); return
	var plant = game.jobs.filter(func(j): return j.kind == "plant")[0]
	plant.materials.delivered = plant.materials.required.duplicate()
	plant.build(4)
	var replacement = game.sources.filter(func(s): return s.is_tree and not s.removed and s.origin == tree.origin)[0]
	check(replacement.stage == 0 and not replacement.cut_requested,"Replacement is a new growing tree without inherited cut order")
	finish()

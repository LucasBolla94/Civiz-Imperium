extends "res://Tests/test_v005.gd"

func run() -> void:
	fresh()
	stop_workers()
	var worker = game.workers[0]
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	tree.remaining = 1
	worker.assign_to("food",game.base)
	var claim: Dictionary = game.work_planner.claim_harvest(worker)
	worker.target = tree
	worker.position = game.cell_center(claim.cell)
	worker.path.clear()
	worker.state = "harvesting"
	worker._process(1)
	check(tree.stage == 6 and worker.cargo_resource == "produce" and worker.cargo == 1, "Final tree unit remains food cargo after source becomes wood")
	var before: int = game.stock.produce
	tick(20)
	check(game.stock.produce == before+1, "Worker delivers final tree food exactly once")
	# Worker actually walks and works; pause cannot advance the demolition.
	fresh()
	stop_workers()
	var depot = game.add_building("warehouse",Vector2i(42,23),true)
	depot.stored.stone = 12
	depot.stored.wood = 5
	game.rebuild_navigation()
	depot.request_demolition()
	worker = game.workers[0]
	worker.assign_to("builder",game.base)
	worker.find_job()
	check(worker.target == depot and worker.state == "to_build", "Builder claims demolition through the normal work planner")
	game.simulation_paused = true
	tick(50)
	check(depot.demolition_progress == 0, "Pause stops demolition and travel")
	game.simulation_paused = false
	for step in range(600):
		tick(0.1)
		if not game.buildings.has(depot): break
	check(not game.buildings.has(depot), "Builder walks and finishes ten base seconds of demolition")
	check(pile_total("wood") == 5 and pile_total("stone") == 12, "Worker-driven demolition preserves exact inventory")
	# Adjacent gardens share a traversable edge, never the same plot.
	fresh()
	game.add_building("food",Vector2i(42,23),true).level = 2
	game.base.stored.wood = 70
	game.rebuild_navigation()
	var garden = game.place_job("garden",Vector2i(58,29))
	var neighbor = game.place_job("garden",Vector2i(60,29))
	check(garden != null and neighbor != null, "Gardens can touch side by side")
	check(not game.route_to_cell(game.cell_center(garden.door()),neighbor.door()).is_empty(), "Neighboring garden work entrances stay reachable")
	# Restart an actual cycle via real supply and harvesting, retaining fence.
	game.base.stored.produce = 30
	game.workers[2].assign_to("builder",game.base)
	for step in range(2000):
		tick(0.1)
		if garden.phase == "ripe": break
	check(garden.phase == "ripe" and garden.remaining == 15, "Physical installation and planting reach full first harvest")
	var wood_after_fence: int = game.stock.wood
	garden.auto_replant = true
	for step in range(4000):
		tick(0.1)
		if garden.phase == "growing": break
	check(garden.phase == "growing", "Food worker harvests, delivers and replants automatically")
	check(game.stock.wood == wood_after_fence, "Repeated planting consumes no further fence wood")
	# Two occupied demolitions cannot reserve the same housing vacancy.
	fresh()
	stop_workers()
	var a = game.add_building("house",Vector2i(42,23),true)
	var b = game.add_building("house",Vector2i(58,23),true)
	game.rebuild_navigation()
	for index in range(8): game.spawn_worker("idle",game.base,game.cell_center(game.base.door()))
	a.request_demolition()
	b.request_demolition()
	check(game.workers.all(func(w): return not is_instance_valid(w.move_destination)), "Two full homes wait when no safe destination exists")
	var c = game.add_building("house",Vector2i(44,32),true)
	game.rebuild_navigation()
	game.settlement.tick_moves()
	check(game.settlement.reserved_residents(c) == 4, "New four-person home reserves exactly four relocation slots")
	check(game.settlement.residents(a).all(func(w): return w.move_destination == c) and game.settlement.residents(b).all(func(w): return w.move_destination == null), "Competing demolition cannot steal a booked destination")
	check(not game.settlement.healthy_for_arrival(), "Immigration cannot claim relocation vacancies")
	# Cancelling a destination demolition allows suspended moves to resume.
	c.request_demolition()
	game.settlement.tick_moves()
	check(game.workers.all(func(w): return w.move_destination != c), "Unavailable relocation destination releases safely")
	c.cancel_demolition()
	game.settlement.tick_moves()
	check(game.settlement.reserved_residents(c) == 4, "Moves retry automatically when safe housing becomes available")
	# Legacy saves are rejected without altering current state.
	var file := FileAccess.open("res://Tests/v005_legacy.save",FileAccess.WRITE)
	file.store_var({"version":4,"payload":PackedByteArray(),"digest":""})
	file.close()
	var snapshot: Dictionary = game.saves.snapshot()
	check(not game.saves.load_file("res://Tests/v005_legacy.save") and game.saves.snapshot() == snapshot, "V004 data is not silently migrated or overwritten")
	# Every actual UI label and template must have a complete English equivalent.
	var locale = root.get_node("Localization")
	locale.choose("en")
	var translations := FileAccess.open("res://Assets/Localization/en_pt.tsv",FileAccess.READ)
	var all_translated := true
	var placeholder := RegEx.new()
	placeholder.compile("%(?:[0-9.]*[dfs]|%)")
	while not translations.eof_reached():
		var line := translations.get_line().split("\t",true,1)
		if line.size() != 2: continue
		var source: String = line[0].c_unescape()
		var expected: String = line[1].c_unescape()
		for match_result in placeholder.search_all(source):
			var token: String = match_result.get_string()
			var sample := "João" if token == "%s" else ("%" if token == "%%" else "12")
			source = source.replace(token,sample)
			expected = expected.replace(token,sample)
		if locale.text(source) != expected:
			all_translated = false
			print("TRANSLATION MISMATCH: ",source," -> ",locale.text(source)," expected ",expected)
	check(all_translated,"All localization templates translate dynamic values without mixed language")
	print("V0.0.5 edges: %d checks; %d failures" % [checks,failures.size()])
	game.free()
	quit(0 if failures.is_empty() else 1)

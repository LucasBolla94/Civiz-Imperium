extends "res://Tests/test_v003.gd"
func run() -> void:
	fresh()
	stop_workers()
	game.base.stored.wood = 1000
	game.base.stored.stone = 1000
	game.base.stored.produce = 1000
	game.expansion_brush_size = 9
	var expansion = game.place_job("expand",Vector2i(71,27))
	expansion.materials.delivered = expansion.materials.required.duplicate()
	expansion.build(expansion.duration)
	check(game.can_place("house",Vector2i(72,28)),"House fits finished expanded terrain")
	var limit: int = game.population_limit()
	var house = game.place_building("house",Vector2i(72,28))
	check(house != null,"House order can be placed on expansion")
	game.workers[0].assign_to("builder",game.base)
	tick(240)
	check(house.completed,"Constructor physically supplies and finishes house on expansion")
	check(game.population_limit() == limit+4,"Expanded-land house adds four housing spaces")
	game.land.erase_cell(Vector2i(73,33))
	game.rebuild_navigation()
	check(not game.can_place("house",Vector2i(72,33)) and game.placement_reason.contains("água"),"Water under footprint is explicitly explained")
	# Optional reproduction with a local copy: never read/write the player's live save.
	if FileAccess.file_exists("res://Tests/user_diagnostic.save"):
		check(game.saves.load_file("res://Tests/user_diagnostic.save"),"Player save copy loads")
		var available: Dictionary = game.available_stock()
		check(available.wood >= 20 and available.stone >= 10,"Player save has resources for another house")
		var location := Vector2i(-999,-999)
		for cell in game.land.get_used_cells():
			if not game.initial_bounds.encloses(Rect2i(cell,game.DATA.building_size("house"))) and game.can_place("house",cell): location = cell; break
		check(location.x != -999,"Player save has a valid house site on expanded ground")
		if location.x != -999:
			stop_workers()
			limit = game.population_limit()
			house = game.place_building("house",location)
			check(house != null,"Real save copy accepts house placement")
			game.workers[0].person.energy = 100
			game.workers[0].person.nutrition = 100
			game.workers[0].assign_to("builder",game.base)
			tick(240)
			check(house.completed and game.population_limit() >= limit+4,"House completes on expanded terrain in copied save")
	print("Expanded construction: ",checks," checks; ",failures.size()," failures")
	game.free()
	quit(0 if failures.is_empty() else 1)

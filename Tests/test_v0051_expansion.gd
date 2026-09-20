extends "res://Tests/test_v003.gd"

func rich() -> void:
	game.base.stored.stone = 10000
	game.base.stored.wood = 10000

func run() -> void:
	fresh()
	stop_workers()
	rich()
	# Reproduction: a neighboring footprint partly overlaps an existing order.
	var first = game.place_job("expand",Vector2i(39,21),false,true)
	check(first != null,"Upper-left coast accepts adjacent reachable water")
	var before: Dictionary = game.available_stock().duplicate()
	var next = game.place_job("expand",Vector2i(39,23),false,true)
	check(next != null,"Upper-left overlapping brush can extend along existing shore")
	check(next.cells.size() == 6 and not next.cells.any(func(c): return first.cells.has(c)),"Pending cells excluded instead of blocking the whole brush")
	check(next.materials.required == game.expansion_brush.cost(6),"Only unreserved water enters the cost")
	check(game.available_stock().stone == before.stone-next.materials.required.stone,"No duplicate reservation charge")
	check(not game.can_place_job("expand",Vector2i(39,21)),"Entirely queued area cannot be ordered again")
	check(not game.can_place_job("expand",Vector2i(36,21)),"Pending land cannot authorize remote dependent expansion")
	for worker in game.workers: worker.assign_to("builder",game.base)
	tick(150)
	check(first.completed and next.completed,"Real builders deliver and complete both upper-left orders")
	check((first.cells+next.cells).all(func(c): return game.is_walkable(c)),"New upper-left land joins navigation")
	# All four directions, sizes, corners and negative-coordinate floor alignment.
	fresh()
	stop_workers()
	rich()
	for size in range(1,10):
		game.expansion_brush_size = size
		for cell in [Vector2i(42-size,25),Vector2i(71,25),Vector2i(55,23-size),Vector2i(60,39)]:
			check(game.can_place_job("expand",cell),"Size %d works on border %s" % [size,cell])
	check(game.world_cell(Vector2(-0.01,-16.01)) == Vector2i(-1,-2),"Negative coordinates floor correctly")
	var data: Dictionary = game.saves.snapshot()
	var offset := Vector2i(-55,-30)
	for tile in data.land: tile[0] += offset
	for b in data.buildings: b.origin += offset
	for s in data.sources: s.origin += offset
	for w in data.workers: w.position += Vector2(offset*16)
	game.saves.restore(data)
	game.expansion_brush_size = 3
	check(game.can_place_job("expand",Vector2i(39,21)+offset),"Upper-left expansion also works with negative map coordinates")
	game.base.stored.wood = 0
	check(not game.can_place_job("expand",Vector2i(39,21)+offset),"Insufficient resources still reject expansion")
	finish()

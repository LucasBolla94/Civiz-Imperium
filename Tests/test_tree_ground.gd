extends "res://Tests/test_v003.gd"
func run() -> void:
	root.size = Vector2i(960,400)
	root.content_scale_size = Vector2i.ZERO
	fresh()
	stop_workers()
	var tree = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	var trunk: Vector2i = tree.origin + Vector2i(1,3)
	check(not game.is_walkable(trunk), "Trunk blocks navigation")
	check(game.is_walkable(tree.origin + Vector2i(1,1)), "Residents can walk behind canopy")
	check(tree.blocking_cells().size() == 1, "Tree does not block entire artwork")
	check(not game.can_place_job("plant", tree.origin), "Walkable canopy cannot accept overlapping trees")
	var worker = game.workers[1]
	worker.assign_to("food",game.base)
	var claim: Dictionary = game.work_planner.claim_harvest(worker)
	check(not claim.is_empty() and claim.source == tree, "Collector reserves fruit tree")
	if not claim.is_empty():
		var offset: Vector2i = claim.cell - trunk
		check(absi(offset.x) + absi(offset.y) == 1, "Harvest happens adjacent to trunk, never top of canopy")
		check(not claim.route.is_empty(), "Harvest stand reachable")
	tree.set_stage(6)
	check(tree.blocking_cells() == [trunk] and game.is_walkable(tree.origin), "Stump keeps only its small ground obstacle")
	tree.take(tree.remaining,"wood")
	check(game.is_walkable(trunk), "Exhausted stump frees trunk cell")
	game.hide()
	game.camera.enabled = false
	game.hud.hide()
	var stage := Node2D.new()
	root.add_child(stage)
	for index in range(4):
		var group := Node2D.new()
		group.y_sort_enabled = true
		group.position = Vector2(65 + index * 230,70)
		group.scale = Vector2.ONE * 3
		stage.add_child(group)
		var sample = load("res://Scripts/resource_source.gd").new()
		group.add_child(sample)
		sample.setup_tree(game, Vector2i.ZERO, 6 if index == 3 else 4)
		sample.set_process(false)
		var visual = load("res://Scripts/resident_visual.gd").new()
		group.add_child(visual)
		visual.configure(1)
		visual.sprite.pause()
		visual.position = [Vector2(40,48),Vector2(24,72),Vector2(8,56),Vector2(8,56)][index]
		var title := Label.new()
		title.text = ["ATRÁS DA ÁRVORE", "NA FRENTE", "COLETA NO PÉ", "TOCO"][index]
		title.position = Vector2(40 + index * 230,25)
		stage.add_child(title)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Tests/tree_ground.png")
	stage.free()
	finish()

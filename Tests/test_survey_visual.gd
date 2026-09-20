extends "res://Tests/test_v003.gd"

func capture() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(960,340)
	root.content_scale_size = Vector2i.ZERO
	fresh()
	stop_workers()
	var depot = game.add_building("stone",Vector2i(42,23),true)
	depot.level = 2
	game.rebuild_navigation()
	var cell := Vector2i.ZERO
	for candidate in game.land.get_used_cells():
		if game.can_place_job("survey",candidate): cell = candidate; break
	var job = game.place_job("survey",cell)
	check(job != null,"Survey can be placed")
	game.workers[1].assign_to("stone",depot)
	tick(45)
	check(job.completed and job.deposit > 0,"Miner completes survey and discovers a finite deposit")
	var deposit: int = job.deposit
	check(game.saves.save_file("res://Tests/survey_visual.save"),"Discovered deposit saved")
	check(game.saves.load_file("res://Tests/survey_visual.save"),"Discovered deposit restored")
	job = game.jobs[0]
	check(job.completed and job.deposit == deposit and not job.released,"Discovered state survives reload")
	game.hide()
	game.camera.enabled = false
	game.hud.hide()
	if DisplayServer.get_name() != "headless":
		var stage := Node2D.new()
		stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		root.add_child(stage)
		var background := ColorRect.new()
		background.color = Color("59ac28")
		background.size = Vector2(960,340)
		stage.add_child(background)
		var examples: Array = []
		for index in range(4):
			var sample = game.JOB.new()
			sample.setup(game,"survey",Vector2i.ZERO,Vector2i.ZERO)
			sample.completed = index > 0
			if index == 2: sample.kind = "quarry"; sample.completed = false
			if index == 3: sample.released = true
			sample.position = Vector2(24+index*240,90)
			sample.scale = Vector2.ONE*4
			stage.add_child(sample)
			examples.append(sample)
			var title := Label.new()
			title.text = ["INVESTIGANDO", "JAZIDA DESCOBERTA", "ABRINDO PEDREIRA", "TERRENO LIBERADO"][index]
			title.position = Vector2(24+index*240,40)
			stage.add_child(title)
		var screen := await capture()
		var texture: Texture2D = game.DATA.CATALOG.entry("Stone").texture
		var stone: Image = texture.get_image()
		check(texture.get_size().x <= 48 and texture.get_size().y <= 48,"Native Stone fits survey footprint without resizing")
		for index in range(4):
			var tested := 0
			var matched := 0
			for y in stone.get_height():
				for x in stone.get_width():
					var expected := stone.get_pixel(x,y)
					if expected.a < 0.99: continue
					var local := (Vector2(48,48)-texture.get_size())/2 + Vector2(x,y)
					var point := Vector2i(examples[index].to_global(local))+Vector2i(2,2)
					tested += 1
					var actual := screen.get_pixelv(point)
					if actual.is_equal_approx(expected): matched += 1
			check(tested > 100 and (matched == tested if index in [1,2] else matched == 0),"Native Stone pixels visible only after discovery / during opening: " + str(index))
		var output := OS.get_environment("CIVIZ_CAPTURE")
		screen.save_png(output if output != "" else "res://Tests/survey_visual.png")
		stage.free()
	check(job.open_quarry(),"Discovered deposit can still be opened")
	job.materials.delivered = job.materials.required.duplicate()
	job.build(job.duration)
	var quarry = game.sources.filter(func(source): return source.is_quarry)[0]
	check(quarry.remaining == deposit,"Opening preserves investigated reserve")
	check(quarry.take(deposit,"stone") == deposit and quarry.removed,"Exhaustion releases site with no duplicated deposit")
	finish()

func finish() -> void:
	print("Survey visual: ",checks," checks; ",failures.size()," failures")
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)

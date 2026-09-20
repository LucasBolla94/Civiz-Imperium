extends "res://Tests/test_v003.gd"
const DATA = preload("res://Scripts/game_data.gd")

func capture() -> Image:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func run() -> void:
	root.size = Vector2i(960,480)
	root.content_scale_size = Vector2i.ZERO
	# No HUD or other owner may be needed to keep a draw-only resource alive.
	DATA.resource_texture_cache.clear()
	for pile in [false,true]:
		var handle: WeakRef = weakref(DATA.resource_texture("produce",pile))
		check(handle.get_ref() != null,"Produce texture survives caller return: " + str(pile))
		var img: Image = DATA.resource_texture("produce",pile).get_image()
		var size := 16 if pile else 32
		var margin := 1 if pile else 2
		check(img.get_size() == Vector2i(size,size),"Native dimensions: " + str(size))
		check(Rect2i(margin,margin,size-2*margin,size-2*margin).encloses(img.get_used_rect()),"Transparent margin: " + str(size))
		var red := 0
		var green := 0
		var white := 0
		for y in size:
			for x in size:
				var color := img.get_pixel(x,y)
				if color.a < 0.5: continue
				if color.r > color.g * 1.3: red += 1
				if color.g > color.r * 1.15: green += 1
				if minf(color.r,minf(color.g,color.b)) > 0.9: white += 1
		check(red > 5 and green > 5 and white == 0,"Colored produce without opaque white backdrop: " + str(size))
	fresh()
	stop_workers()
	game.add_building("food",Vector2i(42,23),true)
	game.rebuild_navigation()
	var garden = game.place_job("garden",Vector2i(58,29))
	check(garden != null,"Garden placed")
	for cell in garden.cells:
		check(game.is_walkable(cell) and not game.route_to_cell(game.workers[0].position,cell).is_empty(),"Garden cell remains traversable: " + str(cell))
	check(garden.z_index + game.entities.z_index >= game.land.z_index,"Garden above terrain")
	check(garden.z_index < game.workers[0].z_index,"Workers above garden independently of Y")
	game.hide()
	game.camera.enabled = false
	game.hud.hide()
	if DisplayServer.get_name() == "headless": finish(); return
	var stage := Node2D.new()
	stage.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(stage)
	var background := ColorRect.new()
	background.color = Color("59ac28")
	background.size = Vector2(960,480)
	stage.add_child(background)
	var gardens: Array = []
	var visuals: Array = []
	for index in range(4):
		var group := Node2D.new()
		group.z_index = game.entities.z_index
		group.y_sort_enabled = true
		group.position = Vector2(70+index*225,160)
		group.scale = Vector2.ONE * 4
		stage.add_child(group)
		var sample = load("res://Scripts/garden.gd").new()
		group.add_child(sample)
		sample.setup_garden(game,Vector2i.ZERO)
		sample.phase = "ripe"
		sample.set_process(false)
		sample.hide()
		gardens.append(sample)
		var visual = load("res://Scripts/resident_visual.gd").new()
		group.add_child(visual)
		visual.configure(index%3)
		visual.sprite.pause()
		visual.position = Vector2(8+16*(index%2),8+16*(index/2))
		visuals.append(visual)
		var label := Label.new()
		label.text = "TRABALHADOR NA CÉLULA %d" % (index+1)
		label.position = Vector2(30+index*225,55)
		stage.add_child(label)
		var pile = load("res://Scripts/resource_pile.gd").new()
		pile.resource_kind = "produce"
		pile.position = Vector2(16,65)
		group.add_child(pile)
	var without := await capture()
	for sample in gardens: sample.show()
	var with_garden := await capture()
	for index in range(4):
		var visual = visuals[index]
		var frame: Image = visual.sprite.sprite_frames.get_frame_texture("Idle",0).get_image()
		var tested := 0
		var covered := 0
		for y in 32:
			for x in 32:
				if frame.get_pixel(x,y).a < 0.99: continue
				var screen: Vector2i = Vector2i(visual.to_global(Vector2(x-16,y-32))*1.0)+Vector2i(2,2)
				tested += 1
				if without.get_pixelv(screen) != with_garden.get_pixelv(screen): covered += 1
		check(tested > 50 and covered == 0,"No worker pixels hidden by garden in cell %d (%d tested, %d covered)" % [index+1,tested,covered])
		var corner := Vector2i(70+index*225+8*4+2,160+53*4+2)
		check(with_garden.get_pixelv(corner).is_equal_approx(background.color),"Pile transparent corner on terrain: " + str(index))
	check(without.get_data() != with_garden.get_data(),"Garden is rendered above terrain")
	with_garden.save_png("res://Tests/v005_visual_fix.png")
	stage.free()
	finish()

func finish() -> void:
	print("V0.0.5 visual fixes: ",checks," checks; ",failures.size()," failures")
	if is_instance_valid(game): game.free()
	quit(0 if failures.is_empty() else 1)

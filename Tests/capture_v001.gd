extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	root.size = Vector2i(1280, 800)
	var game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/v001_start.png")
	game.place_building("food", Vector2i(59, 25))
	game.place_building("stone", Vector2i(47, 33))
	game.simulation_speed = 30
	await create_timer(3.0).timeout
	game.simulation_speed = 1
	game.select_entity(game.base)
	game.base.enqueue()
	game.base.enqueue()
	game.hud.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/v001_queue.png")
	game.simulation_speed = 20
	await create_timer(0.8).timeout
	game.change_allocation("food", 1)
	game.change_allocation("stone", 1)
	await create_timer(3.0).timeout
	game.select_entity(game.buildings[1])
	game.simulation_speed = 1
	game.hud.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/v001_playing.png")
	game.begin_placement("food")
	game.base.stored.stone = 100
	game.preview_cell = Vector2i(55, 25)
	game.preview_valid = true
	game.set_process(false)
	game.placement_overlay.queue_redraw()
	game.hud.refresh()
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/v001_placement.png")
	print("VISUAL CAPTURES SAVED")
	quit()

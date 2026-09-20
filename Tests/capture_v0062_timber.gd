extends "res://Tests/test_v003.gd"
## Confere, em escala de jogo, os cinco estágios da árvore de madeira ao lado da frutífera.
func run() -> void:
	root.size = Vector2i(1100,420)
	root.content_scale_size = Vector2i.ZERO
	fresh()
	stop_workers()
	game.hide()
	game.camera.enabled = false
	game.hud.hide()
	var stage := Node2D.new()
	root.add_child(stage)
	var labels := ["SEMENTE","BROTO","MUDA","JOVEM","MADURA","FRUTÍFERA"]
	for index in range(6):
		var group := Node2D.new()
		group.y_sort_enabled = true
		group.position = Vector2(90 + index * 170,90)
		group.scale = Vector2.ONE * 3
		stage.add_child(group)
		var sample = load("res://Scripts/resource_source.gd").new()
		group.add_child(sample)
		if index == 5: sample.setup_tree(game, Vector2i.ZERO, 4)
		else: sample.setup_timber(game, Vector2i.ZERO, index)
		sample.set_process(false)
		var visual = load("res://Scripts/resident_visual.gd").new()
		group.add_child(visual)
		visual.configure(1)
		visual.sprite.pause()
		visual.position = Vector2(8,56)
		var title := Label.new()
		title.text = labels[index]
		title.position = Vector2(60 + index * 170,30)
		stage.add_child(title)
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Tests/v0062_timber_stages.png")
	stage.free()
	finish()

extends SceneTree
const VISUAL = preload("res://Scripts/resident_visual.gd")
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(message)
func run() -> void:
	root.size = Vector2i(960, 1080)
	root.content_scale_size = Vector2i.ZERO
	RenderingServer.set_default_clear_color(Color("33434d"))
	var stage := Node2D.new()
	root.add_child(stage)
	var row := 0
	for variant in range(3):
		for clip in ["Idle", "Walk", "Work"]:
			for frame in range(VISUAL.CLIPS[clip][1]):
				for facing in [1, -1]:
					var visual = VISUAL.new()
					stage.add_child(visual)
					visual.configure(variant)
					visual.sprite.play(clip)
					visual.sprite.pause()
					visual.sprite.frame = frame
					visual.face(Vector2(facing, 0))
					visual.crown.visible = true
					visual.scale = Vector2.ONE * 3
					visual.position = Vector2(42 + frame * 78 + (480 if facing == -1 else 0), 108 + row * 116)
					check(visual.crown.position.y <= -29 and visual.crown.position.y >= -31, "Crown stays near scalp")
					check(visual.crown.flip_h == visual.sprite.flip_h, "Crown mirrors with head")
			row += 1
		var library: SpriteFrames = VISUAL.frame_cache[variant]
		for clip in VISUAL.CLIPS:
			check(library.get_frame_count(clip) == VISUAL.CLIPS[clip][1], "Complete animation " + clip)
			for frame in range(library.get_frame_count(clip)):
				var atlas: AtlasTexture = library.get_frame_texture(clip, frame)
				check(Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region), "Frame stays inside sheet")
	if DisplayServer.get_name() != "headless":
		await process_frame
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://Tests/resident_crowns.png")
	stage.free()
	var game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.simulation_paused = true
	check(game.workers.map(func(w): return w.person.appearance_id) == [0,1,2], "Founders use all three models")
	check(game.workers.filter(func(w): return w.visual.crown.visible).size() == 1, "Exactly one crowned founder")
	var worker = game.workers[0]
	game.simulation_paused = false
	worker.needs.wake_grace = 30.0
	worker.path = PackedVector2Array([worker.position + Vector2.RIGHT])
	worker.move_along_path(0.001)
	check(worker.sprite.animation == &"Walk" and not worker.sprite.flip_h, "Worker walks facing route")
	worker.path.clear()
	worker.state = "idle"
	worker.think_timer = 100
	worker._process(0.01)
	check(worker.sprite.animation == &"Idle", "Stopped worker returns to idle")
	worker.state = "building"
	worker._process(0.01)
	check(worker.sprite.animation == &"Work", "Work state selects work animation")
	game.simulation_paused = true
	worker._process(0.01)
	check(not worker.sprite.is_playing(), "Paused simulation pauses sprites")
	var successor = game.workers[1]
	game.settlement.remove(game.workers[0])
	check(successor.person.is_king and successor.visual.crown.visible, "Successor receives crown immediately")
	check(successor.person.appearance_id == 1, "Succession preserves appearance")
	successor.visible = false
	check(not successor.visual.crown.is_visible_in_tree(), "Rest hides crown with resident")
	successor.visible = true
	check(successor.visual.crown.is_visible_in_tree(), "Waking restores crown")
	game.free()
	print("RESIDENT VISUALS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

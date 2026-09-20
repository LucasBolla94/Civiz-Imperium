extends SceneTree
var game
var failures: Array[String] = []
var assertions := 0
func check(value: bool, text: String) -> void:
	assertions += 1
	if not value:
		failures.append(text)
		push_error(text)
func _initialize() -> void: call_deferred("run")
func click(point: Vector2, held_frames := 0) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	root.push_input(motion, true)
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event, true)
		if pressed:
			for frame in range(held_frames): await process_frame
	await process_frame
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.selection == game.base and game.hud.recruit_button.visible, "Base recruitment initially visible")
	check(game.hud.build_buttons.size() == 2, "Menu only offers activity buildings")
	var controls: Dictionary = game.hud.activity_controls
	check(controls.food.plus.disabled, "Food allocation disabled without workplace")
	await click(game.hud.recruit_button.get_global_rect().get_center(), 25)
	check(game.base.queue_count == 1, "Held click survives refresh")
	await click(game.hud.recruit_button.get_global_rect().get_center())
	check(game.base.queue_count == 2, "Repeated recruitment clicks")
	await click(game.hud.cancel_button.get_global_rect().get_center())
	check(game.base.queue_count == 1 and game.stock.food == 16, "Central queue cancellation")
	var picture = game.hud.build_buttons.food.get_child(0).get_child(0)
	await click(picture.get_global_rect().get_center())
	check(game.placement_kind == "food" and game.buildings.size() == 1, "Picture selects construction without click-through")
	var screen_point: Vector2 = game.get_global_transform_with_canvas() * game.cell_center(Vector2i(60,26))
	await click(screen_point)
	check(game.buildings.size() == 2, "Place activity building")
	if game.buildings.size() < 2:
		finish()
		return
	var food = game.buildings[1]
	game.simulation_speed = 20
	for frame in range(300):
		await process_frame
		if food.completed and game.workers.size() == 2: break
	game.simulation_speed = 1
	game.hud.refresh()
	await process_frame
	check(food.completed and game.activity_count("idle") == 1, "Base recruits while builder works")
	check(not game.hud.recruit_button.visible, "Workplace hides recruitment")
	await click(controls.food.plus.get_global_rect().get_center(), 25)
	check(game.activity_count("food") == 1 and controls.food.amount.text == "1", "Plus updates allocation immediately")
	check(game.workers[-1].home == food, "Automatic workplace destination")
	await click(controls.food.minus.get_global_rect().get_center())
	check(game.activity_count("food") == 0 and game.activity_count("idle") == 1, "Minus frees worker")
	await click(controls.builder.plus.get_global_rect().get_center())
	check(game.activity_count("builder") == 2, "Free worker changes to builder")
	await click(controls.builder.minus.get_global_rect().get_center())
	await click(controls.food.plus.get_global_rect().get_center())
	check(game.activity_count("builder") == 1 and game.activity_count("food") == 1, "Repeated changes conserve counts")
	await click(game.hud.build_buttons.stone.get_global_rect().get_center())
	await click(game.hud.build_buttons.stone.get_global_rect().get_center())
	check(game.placement_kind == "", "Repeat card cancels placement")
	await click(game.hud.build_buttons.stone.get_global_rect().get_center())
	await click(screen_point)
	check(game.selection == food and game.placement_kind == "", "Workplace selection during placement")
	check(food.sprite.texture == game.DATA.CATALOG.entry("Building-2").texture, "Food visual comes from exact example assembly")
	check(game.hud.blocks_world_input(controls.food.plus.get_global_rect().get_center()), "Allocation panel blocks world input")
	finish()
func finish() -> void:
	print("UI TESTS: ", assertions, " checks, ", failures.size(), " failures")
	game.free()
	quit(0 if failures.is_empty() else 1)

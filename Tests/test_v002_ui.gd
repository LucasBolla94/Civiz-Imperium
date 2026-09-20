extends SceneTree
var game
var errors := 0
var checks := 0
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		errors += 1
		push_error(text)
func _initialize() -> void: call_deferred("run")
func click(point: Vector2, hold := 0) -> void:
	for pressed in [true,false]:
		var e := InputEventMouseButton.new()
		e.position = point
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = pressed
		root.push_input(e,true)
		if pressed:
			for frame in range(hold): await process_frame
	await process_frame
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	game.simulation_paused = true
	var transform: Transform2D = game.get_global_transform_with_canvas()
	await click(transform * game.cell_center(game.base.origin + Vector2i(3,3)))
	check(game.hud.building_actions.visible and not game.hud.construction_menu.visible,"Base context replaces buildings")
	await click(game.hud.recruit_button.get_global_rect().get_center(),25)
	check(game.base.queue_count == 1,"Contextual recruitment survives held click")
	await click(game.hud.cancel_button.get_global_rect().get_center())
	check(game.base.queue_count == 0 and game.stock.food == 24,"Contextual cancellation refunds")
	await click(Vector2(1150,400))
	check(game.hud.construction_menu.visible,"Map restores building icons")
	var food = game.add_building("food",Vector2i(59,25),true)
	game.rebuild_navigation()
	await click(transform * game.cell_center(Vector2i(60,26)))
	check(game.selection == food and game.hud.plant_button.visible,"Food context offers planting")
	check(not game.hud.recruit_button.visible,"Activity building cannot recruit")
	await click(game.hud.plant_button.get_global_rect().get_center())
	check(game.action_mode == "plant","Plant button activates map order")
	await click(transform * game.cell_center(Vector2i(44,25)))
	check(game.jobs.size() == 1 and game.jobs[0].kind == "plant","Map click creates planting job")
	check(game.stock.food == 22 and game.action_mode == "","Plant cost charged once; mode exits")
	await click(Vector2(1150,400))
	check(game.hud.construction_menu.visible,"Return to construction after planting")
	game.base.stored.wood = 10
	await click(transform * game.cell_center(game.base.origin + Vector2i(3,3)))
	game.hud.refresh()
	await process_frame
	await click(game.hud.expand_button.get_global_rect().get_center())
	check(game.action_mode == "expand","Base expansion button enters coast mode")
	await click(transform * game.cell_center(Vector2i(72,28)))
	check(game.jobs.size() == 2 and game.jobs[-1].kind == "expand","Coast click creates expansion job")
	check(game.stock.wood == 5,"Expansion debits wood")
	await click(game.hud.aid_button.get_global_rect().get_center())
	check(game.stock.food == 26 and game.hud.aid_button.disabled,"Aid button grants food then disables")
	check(game.hud.workforce_panel.get_global_rect().end.y < game.hud.bottom_panel.get_global_rect().position.y,"Workforce panel does not overlap context panel")
	print("V0.0.2 UI: ",checks," checks; ",errors," failures")
	game.free()
	quit(0 if errors == 0 else 1)

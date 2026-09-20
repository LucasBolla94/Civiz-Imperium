extends "res://Tests/test_v003_ui.gd"

func settle() -> void:
	for frame in range(6): await process_frame

func point(cell: Vector2i) -> Vector2:
	return game.get_global_transform_with_canvas() * game.cell_center(cell)

func hover(cell: Vector2i) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point(cell)
	root.push_input(event,true)
	game.preview_check_time = 0
	await settle()

func wheel(direction: int, ctrl := true) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_UP if direction > 0 else MOUSE_BUTTON_WHEEL_DOWN
	event.pressed = true
	event.ctrl_pressed = ctrl
	event.position = game.pointer_position
	root.push_input(event,true)
	await settle()

func stamp(cell: Vector2i, repeat := false) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		event.shift_pressed = repeat
		event.position = point(cell)
		root.push_input(event,true)
	await settle()

func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	game.simulation_paused = true
	game.camera.zoom = Vector2.ONE * 2
	game.camera.position = Vector2(960,480)
	game.camera.force_update_scroll()
	game.base.stored.stone = 1000
	game.base.stored.wood = 1000
	var locale = root.get_node("Localization")
	locale.choose("pt")
	for cell in [Vector2i(60,31),Vector2i(62,31)]: game.land.erase_cell(cell)
	game.refresh_shoreline()
	game.rebuild_navigation()
	game.select_entity(game.base)
	game.hud.expand_button.pressed.emit()
	await hover(Vector2i(60,31))
	check(game.expansion_brush_size == 3,"Brush defaults to 3x3")
	var zoom: Vector2 = game.camera.zoom
	await wheel(-1)
	await wheel(-1)
	check(game.expansion_brush_size == 1 and game.camera.zoom == zoom,"Ctrl wheel shrinks brush without zoom")
	check(game.preview_cell == Vector2i(60,31) and game.preview_valid,"1x1 preview targets pointer cell")
	check(game.expansion_preview.cost == {"stone":2,"wood":1},"One-cell preview shows cheap cost")
	check(game.hud.title_label.text.contains("1 × 1") and game.hud.detail_label.text.contains("Pedras: 2 · Madeiras: 1"),"HUD updates brush size and actual cost")
	await capture("expansion_brush_1_pt")
	await wheel(-1)
	check(game.expansion_brush_size == 1,"Lower brush limit")
	for step in 4: await wheel(1)
	check(game.expansion_brush_size == 5 and game.camera.zoom == zoom,"Ctrl wheel enlarges brush without zoom")
	check(game.expansion_preview.cells.size() == 2 and game.expansion_preview.cost == {"stone":3,"wood":2},"Larger brush charges only two holes, ignoring land")
	await capture("expansion_brush_5_pt")
	locale.choose("en")
	await settle()
	check(game.hud.title_label.text.contains("Brush 5") and game.hud.detail_label.text.contains("Cells: 2") and game.hud.detail_label.text.contains("Ctrl + wheel"),"English dynamic preview translated")
	await capture("expansion_brush_5_en")
	for step in 6: await wheel(1)
	check(game.expansion_brush_size == 9,"Upper brush limit")
	for step in 4: await wheel(-1)
	await hover(Vector2i(61,31))
	var expected: Array = game.expansion_preview.cells.duplicate()
	await stamp(Vector2i(61,31),true)
	check(game.jobs.size() == 1 and game.jobs[0].cells == expected,"Click commits exactly previewed cells")
	check(game.action_mode == "expand","Shift retains expansion brush")
	await stamp(Vector2i(61,31),true)
	check(game.jobs.size() == 1,"Repeated click cannot reserve same water twice")
	await wheel(-1)
	check(game.jobs[0].brush_size == 5,"Placed brush size frozen while preview changes")
	await wheel(1,false)
	check(game.camera.zoom.x > zoom.x and game.expansion_brush_size == 4,"Wheel without Ctrl still zooms")
	game.camera.zoom = zoom
	game.camera.force_update_scroll()
	var size_before: int = game.expansion_brush_size
	game.hud.policy_window.popup_centered(Vector2i(520,330))
	await settle()
	await wheel(1)
	check(game.expansion_brush_size == size_before and game.camera.zoom == zoom,"Modal blocks brush and zoom")
	game.hud.policy_window.hide()
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	root.push_input(event,true)
	await settle()
	check(game.action_mode.is_empty() and not game.hud.game_menu.visible,"Esc cancels brush before opening game menu")
	# A failed expensive placement can be reduced to an affordable one.
	game.base.stored.stone = 5
	game.base.stored.wood = 3
	game.begin_action("expand")
	await hover(Vector2i(72,29))
	check(not game.preview_valid,"Unaffordable brush visibly rejected")
	for step in 3: await wheel(-1)
	await hover(Vector2i(71,29))
	check(game.preview_valid and game.expansion_brush_size == 1,"Shrinking permits affordable repair with outstanding reservations")
	await stamp(Vector2i(71,29))
	check(game.jobs.size() == 2 and game.action_mode.is_empty(),"Click without Shift places once and exits brush mode")
	print("Expansion brush UI: ",checks," checks; ",failures," failures")
	game.free()
	quit(0 if failures == 0 else 1)

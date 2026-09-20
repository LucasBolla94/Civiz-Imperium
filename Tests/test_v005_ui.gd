extends "res://Tests/test_v003_ui.gd"
func settle() -> void:
	for frame in range(6): await process_frame
func modified_click(point: Vector2, repeat: bool) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.shift_pressed = repeat
		root.push_input(event,true)
	await settle()
func press(keycode: int) -> void:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.pressed = true
	root.push_input(event,true)
	await settle()
func screen(cell: Vector2i) -> Vector2:
	return game.get_global_transform_with_canvas() * game.cell_center(cell)
func clear_site(kind: String) -> Vector2i:
	for cell in game.land.get_used_cells():
		if game.can_place(kind,cell) and not game.hud.blocks_world_input(screen(cell + game.DATA.building_size(kind)/2)): return cell
	return Vector2i(-999,-999)
func run() -> void:
	root.size = Vector2i(1280,720)
	var locale = root.get_node("Localization")
	locale.choose("en")
	var menu = load("res://Scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await settle()
	check(menu.start_button.text == "Found a civilization", "Main menu starts in English")
	await capture("v005_menu_en")
	locale.choose("pt")
	check(menu.start_button.text == "Fundar uma civilização", "Main menu switches language live")
	await capture("v005_menu_pt")
	locale.choose("en")
	await click(menu.start_button.get_global_rect().get_center())
	await settle()
	game = current_scene
	game.simulation_paused = true
	game.camera.zoom = Vector2.ONE * 1.5
	game.camera.position = Vector2(910,525)
	await capture("v005_start_en")
	# Real modified clicks repeat buildings; occupied clicks preserve placement.
	game.base.stored.stone = 100
	game.begin_placement("food")
	await settle()
	for index in range(2):
		var cell := clear_site("food")
		check(cell != Vector2i(-999,-999), "Visible building site found")
		await modified_click(screen(cell + game.placement_offset()),true)
		check(game.buildings.size() == index + 2 and game.placement_kind == "food", "Shift click creates one building and keeps placement")
	var count: int = game.buildings.size()
	await modified_click(screen(game.buildings[-1].origin+Vector2i(1,1)),true)
	check(game.buildings.size() == count and game.placement_kind == "food", "Invalid occupied click does not cancel repeated placement")
	var cell := clear_site("food")
	await modified_click(screen(cell + game.placement_offset()),false)
	check(game.buildings.size() == count + 1 and game.placement_kind.is_empty(), "Click without Shift places once and exits")
	game.begin_placement("house")
	await press(KEY_ESCAPE)
	check(game.placement_kind.is_empty(), "Escape cancels repeated placement")
	# Test cancel from the real context action.
	var construction = game.buildings[-1]
	game.select_entity(construction)
	await settle()
	await click(game.hud.cancel_work_button.get_global_rect().get_center())
	check(not game.buildings.has(construction), "Cancel construction button removes unstarted order")
	var depot = game.buildings[1]
	depot.materials.delivered = depot.materials.required.duplicate()
	depot.build(20)
	game.select_entity(depot)
	await settle()
	check(game.hud.garden_button.visible, "Food depot offers Create garden")
	await click(game.hud.garden_button.get_global_rect().get_center())
	check(game.action_mode == "garden", "Create garden activates placement")
	game.base.stored.wood = 100
	for index in range(2):
		for candidate in game.land.get_used_cells():
			if game.can_place_garden(candidate) and not game.hud.blocks_world_input(screen(candidate+Vector2i.ONE)):
				cell = candidate
				break
		await modified_click(screen(cell+Vector2i.ONE),true)
		check(game.gardens.size() == index+1 and game.action_mode == "garden", "Shift repeats garden placement")
	await press(KEY_ESCAPE)
	var garden = game.gardens[0]
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(10)
	garden.materials.delivered = garden.materials.required.duplicate()
	garden.build(4)
	game.simulation_paused = false
	garden._process(60)
	game.simulation_paused = true
	game.select_entity(garden)
	await settle()
	check(game.hud.detail_label.text.contains("15 Produce"), "Mature garden shows fifteen Produce in English")
	await click(game.hud.replant_button.get_global_rect().get_center())
	check(garden.auto_replant, "Context button enables automatic replanting")
	await capture("v005_garden_en")
	locale.choose("pt")
	await settle()
	await capture("v005_garden_pt")
	locale.choose("en")
	# Expansion repetition uses the same input path and real reservation budget.
	game.cancel_placement()
	game.select_entity(null)
	game.base.stored.stone = 100
	game.base.stored.wood = 100
	game.begin_action("expand")
	for origin in [Vector2i(71,27),Vector2i(71,31)]:
		await modified_click(screen(origin+Vector2i.ONE),true)
	check(game.jobs.filter(func(j): return j.kind == "expand").size() == 2 and game.action_mode == "expand", "Shift repeats valid coastal expansions")
	await press(KEY_ESCAPE)
	var zoom_before: float = game.camera.zoom.x
	await press(KEY_E)
	check(game.camera.zoom.x > zoom_before, "E zooms while simulation paused")
	await press(KEY_Q)
	await create_timer(0.8).timeout
	check(is_equal_approx(game.camera.zoom.x,zoom_before), "Q uses inverse mouse wheel step")
	game.select_entity(game.base)
	game.hud.policy_button.pressed.emit()
	await settle()
	await press(KEY_E)
	check(is_equal_approx(game.camera.zoom.x,zoom_before), "Modal blocks keyboard zoom")
	game.hud.policy_window.hide()
	var edit := LineEdit.new()
	game.hud.add_child(edit)
	edit.grab_focus()
	await press(KEY_E)
	check(is_equal_approx(game.camera.zoom.x,zoom_before), "Text entry blocks keyboard zoom")
	edit.queue_free()
	await settle()
	# Real demolition UI, construction hammer progress and persisted disabled cancel.
	game.select_entity(depot)
	await settle()
	await click(game.hud.demolish_button.get_global_rect().get_center())
	check(depot.demolition_requested, "Demolish button creates a worker task")
	await settle()
	check(game.hud.cancel_demolish_button.visible and not game.hud.cancel_demolish_button.disabled, "Unstarted demolition can be cancelled")
	depot.build(0.1)
	game.hud.refresh()
	check(game.hud.cancel_demolish_button.disabled, "Started demolition cannot be cancelled in UI")
	await capture("v005_demolition_en")
	# Each new context and localized top bar fits supported logical viewports.
	for language in ["en","pt"]:
		locale.choose(language)
		for resolution in [Vector2i(640,360),Vector2i(1280,720),Vector2i(1920,1080),Vector2i(720,1280)]:
			root.size = resolution
			await settle()
			for entity in [garden,depot,game.base]:
				game.select_entity(entity)
				await settle()
				var bounds := Rect2(Vector2.ZERO,root.get_visible_rect().size).grow(1)
				check(bounds.encloses(game.hud.top_panel.get_global_rect()), "Localized resource bar fits " + str(resolution))
				check(bounds.encloses(game.hud.bottom_panel.get_global_rect()), "New context fits " + str(resolution))
	locale.choose("en")
	print("V0.0.5 UI: %d checks; %d failures" % [checks,failures])
	game.free()
	quit(0 if failures == 0 else 1)

extends "res://Tests/test_expansion_brush_ui.gd"

func press_at(cell: Vector2i, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = down
	event.shift_pressed = true
	event.position = point(cell)
	root.push_input(event,true)

func motion_to(position: Vector2, held := true) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.shift_pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	root.push_input(event,true)

func run() -> void:
	root.size = Vector2i(1280,720)
	for zoom in [0.75,2.0,3.5]:
		if is_instance_valid(game): game.free()
		game = load("res://Scenes/main.tscn").instantiate()
		root.add_child(game)
		await settle()
		game.simulation_paused = true
		game.camera.zoom = Vector2.ONE * zoom
		game.camera.position = game.cell_center(Vector2i(57,25))
		game.camera.force_update_scroll()
		game.base.stored.stone = 1000
		game.base.stored.wood = 1000
		game.expansion_brush_size = 1
		game.begin_action("expand")
		await hover(Vector2i(53,22))
		press_at(Vector2i(53,22),true)
		motion_to(point(Vector2i(62,22)))
		check(game.jobs.size() == 10,"Fast drag fills every traversed coastal cell at zoom %.2f" % zoom)
		var reserved: Dictionary = game.available_stock().duplicate()
		motion_to(point(Vector2i(53,22)))
		check(game.jobs.size() == 10 and game.available_stock() == reserved,"Return over stroke never duplicates cost")
		press_at(Vector2i(53,22),false)
		motion_to(point(Vector2i(52,22)),false)
		check(game.jobs.size() == 10 and not game.expansion_dragging,"Release ends painting, even while Shift stays held")
		# Slow continuation, then across the UI, returning elsewhere on the coast.
		press_at(Vector2i(52,22),true)
		for x in [51,50,49]: motion_to(point(Vector2i(x,22)))
		check(game.jobs.size() == 14,"Slow movement queues contiguous coast")
		var n: int = game.jobs.size()
		motion_to(game.hud.top_panel.get_global_rect().get_center())
		check(game.jobs.size() == n,"Dragging over interface adds no orders")
		motion_to(point(Vector2i(63,22)))
		check(game.jobs.size() == n+1,"Reentry from UI does not bridge an unintended route")
		press_at(Vector2i(63,22),false)
		var cells := {}
		for job in game.jobs:
			for cell in job.cells:
				check(not cells.has(cell),"Each queued water cell has a single owner")
				cells[cell] = true
		await hover(Vector2i(64,22))
		check(game.preview_valid == game.can_place_job("expand",game.preview_cell),"Preview and command validation agree")
		if zoom == 2.0:
			root.get_node("Localization").choose("pt")
			await settle()
			await capture("v0051_expansion_drag_pt")
			root.get_node("Localization").choose("en")
			await settle()
			check(game.hud.detail_label.text.contains("Cells:") and game.hud.detail_label.text.contains("Shift + drag"),"English brush cost and drag instructions are fully translated")
			await capture("v0051_expansion_drag_en")
		# Starting over water with insufficient resources never reserves anything.
		game.base.stored.stone = 0
		game.base.stored.wood = 0
		n = game.jobs.size()
		press_at(Vector2i(65,22),true)
		motion_to(point(Vector2i(68,22)))
		press_at(Vector2i(68,22),false)
		check(game.jobs.size() == n,"Drag stops accepting orders when resources run out")
		game.hud.policy_window.popup_centered()
		await settle()
		press_at(Vector2i(65,22),true)
		motion_to(point(Vector2i(68,22)))
		check(game.jobs.size() == n and not game.expansion_dragging,"Modal does not start a world gesture")
		game.hud.policy_window.hide()
	print("V0051 drag: ",checks," checks; ",failures," failures")
	game.free()
	quit(1 if failures else 0)

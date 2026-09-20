extends SceneTree
var game
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("run")
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures += 1
		push_error(text)
func click(point: Vector2, hold := 0) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)
		if pressed:
			for frame in range(hold): await process_frame
	await process_frame
func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1920,1200)
	var menu = load("res://Scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	await process_frame
	await process_frame
	check(menu.backdrop.simulation_paused, "Menu pauses backdrop simulation")
	await capture("v003_menu")
	await click(menu.start_button.get_global_rect().get_center(),3)
	await process_frame
	await process_frame
	game = current_scene
	check(game.has_method("spawn_worker") and game.workers.size() == 3, "New game button opens actual three-person colony")
	game.simulation_paused = true
	await capture("v003_start")
	if DisplayServer.get_name() != "headless": test_camera_keys()
	check(game.hud.workforce_panel.get_global_rect().end.y < game.hud.bottom_panel.get_global_rect().position.y, "Workforce panel does not overlap context")
	check(game.hud.bottom_panel.get_global_rect().end.x <= 1920, "HUD fits viewport width")
	await click(game.get_global_transform_with_canvas() * game.cell_center(game.base.origin + Vector2i(3,3)))
	check(game.selection == game.base and game.hud.building_actions.visible, "Base click opens management context")
	await capture("v003_base")
	check(game.hud.bottom_panel.get_global_rect().end.x <= 1920, "Base actions fit viewport width")
	check(game.hud.recruit_button.disabled, "Colony needs housing before attracting settlers")
	await click(game.hud.plant_button.get_global_rect().get_center(),20)
	check(game.action_mode == "plant", "Held plant click survives refresh")
	game.cancel_placement()
	await click(game.hud.residents_button.get_global_rect().get_center())
	check(game.hud.residents_window.visible and game.hud.resident_controls.size() == 3, "Base lists its specific residents")
	var worker = game.workers[1]
	worker.state = "resting"
	worker.person.energy = 30
	worker.visible = false
	game.hud.refresh_residents()
	var wake_button: Button = game.hud.resident_controls[worker].wake
	check(not wake_button.disabled, "Resting resident has wake action")
	await process_frame
	await process_frame
	await click(wake_button.get_global_rect().get_center())
	check(worker.visible and worker.complaint_time > 0, "Wake button wakes resident and shows complaint")
	await capture("v003_residents")
	game.hud.close_residents()
	game.select_entity(null)
	await process_frame
	await click(game.hud.build_buttons.house.get_global_rect().get_center())
	check(game.placement_kind == "house", "House icon starts placement")
	game.cancel_placement()
	game.select_entity(worker)
	check(game.hud.detail_label.text.contains("Alimentação") and game.hud.detail_label.text.contains("XP"), "Resident inspection exposes needs and experience")
	var workshop = game.add_building("workshop",Vector2i(58,24),true)
	game.rebuild_navigation()
	workshop.level = 2
	game.select_entity(workshop)
	await process_frame
	check(game.hud.tools_box.visible, "Workshop exposes stock goals")
	game.hud.tools_controls.axe.value = 7
	check(workshop.tool_targets.axe == 7, "Stock goal control changes workshop policy")
	await capture("v003_workshop")
	game.select_entity(null)
	await process_frame
	await click(game.hud.workforce_toggle.get_global_rect().get_center())
	await click(game.hud.activity_controls.wood.minus.get_global_rect().get_center())
	check(game.activity_count("idle") == 1, "Minus releases worker")
	await click(game.hud.activity_controls.stone.plus.get_global_rect().get_center())
	check(game.activity_count("stone") == 1, "Plus assigns mining without requiring early specialization")
	print("V0.0.3 UI: ",checks," checks; ",failures," failures")
	game.free()
	quit(0 if failures == 0 else 1)






func key_event(key: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func test_camera_keys() -> void:
	game.camera.set_process(false)
	var origin: Vector2 = game.camera.position
	var steps := {KEY_W:Vector2.UP,KEY_A:Vector2.LEFT,KEY_S:Vector2.DOWN,KEY_D:Vector2.RIGHT}
	for key in steps:
		game.camera.position = origin
		key_event(key,true)
		game.camera._process(0.25)
		key_event(key,false)
		var motion: Vector2 = game.camera.position - origin
		check(motion.dot(steps[key]) > 1 and absf(motion.cross(steps[key])) < 0.01, "WASD key %s pans the camera while paused" % OS.get_keycode_string(key))
	game.camera.position = origin
	game.hud.open_residents(null)
	key_event(KEY_D,true)
	game.camera._process(0.5)
	key_event(KEY_D,false)
	check(game.camera.position == origin, "Resident modal blocks camera movement")
	game.hud.close_residents()
	game.center_camera()
	check(game.camera.position.is_equal_approx(origin), "Centring restores the initial framing")
	game.camera.set_process(true)


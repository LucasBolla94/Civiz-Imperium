extends "res://Tests/test_v003_ui.gd"
const SIZES = [Vector2i(3840,2160), Vector2i(3440,1440), Vector2i(2560,1080), Vector2i(1920,1200), Vector2i(1920,1080), Vector2i(1366,768), Vector2i(1280,720), Vector2i(1024,768), Vector2i(960,540), Vector2i(800,600), Vector2i(640,360), Vector2i(720,1280)]
func settle() -> void:
	for frame in range(8): await process_frame
func contained(control: Control, title: String) -> void:
	var bounds := Rect2(Vector2.ZERO, root.get_visible_rect().size).grow(1)
	check(bounds.encloses(control.get_global_rect()), title + " inside viewport " + str(root.size))
func run() -> void:
	if DisplayServer.get_name() != "headless":
		var usable := DisplayServer.screen_get_usable_rect(root.current_screen)
		check(usable.encloses(Rect2i(root.position, root.size)), "Initial game window fits physical monitor")
	var menu = load("res://Scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for resolution in SIZES:
		root.size = resolution
		await settle()
		contained(menu.start_button, "Start button")
		contained(menu.start_button.get_parent().get_parent(), "Main menu")
	await click(menu.start_button.get_global_rect().get_center(),3)
	await settle()
	game = current_scene
	game.simulation_paused = true
	for resolution in SIZES:
		root.size = resolution
		await settle()
		game.select_entity(null)
		await settle()
		check(not game.hud.workforce_panel.visible, "Workforce does not permanently cover the map")
		var map_area: Rect2 = game.hud.map_visible_rect()
		check(map_area.get_area() / root.get_visible_rect().get_area() >= 0.70,"At least 70 percent of viewport reserved for map")
		for b in game.hud.build_buttons.values():
			check(game.hud.bottom_scroll.get_global_rect().encloses(b.get_global_rect()),"Construction shortcut fully visible without scrolling")
		await click(game.hud.workforce_toggle.get_global_rect().get_center())
		await settle()
		check(game.hud.workforce_panel.visible,"Workforce toggle opens management")
		for controls in game.hud.activity_controls.values():
			check(controls.plus.get_parent().get_parent().get_parent().get_global_rect().encloses(controls.plus.get_global_rect()),"Every allocation button visible without scrolling")
		if resolution == Vector2i(1280,720): await capture("compact_720_workforce")
		await click(game.hud.workforce_toggle.get_global_rect().get_center())
		for panel in [game.hud.top_panel,game.hud.bottom_panel,game.hud.workforce_panel]: contained(panel,"HUD panel")
		check(game.hud.workforce_panel.get_global_rect().end.y < game.hud.bottom_panel.position.y, "Workforce never overlaps bottom panel")
		var before: Rect2 = game.hud.bottom_panel.get_global_rect()
		game.camera.pan(Vector2.RIGHT,0.2)
		game.camera.change_zoom(1.12)
		check(before == game.hud.bottom_panel.get_global_rect(), "HUD independent of camera")
		game.center_camera()
		if resolution == Vector2i(1280,720): await capture("responsive_720_game")
		game.select_entity(game.base)
		await settle()
		contained(game.hud.building_actions,"Base action layout")
		for child in game.hud.building_actions.get_children():
			if not child.visible: continue
			check(child.get_global_rect().end.x <= game.hud.bottom_panel.get_global_rect().end.x, "Action fits horizontally")
		if resolution == Vector2i(1280,720): await capture("responsive_720_base")
		game.hud.open_residents(null)
		await settle()
		contained(game.hud.residents_window,"Residents modal")
		check(game.hud.residents_window.get_global_rect().get_center().distance_to(root.get_visible_rect().size / 2) < 1, "Residents stay centered after resize")
		var resident = game.workers[0]
		resident.state = "resting"
		resident.visible = false
		game.hud.refresh_residents()
		await settle()
		var wake: Button = game.hud.resident_controls[resident].wake
		contained(wake,"Wake button")
		await click(wake.get_global_rect().get_center())
		check(resident.visible,"Wake action clickable at every resolution")
		if resolution == Vector2i(1280,720): await capture("responsive_720_residents")
		# Resize an already open modal, which previously retained stale offsets.
		root.size = resolution - Vector2i(20,10)
		await settle()
		contained(game.hud.residents_window,"Open modal after resize")
		check(game.hud.residents_window.get_global_rect().get_center().distance_to(root.get_visible_rect().size / 2) < 1,"Open modal recenters")
		game.hud.close_residents()
		game.hud.extinction_panel.show()
		game.hud.layout_windows()
		contained(game.hud.extinction_panel,"Extinction panel")
		game.hud.extinction_panel.hide()
	root.size = Vector2i(1280,720)
	game.hud.restart_dialog.popup_centered()
	await settle()
	check(Rect2i(Vector2i.ZERO,Vector2i(root.get_visible_rect().size)).encloses(Rect2i(game.hud.restart_dialog.position,game.hud.restart_dialog.size)),"Restart confirmation fits viewport")
	game.hud.restart_dialog.hide()
	for index in range(15):
		var worker = game.spawn_worker("idle",game.base,game.cell_center(game.base.door()))
		worker.person.display_name = "Habitante com nome longo %d" % index
		worker.residence = game.base # UI-only crowded residence fixture; simulation is paused.
		worker.state = "resting"
		worker.visible = false
	game.hud.open_residents(null)
	await settle()
	var last = game.workers[-1]
	var last_button: Button = game.hud.resident_controls[last].wake
	var resident_scroll: ScrollContainer = game.hud.residents_rows.get_parent()
	resident_scroll.ensure_control_visible(last_button)
	await settle()
	check(resident_scroll.get_global_rect().encloses(last_button.get_global_rect()),"Last resident reachable by scrolling")
	await click(last_button.get_global_rect().get_center())
	check(last.visible,"Last resident wake button works after scrolling")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	root.push_input(escape,true)
	check(not game.hud.residents_window.visible,"Escape closes residents window")
	print("Responsive UI: %d checks; %d failures" % [checks,failures])
	game.free()
	quit(1 if failures else 0)

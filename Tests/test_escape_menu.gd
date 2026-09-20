extends "res://Tests/test_v003_ui.gd"

func settle() -> void:
	for frame in range(5): await process_frame

func press_escape(echo := false) -> void:
	for down in [true,false]:
		var event := InputEventKey.new()
		event.keycode = KEY_ESCAPE
		event.pressed = down
		event.echo = echo if down else false
		root.push_input(event,true)
	await settle()

func menu_click(control: Button) -> void:
	for down in [true,false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = Vector2(game.hud.game_menu.position) + control.get_global_rect().get_center()
		event.pressed = down
		root.push_input(event,true)
	await settle()

func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await settle()
	var hud = game.hud
	var locale = root.get_node("Localization")
	locale.choose("pt")
	if OS.get_cmdline_user_args().has("--quit-button"):
		hud.open_game_menu()
		await settle()
		print("QUIT BUTTON: sending real click")
		await menu_click(hud.menu_quit_button)
		push_error("Quit button failed to terminate the application")
		quit(1)
		return
	game.simulation_paused = true
	game.select_entity(game.base)
	hud.toggle_workforce()
	await press_escape()
	check(not hud.workforce_panel.visible and not hud.game_menu.visible,"First Esc closes workforce only")
	await press_escape()
	check(game.selection == null and not hud.game_menu.visible,"Second Esc closes selection only")
	await press_escape()
	check(hud.game_menu.visible and game.simulation_paused,"Next Esc opens game menu")
	check(hud.menu_save_button.text == "Salvar jogo" and hud.menu_quit_button.text == "Fechar jogo","Portuguese menu actions")
	check(game.camera.input_blocked(),"Modal blocks map controls")
	await capture("escape_menu_pt")
	await press_escape()
	check(not hud.game_menu.visible and game.simulation_paused,"Esc closes menu and preserves manual pause")
	game.simulation_paused = false
	await press_escape(true)
	check(not hud.game_menu.visible,"Key repeat does not open menu")
	await press_escape()
	check(hud.game_menu.visible and game.simulation_paused,"Opening pauses running colony")
	var energy: float = game.workers[0].person.energy
	await create_timer(0.3).timeout
	check(game.workers[0].person.energy == energy,"No simulation advances behind menu")
	await menu_click(hud.menu_save_button)
	check(FileAccess.file_exists(game.saves.PATH) and hud.menu_save_status.text == "Partida salva.","Save button writes real save and confirms success")
	check(hud.game_menu.visible and game.simulation_paused,"Saving keeps menu open and paused")
	locale.choose("en")
	await settle()
	check(hud.game_menu.title == "Game paused" and hud.menu_save_button.text == "Save game" and hud.menu_quit_button.text == "Quit game","English menu actions")
	await capture("escape_menu_en")
	await menu_click(hud.game_menu.get_ok_button())
	check(not hud.game_menu.visible and not game.simulation_paused,"Continue button restores running game")
	hud.open_residents(null)
	await press_escape()
	check(not hud.residents_window.visible and not hud.game_menu.visible,"Residents close without opening game menu")
	game.begin_placement("house")
	await press_escape()
	check(game.placement_kind.is_empty() and not hud.game_menu.visible,"Placement cancels without opening menu")
	hud.policy_window.popup_centered(Vector2i(520,330))
	await settle()
	await press_escape()
	check(not hud.policy_window.visible and not hud.game_menu.visible,"Existing modal consumes Esc without opening menu")
	await press_escape()
	check(hud.game_menu.visible,"Esc after last modal opens menu")
	hud.game_menu.hide()
	check(game.saves.load_file(),"Menu save reloads successfully")
	root.size = Vector2i(640,360)
	await settle()
	hud.open_game_menu()
	await settle()
	check(hud.game_menu.size.x <= root.size.x and hud.game_menu.size.y <= root.size.y,"Menu fits small window")
	hud.game_menu.hide()
	print("Escape menu: ",checks," checks; ",failures," failures")
	game.free()
	quit(0 if failures == 0 else 1)

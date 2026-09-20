extends "res://Tests/test_v003_ui.gd"
func run() -> void:
	var slots=root.get_node("IslandSaves")
	slots.directory="user://test-v006-ui-"+slots.token()
	slots.open_catalog()
	var locale=root.get_node("Localization")
	locale.choose("en")
	var settings=root.get_node("AppSettings")
	settings.apply_video(Vector2i(1280,720),false)
	var menu=load("res://Scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	await process_frame
	await process_frame
	var music=root.get_node("Music")
	var playback=music.player.get_stream_playback()
	var initial_clip: int=playback.get_current_clip_index()
	check(initial_clip>=0 and music.player.playing,"native audio actually playing")
	check(menu.start_button.text=="Play","menu English default translation")
	check(menu.home.get_global_rect().get_center().distance_to(root.get_visible_rect().get_center())<2,"centered menu")
	check(not menu.backdrop.has_method("spawn_worker"),"backdrop cannot run real colony")
	var elapsed: float=menu.backdrop.elapsed
	await create_timer(0.2).timeout
	check(menu.backdrop.elapsed>elapsed,"living backdrop animates")
	var online=menu.get_node("Interface/Center/Home/Rows/Buttons/Online")
	await click(online.get_global_rect().get_center())
	check(current_scene==menu and online.disabled and online.focus_mode==Control.FOCUS_NONE,"Online ignores input")
	await capture("v006_menu_en")
	await click(menu.start_button.get_global_rect().get_center())
	await process_frame
	check(menu.slots_panel.visible and menu.slot_rows.get_child_count()==5,"Play shows five islands")
	await click(menu.slot_rows.get_child(0).get_node("Action").get_global_rect().get_center())
	await process_frame
	check(menu.name_dialog.visible and menu.name_dialog.get_ok_button().disabled,"new island requires name")
	menu.name_input.text="Madeira — A nossa primeira civilização"
	menu.name_input.text_changed.emit(menu.name_input.text)
	check(not menu.name_dialog.get_ok_button().disabled,"valid name enables creation")
	menu.name_dialog.confirmed.emit()
	await process_frame
	await process_frame
	await process_frame
	game=current_scene
	check(game.has_method("spawn_worker") and slots.active_index()==0,"named island created and initially saved")
	game.simulation_paused=true
	check(music.player.get_stream_playback()==playback and playback.get_current_clip_index()==initial_clip,"enter game preserves music playback")
	game.base.stored.wood=76
	check(game.saves.save_file(),"manual save in active game")
	game.hud.open_game_menu()
	check(game.hud.game_menu.visible,"ESC menu opens")
	await capture("v006_pause_en")
	game.hud.game_menu.hide()
	change_scene_to_file("res://Scenes/main_menu.tscn")
	await process_frame
	await process_frame
	menu=current_scene
	check(music.player.get_stream_playback()==playback and playback.get_current_clip_index()==initial_clip,"return menu preserves playback")
	menu.show_islands()
	await process_frame
	await capture("v006_islands_en")
	var occupied=menu.slot_rows.get_child(0)
	await click(occupied.get_child(3).get_global_rect().get_center())
	await process_frame
	check(menu.delete_dialog.visible and menu.delete_dialog.dialog_text.contains("Madeira"),"delete confirmation names island")
	menu.delete_dialog.canceled.emit()
	menu.delete_dialog.hide()
	check(not slots.island(0).is_empty(),"cancel delete preserves island")
	menu.show_home()
	menu.open_settings()
	await process_frame
	check(menu.settings_panel.visible,"settings open")
	check(menu.settings_panel.get_ok_button().text=="Back" and menu.name_dialog.get_ok_button().text=="Create and play","internal dialog buttons translated")
	check(root.get_visible_rect().encloses(Rect2(menu.settings_panel.position,menu.settings_panel.size)),"settings including Back fit viewport")
	await capture("v006_settings_en")
	settings.begin_video(Vector2i(960,540),true)
	menu.settings_panel.confirmation.popup_centered(Vector2i(460,180))
	await process_frame
	await capture("v006_video_confirm")
	settings.deadline_msec=Time.get_ticks_msec()-1
	settings._process(0.1)
	check(not settings.trial and not menu.settings_panel.confirmation.visible,"video timer independent of paused game")
	locale.choose("pt")
	await capture("v006_settings_pt")
	menu.settings_panel.hide()
	menu.show_islands()
	await capture("v006_islands_pt")
	check(menu.slot_rows.get_child(0).get_child(1).get_child(0).text=="Madeira — A nossa primeira civilização","player names never translated")
	for i in range(1,5):
		var sample=load("res://Scenes/main.tscn").instantiate()
		root.add_child(sample)
		sample.process_mode=Node.PROCESS_MODE_DISABLED
		sample.village_level=1+i%3
		for extra in i: sample.spawn_worker("idle",sample.base,sample.cell_center(Vector2i(60+extra,32)))
		sample.add_building("house",Vector2i(43+i*4,36),true)
		check(slots.begin_new(i,"Arquipélago %d — Uma nova civilização"%i) and sample.saves.save_file(),"five distinct visual fixtures")
		sample.free()
	menu.refresh_slots()
	await capture("v006_five_islands_pt")
	for size in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=size
		await process_frame
		await process_frame
		check(root.get_visible_rect().encloses(menu.slots_panel.get_global_rect()),"five slots fit supported screen")
		menu.show_home()
		await process_frame
		check(root.get_visible_rect().encloses(menu.home.get_global_rect()),"home fits supported screen")
		var accept := InputEventAction.new()
		accept.action="ui_accept"
		accept.pressed=true
		root.push_input(accept)
		accept=accept.duplicate()
		accept.pressed=false
		root.push_input(accept)
		await process_frame
		check(menu.slots_panel.visible,"keyboard/controller accept opens Play")
	await capture("v006_final_pt")
	music.player.stop()
	music.player.finished.emit()
	await create_timer(0.15).timeout
	check(music.player.playing and music.player.get_stream_playback().get_current_clip_index()>=0,"unexpected playback end resumes music")
	print("V0.0.6 UI: %d checks; %d failures"%[checks,failures])
	quit(1 if failures else 0)

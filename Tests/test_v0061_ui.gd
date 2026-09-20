extends "res://Tests/test_v003_ui.gd"
func settle() -> void:
	for i in 8: await process_frame

func run() -> void:
	root.get_node("AppSettings").apply_video(Vector2i(1280,720),false)
	root.get_node("Localization").choose("en")
	game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused=true
	game.village_level=3
	var post=game.add_building("gold_mining",Vector2i(43,24),true)
	var furnace=game.add_building("smelter",Vector2i(65,23),true)
	game.rebuild_navigation()
	game.workers[1].assign_to("idle",game.base)
	game.workers[2].assign_to("idle",game.base)
	game.hud.refresh()
	await settle()
	await capture("v0061_hud_en")
	await click(game.hud.workforce_toggle.get_global_rect().get_center())
	await settle()
	check(game.hud.workforce_panel.visible,"Central workforce opens from top bar")
	game.hud.workforce_view.reveal("gold_mining")
	await settle()
	var controls: Dictionary=game.hud.activity_controls.gold_mining
	game.hud.workforce_view.get_parent().ensure_control_visible(controls.plus)
	await settle()
	await click(controls.plus.get_global_rect().get_center())
	game.hud.refresh()
	check(game.activity_count("gold_mining")==1 and game.workplace_count(post,"gold_mining")==1,"Global allocation updates exactly one building team")
	check(controls.amount.text=="1","Central count follows actual assignment")
	var local: Dictionary=game.hud.workforce_view.building_rows.gold_mining[post.entity_id]
	game.hud.workforce_view.get_parent().ensure_control_visible(local.minus)
	await settle()
	await click(local.minus.get_global_rect().get_center())
	game.hud.refresh()
	check(game.activity_count("gold_mining")==0 and controls.amount.text=="0","Local minus updates the central allocation")
	await click(local.plus.get_global_rect().get_center())
	game.hud.refresh()
	check(game.activity_count("gold_mining")==1 and controls.amount.text=="1","Local plus shares the central allocation state")
	await capture("v0061_teams_en")
	game.hud.toggle_workforce()
	game.select_entity(furnace)
	game.hud.refresh()
	await settle()
	await capture("v0061_smelter_en")
	root.get_node("Localization").choose("pt")
	game.select_entity(null)
	for dimensions in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
		root.size=dimensions
		await settle()
		var bounds := root.get_visible_rect()
		check(bounds.encloses(game.hud.top_panel.get_global_rect()),"Top bar stays within viewport")
		check(bounds.encloses(game.hud.bottom_panel.get_global_rect()),"Build bar stays within viewport")
		for item in game.hud.resource_labels.values():
			check(game.hud.top_panel.get_global_rect().encloses(item.amount.get_global_rect()),"Resource amounts remain inside top panel")
		for button in game.hud.build_buttons.values():
			check(game.hud.bottom_panel.get_global_rect().encloses(button.get_global_rect()),"Every construction action is visible")
	await capture("v0061_hud_pt")
	print("V0.0.6.1 UI: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

extends "res://Tests/test_v003_ui.gd"

func settle() -> void:
	for frame in 12: await process_frame

func bounded(label: String) -> void:
	var panel: Control=game.hud.workforce_panel
	var body: Control=game.hud.workforce_content
	var scroll: ScrollContainer=game.hud.workforce_view.get_parent()
	var bounds: Rect2=root.get_visible_rect().grow(1)
	check(bounds.encloses(panel.get_global_rect()),label+": panel fits screen")
	check(panel.get_global_rect().encloses(body.get_child(0).get_global_rect()),label+": heading and close stay inside panel")
	check(panel.get_global_rect().encloses(body.get_child(-1).get_global_rect()),label+": footer stays inside panel")
	check(panel.get_global_rect().encloses(scroll.get_global_rect()),label+": scroll area fits panel")
	check(scroll.size.y>20,label+": list has usable space")

func run() -> void:
	root.get_node("AppSettings").apply_video(Vector2i(1280,720),false)
	game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused=true
	game.village_level=3
	for index in 9:
		game.add_building("gold_mining",Vector2i(38+index*3,28),true)
	game.add_building("smelter",Vector2i(40,33),true)
	game.rebuild_navigation()
	await settle()
	game.hud.toggle_workforce()
	await settle()
	for locale in ["pt","en"]:
		root.get_node("Localization").choose(locale)
		for dimensions in [Vector2i(1280,720),Vector2i(960,540),Vector2i(640,360),Vector2i(720,1280)]:
			root.size=dimensions
			await settle()
			for activity in game.hud.workforce_view.ACTIVITIES:
				game.hud.workforce_view.reveal(activity)
			game.hud.refresh()
			await settle()
			bounded(locale+str(dimensions)+" expanded")
			var scroll: ScrollContainer=game.hud.workforce_view.get_parent()
			for activity in game.hud.workforce_view.ACTIVITIES:
				var target: Control=game.hud.activity_controls[activity].plus
				scroll.ensure_control_visible(target)
				await settle()
				check(scroll.get_global_rect().encloses(target.get_global_rect()),"Allocation reachable: "+activity)
				bounded(locale+str(dimensions)+" scrolled "+activity)
			if dimensions==Vector2i(1280,720): await capture("workforce_bounds_"+locale)
			if dimensions==Vector2i(640,360): await capture("workforce_bounds_small_"+locale)
			# Reopening after scrolling must not retain an oversized panel or lose its close button.
			var heading: Control=game.hud.workforce_content.get_child(0)
			await click(heading.get_child(-1).get_global_rect().get_center())
			check(not game.hud.workforce_panel.visible,"Visible close button works after scrolling")
			game.hud.toggle_workforce()
			await settle()
			bounded("reopened")
	print("Workforce bounds: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

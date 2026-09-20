extends "res://Tests/test_v003_ui.gd"

func settle() -> void:
	for i in 8: await process_frame

func run() -> void:
	root.get_node("AppSettings").apply_video(Vector2i(1280,720),false)
	root.get_node("Localization").choose("pt")
	game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused=true
	game.village_level=3
	game.base.stored.wood=80
	game.base.stored.stone=80
	game.base.stored.gold_bar=10
	game.hud.refresh()
	await settle()
	await click(game.hud.build_buttons.trading_port.get_global_rect().get_center())
	check(game.placement_kind=="trading_port","Port button opens placement")
	game.camera.position=game.cell_center(Vector2i(46,40))
	game.camera.zoom=Vector2(2.5,2.5)
	game.camera.zoom_target=-1
	await settle()
	game.pointer_position=game.get_global_transform_with_canvas()*game.cell_center(Vector2i(46,39))
	await settle()
	check(game.preview_cell==Vector2i(44,37) and game.preview_valid,"Real cursor preview finds the valid southern coast")
	check(game.hud.rotate_port_button.visible,"Rotate control is visible in placement context")
	await capture("v0061_port_preview_pt")
	await click(game.hud.rotate_port_button.get_global_rect().get_center())
	check(game.placement_orientation==1,"Visible rotate button updates the logical coast")
	for i in 3:
		var event := InputEventKey.new()
		event.pressed=true
		event.keycode=KEY_R
		game._unhandled_input(event)
	check(game.placement_orientation==0,"R rotates the same logical masks")
	var port=game.place_building("trading_port",Vector2i(44,37))
	check(port!=null,"Player can confirm valid port placement")
	if port==null: quit(1); return
	port.materials.delivered=port.materials.required.duplicate()
	port.build(30)
	game.merchant.tick(60)
	for i in 1000:
		if game.merchant.state=="docked": break
		game.merchant.tick(0.5)
	var worker=game.workers[1]
	worker.interrupt_task()
	worker.position=game.cell_center(port.door())
	game.select_entity(port)
	game.hud.refresh()
	await settle()
	check(game.merchant.visible and game.merchant.state=="docked","Existing boat sprite appears physically at the dock")
	check(port.sprite.texture.get_size()==Vector2(80,96) and port.sprite.z_index<worker.z_index,"Native size and worker-above-apron rendering")
	await capture("v0061_port_docked_pt")
	root.get_node("Localization").choose("en")
	game.hud.refresh()
	await settle()
	await capture("v0061_port_docked_en")
	check("New trades" in game.hud.detail_label.text,"Port arrival status is translated")
	print("V0.0.6.1 port UI: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

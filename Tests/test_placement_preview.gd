extends "res://Tests/test_v003_ui.gd"

func run() -> void:
	root.get_node("AppSettings").apply_video(Vector2i(1280,720),false)
	game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.simulation_paused=true
	game.village_level=3
	for i in 8: await process_frame
	for kind in game.DATA.CONSTRUCTIBLE:
		for orientation in (4 if kind=="trading_port" else 1):
			var origin := Vector2i(61,23)
			var built=game.add_building(kind,origin,true,orientation)
			var texture: Texture2D=game.DATA.port_texture(orientation) if kind=="trading_port" else game.DATA.building_texture(kind)
			var preview: Rect2=game.DATA.building_art_rect(kind,origin,texture)
			var actual: Rect2=built.sprite.get_global_transform()*built.sprite.get_rect()
			check(preview.is_equal_approx(actual),"Preview and real sprite coincide for %s orientation %d"%[kind,orientation])
			check(is_equal_approx(preview.end.y,(origin.y+built.grid_size.y)*16),"Sprite foot remains at the logical footprint edge")
			check(is_equal_approx(preview.get_center().x,origin.x*16+built.grid_size.x*8),"Sprite remains horizontally centered over the logical grid")
			game.buildings.erase(built)
			built.free()
	game.base.stored.wood=80
	game.base.stored.stone=80
	game.begin_placement("smelter")
	game.camera.position=game.cell_center(Vector2i(62,25))
	game.camera.zoom=Vector2(3,3)
	game.camera.zoom_target=-1
	game.camera.force_update_scroll()
	game.pointer_position=game.get_global_transform_with_canvas()*game.cell_center(Vector2i(62,24))
	for i in 8: await process_frame
	check(game.preview_cell==Vector2i(61,23),"Preview follows the selected ground cells")
	check(game.preview_valid,"Smelter preview is on buildable ground")
	await capture("v0061_preview_aligned")
	var rect: Rect2=game.DATA.building_art_rect("smelter",game.preview_cell,game.preview_texture)
	var built=game.place_building("smelter",game.preview_cell)
	check(built!=null,"Confirmation builds exactly at the preview origin")
	if built!=null: check(rect.is_equal_approx(built.sprite.get_global_transform()*built.sprite.get_rect()),"Confirming placement does not shift the image")
	await capture("v0061_preview_confirmed")
	print("Placement preview: ",checks," checks; ",failures," failures")
	quit(1 if failures else 0)

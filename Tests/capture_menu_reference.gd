extends SceneTree
func _initialize() -> void: call_deferred("capture")
func capture() -> void:
	root.size = Vector2i(1100, 550)
	var menu = load("res://Scenes/menu_ex.tscn").instantiate()
	menu.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	root.add_child(menu)
	var rect: Rect2i = menu.get_used_rect()
	print("MENU BOUNDS ", rect)
	var sources := {}
	for cell in menu.get_used_cells():
		var key = str(menu.get_cell_source_id(cell)) + ":" + str(menu.get_cell_atlas_coords(cell))
		sources[key] = sources.get(key, 0) + 1
	print(sources)
	var frame_tiles := {}
	for cell in menu.get_node("TileMapLayer2").get_used_cells():
		var atlas: Vector2i = menu.get_node("TileMapLayer2").get_cell_atlas_coords(cell)
		frame_tiles[str(atlas)] = frame_tiles.get(str(atlas), 0) + 1
	print("FRAMES ", frame_tiles)
	var camera := Camera2D.new()
	root.add_child(camera)
	camera.position = Vector2(rect.position * 16) + Vector2(rect.size * 16) / 2
	var zoom_factor := minf(1000.0 / (rect.size.x * 16), 450.0 / (rect.size.y * 16))
	camera.zoom = Vector2.ONE * zoom_factor
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/menu_reference.png")
	quit()

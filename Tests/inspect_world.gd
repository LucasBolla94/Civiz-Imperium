extends SceneTree

func _initialize() -> void:
	var world = load("res://Scenes/world.tscn").instantiate()
	root.add_child(world)
	for layer in world.get_children():
		if layer is TileMapLayer:
			print(layer.name, " cells=", layer.get_used_cells().size(), " bounds=", layer.get_used_rect())
			if layer.name in ["Fruit", "Stone", "TileMapLayer2"]:
				for cell in layer.get_used_cells():
					print("  ", cell, " atlas=", layer.get_cell_atlas_coords(cell))
	quit()

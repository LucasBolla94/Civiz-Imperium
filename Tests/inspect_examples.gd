extends SceneTree
func _initialize() -> void:
	for path in ["res://Scenes/buildings_exemples.tscn", "res://Scenes/Objects_Exemple.tscn"]:
		var scene = load(path).instantiate()
		for layer in scene.get_children():
			if layer is TileMapLayer:
				print(layer.name, " bounds=", layer.get_used_rect(), " cells=", layer.get_used_cells().size())
				if layer.name == "Building-6":
					for cell in layer.get_used_cells(): print(cell, " atlas ", layer.get_cell_atlas_coords(cell))
		scene.free()
	quit()

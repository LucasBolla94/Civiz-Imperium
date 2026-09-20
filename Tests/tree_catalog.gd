extends SceneTree
func _initialize() -> void:
	var catalog = load("res://Scripts/example_catalog.gd")
	catalog.ensure_loaded()
	for key in catalog.entries:
		if key.begins_with("Tree"):
			print(key, " ", catalog.entries[key].tiles)
	quit()

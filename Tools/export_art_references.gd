extends SceneTree
func _initialize() -> void:
	var catalog=preload("res://Scripts/example_catalog.gd")
	DirAccess.make_dir_recursive_absolute("res://Tools/ArtSources")
	for key in ["Building-1","Building-3","Building-5","Stone"]:
		var image: Image=catalog.entry(key).texture.get_image()
		image.save_png("res://Tools/ArtSources/"+key+".png")
		print(key," ",image.get_size())
	quit()

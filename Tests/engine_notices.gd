extends SceneTree
func _initialize() -> void:
	var file := FileAccess.open("res://Builds/Civiz-Imperium-V0.0.5/GODOT-LICENSE.txt",FileAccess.WRITE)
	file.store_string(Engine.get_license_text())
	file.store_string("\n\nThird-party licenses and notices\n\n")
	file.store_string(JSON.stringify(Engine.get_copyright_info(),"  "))
	file.store_string("\n\n" + JSON.stringify(Engine.get_license_info(),"  "))
	file.close()
	quit()

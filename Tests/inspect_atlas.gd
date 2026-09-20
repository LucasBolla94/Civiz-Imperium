extends SceneTree
func _initialize() -> void:
	var img = load("res://Assets/Houses/model1/Desert-Houses-Sheet.png").get_image()
	print("ATLAS ", img.get_size())
	var spans := []
	var start := -1
	for x in range(img.get_width() + 1):
		var opaque := false
		if x < img.get_width():
			for y in range(img.get_height()):
				if img.get_pixel(x,y).a > 0.01: opaque = true
		if opaque and start < 0: start = x
		if not opaque and start >= 0:
			spans.append(Vector2i(start, x))
			start = -1
	print("Occupied columns: ", spans)
	img.resize(img.get_width()*5, img.get_height()*5, Image.INTERPOLATE_NEAREST)
	img.save_png("res://Tests/atlas_inspection.png")
	quit()

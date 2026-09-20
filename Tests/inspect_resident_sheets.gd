extends SceneTree
func _initialize() -> void:
	var canvas := Image.create(192, 32 * 9, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("33434d"))
	var row := 0
	for variant in ["Pink_Monster", "Dude_Monster", "Owlet_Monster"]:
		var index := ["Pink_Monster", "Dude_Monster", "Owlet_Monster"].find(variant) + 1
		for clip in ["Idle_4", "Walk_6", "Push_6"]:
			var sheet := Image.load_from_file("res://Assets/Characters/char-%d/%s_%s.png" % [index, variant, clip])
			canvas.blend_rect(sheet, Rect2i(Vector2i.ZERO, sheet.get_size()), Vector2i(0, row * 32))
			var heights := []
			for frame in range(sheet.get_width() / 32):
				var x := 18 if clip == "Push_6" else 15
				for y in range(32):
					if sheet.get_pixel(frame * 32 + x, y).a > 0.5:
						heights.append(y)
						break
			print(variant, " ", clip, " ", heights)
			row += 1
	canvas.resize(768, 1152, Image.INTERPOLATE_NEAREST)
	canvas.save_png("res://Tests/resident_sheets.png")
	quit()

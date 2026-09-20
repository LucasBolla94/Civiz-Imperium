extends SceneTree
const LAYOUT = preload("res://Scripts/window_layout.gd")
func _initialize() -> void:
	var checks := 0
	for monitor in [Rect2i(0,0,1920,1040), Rect2i(0,0,1366,728), Rect2i(-1920,-200,1920,1080), Rect2i(1920,0,3840,2120), Rect2i(0,0,640,360), Rect2i(0,0,720,1280)]:
		for requested in [Vector2i(1920,1080), Vector2i(1280,720), Vector2i(3440,1440)]:
			var fitted := LAYOUT.fitted_rect(monitor, requested)
			assert(monitor.encloses(fitted), "Window must fit its monitor")
			assert(fitted.size.x > 0 and fitted.size.y > 0, "Positive window dimensions")
			assert(absf(float(fitted.size.x) / fitted.size.y - float(requested.x) / requested.y) < 0.02, "Preserve window proportions")
			assert((Vector2(fitted.get_center()) - Vector2(monitor.get_center())).length() < 2, "Center including monitor origin")
			checks += 4
	print("Window layout: %d checks; 0 failures" % checks)
	quit()

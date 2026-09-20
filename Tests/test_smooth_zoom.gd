extends "res://Tests/test_v003.gd"
func run() -> void:
	fresh()
	var camera = game.camera
	camera.zoom = Vector2.ONE*2
	camera.smooth_zoom(1.12)
	check(camera.zoom.x == 2,"Keyboard zoom starts without a jump")
	camera.advance_zoom(1.0/60.0)
	check(camera.zoom.x > 2 and camera.zoom.x < 2.24,"First frame is a partial smooth step")
	var previous: float = camera.zoom.x
	var monotonic := true
	for frame in 60:
		camera.advance_zoom(1.0/60.0)
		monotonic = monotonic and camera.zoom.x >= previous and camera.zoom.x <= 2.24001
		previous = camera.zoom.x
	check(monotonic and is_equal_approx(camera.zoom.x,2.24),"Smooth zoom converges monotonically without overshoot")
	camera.smooth_zoom(1.0/1.12)
	camera.advance_zoom(1.0)
	check(is_equal_approx(camera.zoom.x,2.0),"Opposite step restores original zoom")
	camera.smooth_zoom(1.12)
	camera.advance_zoom(1.0/60.0)
	camera.smooth_zoom(1.0/1.12)
	check(is_equal_approx(camera.zoom_target,2.0),"Reversing direction during animation targets original scale")
	camera.advance_zoom(1.0)
	for frame in 60:
		camera.smooth_zoom(exp(camera.HELD_ZOOM_RATE/60.0))
		camera.advance_zoom(1.0/60.0)
	check(camera.zoom.x > 3 and camera.zoom.x < 5,"Holding increases zoom continuously at a controlled rate")
	camera.smooth_zoom(100)
	camera.advance_zoom(1.0)
	check(camera.zoom.x == 5,"Maximum zoom clamped")
	camera.smooth_zoom(0.001)
	camera.advance_zoom(1.0)
	check(is_equal_approx(camera.zoom.x,0.8),"Minimum zoom clamped")
	camera.smooth_zoom(1.12)
	camera.change_zoom(1.12)
	check(camera.zoom_target == -1 and is_equal_approx(camera.zoom.x,0.896),"Mouse wheel cancels keyboard easing and keeps existing step")
	camera.smooth_zoom(1.12)
	game.hud.open_game_menu()
	camera._process(0.1)
	check(camera.zoom_target == -1,"Modal cancels pending keyboard motion")
	game.hud.game_menu.hide()
	camera.smooth_zoom(1.12)
	camera.reset_view()
	check(camera.zoom_target == -1,"Center camera cancels pending zoom")
	print("Smooth zoom: ",checks," checks; ",failures.size()," failures")
	game.free()
	quit(0 if failures.is_empty() else 1)

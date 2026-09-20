extends "res://Tests/test_v003.gd"
func run() -> void:
	fresh()
	stop_workers()
	game.add_building("house",Vector2i(42,23),true)
	game.rebuild_navigation()
	game.base.store("fruit",30)
	game.immigration.prepare_expedition()
	game.immigration.tick(36)
	var original: Vector2i = game.immigration.dock
	for direction in game.CARDINALS:
		var neighbor: Vector2i = original + direction
		if game.navigation.is_in_boundsv(neighbor): game.navigation.set_point_solid(neighbor)
	game.immigration.tick(20)
	print("Dock stays walkable: ",game.is_walkable(original))
	print("Ship stalled without arrival: ",game.immigration.sailing and game.immigration.arrivals == 0)
	print("Another reachable dock exists: ",game.immigration.find_dock() and game.immigration.dock != original)
	game.free()
	quit()

extends SceneTree
var game
func _initialize() -> void: call_deferred("run")
func tick(seconds: float) -> void:
	for i in range(ceili(seconds / 0.1)):
		game._process(0.1)
		for source in game.sources.duplicate(): source._process(0.1)
		for building in game.buildings.duplicate(): building._process(0.1)
		for worker in game.workers.duplicate(): worker._process(0.1)
func capture(name: String) -> void:
	game.hud.refresh()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://Tests/" + name + ".png")
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.process_mode = Node.PROCESS_MODE_DISABLED
	await capture("v002_construction")
	game.select_entity(game.base)
	await capture("v002_base")
	var food = game.place_building("food",Vector2i(59,25))
	game.place_building("stone",Vector2i(47,33))
	game.place_building("wood",Vector2i(60,34))
	for i in range(3): game.base.enqueue()
	tick(80)
	for activity in ["food","stone","wood"]: game.change_allocation(activity,1)
	game.place_job("plant",Vector2i(43,24))
	game.place_job("plant",Vector2i(43,29))
	tick(60)
	game.select_entity(food)
	await capture("v002_orchard")
	game.place_job("expand",Vector2i(71,27))
	tick(120)
	game.upgrade_village()
	game.select_entity(game.base)
	await capture("v002_expansion")
	print("Natural playthrough level=",game.village_level," stock=",game.stock," trees=",game.planted_count," expansions=",game.expansion_count)
	if game.village_level != 2:
		push_error("Natural economy failed to reach level 2")
		quit(1)
		return
	game.place_job("plant",Vector2i(43,34))
	game.place_job("plant",Vector2i(64,23))
	game.place_job("expand",Vector2i(74,27))
	tick(45)
	game.place_job("expand",Vector2i(71,30))
	for step in range(60):
		tick(10)
		if game.upgrade_ready(): break
	game.upgrade_village()
	game.select_entity(null)
	await capture("v002_village")
	print("Natural playthrough final level=",game.village_level," stock=",game.stock," trees=",game.planted_count," expansions=",game.expansion_count)
	quit(0 if game.village_level == 3 else 1)

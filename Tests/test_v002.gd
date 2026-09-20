extends SceneTree
var game
var failures: Array[String] = []
var checks := 0
func check(value: bool, text: String) -> void:
	checks += 1
	if not value:
		failures.append(text)
		push_error(text)
func tick(seconds: float) -> void:
	for i in range(ceili(seconds / 0.1)):
		game._process(0.1)
		for source in game.sources.duplicate(): source._process(0.1)
		for building in game.buildings.duplicate(): building._process(0.1)
		for worker in game.workers.duplicate():
			worker._process(0.1)
			if not game.is_walkable(game.world_cell(worker.position)): check(false,"Worker left walkable ground")
func click(point: Vector2) -> void:
	for pressed in [true,false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		root.push_input(event,true)
	await process_frame
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size = Vector2i(1280,800)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	await process_frame
	check(game.hud.construction_menu.visible and not game.hud.building_actions.visible,"Starts with construction menu")
	await click(game.get_global_transform_with_canvas() * game.cell_center(game.base.origin + Vector2i(3,3)))
	check(not game.hud.construction_menu.visible and game.hud.building_actions.visible,"Building click replaces construction menu")
	await click(Vector2(1100,450))
	check(game.selection == null and game.hud.construction_menu.visible,"Empty map click restores menu")
	game.process_mode = Node.PROCESS_MODE_DISABLED
	check(game.base.grid_size == Vector2i(9,9),"Building-6 retained")
	for stage in range(1,8):
		check(game.DATA.CATALOG.entry("Tree-%d" % stage).size.x <= 3,"Each tree stage isolated")
	var fruit = game.sources[1]
	var dead = game.sources[2]
	check(fruit.harvestable("food") and not fruit.harvestable("wood"),"Fruit stage only yields food")
	check(dead.harvestable("wood") and not dead.harvestable("food"),"Final stage only yields wood")
	check(fruit.take(1,"wood") == 0,"Wrong worker cannot harvest fruit as wood")
	var food = game.place_building("food",Vector2i(59,25))
	var stone = game.place_building("stone",Vector2i(47,33))
	var wood = game.place_building("wood",Vector2i(60,34))
	check(food != null and stone != null and wood != null,"Three activity buildings fit initial island")
	if food == null or stone == null or wood == null:
		finish()
		return
	for i in range(3): check(game.base.enqueue(),"Recruit at base")
	tick(80)
	check(food.completed and stone.completed and wood.completed,"Constructor completes all depots")
	check(game.workers.size() == 4,"Queued population spawned")
	for activity in ["food","stone","wood"]: check(game.change_allocation(activity,1),"Allocate activity")
	tick(60)
	check(game.total_delivered.food > 0 and game.total_delivered.wood > 0 and game.total_delivered.stone > 0,"All resource types delivered to depots")
	check(wood.stored.wood > 0,"Wood stored at lumber depot")
	game.select_entity(food)
	check(game.hud.plant_button.visible and not game.hud.construction_menu.visible,"Food depot exposes planting instead of buildings")
	var plant = game.place_job("plant",Vector2i(43,24))
	check(plant != null,"Reserve valid orchard")
	check(not game.can_place_job("plant",Vector2i(43,24)),"No overlapping planting reservations")
	tick(30)
	check(plant.completed and game.planted_count == 1,"Food worker plants automatically")
	var tree = game.sources[-1]
	check(tree.is_tree and not tree.harvestable("wood"),"New tree not cuttable")
	game.simulation_paused = true
	var age: float = tree.age
	tick(5)
	check(tree.age == age,"Pause freezes tree aging")
	game.simulation_paused = false
	# Finite clock phases; exhausting fruit cannot skip to wood.
	tree.set_stage(4)
	tree.take(tree.remaining,"food")
	check(tree.stage == 4 and tree.blocks_ground() and not tree.harvestable("wood"),"Harvest does not bypass maturation time")
	tree._process(161)
	check(tree.stage == 5 and not tree.harvestable("food") and not tree.harvestable("wood"),"Aging phase cannot be harvested")
	tree._process(21)
	check(tree.stage == 6 and tree.harvestable("wood"),"Final phase becomes lumber")
	var old_cells: Array[Vector2i] = tree.cells.duplicate()
	tree.take(30,"wood")
	check(tree.removed and game.is_walkable(old_cells[0]),"Felling releases orchard space")
	check(not game.can_place_job("expand",Vector2i(80,40)),"Expansion must touch existing land")
	var expansion = game.place_job("expand",Vector2i(71,27))
	check(expansion != null,"Coastal expansion can be ordered")
	tick(45)
	check(expansion.completed and game.expansion_count == 1,"Builder completes reclamation")
	check(game.land.get_cell_source_id(Vector2i(73,29)) >= 0 and game.is_walkable(Vector2i(73,29)),"New territory navigable")
	var before: int = game.stock.food
	check(game.coastal_aid() and game.stock.food == before + 4,"Coastal food recovery")
	check(not game.coastal_aid(),"Coastal aid cooldown enforced")
	check(game.upgrade_ready() == game.can_afford(game.upgrade_cost()),"Evolution availability matches displayed resource cost")
	# Replant cleared cell, harvest renewable cycle, evolve using earned resources.
	game.place_job("plant",Vector2i(43,24))
	tick(35)
	check(game.planted_count == 2,"Cleared orchard can be replanted")
	game.stock = {"food":100,"stone":100,"wood":100}
	check(game.upgrade_village() and game.village_level == 2,"Level 2 evolution")
	check(game.population_limit() == 10 and game.carry_capacity() == 7,"Evolution has functional benefits")
	var p2 = game.place_job("plant",Vector2i(43,29))
	var p3 = game.place_job("plant",Vector2i(43,34))
	var e2 = game.place_job("expand",Vector2i(74,27))
	check(p2 != null and p3 != null and e2 != null,"Further projects accepted")
	tick(90)
	check(game.expansion_count == 2 and game.planted_count == 4,"Expansion and orchards progress in parallel")
	var discovered := false
	for source in game.sources:
		if not source.is_tree and source.origin == Vector2i(74,27): discovered = true
	check(discovered,"Second expansion reveals replenishing stone supply")
	var e3 = game.place_job("expand",Vector2i(71,30))
	check(e3 != null,"Third adjacent expansion")
	tick(60)
	check(game.upgrade_village() and game.village_level == 3,"Reach final playable milestone")
	check(not game.upgrade_village(),"No upgrade beyond level 3")
	finish()
func finish() -> void:
	print("V0.0.2: ",checks," checks; ",failures.size()," failures")
	game.free()
	quit(0 if failures.is_empty() else 1)

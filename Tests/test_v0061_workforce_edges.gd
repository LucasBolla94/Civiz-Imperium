extends "res://Tests/test_v003.gd"

func run() -> void:
	fresh()
	stop_workers()
	game.village_level=3
	var first=game.add_building("gold_mining",Vector2i(43,24),true)
	var second=game.add_building("gold_mining",Vector2i(65,23),true)
	game.rebuild_navigation()
	for i in 3: game.spawn_worker("idle",game.base,game.cell_center(game.base.door()))
	for i in 6:
		check(game.change_allocation("gold_mining",1),"Allocate only an available resident to a real mining post")
		check(absi(game.workplace_count(first,"gold_mining")-game.workplace_count(second,"gold_mining"))<=1,"Global allocation balances relative occupancy across posts")
	check(game.workplace_count(first,"gold_mining")==3 and game.workplace_count(second,"gold_mining")==3,"Two mining posts provide exactly six total positions")
	check(not game.change_allocation("gold_mining",1),"No spare resident means no extra automatic allocation")
	game.hud.workforce_view.reveal("gold_mining")
	game.hud.refresh()
	check(game.hud.activity_controls.gold_mining.amount.text=="6","Central count equals all six actual assignments")
	check(game.hud.workforce_view.building_rows.gold_mining[first.entity_id].count.text=="3" and game.hud.workforce_view.building_rows.gold_mining[second.entity_id].count.text=="3","Local rows agree with their actual three-person teams")
	fresh()
	stop_workers()
	game.village_level=3
	var furnace=game.add_building("smelter",Vector2i(43,24),true)
	game.rebuild_navigation()
	var worker=game.workers[1]
	worker.assign_to("smelter",furnace)
	worker.position=game.cell_center(furnace.door())
	furnace.stored.gold_ore=5
	check(not game.gold.smelt(worker,1) and furnace.stored.gold_ore==5,"Missing wood prevents a batch without consuming ore")
	furnace.stored.gold_ore=0
	furnace.stored.wood=2
	check(not game.gold.smelt(worker,1) and furnace.stored.wood==2,"Missing ore prevents a batch without consuming wood")
	furnace.stored.gold_ore=5
	check(game.gold.smelt(worker,4),"Begin one partial batch")
	worker.person.energy=0
	worker._process(0.1)
	check(worker.state in ["to_rest","resting"],"Exhausted smelter leaves work for actual rest")
	var progress: float=furnace.smelting_batches[0].progress
	for i in 30: worker._process(0.1)
	check(is_equal_approx(furnace.smelting_batches[0].progress,progress) and furnace.stored.gold_bar==0,"Walking to rest or resting never advances abandoned production")
	worker.assign_to("idle",game.base)
	var replacement=game.workers[2]
	replacement.assign_to("smelter",furnace)
	replacement.position=game.cell_center(furnace.door())
	check(game.gold.smelt(replacement,15-progress),"A replacement resumes the exact saved batch")
	check(furnace.stored.gold_bar==1 and furnace.stored.wood==0 and furnace.stored.gold_ore==0,"Rest and reassignment consume the recipe and produce its output only once")
	print("V0.0.6.1 workforce edges: ",checks," checks; ",failures.size()," failures")
	finish()

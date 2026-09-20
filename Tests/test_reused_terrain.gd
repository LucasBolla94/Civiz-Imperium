extends "res://Tests/test_v003.gd"

func run() -> void:
	fresh()
	stop_workers()
	game.village_level=3
	game.base.stored.wood=60
	game.base.stored.stone=50
	var stone=game.add_building("stone",Vector2i(65,23),true)
	stone.level=2
	game.rebuild_navigation()
	var origin := Vector2i(-999,-999)
	for cell in game.land.get_used_cells():
		if game.can_place("house",cell) and game.can_place_job("survey",cell): origin=cell; break
	check(origin!=Vector2i(-999,-999),"Find a genuine reusable plot with access")
	if origin==Vector2i(-999,-999): finish(); return
	game.gold.initial_stones=3
	var survey=game.place_job("survey",origin)
	survey.build(12)
	check(survey.completed and survey.deposit_resource=="gold_ore","Fixture completes a real survey")
	check(not game.can_place("house",origin),"Active surveyed deposit remains protected until released")
	survey.open_quarry()
	survey.materials.delivered=survey.materials.required.duplicate()
	survey.build(15)
	var source=game.sources.filter(func(s): return s.origin==origin)[0]
	source.take(source.remaining,"gold_mining")
	source.release_site()
	var history: Dictionary=game.gold.snapshot()
	check(game.can_place("house",origin),"Exhausted and released deposit accepts a house on the same cells")
	check(not game.can_place_job("survey",origin+Vector2i.ONE),"Overlapping surveys still cannot regenerate exhausted ore")
	check("menu Construir" in game.placement_reason,"Survey explanation directs rebuilding to the correct action")
	game.begin_action("survey")
	game.can_place_job("survey",origin+Vector2i.ONE)
	var size: Vector2i=game.DATA.building_size("house")
	game.pointer_position=game.get_global_transform_with_canvas()*game.cell_center(origin+Vector2i(size.x/2,size.y/2))
	game.begin_placement("house")
	check(game.action_mode.is_empty() and game.preview_valid and game.placement_reason.is_empty(),"Switching to Build immediately clears the old survey error")
	var house=game.place_building("house",origin)
	check(is_instance_valid(house),"Place an actual house over the exhausted deposit")
	if not is_instance_valid(house): finish(); return
	house.materials.delivered=house.materials.required.duplicate()
	house.build(100)
	check(house.completed,"House finishes over historical survey cells")
	check(game.gold.snapshot()==history,"Building never erases underground depletion history")
	var saved: Dictionary=game.saves.snapshot()
	game.saves.restore(saved)
	house=game.buildings.filter(func(b): return b.kind=="house")[0]
	check(house.request_demolition(),"Empty house can be demolished normally")
	house.build(10)
	check(game.can_place("house",origin),"Demolished building footprint is reusable")
	saved=game.saves.snapshot()
	game.saves.restore(saved)
	check(game.can_place("house",origin),"Demolished and historically surveyed footprint remains reusable after reload")
	check(not game.gold.survey_reason(origin).is_empty(),"Reload does not regenerate underground ore")
	check(game.gold.snapshot()==history,"Demolition and reload preserve the same exhausted history")
	var rebuilt=game.place_building("house",origin)
	check(is_instance_valid(rebuilt),"Reconstruction can be ordered at the identical coordinates")
	print("Reused terrain: ",checks," checks; ",failures.size()," failures")
	finish()

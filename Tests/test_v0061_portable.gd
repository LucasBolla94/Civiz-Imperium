extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	assert(ProjectSettings.get_setting("application/config/version")=="0.0.6.1")
	var slots=root.get_node("IslandSaves")
	slots.directory="user://portable-v0061-"+slots.token()
	slots.open_catalog()
	assert(slots.begin_new(0,"Validação portátil"))
	var game=load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.process_mode=Node.PROCESS_MODE_DISABLED
	game.village_level=3
	for worker in game.workers: worker.assign_to("idle",game.base)
	var warehouse=game.add_building("warehouse",Vector2i(43,28),true)
	warehouse.stored.wood=40
	warehouse.stored.gold_bar=20
	var port=game.add_building("trading_port",Vector2i(44,37),true)
	game.rebuild_navigation()
	game.workers[1].assign_to("carrier",game.base)
	for resource in ["gold_ore","gold_bar","produce"]:
		assert(game.DATA.resource_texture(resource).get_size()==Vector2(32,32))
		assert(game.DATA.resource_texture(resource,true).get_size()==Vector2(16,16))
	for orientation in 4: assert(game.DATA.port_texture(orientation).get_size()==Vector2(80,96))
	assert(game.DATA.building_texture("smelter").get_size()==Vector2(64,80))
	assert(root.get_node("Music").stream.clip_count==4)
	game.merchant.tick(60)
	for i in 2000:
		if game.merchant.state=="docked": break
		game.merchant.tick(0.5)
	assert(game.merchant.can_confirm())
	var id: int=game.commerce.confirm("sell","wood",20,"portable-sale")
	assert(id>0 and warehouse.stored.wood==40)
	assert(game.saves.save_file() and game.saves.load_file())
	game.simulation_paused=false
	for i in 4000:
		game._process(0.1)
		for worker in game.workers.duplicate(): worker._process(0.1)
		if game.commerce.order(id).phase=="settled" and game.commerce.order(id).to_store==0: break
	warehouse=game.buildings.filter(func(b): return b.kind=="warehouse")[0]
	assert(game.commerce.order(id).phase=="settled" and warehouse.stored.wood==20 and warehouse.stored.gold_bar==22)
	game.simulation_paused=true
	game.hud.toggle_workforce()
	game.hud.workforce_view.reveal("gold_mining")
	game.hud.refresh()
	for frame in 12: await process_frame
	assert(root.get_visible_rect().encloses(game.hud.workforce_panel.get_global_rect()))
	game.hud.toggle_workforce()
	game.hud.trade_window.open()
	for frame in 12: await process_frame
	assert(game.hud.trade_window.visible)
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var capture := OS.get_environment("CIVIZ_CAPTURE")
		if not capture.is_empty(): root.get_texture().get_image().save_png(capture)
	print("V0.0.6.1 portable: passed")
	quit()

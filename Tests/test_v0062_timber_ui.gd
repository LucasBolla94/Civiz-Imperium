extends "res://Tests/test_v003_ui.gd"
## Confere o botão de plantio de madeira na interface real, nos dois idiomas.
func run() -> void:
	root.size = Vector2i(1280,720)
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.simulation_paused = true
	for worker in game.workers: worker.assign_to("idle",game.base)
	var wood_store = game.add_building("wood",Vector2i(42,30),true)
	var food = game.add_building("food",Vector2i(42,23),true)
	var locale = root.get_node("Localization")
	locale.choose("pt")

	game.select_entity(food)
	check(game.hud.plant_button.visible and not game.hud.timber_button.visible,"O depósito de comida oferece só o plantio frutífero")
	game.select_entity(wood_store)
	check(game.hud.timber_button.visible and not game.hud.plant_button.visible,"O depósito de madeira oferece só o plantio de madeira")
	game.select_entity(game.base)
	check(game.hud.plant_button.visible and game.hud.timber_button.visible,"A base oferece as duas espécies")
	await capture("v0062_timber_base_pt")

	await click(game.hud.timber_button.get_global_rect().get_center())
	check(game.action_mode == "plant_wood","O botão real inicia a marcação de plantio de madeira")
	check(game.hud.title_label.text.contains("madeira"),"O título da marcação identifica a espécie")
	await capture("v0062_timber_marking_pt")
	game.cancel_placement()

	var timber = game.spawn_timber_tree(Vector2i(60,31),game.DATA.TIMBER_MATURE_STAGE)
	game.rebuild_navigation()
	game.select_entity(timber)
	game.hud.refresh()
	check(not game.hud.cut_button.visible,"A árvore de madeira não mostra Cortar agora")
	check(not game.hud.orchard_button.visible,"A árvore de madeira fica fora da renovação de pomar")
	check(game.hud.title_label.text.contains("madeira") and game.hud.detail_label.text.contains("45"),"O painel descreve a árvore de madeira e seu estoque")
	check(is_equal_approx(game.hud.progress.value,100.0),"Árvore intacta mostra estoque cheio")
	await capture("v0062_timber_selected_pt")

	locale.choose("en")
	game.hud.refresh()
	await process_frame
	check(game.hud.timber_button.text.contains("timber") or game.hud.timber_button.text.contains("Timber"),"O botão é traduzido para inglês")
	await capture("v0062_timber_selected_en")

	var fruit = game.sources.filter(func(s): return s.is_tree and not s.is_timber and s.stage == 4)[0]
	game.select_entity(fruit)
	game.hud.refresh()
	check(game.hud.cut_button.visible,"A frutífera mantém Cortar agora")
	print("V0062 timber UI: ",checks," checks; ",failures," failures")
	game.free()
	quit(1 if failures else 0)

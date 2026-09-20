extends "res://Tests/test_v005.gd"
## V0.0.6.2 — plantio de árvore de madeira ao lado do ciclo frutífero preservado.

## Células fixas mantêm a suíte rápida: validar plantio varre a ilha inteira.
const SITES = [Vector2i(43,24), Vector2i(43,28), Vector2i(58,24), Vector2i(60,31)]

func plant_site(mode: String):
	for cell in SITES:
		if game.can_place_job(mode, cell): return game.place_job(mode, cell)
	return null

func run() -> void:
	fresh()
	stop_workers()
	# Sem depósito de madeira a ordem não existe, mesmo com terreno livre.
	var blocked = plant_site("plant_wood")
	check(blocked == null and game.placement_reason.contains("depósito de madeira"), "Plantio de madeira exige depósito de madeira")
	var wood_store = game.add_building("wood", Vector2i(42,30), true)
	check(wood_store != null, "Depósito de madeira construído para o teste")
	var stock_before: int = game.stock.produce
	var job = plant_site("plant_wood")
	check(job != null, "Terreno livre aceita o plantio de madeira")
	check(job.activity == "wood", "O pedido de madeira é executado por lenhadores")
	check(job.materials.required == game.DATA.PLANT_COST, "Muda de madeira custa o mesmo que a frutífera")
	check(job.cells.size() == 12, "O plantio de madeira ocupa a mesma área 3 × 4")

	# Um coletor de comida não assume o pedido; um lenhador assume.
	var worker = game.workers[0]
	worker.assign_to("food", game.base)
	worker.find_job()
	check(worker.target != job, "Coletor de comida ignora o plantio de madeira")
	worker.assign_to("wood", wood_store)
	worker.person.tool = "axe"
	worker.person.durability = game.DATA.TOOL_DURABILITY
	tick(90)
	check(job.completed and game.stock.produce < stock_before, "O lenhador entrega a semente e conclui o plantio")
	var timber = game.sources.filter(func(s): return s.is_timber)[0]
	check(timber != null and timber.is_tree and timber.stage < game.DATA.TIMBER_MATURE_STAGE, "A muda de madeira nasce imatura")
	check(timber.remaining == 0 and not timber.harvestable("food") and not timber.harvestable("wood"), "Muda jovem não rende nada")
	timber.set_stage(0)

	# Crescimento: mesmo tempo total da frutífera, sem nunca produzir Hortifruti.
	timber._process(game.DATA.timber_growth_seconds() - 0.2)
	check(timber.stage < game.DATA.TIMBER_MATURE_STAGE and not timber.harvestable("food"), "Antes de 180s a árvore de madeira ainda cresce")
	timber._process(0.3)
	check(timber.stage == game.DATA.TIMBER_MATURE_STAGE, "Aos 180s a árvore de madeira amadurece")
	check(timber.resource_kind == "wood" and timber.remaining == game.DATA.TIMBER_STOCK, "Árvore madura entrega 45 madeiras")
	check(not timber.harvestable("food") and timber.take(1,"food") == 0, "A árvore de madeira nunca vira fonte de Hortifruti")
	check(timber.harvestable("wood"), "Lenhadores colhem a árvore madura sem ordem de corte")
	check(not timber.request_cut() and not timber.cut_requested, "\"Cortar agora\" não se aplica à árvore de madeira")
	timber._process(600)
	check(timber.stage == game.DATA.TIMBER_MATURE_STAGE and timber.remaining == game.DATA.TIMBER_STOCK, "Árvore madura não envelhece nem perde estoque")

	# Reserva e colheita passam pelo mesmo planejador das árvores naturais.
	var claim: Dictionary = game.work_planner.claim_harvest(worker)
	check(claim.get("source") == timber and claim.resource == "wood", "O planejador reserva a árvore de madeira para o lenhador")
	worker.position = game.cell_center(claim.cell)
	check(game.work_planner.collect(worker) == 1 and timber.remaining == game.DATA.TIMBER_STOCK - 1, "Cada machadada rende uma madeira")

	# Persistência: espécie, estágio e estoque sobrevivem ao salvamento.
	var saved: Dictionary = game.saves.snapshot()
	check(game.saves.valid(saved), "Ilha com árvore de madeira gera salvamento válido")
	game.saves.restore(saved)
	var restored = game.sources.filter(func(s): return s.is_timber)
	check(restored.size() == 1, "A espécie de madeira é restaurada como tal")
	if restored.size() == 1:
		check(restored[0].stage == game.DATA.TIMBER_MATURE_STAGE and restored[0].remaining == game.DATA.TIMBER_STOCK - 1, "Estágio e estoque restante são preservados")
		check(restored[0].tree_sprite.texture == game.DATA.timber_texture(game.DATA.TIMBER_MATURE_STAGE), "A arte restaurada é a da árvore de madeira")
	var corrupt: Dictionary = game.saves.snapshot()
	corrupt.sources.filter(func(s): return s.get("is_timber", false))[0].cut_requested = true
	check(not game.saves.valid(corrupt), "Ordem de corte em árvore de madeira invalida o salvamento")

	# Esgotamento: o terreno volta a ficar livre, sem toco persistente.
	var timber_after = game.sources.filter(func(s): return s.is_timber)[0]
	timber_after.take(game.DATA.TIMBER_STOCK, "wood")
	check(timber_after.removed and timber_after.remaining == 0, "Árvore cortada até o fim é removida")
	# O lenhador restaurado está sobre o terreno; ele sai antes de uma nova marcação.
	for resident in game.workers: resident.position = game.cell_center(game.base.door())
	var free: bool = game.can_place_job("plant_wood", timber_after.origin)
	if not free: print("motivo do terreno: ", game.placement_reason)
	check(free, "O terreno liberado aceita um novo plantio de madeira")

	# O ciclo da árvore frutífera permanece inalterado.
	fresh()
	stop_workers()
	var fruit = game.sources.filter(func(s): return s.is_tree and s.stage == 4)[0]
	check(not fruit.is_timber and fruit.remaining == 50, "Árvore frutífera continua com 50 Hortifruti")
	check(fruit.take(50,"food") == 50 and fruit.stage == 6 and fruit.remaining == 30, "Frutífera esgotada ainda vira 30 madeiras")
	var young = game.spawn_tree(Vector2i(50,26), 4)
	check(young.request_cut() and young.cut_requested, "\"Cortar agora\" continua disponível na frutífera adulta")
	finish()

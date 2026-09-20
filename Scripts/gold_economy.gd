extends RefCounted
const BALANCE = preload("res://Scripts/economy_data.gd")
const USED_GROUND_HINT = "Área já investigada. Para construir no terreno liberado, escolha um prédio no menu Construir. Investigar novamente não renova a jazida."
var game
var rng := RandomNumberGenerator.new()
var discoveries: Dictionary = {}
var surveyed_cells: Dictionary = {}
var initial_stones := 0
var protection_used := false

func _init() -> void: rng.randomize()

func survey_reason(origin: Vector2i) -> String:
	for y in 3:
		for x in 3:
			var cell := origin+Vector2i(x,y)
			if surveyed_cells.has(cell) and surveyed_cells[cell]!=origin:
				return USED_GROUND_HINT
	if discoveries.has(origin) and discoveries[origin].state in ["released","opened","exhausted"]:
		return USED_GROUND_HINT
	return ""

func register_survey(job) -> void:
	if not discoveries.has(job.origin):
		var gold := false
		if game.village_level>=3:
			gold=(not protection_used and initial_stones>=BALANCE.GUARANTEE_AFTER_STONE) or rng.randf()<BALANCE.GOLD_CHANCE
			if not protection_used:
				if gold: protection_used=true
				else: initial_stones+=1
		var amount: int=BALANCE.GOLD_RESERVES[rng.randi_range(0,2)] if gold else job.deposit
		discoveries[job.origin]={"resource":"gold_ore" if gold else "stone","reserve":amount,"state":"surveyed"}
		for cell in job.cells: surveyed_cells[cell]=job.origin
	var result: Dictionary=discoveries[job.origin]
	job.deposit_resource=result.resource
	job.deposit=result.reserve

func mark(origin: Vector2i, state: String) -> void:
	if discoveries.has(origin): discoveries[origin].state=state

func snapshot() -> Dictionary:
	return {"rng_seed":rng.seed,"rng_state":rng.state,"discoveries":discoveries.duplicate(true),"initial_stones":initial_stones,"protection_used":protection_used}

func restore(data: Dictionary) -> void:
	discoveries=data.get("discoveries",{}).duplicate(true)
	initial_stones=data.get("initial_stones",0)
	protection_used=data.get("protection_used",false)
	if data.has("rng_seed"): rng.seed=data.rng_seed
	if data.has("rng_state"): rng.state=data.rng_state
	surveyed_cells.clear()
	# Legacy deposits, including exhausted stone, remain historical stone.
	for source in game.sources:
		if source.is_tree: continue
		if not discoveries.has(source.origin):
			discoveries[source.origin]={"resource":source.resource_kind,"reserve":source.initial_reserve,"state":"exhausted" if source.remaining==0 else "opened"}
		for cell in source.cells: surveyed_cells[cell]=source.origin
	for job in game.jobs:
		if job.kind not in ["survey","quarry"]: continue
		if not discoveries.has(job.origin):
			discoveries[job.origin]={"resource":job.deposit_resource,"reserve":job.deposit,"state":"released" if job.released else ("opened" if job.kind=="quarry" else "surveyed")}
	for origin in discoveries:
		for y in 3:
			for x in 3: surveyed_cells[origin+Vector2i(x,y)]=origin

func post_space(post, except_worker=null) -> int:
	if not is_instance_valid(post) or post.kind!="gold_mining" or not post.completed or post.demolition_requested: return 0
	var free: int=game.logistics.storage_free(post)
	for worker in game.workers:
		if worker==except_worker or worker.assigned_home!=post: continue
		if worker.cargo_resource=="gold_ore" and worker.ticket.is_empty(): free-=worker.cargo
		if game.work_planner.claims.has(worker): free-=game.work_planner.claims[worker].remaining
	return maxi(0,free)

func smelter_space(building, resource: String) -> int:
	var reserved_outputs := 0
	if resource=="gold_bar":
		for batch in building.smelting_batches:
			if batch.active: reserved_outputs+=1
	return maxi(0,BALANCE.SMELTER_CAPS.get(resource,0)-building.stored.get(resource,0)-game.logistics.incoming(building,resource)-reserved_outputs)

func release_bench(worker) -> void:
	for building in game.buildings:
		if building.kind!="smelter": continue
		for batch in building.smelting_batches:
			if batch.get("worker",0)==worker.person.id: batch.worker=0

func bench_for(worker) -> int:
	var building=worker.assigned_home
	if not is_instance_valid(building) or building.kind!="smelter" or not building.completed or building.demolition_requested: return -1
	for i in building.smelting_batches.size():
		if building.smelting_batches[i].worker==worker.person.id: return i
	# Resume the oldest partially finished batch before starting another.
	for active in [true,false]:
		for i in building.smelting_batches.size():
			var batch: Dictionary=building.smelting_batches[i]
			if batch.worker==0 and batch.active==active:
				if not active and not can_start(building): continue
				batch.worker=worker.person.id
				return i
	return -1

func can_start(building) -> bool:
	if smelter_space(building,"gold_bar")<1: return false
	for resource in BALANCE.SMELTER_RECIPE:
		if game.logistics.available(building,resource)<BALANCE.SMELTER_RECIPE[resource]: return false
	return true

func smelt(worker, delta: float) -> bool:
	var building=worker.assigned_home
	if delta<=0 or not is_instance_valid(building) or worker.kind!="smelter" or worker.assignment!="smelter" or game.world_cell(worker.position)!=building.door(): return false
	var index := bench_for(worker)
	if index<0: return false
	var batch: Dictionary=building.smelting_batches[index]
	if not batch.active:
		if not can_start(building): batch.worker=0; return false
		for resource in BALANCE.SMELTER_RECIPE: building.stored[resource]-=BALANCE.SMELTER_RECIPE[resource]
		batch.active=true
		batch.progress=0.0
	batch.progress+=delta
	building.fire_until_msec=Time.get_ticks_msec()+250
	if batch.progress>=BALANCE.SMELTER_SECONDS:
		# The output slot belongs to this batch from its start.
		building.stored.gold_bar+=1
		batch.active=false
		batch.progress=0.0
		batch.worker=0
	building.queue_redraw()
	return true

func smelter_status(building) -> String:
	var active := 0
	for batch in building.smelting_batches:
		if batch.active: active+=1
	if active>0: return "Fundição: %d lotes em andamento"%active
	if smelter_space(building,"gold_bar")==0: return "Saída cheia — aguardando transporte de barras"
	if game.logistics.available(building,"gold_ore")<5: return "Aguardando minério de ouro"
	if game.logistics.available(building,"wood")<2: return "Aguardando madeira para o forno"
	return "Aguardando trabalhador da fundição"

func progression_text() -> String:
	if not game.buildings.any(func(b): return b.kind=="stone" and b.completed and b.level>=2): return "Era do ouro: melhore o depósito de pedra para investigar terrenos."
	if not game.sources.any(func(s): return s.resource_kind=="gold_ore" and not s.removed and s.remaining>0):
		if game.jobs.any(func(j): return j.kind=="survey" and j.completed and not j.released and j.deposit_resource=="gold_ore"): return "Ouro descoberto: selecione a área e abra a jazida com um construtor."
		return "Investigue terrenos para encontrar ouro. Resultados permanecem fixos por local."
	if not game.buildings.any(func(b): return b.kind=="gold_mining" and b.completed): return "Construa um posto de mineração para extrair o ouro descoberto."
	if game.activity_count("gold_mining")==0: return "Aloque mineiros de ouro em Habitantes. Eles usam picaretas."
	if not game.buildings.any(func(b): return b.kind=="smelter" and b.completed): return "Construa uma fundição: minério e madeira viram barras de ouro."
	if game.activity_count("smelter")==0 or game.activity_count("carrier")==0: return "Aloque fundidores e transportadores para produzir e guardar barras."
	return "Produza cinco barras para construir o porto comercial e abrir novas rotas."

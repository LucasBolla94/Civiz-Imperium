extends "res://Tests/test_v003.gd"

func run() -> void:
	fresh()
	check(not game.can_place("gold_mining",Vector2i(43,24)),"Gold buildings require base level three")
	game.village_level=3
	var seed_value := 0
	var random := RandomNumberGenerator.new()
	while true:
		random.seed=seed_value
		if random.randf()>=0.25 and random.randf()>=0.25 and random.randf()>=0.25: break
		seed_value+=1
	game.gold.rng.seed=seed_value
	for i in 4:
		var job=game.JOB.new()
		job.setup(game,"survey",Vector2i(-30+i*4,0),Vector2i.ZERO)
		game.gold.register_survey(job)
		check(job.deposit_resource==("gold_ore" if i==3 else "stone"),"Fourth discovery protects against initial bad luck")
		var first: int=job.deposit
		var state: int=game.gold.rng.state
		game.gold.register_survey(job)
		check(job.deposit==first and game.gold.rng.state==state,"Retry keeps deposit and random state")
		check(not game.gold.survey_reason(job.origin+Vector2i.ONE).is_empty(),"Overlap cannot reroll an earlier discovery")
		job.free()
	check(game.gold.protection_used,"Initial gold protection is consumed once")
	var record: Dictionary=game.gold.snapshot()
	game.gold.restore(record)
	check(game.gold.rng.state==record.rng_state,"Random generator survives persistence exactly")
	game.gold.mark(Vector2i(-18,0),"released")
	check(not game.gold.survey_reason(Vector2i(-18,0)).is_empty(),"Released deposit cannot regenerate")
	var furnace=game.add_building("smelter",Vector2i(65,23),true)
	var post=game.add_building("gold_mining",Vector2i(43,24),true)
	game.rebuild_navigation()
	furnace.stored.gold_ore=10
	furnace.stored.wood=4
	var first_worker=game.workers[1]
	var second_worker=game.workers[2]
	for worker in [first_worker,second_worker]:
		worker.assign_to("smelter",furnace)
		worker.position=game.cell_center(furnace.door())
	check(game.workplace_capacity(furnace,"smelter")==2 and game.workplace_for("smelter")==null,"Two assigned workers fill the smelter")
	check(game.gold.smelt(first_worker,6) and game.gold.smelt(second_worker,7),"Two workers own distinct batches")
	check(furnace.stored.gold_ore==0 and furnace.stored.wood==0 and furnace.stored.gold_bar==0,"Ingredients consumed exactly at start, no early bar")
	first_worker.interrupt_task()
	check(furnace.smelting_batches.filter(func(b): return b.active).size()==2,"Interrupted worker leaves batch intact")
	check(game.gold.smelt(first_worker,9),"Partial batch resumes")
	check(furnace.stored.gold_bar==1,"One completed batch creates exactly one bar")
	check(game.gold.smelt(second_worker,8),"Second batch completes independently")
	check(furnace.stored.gold_bar==2,"Exact total output for two recipes")
	check(not game.gold.smelt(first_worker,15),"No recipe starts without ingredients")
	furnace.stored.gold_ore=30
	furnace.stored.wood=12
	furnace.stored.gold_bar=19
	check(game.gold.smelt(first_worker,1),"Last output slot can be reserved")
	check(not game.gold.smelt(second_worker,1),"Other bench cannot reserve occupied final output slot")
	check(furnace.store("gold_ore",50)==5 and furnace.stored.gold_ore==30,"Ore input has a separate hard limit")
	var saved=game.saves.snapshot()
	check(game.saves.valid(saved),"New save schema is valid")
	game.saves.restore(saved)
	furnace=game.buildings.filter(func(b): return b.kind=="smelter")[0]
	check(furnace.smelting_batches.any(func(b): return b.active and is_equal_approx(b.progress,1)),"Save/load preserves partial recipe")
	check(furnace.smelting_batches.all(func(b): return b.worker==0),"Transient bench claims are reconstructed")
	first_worker=game.workers[1]
	first_worker.position=game.cell_center(furnace.door())
	check(game.gold.smelt(first_worker,14),"Restored partial batch can finish")
	check(furnace.stored.gold_bar==20 and furnace.stored.gold_ore==30,"Reload does not consume the recipe twice")
	check(not game.gold.smelt(first_worker,15),"Full output pauses production")
	post=game.buildings.filter(func(b): return b.kind=="gold_mining")[0]
	check(post.accepts("gold_ore") and not post.accepts("gold_bar") and post.capacity()==100,"Mining post stores only ore with capacity 100")
	check(game.DATA.TOOLS.gold_mining=="pickaxe" and game.DATA.ECONOMY.GOLD_HARVEST_SECONDS==6,"Gold reuses pickaxes with six-second work cycle")
	var deposit=game.SOURCE.new()
	deposit.setup_quarry(game,Vector2i(61,34),1)
	deposit.resource_kind="gold_ore"
	game.entities.add_child(deposit)
	game.sources.append(deposit)
	check(deposit.take(1,"gold_mining")==1 and not deposit.removed,"Exhausted gold deposit remains marked until released")
	deposit.release_site()
	check(deposit.removed and deposit.take(1,"gold_mining")==0,"Releasing exhausted gold yields no ore")
	var bad: Dictionary=game.saves.snapshot().duplicate(true)
	bad.buildings.filter(func(b): return b.kind=="smelter")[0].smelting_batches[0].progress=-1.0
	check(not game.saves.valid(bad),"Invalid batch progress cannot enter the running island")
	check(game.gold.discoveries.has(game.initial_stone_cell),"Original stone remains in underground history")
	physical_chain()
	orders_and_demolition()
	print("V0.0.6.1 gold: ",checks," checks; ",failures.size()," failures")
	finish()

func units(resource: String) -> int:
	var result: int=game.stock.get(resource,0)
	for pile in game.logistics.piles: result+=pile.stored.get(resource,0)
	for worker in game.workers:
		if worker.cargo_resource==resource: result+=worker.cargo
	return result

func physical_chain() -> void:
	fresh()
	game.village_level=3
	stop_workers()
	# Isolated fixture, not the resource-free delivery demonstration.
	game.base.stored=game.DATA.empty_stock()
	game.base.stored.merge({"wood":30,"produce":60,"pickaxe":2},true)
	var post=game.add_building("gold_mining",Vector2i(43,24),true)
	var furnace=game.add_building("smelter",Vector2i(65,23),true)
	var warehouse=game.add_building("warehouse",Vector2i(43,30),true)
	var source=game.SOURCE.new()
	source.setup_quarry(game,Vector2i(61,33),30)
	source.resource_kind="gold_ore"
	game.entities.add_child(source)
	game.sources.append(source)
	game.rebuild_navigation()
	game.workers[0].assign_to("carrier",game.base)
	game.workers[1].assign_to("gold_mining",post)
	game.workers[2].assign_to("smelter",furnace)
	var first_withdrawal := false
	var first_ore_at_post := false
	for i in 3000:
		tick(0.1)
		if game.workers[1].cargo>0: first_withdrawal=true
		if post.stored.gold_ore>0: first_ore_at_post=true
		var active: int=furnace.smelting_batches.filter(func(b): return b.active).size()
		var bars := units("gold_bar")
		check(source.remaining+units("gold_ore")+5*(bars+active)==30,"Ore conserved through every mining/carrying/smelting step")
		check(units("wood")+2*(bars+active)==30,"Wood consumed only by complete recipe starts")
		check(post.used()<=100 and furnace.stored.gold_ore<=30 and furnace.stored.wood<=12 and furnace.stored.gold_bar+active<=20,"All buffers respect capacity throughout physical work")
		if warehouse.stored.gold_bar>=2: break
	check(first_withdrawal and first_ore_at_post,"Gold miner physically collects and returns to own post")
	check(warehouse.stored.gold_bar>=2,"Carrier supplies furnace and delivers real bars to general warehouse")
	check(game.workers[1].person.durability<45,"Gold extraction wears the existing pickaxe")
	check(game.logistics.piles.filter(func(p): return p.resource_kind=="gold_ore").is_empty(),"Gold miners do not dump ore instead of using their post")

func orders_and_demolition() -> void:
	fresh()
	stop_workers()
	game.village_level=3
	var stone=game.add_building("stone",Vector2i(43,24),true)
	stone.level=2
	game.rebuild_navigation()
	var job=null
	for cell in game.land.get_used_cells():
		if game.can_place_job("survey",cell): job=game.place_job("survey",cell); break
	check(job!=null,"Survey has a legal physical site")
	if job==null: return
	var cell: Vector2i=job.origin
	var reserve: int=job.deposit
	var resource: String=job.deposit_resource
	var state: int=game.gold.rng.state
	check(job.cancel_survey(),"In-progress survey can be cancelled through its action")
	var restored=game.place_job("survey",cell)
	check(restored!=null and restored.deposit==reserve and restored.deposit_resource==resource and game.gold.rng.state==state,"Replacing a cancelled physical survey preserves the exact result")
	var furnace=game.add_building("smelter",Vector2i(65,23),true)
	furnace.stored.gold_ore=10
	furnace.stored.wood=4
	game.rebuild_navigation()
	var worker=game.workers[1]
	worker.assign_to("smelter",furnace)
	worker.position=game.cell_center(furnace.door())
	check(game.gold.smelt(worker,4),"Start a real batch before demolition")
	furnace.request_demolition()
	furnace.build(10)
	check(units("gold_ore")==5 and units("wood")==game.DATA.STARTING_STOCK.wood+2 and units("gold_bar")==0,"Demolition salvages unconsumed stock, not consumed batch ingredients")
	check(worker.assignment=="idle" and worker.kind=="idle","Demolished smelter releases its worker without profession migration")
	for path in ["res://Assets/Buildings/Gold/gold_mining_post.png","res://Assets/Buildings/Gold/smelter.png"]:
		var texture: Texture2D=load(path)
		check(texture.get_size()==Vector2(64,80),"Gold buildings keep contractual canvas dimensions")
	var reference: WeakRef = weakref(game.DATA.gold_deposit_texture(false))
	check(reference.get_ref()!=null,"Deposit textures stay alive after draw calls")

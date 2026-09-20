extends "res://Tests/test_v0061_commerce.gd"
var records: Array=[]
var inventories: Array=[]

func run() -> void:
	var slots=root.get_node("IslandSaves")
	slots.directory="user://test-v0061-five-islands-"+slots.token()
	slots.open_catalog()
	for index in 5:
		fixture()
		check(slots.begin_new(index,"Comércio %d"%index),"Reserve isolated slot %d"%index)
		game.gold.rng.seed=170+index
		game.gold.initial_stones=index%3
		depot.stored.gold_bar+=index
		initial=totals()
		var id: int=game.commerce.confirm("sell","wood",20,"same-key-independent-islands")
		check(id==1,"Order identifiers restart independently per island")
		if index>0:
			for i in 4000:
				step()
				var value: Dictionary=game.commerce.order(id)
				if index==1 and carrier.cargo>0: break
				if index in [2,4] and value.custody>0: break
				if index==3 and value.phase=="settled": break
		if index==4:
			check(game.commerce.cancel(id),"Fifth island stores a physical return")
			for i in 1500:
				step()
				if carrier.cargo>0 and carrier.trade_leg=="receipt": break
		check(game.saves.save_file(),"Save actual island stage %d"%index)
		var record: Dictionary=slots.island(index)
		check(not record.is_empty(),"Saved island validates its entire record")
		records.append(record.data.duplicate(true))
		inventories.append(totals())
	for index in [4,0,3,1,2,4,2,0,1,3]:
		check(slots.activate(index) and game.saves.load_file(),"Load independently from disk: %d"%index)
		depot=game.buildings.filter(func(b): return b.kind=="warehouse")[0]
		port=game.buildings.filter(func(b): return b.kind=="trading_port")[0]
		carrier=game.workers[1]
		check(totals()==inventories[index],"No cargo, custody or gold leaks between islands")
		check(game.merchant.snapshot()==records[index].merchant,"Visitor position, clock, limits and budget restored without offline advance")
		check(game.gold.snapshot()==records[index].gold,"Survey protection and random history isolated per island")
		check(game.commerce.order(1).phase==records[index].commerce.orders[0].phase,"Trade phase remains specific to each island")
		check(game.commerce.requests.get("same-key-independent-islands")==1,"Idempotence key is restored on its own island")
		# Resuming this island must not mutate any inactive record.
		initial=game.DATA.empty_stock()
		initial.merge({"wood":60,"stone":60,"gold_bar":30+index,"produce":90},true)
		finish_order(1)
		for other in 5:
			check(slots.island(other).data==records[other],"Inactive saved revision remains unchanged after another island progresses")
	# Load an actual old-schema-shaped snapshot with no gold/merchant/order fields.
	fixture()
	var legacy: Dictionary=game.saves.snapshot()
	legacy.erase("gold")
	legacy.erase("merchant")
	legacy.erase("commerce")
	legacy.buildings=legacy.buildings.filter(func(b): return b.kind!="trading_port")
	for b in legacy.buildings:
		b.stored.erase("gold_ore")
		b.stored.erase("gold_bar")
	for worker in legacy.workers:
		worker.erase("trade_id")
		worker.erase("trade_leg")
	check(game.saves.valid(legacy),"Legacy saves without new economy fields remain accepted")
	game.saves.restore(legacy)
	check(game.stock.gold_bar==0 and game.stock.gold_ore==0,"Legacy migration never invents gold")
	check(game.commerce.orders.is_empty() and game.merchant.state=="waiting","Legacy island starts without orders or visitors")
	check(not game.gold.protection_used,"Legacy island retains its unused first-gold protection")
	print("V0.0.6.1 islands: ",checks," checks; ",failures.size()," failures")
	finish()

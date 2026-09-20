extends "res://Tests/test_v0061_commerce.gd"

func run() -> void:
	# Multiple carriers share source, receiving and output capacity reservations.
	fixture()
	game.workers[2].assign_to("carrier",game.base)
	var id: int=game.commerce.confirm("sell","stone",60,"multi")
	check(id>0,"Sixty-unit multi-carrier order accepted")
	finish_order(id)
	check(depot.stored.stone==0 and depot.stored.gold_bar==42,"Shared reservation prevents double pickup and duplicate payment")
	# Budget and offer limits are shared across all orders, including queued ones.
	fixture()
	var other=game.add_building("warehouse",Vector2i(65,23),true)
	other.level=2
	other.stored.wood=60
	other.stored.stone=60
	other.stored.produce=60
	game.rebuild_navigation()
	initial=totals()
	check(game.commerce.confirm("sell","stone",60,"caps-stone")>0,"Merchant reserves twelve bars for stone")
	check(game.commerce.confirm("sell","stone",10,"over-cap")==0,"Sixty-stone purchase cap cannot be exceeded by another order")
	check(game.commerce.confirm("sell","wood",60,"caps-wood")>0,"Wood cap reserved independently")
	check(game.commerce.confirm("sell","produce",60,"caps-food")>0,"Food surplus can reserve its complete offer")
	check(game.merchant.budget==6,"Merchant budget reflects all queued sales")
	check(game.commerce.confirm("buy","stone",60,"buy-limit")>0,"Buying does not use the merchant's purchase budget")
	check(game.commerce.confirm("buy","stone",10,"buy-over")==0,"Queued purchases reserve the entire offer immediately")
	check(game.merchant.budget==6,"Gold paid by player does not replenish spending budget")
	# Save and restore with an actual load in each direction.
	fixture()
	id=game.commerce.confirm("buy","wood",20,"save-input")
	for i in 1000:
		step()
		if carrier.cargo>0: break
	check(carrier.trade_leg=="input" and carrier.cargo_resource=="gold_bar","Reached gold payment in transit")
	reload()
	for i in 2000:
		step()
		if carrier.trade_id==id and carrier.trade_leg=="receipt" and carrier.cargo>0: break
	check(carrier.cargo>0 and carrier.cargo_resource=="wood","Reached purchased goods in transit")
	reload()
	finish_order(id)
	check(depot.stored.wood==80 and depot.stored.gold_bar==26,"Both travel-stage reloads preserve one exchange")
	# Resting retains the assignment; reassignment delivers its existing load.
	fixture()
	carrier.person.energy=5
	carrier.state="resting"
	id=game.commerce.confirm("sell","wood",10,"resting")
	check(id>0 and game.commerce.quote("sell","wood",10).waiting,"Resting assigned carrier allows a warned queue")
	carrier.state="idle"
	for i in 1000:
		step()
		if carrier.cargo>0: break
	carrier.assign_to("idle",game.base)
	check(carrier.assignment=="idle" and carrier.cargo>0,"Profession change preserves an existing trade load")
	for i in 500:
		step()
		if carrier.cargo==0: break
	check(carrier.cargo==0 and game.commerce.order(id).custody>0,"Pending change safely finishes its input delivery")
	game.commerce.cancel(id)
	game.workers[2].assign_to("carrier",game.base)
	finish_order(id)
	check(totals()==initial,"Cancellation after reassignment recovers exact stock")
	# Cancelling a warehouse demolition releases inputs before inventory is dropped.
	fixture()
	other=game.add_building("warehouse",Vector2i(65,23),true)
	game.rebuild_navigation()
	initial=totals()
	id=game.commerce.confirm("sell","wood",20,"warehouse-demolition")
	for i in 1000:
		step()
		if game.commerce.order(id).custody>0: break
	check(depot.request_demolition(),"Origin warehouse demolition requested")
	check(game.commerce.order(id).phase=="cancelled","Affected order cancels before any demolition strike")
	depot.build(10)
	check(not game.buildings.has(depot),"Warehouse is actually removed")
	finish_order(id)
	check(totals()==initial,"Warehouse removal preserves stored, carried and custodied goods")
	# Port demolition waits for the visitor and leaves receipt piles on dry land.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"port-demolition")
	for i in 1000:
		step()
		if game.commerce.order(id).custody>0: break
	check(port.request_demolition(),"Port can begin coordinated shutdown")
	check(game.commerce.order(id).phase=="cancelled","Port shutdown cancels unfinished trades")
	port.build(10)
	check(not port.demolition_started,"Port waits for the actual boat to leave")
	for i in 1000:
		game.merchant.tick(0.5)
		if game.merchant.state=="waiting": break
	port.build(10)
	check(not game.buildings.has(port),"Port removed only after boat departure")
	check(game.logistics.piles.all(func(p): return game.land.get_cell_source_id(p.cell)>=0),"Every port demolition pile is on dry land")
	finish_order(id)
	check(totals()==initial,"Port removal preserves all returned goods without an absent-boat dependency")
	# Invalid stable origins cancel on load rather than creating payment.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"bad-origin")
	for i in 1000:
		step()
		if game.commerce.order(id).custody>0: break
	var saved: Dictionary=game.saves.snapshot()
	saved.commerce.orders[0].origins[0].building=99999
	var before := totals()
	game.saves.restore(saved)
	depot=game.buildings.filter(func(b): return b.kind=="warehouse")[0]
	port=game.buildings.filter(func(b): return b.kind=="trading_port")[0]
	carrier=game.workers[1]
	check(game.commerce.order(id).phase=="cancelled" and totals()==before,"Invalid origin reconciles into a physical return without creating gold")
	finish_order(id)
	check(totals()==initial,"Reconciled invalid order returns its entire owned inventory")
	# Requested construction may move a trade pile while preserving its ownership.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"clear-pile")
	for i in 1000:
		step()
		if carrier.cargo>0: break
	carrier.interrupt_task()
	var pile=game.logistics.piles.filter(func(p): return p.trade_id==id)[0]
	check(game.logistics.available(pile,"wood")==0,"Reserved trade pile is unavailable to ordinary tasks")
	reload()
	game.commerce.cancel(id)
	finish_order(id)
	check(totals()==initial,"Dropped reserved cargo remains recoverable across save and cancellation")
	# Port receipt metadata allocates real stock and cannot manufacture inventory.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"receipt-reconciliation")
	for i in 3000:
		step()
		if game.commerce.order(id).phase=="settled": break
	saved=game.saves.snapshot()
	before=totals()
	saved.commerce.orders[0].receipt+=100
	saved.commerce.orders[0].to_store+=100
	game.saves.restore(saved)
	depot=game.buildings.filter(func(b): return b.kind=="warehouse")[0]
	port=game.buildings.filter(func(b): return b.kind=="trading_port")[0]
	carrier=game.workers[1]
	check(totals()==before and game.commerce.order(id).receipt==2 and game.commerce.order(id).to_store==2,"Oversized receipt metadata is clamped to the two actual paid bars")
	finish_order(id)
	check(depot.stored.gold_bar==32,"Reconciled receipt delivers the payment exactly once")
	fixture()
	id=game.commerce.confirm("sell","wood",20,"missing-receipt")
	for i in 3000:
		step()
		if game.commerce.order(id).phase=="settled": break
	saved=game.saves.snapshot()
	before=totals()
	saved.commerce.orders[0].receipt=0
	game.saves.restore(saved)
	check(totals()==before,"Missing ownership metadata never deletes goods already owned by the island")
	check(game.logistics.piles.any(func(p): return p.resource_kind=="gold_bar" and p.stored.gold_bar==2 and game.land.get_cell_source_id(p.cell)>=0),"Unattributed port receipt is recoverable on land without replaying the trade")
	fixture()
	id=game.commerce.confirm("sell","wood",20,"blocked-path")
	for i in 1000:
		step()
		if carrier.cargo>0: break
	var access: Vector2i=port.door()
	var atlas: Vector2i=game.land.get_cell_atlas_coords(access)
	var terrain: int=game.land.get_cell_source_id(access)
	game.land.erase_cell(access)
	game.rebuild_navigation()
	for i in 1400: step()
	check(game.commerce.order(id).phase=="pending" and game.merchant.state=="docked" and not game.merchant.can_confirm(),"Blocked land access pauses actual cargo beyond the offer deadline without expiring its order")
	check(game.commerce.confirm("sell","stone",10,"late-click")==0,"Closed deadline refuses additional orders while an older delivery waits")
	game.land.set_cell(access,terrain,atlas)
	game.rebuild_navigation()
	finish_order(id)
	check(depot.stored.gold_bar==32,"Repairing the path resumes its preserved cargo and pays once")
	print("Commerce edges: ",checks," checks; ",failures.size()," failures")
	finish()

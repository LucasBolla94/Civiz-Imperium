extends "res://Tests/test_v003.gd"
var depot
var port
var carrier
var initial := {}

func fixture() -> void:
	fresh()
	game.village_level=3
	stop_workers()
	game.base.stored=game.DATA.empty_stock()
	game.base.stored.produce=90
	depot=game.add_building("warehouse",Vector2i(43,28),true)
	depot.stored.wood=60
	depot.stored.stone=60
	depot.stored.gold_bar=30
	port=game.add_building("trading_port",Vector2i(44,37),true)
	game.rebuild_navigation()
	carrier=game.workers[1]
	carrier.assign_to("carrier",game.base)
	game.merchant.tick(60)
	for i in 1000:
		if game.merchant.state=="docked": break
		game.merchant.tick(0.5)
	initial=totals()

func totals() -> Dictionary:
	var result: Dictionary=game.DATA.empty_stock()
	for target in game.buildings:
		for resource in result: result[resource]+=target.stored.get(resource,0)
	for worker in game.workers:
		if worker.cargo>0: result[worker.cargo_resource]+=worker.cargo
	for pile in game.logistics.piles: result[pile.resource_kind]+=pile.stored.get(pile.resource_kind,0)
	for value in game.commerce.orders: result[value.input_resource]+=value.custody
	return result

func conserved() -> void:
	var expected: Dictionary=initial.duplicate()
	for value in game.commerce.orders:
		if value.phase=="settled":
			expected[value.input_resource]-=value.input_amount
			expected[value.output_resource]+=value.output_amount
	var actual := totals()
	for resource in ["wood","stone","gold_bar"]:
		check(actual[resource]==expected[resource],"Conservation of %s: actual %d, expected %d"%[resource,actual[resource],expected[resource]])
	for target in game.buildings:
		check(target.used()<=target.capacity(),"Trade never overfills a physical building")
		check(target.stored.values().all(func(n): return n>=0),"No negative physical stock")

func step() -> void:
	# Keep the fixture isolated from starvation, without changing any inventory.
	for worker in game.workers: worker.person.nutrition=100; worker.person.energy=100
	tick(0.1)
	conserved()

func finish_order(id: int) -> void:
	for i in 5000:
		var value: Dictionary=game.commerce.order(id)
		if value.phase!="pending" and value.to_store==0: return
		step()
	check(false,"Order %d did not finish: %s"%[id,str(game.commerce.order(id))])

func reload() -> void:
	var saved: Dictionary=game.saves.snapshot()
	check(game.saves.valid(saved),"Commerce snapshot accepted at current physical stage")
	var before := totals()
	game.saves.restore(saved)
	depot=game.buildings.filter(func(b): return b.kind=="warehouse")[0]
	port=game.buildings.filter(func(b): return b.kind=="trading_port")[0]
	carrier=game.workers[1]
	check(totals()==before,"Reload preserves every unit, including custody and cargo")
	conserved()

func run() -> void:
	fixture()
	var commerce=game.commerce
	var id: int=commerce.confirm("sell","wood",20,"sale-1")
	check(id>0,"Confirm a twenty-wood sale: "+commerce.error)
	check(depot.stored.wood==60 and port.stored.gold_bar==0 and commerce.order(id).custody==0,"Confirmation moves no goods and pays no gold")
	check(game.logistics.available(depot,"wood")==40 and game.merchant.budget==28,"Exact stock and merchant gold are reserved")
	check(commerce.confirm("sell","wood",20,"sale-1")==id and commerce.orders.size()==1,"Repeated confirmation is idempotent")
	reload()
	var trips := 0
	var previous_custody := 0
	for i in 5000:
		step()
		var value: Dictionary=game.commerce.order(id)
		if value.custody>previous_custody:
			trips+=1
			previous_custody=value.custody
			check(value.phase=="pending" and port.stored.gold_bar==0,"Partial delivery earns no gold")
			if trips==1: reload()
		if value.phase=="settled": break
	check(trips>=2,"Twenty units require multiple trips at the real carrying capacity")
	check(game.commerce.order(id).phase=="settled" and port.stored.gold_bar==2,"Full custody exchanges once for exactly two gold bars")
	check(depot.stored.gold_bar==30 and game.resource_breakdown("gold_bar").available==30,"Port receipt is not available stored gold")
	reload()
	finish_order(id)
	check(depot.stored.gold_bar==32 and port.stored.gold_bar==0,"Carrier physically stores the gold in a general warehouse")
	reload()
	check(depot.stored.gold_bar==32,"Reload after payment never pays again")
	# A purchase delivers gold first, then the contracted goods return on foot.
	fixture()
	id=game.commerce.confirm("buy","stone",20,"purchase-1")
	check(id>0,"Confirm purchase")
	check(game.merchant.offers.stone==40 and game.merchant.budget==30,"Purchase reserves offer but does not refill merchant buying budget")
	finish_order(id)
	check(depot.stored.gold_bar==24 and depot.stored.stone==80,"Buy twenty stone for exactly six gold bars")
	check(game.merchant.budget==30 and game.merchant.buying_caps.stone==60,"Trade directions have independent visit limits")
	# Cancelling while a carrier is loaded returns stock without a boat dependency.
	fixture()
	id=game.commerce.confirm("sell","stone",20,"cancel-cargo")
	for i in 1000:
		step()
		if carrier.trade_id==id and carrier.cargo>0: break
	check(carrier.cargo>0 and carrier.cargo<=7,"Carrier holds a real bounded input load")
	check(game.commerce.cancel(id),"Cancel loaded carrier order")
	check(game.merchant.budget==30 and game.merchant.buying_caps.stone==60,"Cancellation releases unused merchant reservations")
	reload()
	game.merchant.close_orders()
	finish_order(id)
	check(totals()==initial and depot.stored.stone==60,"Cancelled travelling goods safely return without gold gain or loss")
	# Partial boat custody is returned on land, never erased when the boat leaves.
	fixture()
	id=game.commerce.confirm("sell","wood",30,"cancel-custody")
	for i in 1000:
		step()
		if game.commerce.order(id).custody>0: break
	check(game.commerce.order(id).custody>0,"Fixture reached actual partial boat custody")
	game.commerce.cancel(id)
	check(game.commerce.order(id).custody==0 and port.stored.wood>0,"Cancellation transfers custody into the physical receiving stock")
	reload()
	finish_order(id)
	check(totals()==initial,"Cancelled custody returns the exact original inventory")
	# FIFO: the next order cannot withdraw anything while the first is pending.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"fifo-1")
	var second: int=game.commerce.confirm("sell","stone",20,"fifo-2")
	check(id>0 and second>id,"Both independent orders can be reserved")
	for i in 1500:
		if game.commerce.order(id).phase!="pending": break
		step()
		check(depot.stored.stone==60,"Second order never starts transport before first exchange")
	finish_order(second)
	check(depot.stored.gold_bar==36,"FIFO orders pay their exact independent values")
	# Death produces a physically recoverable pile carrying the same reservation.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"death")
	for i in 1000:
		step()
		if carrier.cargo>0: break
	var cargo: int=carrier.cargo
	game.settlement.remove(carrier)
	check(game.logistics.piles.any(func(p): return p.trade_id==id and p.stored.wood==cargo),"Death preserves tagged cargo on the ground")
	conserved()
	game.workers[1].assign_to("carrier",game.base)
	finish_order(id)
	check(depot.stored.gold_bar==32,"Replacement carrier recovers the pile and finishes once")
	# No automatic professions; a long confirmed delivery survives the window.
	fixture()
	id=game.commerce.confirm("sell","wood",20,"waiting")
	carrier.assign_to("idle",game.base)
	game.merchant.tick(500)
	check(game.merchant.state=="docked" and not game.merchant.can_confirm(),"Actual confirmed order keeps the merchant after deadline")
	check(game.workers.all(func(w): return w.assignment=="idle"),"Trade never hires or reassigns workers automatically")
	carrier.assign_to("carrier",game.base)
	finish_order(id)
	check(game.commerce.order(id).phase=="settled","Long confirmed order still settles after the visit window")
	# Wrong store and food floor are checked again when stock is withdrawn.
	fixture()
	depot.stored.wood=0
	game.base.stored.wood=20
	initial=totals()
	check(game.commerce.confirm("sell","wood",10,"wrong-store")==0 and "galpão" in game.commerce.error,"Base resources cannot be exported directly")
	game.commerce.request_transfer("wood",10)
	for i in 1500:
		step()
		if depot.stored.wood>=10: break
	check(depot.stored.wood>=10 and game.commerce.orders.is_empty(),"Requested transfer is physical and never confirms a trade automatically")
	fixture()
	depot.stored.produce=20
	game.base.stored.produce=9
	id=game.commerce.confirm("sell","produce",20,"food")
	check(id>0,"Only surplus above three food units per person is exportable")
	game.base.stored.produce=8
	var ticket: Dictionary=game.commerce.claim(carrier)
	check(ticket.is_empty() and "alimentar" in game.commerce.order(id).reason,"Consumption revalidation pauses export before pickup")
	# Full output warehouse blocks new orders even when a sale would free room.
	fixture()
	depot.stored.wood=110
	check(depot.used()==200 and game.commerce.confirm("sell","wood",10,"full")==0,"Full warehouse blocks confirmation without expelling stock")
	print("V0.0.6.1 commerce: ",checks," checks; ",failures.size()," failures")
	finish()

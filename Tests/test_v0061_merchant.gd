extends "res://Tests/test_v003.gd"
const VISITOR=preload("res://Scripts/merchant.gd")
# Isolated schedule input. Actual order ownership/transport is tested separately.
class PendingOrders extends "res://Scripts/commerce.gd":
	var waiting := true
	func has_pending(_visit: int) -> bool: return waiting

func sail_until(visitor, expected: String) -> void:
	for i in 2000:
		if visitor.state==expected: return
		visitor.tick(0.5)
	check(false,"Visitor did not reach "+expected)

func run() -> void:
	fresh()
	game.village_level=3
	var port=game.add_building("trading_port",Vector2i(44,37),true)
	game.rebuild_navigation()
	var visitor=game.merchant
	visitor.tick(59.9)
	check(visitor.state=="waiting" and visitor.offers.is_empty(),"No visit before the first sixty seconds")
	visitor.tick(0.1)
	check(visitor.state=="approaching" and visitor.visible,"First attempt launches a physical boat at sixty seconds")
	check(visitor.offers.is_empty() and visitor.budget==0 and not visitor.can_confirm(),"No offers or gold during the journey")
	check(game.land.get_cell_source_id(game.world_cell(visitor.position))<0,"Merchant starts on water")
	var saved: Dictionary=game.saves.snapshot()
	check(game.saves.valid(saved),"Approaching merchant snapshot valid")
	game.saves.restore(saved)
	visitor=game.merchant
	port=game.buildings[-1]
	check(visitor.position==saved.merchant.position and visitor.route==saved.merchant.route and visitor.clock==saved.merchant.clock,"Reload preserves route, position and simulated time without offline progress")
	game.simulation_paused=true
	game._process(10)
	check(visitor.clock==saved.merchant.clock,"Game pause freezes merchant clock")
	game.simulation_paused=false
	game.simulation_speed=3
	game._process(1)
	check(is_equal_approx(visitor.clock,saved.merchant.clock+3),"Game speed applies once to boat movement and visit clock")
	game.simulation_speed=1
	sail_until(visitor,"docked")
	check(visitor.can_confirm() and visitor.offers=={"wood":60,"stone":60,"produce":60},"Offers appear only after docking")
	check(visitor.buying_caps==visitor.offers and visitor.budget==30,"Visit starts with independent purchase caps and thirty gold bars")
	check(visitor.position==game.cell_center(game.port_layout.layout(port.origin,0).dock),"Physical boat reaches the designated water dock")
	var docked: Dictionary=visitor.snapshot()
	visitor.tick(90)
	check(visitor.warned and visitor.window_open and visitor.can_confirm(),"Thirty-second warning keeps confirmation open")
	var warned_state: Dictionary=visitor.snapshot()
	visitor.restore(warned_state)
	check(visitor.warned,"Reload does not repeat the same visit warning")
	visitor.tick(visitor.closes_at-visitor.clock-0.001)
	check(visitor.can_confirm(),"Confirmation is allowed just before deadline")
	visitor.clock=visitor.closes_at
	check(not visitor.can_confirm() and not visitor.window_open,"Deadline is closed before a simultaneous confirmation")
	visitor.tick(0.01)
	check(visitor.state=="leaving" and visitor.offers.is_empty(),"No pending orders: depart after confirmation window closes")
	sail_until(visitor,"waiting")
	check(visitor.next_attempt>=visitor.last_arrival+300,"New arrivals are separated by at least three hundred seconds")
	# An order which needs longer than both the visit and recurrence keeps this
	# same boat. The schedule must never expire it or accumulate another visitor.
	visitor.restore(docked)
	var orders=PendingOrders.new()
	orders.game=game
	var actual_commerce=game.commerce
	game.commerce=orders
	visitor.tick(500)
	check(visitor.state=="docked" and visitor.pending_orders() and not visitor.can_confirm(),"Confirmed order keeps boat beyond both deadlines")
	check(visitor.description()=="Prazo encerrado · Aguardando entregas" and not "-" in visitor.description(),"Waiting status never displays a negative timer")
	orders.waiting=false
	visitor.tick(0.1)
	check(visitor.state=="leaving","Settled or cancelled last order releases the boat")
	sail_until(visitor,"waiting")
	check(is_equal_approx(visitor.next_attempt-visitor.clock,300) or visitor.next_attempt-visitor.clock>299,"Overdue recurrence restarts after departure rather than stacking visits")
	game.commerce=actual_commerce
	# Demolition must wait while the actual visitor sails away.
	visitor.restore(docked)
	check(port.request_demolition() and not visitor.can_confirm(),"Demolition request closes new trades immediately")
	port.build(10)
	check(not port.demolition_started,"No demolition strike while merchant depends on the port")
	visitor.tick(0.1)
	sail_until(visitor,"waiting")
	port.build(10)
	check(not game.buildings.has(port),"Demolition starts only after physical departure")
	# An inaccessible completed port retries every thirty simulation seconds.
	fresh()
	port=game.add_building("trading_port",Vector2i(44,37),true)
	game.rebuild_navigation()
	visitor=game.merchant
	game.navigation.set_point_solid(port.door())
	visitor.tick(60)
	check(visitor.state=="waiting" and visitor.next_attempt==90 and not visitor.reason.is_empty(),"Blocked access postpones a single attempt by thirty seconds")
	visitor.tick(29)
	check(visitor.state=="waiting" and visitor.visit_id==0,"No accumulated ships during access failure")
	game.rebuild_navigation()
	visitor.tick(1)
	check(visitor.state=="approaching","Repaired access allows the scheduled retry")
	var invalid: Dictionary=visitor.snapshot()
	invalid.clock=NAN
	check(not VISITOR.valid(invalid),"Non-finite visit clock rejected")
	invalid=visitor.snapshot()
	invalid.budget=-1
	check(not VISITOR.valid(invalid),"Negative merchant budget rejected")
	var legacy: Dictionary=game.saves.snapshot()
	legacy.erase("merchant")
	game.saves.restore(legacy)
	check(game.merchant.state=="waiting" and game.merchant.visit_id==0 and game.merchant.offers.is_empty(),"Legacy save initializes no merchant or goods")
	finish()

extends Node2D
## A simulation-clock visitor. Stock appears only after the boat reaches the dock.
const ECONOMY = preload("res://Scripts/economy_data.gd")
const SPEED = 48.0
const STATES = ["waiting","approaching","docked","leaving"]
var game
var clock := 0.0
var state := "waiting"
var port_id := 0
var next_attempt := -1.0
var last_arrival := -1.0
var closes_at := -1.0
var visit_id := 0
var window_open := false
var warned := false
var offers := {}
var buying_caps := {}
var budget := 0
var route: Array[Vector2i]=[]
var outward: Array[Vector2i]=[]
var reason := ""
var retry_navigation_at := 0.0
var last_access_warning := ""
var sprite: Sprite2D

func _ready() -> void:
	sprite=Sprite2D.new()
	sprite.texture=game.DATA.atlas("res://Assets/Objects/Exterior/Beach/Wood Boat.png",Rect2(0,0,176,112))
	sprite.scale=Vector2.ONE*0.25
	add_child(sprite)
	z_index=10
	hide()

func port():
	for building in game.buildings:
		if building.kind=="trading_port" and building.entity_id==port_id: return building
	return null

func pending_orders() -> bool:
	return is_instance_valid(game.commerce) and game.commerce.has_pending(visit_id)

func tick(delta: float) -> void:
	if delta<=0: return
	var remaining := delta
	while remaining>0.000001:
		var target=port()
		if state=="waiting":
			if not is_instance_valid(target):
				for building in game.buildings:
					if building.kind=="trading_port" and building.completed and not building.demolition_requested:
						port_id=building.entity_id
						target=building
						next_attempt=clock+ECONOMY.FIRST_VISIT_SECONDS
						if last_arrival>=0: next_attempt=maxf(next_attempt,last_arrival+ECONOMY.VISIT_INTERVAL_SECONDS)
						break
			if not is_instance_valid(target) or not target.completed or target.demolition_requested:
				clock+=remaining
				break
			if next_attempt<0: next_attempt=clock+ECONOMY.FIRST_VISIT_SECONDS
			var wait_time := minf(remaining,maxf(0,next_attempt-clock))
			clock+=wait_time
			remaining-=wait_time
			if clock>=next_attempt: attempt_arrival(target)
		elif state=="docked":
			close_window_if_due()
			if not window_open and not pending_orders():
				start_departure()
				continue
			var deadline := closes_at if warned else closes_at-ECONOMY.VISIT_WARNING_SECONDS
			var step := minf(remaining,maxf(0,deadline-clock)) if window_open else remaining
			clock+=step
			remaining-=step
			close_window_if_due()
			if window_open and not warned and clock>=closes_at-ECONOMY.VISIT_WARNING_SECONDS:
				warned=true
				game.notify("Comerciante: faltam 30 segundos para novos negócios. Pedidos confirmados serão aguardados.")
		else:
			if route.is_empty():
				if state=="approaching": arrive()
				else: finish_departure()
				continue
			if not game.port_layout.water_free(route[0],target):
				reason="Rota do comerciante bloqueada; aguardando passagem por água."
				clock+=remaining
				if clock>=retry_navigation_at:
					retry_navigation_at=clock+ECONOMY.VISIT_RETRY_SECONDS
					var replacement: Array[Vector2i]=game.port_layout.path_between(game.world_cell(position),route[-1],target)
					if not replacement.is_empty(): route=replacement
				break
			var destination: Vector2=game.cell_center(route[0])
			var seconds := position.distance_to(destination)/SPEED
			var step := minf(remaining,seconds)
			position=position.move_toward(destination,SPEED*step)
			clock+=step
			remaining-=step
			if position.distance_to(destination)<0.001:
				position=destination
				route.pop_front()
				if route.is_empty():
					if state=="approaching": arrive()
					else: finish_departure()
	visible=state!="waiting"
	if is_instance_valid(sprite):
		# Four native frames animate the water alongside the hull at a modest rate.
		sprite.texture=game.DATA.atlas("res://Assets/Objects/Exterior/Beach/Wood Boat.png",Rect2((int(clock*4)%4)*176,0,176,112))

func attempt_arrival(target) -> void:
	reason=game.port_layout.access_reason(target)
	if not reason.is_empty():
		next_attempt=clock+ECONOMY.VISIT_RETRY_SECONDS
		if last_access_warning!=reason:
			game.notify(reason+" Nova tentativa em 30 segundos.")
			last_access_warning=reason
		return
	last_access_warning=""
	outward=game.port_layout.water_route(target.origin,target.orientation,target)
	route=outward.duplicate()
	route.reverse()
	position=game.cell_center(route.pop_front())
	state="approaching"
	window_open=false
	offers.clear()
	buying_caps.clear()
	budget=0
	reason="Comerciante a caminho do porto."
	visible=true

func arrive() -> void:
	state="docked"
	visit_id+=1
	last_arrival=clock
	closes_at=clock+ECONOMY.VISIT_WINDOW_SECONDS
	window_open=true
	warned=false
	for resource in ECONOMY.SELL_PRICES:
		offers[resource]=ECONOMY.MERCHANT_STOCK
		buying_caps[resource]=ECONOMY.MERCHANT_STOCK
	budget=ECONOMY.MERCHANT_BUDGET
	reason=""
	game.notify("Comerciante atracado. Novos negócios disponíveis por 120 segundos.")
	var target=port()
	if not is_instance_valid(target) or target.demolition_requested: close_orders()

func close_orders() -> void:
	window_open=false
	closes_at=minf(closes_at,clock)

func close_window_if_due() -> void:
	if state=="docked" and clock>=closes_at: window_open=false

func can_confirm() -> bool:
	# Call this before any reservation, including button callbacks at the deadline.
	close_window_if_due()
	var target=port()
	return state=="docked" and window_open and is_instance_valid(target) and not target.demolition_requested

func start_departure() -> void:
	state="leaving"
	window_open=false
	offers.clear()
	buying_caps.clear()
	budget=0
	var target=port()
	route=game.port_layout.water_route(target.origin,target.orientation,target) if is_instance_valid(target) else outward.duplicate()
	# No safe route means wait at the dock; never vanish with unresolved cargo.
	if route.is_empty(): route=outward.duplicate()
	reason="Comerciante deixando a ilha."

func finish_departure() -> void:
	state="waiting"
	hide()
	next_attempt=clock+ECONOMY.VISIT_INTERVAL_SECONDS if clock>=last_arrival+ECONOMY.VISIT_INTERVAL_SECONDS else last_arrival+ECONOMY.VISIT_INTERVAL_SECONDS
	reason=""

func description() -> String:
	if state=="approaching" or state=="leaving": return reason
	if state=="docked":
		close_window_if_due()
		if not window_open: return "Prazo encerrado · Aguardando entregas" if pending_orders() else "Prazo encerrado · Preparando partida"
		return "Novos negócios: %ds · Pedidos confirmados aguardam entrega"%ceili(maxf(0,closes_at-clock))
	if not reason.is_empty(): return reason
	return "Próxima tentativa de visita: %ds"%ceili(maxf(0,next_attempt-clock)) if next_attempt>=0 else "Aguardando a conclusão do porto."

func occupies(cell: Vector2i) -> bool:
	return state!="waiting" and (game.world_cell(position)==cell or (not route.is_empty() and route[0]==cell))

func snapshot() -> Dictionary:
	return {"clock":clock,"state":state,"port_id":port_id,"next_attempt":next_attempt,"last_arrival":last_arrival,"closes_at":closes_at,"visit_id":visit_id,"window_open":window_open,"warned":warned,"offers":offers.duplicate(),"buying_caps":buying_caps.duplicate(),"budget":budget,"route":route.duplicate(),"outward":outward.duplicate(),"position":position,"reason":reason,"retry_navigation_at":retry_navigation_at,"last_access_warning":last_access_warning}

func restore(data: Dictionary) -> void:
	# Missing data is the pre-commerce save format; no offline advance or visit.
	var defaults := {"clock":0.0,"state":"waiting","port_id":0,"next_attempt":-1.0,"last_arrival":-1.0,"closes_at":-1.0,"visit_id":0,"window_open":false,"warned":false,"offers":{},"buying_caps":{},"budget":0,"route":[],"outward":[],"position":Vector2.ZERO,"reason":"","retry_navigation_at":0.0,"last_access_warning":""}
	defaults.merge(data,true)
	for key in defaults:
		if key=="route": route.assign(defaults[key])
		elif key=="outward": outward.assign(defaults[key])
		else: set(key,defaults[key])
	visible=state!="waiting"
	close_window_if_due()

static func valid(data) -> bool:
	if not data is Dictionary or data.get("state") not in STATES: return false
	for key in ["clock","next_attempt","last_arrival","closes_at","retry_navigation_at"]:
		if not (data.get(key) is float or data.get(key) is int) or not is_finite(data[key]) or data[key]<-1: return false
	for key in ["port_id","visit_id","budget"]:
		if not data.get(key) is int or data[key]<0: return false
	if data.budget>ECONOMY.MERCHANT_BUDGET: return false
	for key in ["window_open","warned"]:
		if not data.get(key) is bool: return false
	for key in ["reason","last_access_warning"]:
		if not data.get(key) is String: return false
	for key in ["offers","buying_caps"]:
		if not data.get(key) is Dictionary: return false
		for resource in data[key]:
			if resource not in ECONOMY.SELL_PRICES or not data[key][resource] is int or data[key][resource]<0 or data[key][resource]>ECONOMY.MERCHANT_STOCK: return false
	for key in ["route","outward"]:
		if not data.get(key) is Array or data[key].size()>262144: return false
		for cell in data[key]:
			if not cell is Vector2i: return false
		for i in range(1,data[key].size()):
			if (data[key][i]-data[key][i-1]).length_squared()!=1: return false
	if not data.get("position") is Vector2 or not is_finite(data.position.x) or not is_finite(data.position.y): return false
	if data.state!="docked" and data.window_open: return false
	if data.clock<0 or data.last_arrival>data.clock: return false
	if data.state!="waiting" and (data.port_id==0 or data.outward.is_empty()): return false
	if data.state in ["approaching","leaving"] and data.route.is_empty(): return false
	if data.state=="docked" and (data.visit_id==0 or data.last_arrival<0 or data.closes_at<data.last_arrival): return false
	return true

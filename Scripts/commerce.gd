extends RefCounted
## Order records reserve existing inventories. Only custody is inventory here;
## all received goods live in port.stored, a worker cargo or a tagged ground pile.
const ECONOMY=preload("res://Scripts/economy_data.gd")
const PILE=preload("res://Scripts/resource_pile.gd")
var game
var orders: Array=[]
var next_id := 1
var requests := {}
var transfer_targets := {}
var error := ""

func building(id: int):
	for value in game.buildings:
		if value.entity_id==id: return value
	return null

func order(id: int) -> Dictionary:
	for value in orders:
		if value.id==id: return value
	return {}

func warehouse(value) -> bool:
	return is_instance_valid(value) and value.kind=="warehouse" and value.completed and not value.demolition_requested

func has_pending(visit: int) -> bool:
	return orders.any(func(o): return o.visit==visit and o.phase=="pending")

func first_pending() -> Dictionary:
	for value in orders:
		if value.phase=="pending": return value
	return {}

func reserved(source, resource: String) -> int:
	if not source.has_method("footprint"): return 0
	var amount := 0
	for value in orders:
		if value.phase!="pending" or value.input_resource!=resource: continue
		for origin in value.origins:
			if origin.building==source.entity_id: amount+=origin.remaining
	return amount

func incoming(destination, resource: String="") -> int:
	if not destination.has_method("footprint"): return 0
	var amount := 0
	for value in orders:
		if destination.kind=="trading_port" and value.port==destination.entity_id and value.phase=="pending":
			# Keep enough receiving space to return partial custody on cancellation.
			var withdrawn := 0
			for origin in value.origins: withdrawn+=origin.return_space
			if resource.is_empty(): amount+=maxi(value.output_amount,withdrawn)
			elif resource==value.output_resource: amount+=value.output_amount
		else:
			for target in value.destinations:
				if target.building==destination.entity_id and (resource.is_empty() or resource==receipt_resource(value)): amount+=target.remaining
			if value.phase=="pending":
				for origin in value.origins:
					if origin.building==destination.entity_id and (resource.is_empty() or resource==value.input_resource): amount+=origin.return_space
	return amount

func receipt_resource(value: Dictionary) -> String:
	return value.input_resource if value.phase=="cancelled" else value.output_resource

func warehouses_from(point: Vector2) -> Array:
	var result: Array=game.buildings.filter(func(b): return warehouse(b) and not game.route_to_cell(point,b.door()).is_empty())
	result.sort_custom(func(a,b): return game.route_to_cell(point,a.door()).size()<game.route_to_cell(point,b.door()).size())
	return result

func carrier_available(port) -> bool:
	return game.workers.any(func(w): return w.assignment=="carrier" and not game.route_to_cell(w.position,port.door()).is_empty())

func quote(side: String, resource: String, quantity: int) -> Dictionary:
	var result := {"reason":"","origins":[],"destinations":[]}
	if side not in ["buy","sell"] or resource not in ECONOMY.SELL_PRICES or quantity<10 or quantity%10!=0:
		result.reason="Escolha uma quantidade em múltiplos de 10."
		return result
	var visitor=game.merchant
	if not visitor.can_confirm():
		result.reason="A visita está encerrada ou o comerciante ainda não atracou."
		return result
	var port=visitor.port()
	if not carrier_available(port):
		result.reason="Aloque pelo menos um transportador com acesso ao porto em Habitantes."
		return result
	result.payment=(ECONOMY.BUY_PRICES if side=="buy" else ECONOMY.SELL_PRICES)[resource]*(quantity/10)
	result.input_resource="gold_bar" if side=="buy" else resource
	result.output_resource=resource if side=="buy" else "gold_bar"
	result.input_amount=int(result.payment) if side=="buy" else quantity
	result.output_amount=quantity if side=="buy" else int(result.payment)
	if side=="sell" and (visitor.buying_caps.get(resource,0)<quantity or visitor.budget<result.payment):
		result.reason="O comerciante não tem orçamento ou limite disponível para esta venda."
		return result
	if side=="buy" and visitor.offers.get(resource,0)<quantity:
		result.reason="O comerciante não tem esta quantidade disponível."
		return result
	if side=="sell" and resource=="produce" and game.available_stock().produce-quantity<game.workers.size()*game.DATA.FOOD_RESERVE_PER_PERSON:
		result.reason="Preserve a reserva alimentar de três unidades por habitante."
		return result
	var remaining: int=result.input_amount
	var candidates := warehouses_from(game.cell_center(port.door()))
	for source in candidates:
		var amount: int=mini(remaining,game.logistics.available(source,result.input_resource))
		if amount>0:
			result.origins.append({"building":source.entity_id,"remaining":amount,"return_space":0})
			remaining-=amount
	if remaining>0:
		var elsewhere := 0
		for source in game.buildings:
			if source.kind!="warehouse": elsewhere+=game.logistics.available(source,result.input_resource)
		for pile in game.logistics.piles: elsewhere+=game.logistics.available(pile,result.input_resource)
		result.reason="Leve este material ao galpão para vender" if elsewhere>0 else "Material insuficiente, reservado ou sem acesso nos galpões gerais."
		return result
	if game.logistics.storage_free(port)<result.output_amount:
		result.reason="Sem espaço livre no recebimento do porto."
		return result
	remaining=result.output_amount
	for target in candidates:
		var amount: int=mini(remaining,game.logistics.storage_free(target))
		if amount>0:
			result.destinations.append({"building":target.entity_id,"remaining":amount})
			remaining-=amount
	if remaining>0: result.reason="Sem espaço reservado para receber a mercadoria nos galpões gerais."
	result.waiting=game.workers.filter(func(w): return w.assignment=="carrier").all(func(w): return w.state!="idle")
	return result

func confirm(side: String, resource: String, quantity: int, request_id: String) -> int:
	error=""
	if request_id.is_empty(): error="Identificação de confirmação ausente."; return 0
	if requests.has(request_id): return requests[request_id]
	var plan := quote(side,resource,quantity)
	if not plan.reason.is_empty(): error=plan.reason; return 0
	var visitor=game.merchant
	var value := {"id":next_id,"visit":visitor.visit_id,"port":visitor.port_id,"side":side,"resource":resource,"quantity":quantity,"payment":int(plan.payment),"input_resource":plan.input_resource,"input_amount":plan.input_amount,"output_resource":plan.output_resource,"output_amount":plan.output_amount,"origins":plan.origins,"destinations":plan.destinations,"phase":"pending","custody":0,"receipt":0,"to_store":0,"reason":""}
	next_id+=1
	orders.append(value)
	requests[request_id]=value.id
	if side=="sell": visitor.budget-=value.payment; visitor.buying_caps[resource]-=quantity
	else: visitor.offers[resource]-=quantity
	return value.id

func ticketed(source, id: int, unpicked_only := true) -> int:
	var amount := 0
	for ticket in game.logistics.tickets:
		if ticket.source==source and ticket.get("trade_id",0)==id and (not unpicked_only or not ticket.picked): amount+=ticket.amount
	return amount

func target_ticketed(id: int, target_id: int) -> int:
	var amount := 0
	for ticket in game.logistics.tickets:
		if ticket.get("trade_id",0)==id and ticket.get("trade_leg","")!="input" and is_instance_valid(ticket.destination) and ticket.destination.entity_id==target_id: amount+=ticket.amount
	return amount

func reserve(worker, source, target, resource: String, amount: int, value: Dictionary, leg: String) -> Dictionary:
	var ticket: Dictionary=game.logistics.reserve(worker,source,target,resource,amount,false)
	if not ticket.is_empty():
		ticket.trade_id=value.id
		ticket.trade_leg=leg
	return ticket

func claim(worker) -> Dictionary:
	if worker.assignment!="carrier": return {}
	# Finish landed receipts/returns first: they do not require the merchant.
	for value in orders:
		if value.phase=="pending" or value.to_store<=0: continue
		allocate_missing(value)
		var sources: Array=[]
		var port=building(value.port)
		if value.receipt>0 and is_instance_valid(port) and not port.demolition_requested: sources.append(port)
		for pile in game.logistics.piles:
			if pile.trade_id==value.id: sources.append(pile)
		for source in sources:
			var amount: int=(value.receipt if source==port else source.stored.get(receipt_resource(value),0))-ticketed(source,value.id)
			if source is PILE: amount-=game.logistics.reserved(source,receipt_resource(value))
			if amount<=0: continue
			for allocation in value.destinations:
				var destination=building(allocation.building)
				if not warehouse(destination): continue
				var ticket := reserve(worker,source,destination,receipt_resource(value),mini(amount,allocation.remaining-target_ticketed(value.id,allocation.building)),value,"receipt")
				if not ticket.is_empty(): return ticket
		value.reason="Aguardando galpão livre e caminho para recolher a carga."
	var value := first_pending()
	if value.is_empty(): return claim_transfer(worker)
	var port=building(value.port)
	if not is_instance_valid(port): cancel(value.id); return {}
	if game.merchant.state!="docked" or game.merchant.visit_id!=value.visit:
		value.reason="Aguardando o comerciante desta ordem."
		return {}
	# Recover already-owned cargo before withdrawing more stock.
	for pile in game.logistics.piles:
		if pile.trade_id!=value.id: continue
		var amount: int=pile.stored.get(value.input_resource,0)-ticketed(pile,value.id)
		amount-=game.logistics.reserved(pile,value.input_resource)
		var recovered := reserve(worker,pile,port,value.input_resource,amount,value,"input")
		if not recovered.is_empty(): return recovered
	value.reason=input_reason(value)
	if not value.reason.is_empty(): return {}
	for origin in value.origins:
		var source=building(origin.building)
		if not warehouse(source): cancel(value.id); return {}
		var amount: int=origin.remaining-ticketed(source,value.id)
		var ticket := reserve(worker,source,port,value.input_resource,amount,value,"input")
		if not ticket.is_empty(): return ticket
	value.reason="Aguardando transportador, carga em viagem ou caminho livre."
	return {}

func input_reason(value: Dictionary) -> String:
	if value.input_resource=="produce" and game.available_stock().produce<game.workers.size()*game.DATA.FOOD_RESERVE_PER_PERSON: return "Venda pausada para preservar a reserva alimentar."
	if not game.workers.any(func(w): return w.assignment=="carrier"): return "Aguardando transportadores em Habitantes."
	return ""

func pickup(ticket: Dictionary) -> int:
	var value := order(ticket.trade_id)
	if value.is_empty() or not game.logistics.tickets.has(ticket) or ticket.picked: return 0
	var source=ticket.source
	var amount: int=mini(ticket.amount,source.stored.get(ticket.resource,0))
	if ticket.trade_leg=="input":
		if value.phase!="pending" or first_pending().get("id",0)!=value.id: return 0
		if not source is PILE:
			value.reason=input_reason(value)
			if not value.reason.is_empty(): return 0
			var found := false
			for origin in value.origins:
				if origin.building!=source.entity_id: continue
				if not warehouse(source): return 0
				amount=mini(amount,origin.remaining)
				var withdrawn := 0
				for previous in value.origins: withdrawn+=previous.return_space
				var port=building(value.port)
				if not is_instance_valid(port): return 0
				var extra: int=maxi(value.output_amount,withdrawn+amount)-maxi(value.output_amount,withdrawn)
				if game.logistics.storage_free(port)<extra:
					value.reason="Aguardando espaço no porto para garantir a devolução da carga."
					return 0
				origin.remaining-=amount
				origin.return_space+=amount
				found=true
				break
			if not found: return 0
	else:
		if value.phase=="pending": return 0
		if not source is PILE:
			amount=mini(amount,value.receipt)
			value.receipt-=amount
	source.stored[ticket.resource]-=amount
	ticket.amount=amount
	ticket.picked=true
	ticket.worker.trade_id=value.id
	ticket.worker.trade_leg=ticket.trade_leg
	value.reason=""
	return amount

func deliver(ticket: Dictionary, amount: int) -> int:
	var value := order(ticket.trade_id)
	if value.is_empty() or not ticket.picked: return 0
	amount=mini(amount,ticket.amount)
	if ticket.trade_leg=="input":
		if value.phase!="pending" or game.merchant.state!="docked" or game.merchant.visit_id!=value.visit: return 0
		amount=mini(amount,value.input_amount-value.custody)
		value.custody+=amount
		ticket.amount-=amount
		if value.custody==value.input_amount: settle(value)
		return amount
	if value.phase=="pending" or not warehouse(ticket.destination): return 0
	for allocation in value.destinations:
		if allocation.building!=ticket.destination.entity_id: continue
		amount=mini(amount,allocation.remaining)
		var accepted: int=ticket.destination.store(ticket.resource,amount)
		allocation.remaining-=accepted
		value.to_store-=accepted
		ticket.amount-=accepted
		value.reason=""
		return accepted
	return 0

func settle(value: Dictionary) -> void:
	if value.phase!="pending" or value.custody!=value.input_amount: return
	var port=building(value.port)
	if not is_instance_valid(port): return
	# Capacity was reserved before confirmation/withdrawal. One atomic ownership
	# transfer consumes custody and creates exactly the contracted receipt.
	if port.capacity()-port.used()<value.output_amount:
		value.reason="Recebimento do porto ocupado; aguardando espaço."
		return
	value.phase="settled"
	value.custody=0
	value.receipt=value.output_amount
	value.to_store=value.output_amount
	for origin in value.origins: origin.remaining=0; origin.return_space=0
	port.stored[value.output_resource]+=value.output_amount
	game.notify("Negócio %d concluído. Carga recebida no porto; aguardando transporte ao galpão."%value.id)

func loose_amount(value: Dictionary) -> int:
	var amount := 0
	for worker in game.workers:
		if worker.trade_id==value.id: amount+=worker.cargo
	for pile in game.logistics.piles:
		if pile.trade_id==value.id: amount+=pile.stored.get(pile.resource_kind,0)
	return amount

func cancel(id: int, message := "Negócio cancelado; materiais serão devolvidos ao galpão.") -> bool:
	var value := order(id)
	if value.is_empty() or value.phase!="pending": return false
	value.phase="cancelled"
	if value.visit==game.merchant.visit_id:
		if value.side=="sell":
			game.merchant.budget=mini(ECONOMY.MERCHANT_BUDGET,game.merchant.budget+value.payment)
			game.merchant.buying_caps[value.resource]=mini(ECONOMY.MERCHANT_STOCK,game.merchant.buying_caps.get(value.resource,0)+value.quantity)
		else: game.merchant.offers[value.resource]=mini(ECONOMY.MERCHANT_STOCK,game.merchant.offers.get(value.resource,0)+value.quantity)
	value.to_store=value.custody+loose_amount(value)
	value.destinations.clear()
	for origin in value.origins: origin.remaining=0; origin.return_space=0
	var port=building(value.port)
	if value.custody>0:
		var received := 0
		if is_instance_valid(port) and port.kind=="trading_port":
			received=mini(value.custody,maxi(0,port.capacity()-port.used()))
			port.stored[value.input_resource]+=received
		value.receipt=received
		if received<value.custody:
			game.logistics.drop(port.door() if is_instance_valid(port) else game.base.door(),value.input_resource,value.custody-received,value.id,"receipt")
	value.custody=0
	value.reason=message
	for worker in game.workers:
		if worker.trade_id==id or worker.ticket.get("trade_id",0)==id:
			worker.interrupt_task(true)
			worker.trade_leg="receipt" if worker.cargo>0 else ""
			if worker.cargo>0: resume_cargo(worker)
	for pile in game.logistics.piles:
		if pile.trade_id==id: pile.trade_leg="receipt"
	allocate_missing(value)
	return true

func allocate_missing(value: Dictionary) -> void:
	if value.phase=="pending": return
	value.destinations=value.destinations.filter(func(a): return warehouse(building(a.building)) and a.remaining>0)
	var remaining: int=value.to_store
	for target in value.destinations:
		target.remaining=mini(target.remaining,remaining)
		remaining-=target.remaining
	var port=building(value.port)
	var point: Vector2=game.cell_center(port.door() if is_instance_valid(port) else game.base.door())
	for target in warehouses_from(point):
		var amount: int=mini(remaining,game.logistics.storage_free(target))
		if amount<=0: continue
		var existing: Array=value.destinations.filter(func(a): return a.building==target.entity_id)
		if existing.is_empty(): value.destinations.append({"building":target.entity_id,"remaining":amount})
		else: existing[0].remaining+=amount
		remaining-=amount
		if remaining==0: break

func resume_cargo(worker) -> bool:
	var value := order(worker.trade_id)
	if value.is_empty(): worker.trade_id=0; worker.trade_leg=""; return false
	var destination=null
	var amount: int=worker.cargo
	var leg := "input" if value.phase=="pending" else "receipt"
	if leg=="input": destination=building(value.port)
	else:
		allocate_missing(value)
		for allocation in value.destinations:
			var candidate=building(allocation.building)
			var space: int=allocation.remaining-target_ticketed(value.id,allocation.building)
			if space>0 and warehouse(candidate) and not game.route_to_cell(worker.position,candidate.door()).is_empty():
				destination=candidate
				amount=mini(amount,space)
				break
	if not is_instance_valid(destination) or game.route_to_cell(worker.position,destination.door()).is_empty():
		worker.state="idle"
		worker.status="Carga comercial preservada; aguardando galpão ou caminho."
		return true
	var ticket := {"id":game.logistics.next_id,"worker":worker,"source":worker,"destination":destination,"resource":worker.cargo_resource,"amount":amount,"picked":true,"material":false,"trade_id":value.id,"trade_leg":leg}
	game.logistics.next_id+=1
	game.logistics.tickets.append(ticket)
	worker.ticket=ticket
	worker.trade_leg=leg
	worker.path=game.route_to_cell(worker.position,destination.door())
	worker.state="to_deliver"
	worker.status="Levando carga do negócio %d"%value.id
	return true

func before_demolition(target) -> void:
	for value in orders:
		if value.phase=="pending" and (value.port==target.entity_id or value.origins.any(func(a): return a.building==target.entity_id) or value.destinations.any(func(a): return a.building==target.entity_id)):
			cancel(value.id,"Negócio cancelado pela demolição; devolução em andamento.")
		value.destinations=value.destinations.filter(func(a): return a.building!=target.entity_id)
		if value.phase!="pending": allocate_missing(value)

func before_removal(target) -> void:
	before_demolition(target)
	if target.kind!="trading_port": return
	var cells: Array=game.port_layout.layout(target.origin,target.orientation).land
	var index := 0
	for value in orders:
		if value.port!=target.entity_id: continue
		var resource := receipt_resource(value)
		var amount: int=mini(value.receipt,target.stored.get(resource,0))
		if amount>0:
			target.stored[resource]-=amount
			game.logistics.drop(cells[index%cells.size()],resource,amount,value.id,"receipt")
			index+=1
		value.receipt=0
		value.port=0

func request_transfer(resource: String, quantity: int) -> void:
	if resource not in game.DATA.RESOURCES or quantity<=0: return
	transfer_targets[resource]=maxi(quantity,transfer_targets.get(resource,0))

func claim_transfer(worker) -> Dictionary:
	for resource in transfer_targets.keys():
		var stored := 0
		for target in game.buildings:
			if warehouse(target): stored+=game.logistics.available(target,resource)+game.logistics.incoming(target,resource)
		var needed: int=transfer_targets[resource]-stored
		if needed<=0: transfer_targets.erase(resource); continue
		for target in warehouses_from(worker.position):
			for source in game.buildings+game.logistics.piles:
				if source==target or (not source is PILE and source.kind=="warehouse"): continue
				if not source is PILE and ((source.kind=="smelter" and resource in ["wood","gold_ore"]) or (source.kind=="workshop" and resource in ["wood","stone"])): continue
				var amount: int=mini(needed,mini(game.logistics.available(source,resource),game.logistics.storage_free(target)))
				var ticket: Dictionary=game.logistics.reserve(worker,source,target,resource,amount,false)
				if not ticket.is_empty(): return ticket
	return {}

func tick() -> void:
	for value in orders:
		if value.phase=="pending" and value.custody==value.input_amount: settle(value)
		if value.phase=="pending" and not game.workers.any(func(w): return w.assignment=="carrier"): value.reason="Aguardando transportadores em Habitantes."

func extra_transit(resource: String) -> int:
	var amount := 0
	for value in orders:
		if value.input_resource==resource: amount+=value.custody
	for target in game.buildings:
		if target.kind=="trading_port": amount+=target.stored.get(resource,0)
	return amount

func snapshot() -> Dictionary:
	return {"orders":orders.duplicate(true),"next_id":next_id,"requests":requests.duplicate(),"transfer_targets":transfer_targets.duplicate()}

func restore(data: Dictionary) -> void:
	orders=data.get("orders",[]).duplicate(true)
	next_id=data.get("next_id",1)
	requests=data.get("requests",{}).duplicate()
	transfer_targets=data.get("transfer_targets",{}).duplicate()
	# Cargo is physical inventory; an invalid ownership tag must not change its
	# material or make it disappear into an unrelated order on load.
	for worker in game.workers:
		var value := order(worker.trade_id)
		if value.is_empty() or worker.cargo_resource!=(value.input_resource if value.phase=="pending" else receipt_resource(value)):
			worker.trade_id=0; worker.trade_leg=""
	for pile in game.logistics.piles:
		var value := order(pile.trade_id)
		if value.is_empty() or pile.resource_kind!=(value.input_resource if value.phase=="pending" else receipt_resource(value)):
			pile.trade_id=0; pile.trade_leg=""
	for value in orders:
		next_id=maxi(next_id,value.id+1)
		if value.phase=="pending":
			var port=building(value.port)
			var consistent: bool=value.visit==game.merchant.visit_id and game.merchant.state=="docked" and value.port==game.merchant.port_id and is_instance_valid(port) and port.kind=="trading_port" and port.completed and not port.demolition_requested
			var total: int=value.custody+loose_amount(value)
			var withdrawn := 0
			for origin in value.origins:
				total+=origin.remaining
				withdrawn+=origin.return_space
				var source=building(origin.building)
				if not warehouse(source) or reserved(source,value.input_resource)>source.stored.get(value.input_resource,0): consistent=false
			var capacity := 0
			for target in value.destinations:
				var destination=building(target.building)
				capacity+=target.remaining
				if not warehouse(destination) or destination.used()+incoming(destination)>destination.capacity(): consistent=false
			if total!=value.input_amount or capacity!=value.output_amount or withdrawn!=value.custody+loose_amount(value) or value.receipt!=0 or value.to_store!=0: consistent=false
			var expected_payment: int=(ECONOMY.BUY_PRICES if value.side=="buy" else ECONOMY.SELL_PRICES)[value.resource]*(value.quantity/10)
			if value.payment!=expected_payment or value.input_resource!=("gold_bar" if value.side=="buy" else value.resource) or value.output_resource!=(value.resource if value.side=="buy" else "gold_bar"): consistent=false
			if value.quantity<10 or value.quantity>60 or value.quantity%10!=0 or value.input_amount!=(expected_payment if value.side=="buy" else value.quantity) or value.output_amount!=(value.quantity if value.side=="buy" else expected_payment): consistent=false
			if not consistent: cancel(value.id,"Ordem inconsistente cancelada ao carregar; bens preservados.")
	reconcile_receipts()
	for key in requests.keys():
		if order(requests[key]).is_empty(): requests.erase(key)

func reconcile_receipts() -> void:
	# Receipt counts allocate port.stored; they never represent extra inventory.
	var remaining := {}
	for target in game.buildings:
		if target.kind=="trading_port": remaining[target.entity_id]=target.stored.duplicate()
	for value in orders:
		if value.phase=="pending": continue
		var resource := receipt_resource(value)
		var pool: Dictionary=remaining.get(value.port,{})
		value.receipt=mini(value.receipt,pool.get(resource,0))
		pool[resource]=pool.get(resource,0)-value.receipt
		if value.custody>0:
			game.logistics.drop(game.base.door(),value.input_resource,value.custody)
			value.custody=0
		value.to_store=value.receipt+loose_amount(value)
		# Discard oversized stale capacity claims, then rebuild them from real goods.
		for allocation in value.destinations:
			var target=building(allocation.building)
			if not warehouse(target): allocation.remaining=0; continue
			var other: int=incoming(target)-allocation.remaining
			allocation.remaining=mini(allocation.remaining,maxi(0,target.capacity()-target.used()-other))
		allocate_missing(value)
	# Preserve unclaimed stock from a damaged order on dry land where it can be
	# collected. Do not fabricate a completed trade or replay its payment.
	for id in remaining:
		var target=building(id)
		for resource in remaining[id]:
			var amount: int=remaining[id][resource]
			if amount<=0: continue
			target.stored[resource]-=amount
			game.logistics.drop(target.door(),resource,amount)

static func valid(data) -> bool:
	if not data is Dictionary or not data.get("orders") is Array or not data.get("next_id") is int or data.next_id<1: return false
	if not data.get("requests") is Dictionary or not data.get("transfer_targets") is Dictionary: return false
	var seen := {}
	for value in data.orders:
		if not value is Dictionary: return false
		for key in ["id","visit","port","quantity","payment","input_amount","output_amount","custody","receipt","to_store"]:
			if not value.get(key) is int or value[key]<0: return false
		if value.id==0 or seen.has(value.id): return false
		seen[value.id]=true
		if value.get("side") not in ["buy","sell"] or value.get("resource") not in ECONOMY.SELL_PRICES: return false
		if value.get("input_resource") not in ["gold_bar","wood","stone","produce"] or value.get("output_resource") not in ["gold_bar","wood","stone","produce"]: return false
		if value.get("phase") not in ["pending","settled","cancelled"] or not value.get("reason") is String: return false
		for key in ["origins","destinations"]:
			if not value.get(key) is Array: return false
			for entry in value[key]:
				if not entry is Dictionary or not entry.get("building") is int or not entry.get("remaining") is int or entry.remaining<0: return false
				if key=="origins" and (not entry.get("return_space") is int or entry.return_space<0): return false
	for key in data.requests:
		if not key is String or not data.requests[key] is int: return false
	for resource in data.transfer_targets:
		if resource not in preload("res://Scripts/game_data.gd").RESOURCES or not data.transfer_targets[resource] is int or data.transfer_targets[resource]<0: return false
	return true

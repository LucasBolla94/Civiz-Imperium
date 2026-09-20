extends Node2D

const VISUAL = preload("res://Scripts/resident_visual.gd")
const WORLD_JOB = preload("res://Scripts/world_job.gd")
const GARDEN_JOB = preload("res://Scripts/garden.gd")
const NEEDS = preload("res://Scripts/needs.gd")
var person
var needs = NEEDS.new()
var residence = null
var move_destination = null
var selected := false
var ticket: Dictionary = {}
var cargo_resource := ""
var trade_id := 0
var trade_leg := ""
var complaint_time := 0.0
var spare_tools: Dictionary = {}
var preferred_source = null
var clear_destination := Vector2i(-999,-999)
var clear_site_id := 0
var evacuation_destination := Vector2i(-999,-999)
var repath_delay := 0.0
var repath_attempts := 0
var game
var kind: String
var assignment: String
var assigned_home
var home
var cargo := 0
var state := "idle"
var target = null
var path: PackedVector2Array = []
var timer := 0.0
var think_timer := 0.0
var sprite: AnimatedSprite2D
var visual
var status := "Procurando trabalho"

func setup(controller, worker_kind: String, building, start: Vector2) -> void:
	game = controller
	kind = worker_kind
	assignment = worker_kind
	assigned_home = building
	home = building
	position = start
	visual = VISUAL.new()
	add_child(visual)
	visual.configure(0)
	sprite = visual.sprite
	queue_redraw()


func refresh_appearance() -> void:
	if person == null: return
	visual.configure(person.appearance_id)
	visual.crown.visible = person.is_king
	visual.update_crown()

func process_move(delta: float) -> void:
	if not is_instance_valid(move_destination): return
	status = "Mudando para " + move_destination.display_name()
	if game.world_cell(position) == move_destination.door() and path.is_empty():
		residence = move_destination
		person.residence_id = residence.entity_id
		move_destination = null
		apply_assignment()
		return
	if path.is_empty(): path = game.route_to_cell(position, move_destination.door())
	if not path.is_empty(): move_along_path(delta)

func assign_to(activity: String, workplace) -> void:
	if assignment == activity and assigned_home == workplace: return
	assignment = activity
	assigned_home = workplace
	if cargo > 0 and state in ["to_home", "to_deliver"]:
		status = "Concluindo entrega antes de trocar de função"
		return
	if cargo>0:
		interrupt_task(true)
		return_home()
		status="Mudança pendente — entregando a carga"
		return
	if state in ["resting", "to_rest"]: return
	interrupt_task()
	apply_assignment()

func apply_assignment() -> void:
	kind = assignment
	home = assigned_home
	person.profession = assignment
	state = "idle"
	think_timer = 0
	queue_redraw()

func interrupt_task(preserve_cargo := false) -> void:
	clear_destination = Vector2i(-999,-999)
	clear_site_id = 0
	evacuation_destination = Vector2i(-999,-999)
	game.work_planner.release(self)
	if person!=null: game.gold.release_bench(self)
	if is_instance_valid(home) and home.craft_reserved_by == self: home.craft_reserved_by = null
	repath_attempts = 0
	repath_delay = 0
	if is_instance_valid(target) and target.has_method("build") and target.reserved_by == self:
		target.reserved_by = null
	game.logistics.release(self)
	ticket = {}
	if cargo > 0 and not preserve_cargo:
		game.logistics.drop(game.world_cell(position), cargo_resource, cargo, trade_id, trade_leg)
		cargo = 0
	if cargo==0: trade_id=0; trade_leg=""
	path.clear()
	target = null
	timer = 0
	if state != "resting": state = "idle"
	queue_redraw()

func go_rest() -> bool:
	if not is_instance_valid(residence) and not game.settlement.assign_residence(self):
		status = "Sem residência — construa uma casa"
		return false
	var route: PackedVector2Array = game.route_to_cell(position, residence.door())
	if route.is_empty():
		status = "Caminho para residência bloqueado"
		return false
	interrupt_task()
	path = route
	state = "to_rest"
	status = "Indo descansar em " + residence.display_name()
	return true

func wake(early := true) -> void:
	if state != "resting": return
	visible = true
	state = "idle"
	position = game.cell_center(residence.door())
	needs.wake_grace = 30.0 if early else 0.0
	if early:
		complaint_time = 6.0
		game.notify(person.display_name + ": Eu ainda estava dormindo...")
	apply_assignment()

func _process(delta: float) -> void:
	refresh_appearance()
	sprite.speed_scale = game.simulation_speed
	if game.simulation_paused or game.settlement.extinct:
		sprite.pause()
		return
	delta *= game.simulation_speed
	complaint_time = maxf(0, complaint_time - delta)
	repath_delay = maxf(0, repath_delay - delta)
	if needs.tick(self, delta):
		queue_redraw()
		return
	if game.clearance.process_worker(self,delta):
		queue_redraw()
		return
	if is_instance_valid(move_destination):
		process_move(delta)
		return
	if state == "to_source" and not game.work_planner.available_claim(self):
		interrupt_task()
		status = "Fonte indisponível — escolhendo outro trabalho"
		return
	if not path.is_empty():
		move_along_path(delta)
		return
	sprite.play("Work" if state in ["to_build", "building", "to_source", "harvesting", "to_craft", "crafting"] else "Idle")
	if sprite.animation == &"Work" and is_instance_valid(target): visual.face(target.position - position)
	var productivity: float = needs.productivity(self) * person.efficiency(game.DATA)
	match state:
		"to_rest":
			if game.world_cell(position) == residence.door():
				state = "resting"
				visible = false
			else: state = "idle"
		"to_build", "building":
			if not is_instance_valid(target) or not target.needs_work() or not target.materials.ready():
				interrupt_task()
				return
			if game.world_cell(position) != target.door():
				interrupt_task()
				return
			state = "building"
			status = ("Investigando terreno" if target.kind == "survey" else "Abrindo pedreira") if kind == "stone" else "Construindo"
			drain_work(delta)
			target.build(delta * productivity)
			person.gain_xp(kind, delta * 0.2)
		"to_source", "harvesting":
			state = "harvesting"
			var equipped := has_tool()
			status = "Coletando" if equipped else "Sem ferramenta — trabalhando devagar"
			if not game.work_planner.available_claim(self) or cargo >= game.carry_capacity():
				finish_harvest()
				return
			if kind == "wood" and target.has_method("start_cut"):
				target.start_cut()
			var speed: float = 1.0 if equipped else game.DATA.TOOLLESS_SPEED
			drain_work(delta, not equipped)
			timer += delta * productivity * speed
			var harvest_seconds: float=game.DATA.ECONOMY.GOLD_HARVEST_SECONDS if kind=="gold_mining" else game.DATA.HARVEST_SECONDS
			while timer >= harvest_seconds and cargo < game.carry_capacity() and game.work_planner.available_claim(self):
				timer -= harvest_seconds
				var amount: int = game.work_planner.collect(self)
				if amount == 0:
					finish_harvest()
					return
				cargo += amount
				cargo_resource = game.DATA.resource_for_activity(kind)
				person.gain_xp(kind, amount * game.DATA.XP_PER_ACTION)
				if game.DATA.TOOLS.has(kind) and has_tool():
					person.durability -= amount
					if person.durability <= 0:
						person.tool = ""
						game.notify(person.display_name + ": minha ferramenta quebrou; vou procurar outra.")
						finish_harvest()
						return
			queue_redraw()
		"to_home":
			if not is_instance_valid(home) or game.world_cell(position) != home.door():
				interrupt_task()
				return
			var amount: int = game.logistics.deliver(ticket, mini(cargo, ticket.get("amount",0)))
			home.delivered += amount
			game.total_delivered[cargo_resource] = game.total_delivered.get(cargo_resource, 0) + amount
			cargo -= amount
			game.logistics.release(self)
			ticket = {}
			if cargo > 0: return_home()
			else: apply_assignment()
		"to_pickup":
			if ticket.is_empty() or not is_instance_valid(ticket.source) or game.world_cell(position) != ticket.source.door():
				interrupt_task()
				return
			cargo = game.logistics.pickup(ticket)
			cargo_resource = ticket.resource
			path = game.route_to_cell(position, ticket.destination.door())
			state = "to_deliver"
			status = "Levando " + game.DATA.RESOURCES[cargo_resource].name
			if path.is_empty() or cargo <= 0: interrupt_task()
		"to_deliver":
			if ticket.is_empty() or not is_instance_valid(ticket.destination) or game.world_cell(position) != ticket.destination.door():
				interrupt_task()
				return
			var amount: int = game.logistics.deliver(ticket, cargo)
			if not ticket.material: game.total_delivered[cargo_resource] = game.total_delivered.get(cargo_resource, 0) + amount
			cargo -= amount
			person.gain_xp("carrier", amount * 0.25)
			interrupt_task()
		"to_tool":
			if ticket.is_empty() or game.world_cell(position) != ticket.source.door():
				interrupt_task()
				return
			if game.logistics.pickup(ticket) == 1:
				if person.tool != "" and person.durability > 0: spare_tools[person.tool] = person.durability
				person.tool = ticket.resource
				person.durability = game.DATA.TOOL_DURABILITY
			interrupt_task()
		"to_craft", "crafting":
			if not is_instance_valid(home) or game.world_cell(position) != home.door():
				interrupt_task()
				return
			state = "crafting"
			if kind=="smelter":
				if game.gold.smelt(self,delta*productivity):
					status="Fundindo barras de ouro"
					drain_work(delta)
					person.gain_xp("smelter",delta*0.2)
				else:
					interrupt_task()
					status=game.gold.smelter_status(home)
				return
			if home.craft(delta * productivity):
				status = "Produzindo ferramentas"
				drain_work(delta)
				person.gain_xp("workshop", delta * 0.2)
			else:
				interrupt_task()
				think_timer = game.DATA.IDLE_RECHECK_SECONDS
				status = "Metas atendidas ou aguardando insumos"
		"idle":
			think_timer -= delta
			if think_timer <= 0:
				think_timer = game.DATA.IDLE_RECHECK_SECONDS + (person.id % 5) * 0.09
				find_job()
	queue_redraw()

func move_along_path(delta: float) -> void:
	if repath_delay > 0:
		sprite.play("Idle")
		return
	var budget: float = game.DATA.WALK_SPEED * delta
	person.energy = maxf(0, person.energy - game.DATA.ENERGY_WALK * delta)
	while not path.is_empty() and budget > 0:
		if not game.is_walkable(game.world_cell(path[0])):
			retry_route()
			return
		repath_attempts = 0
		var difference: Vector2 = path[0] - position
		var distance := difference.length()
		visual.face(difference)
		sprite.play("Walk")
		if distance <= budget:
			position = path[0]
			path.remove_at(0)
			budget -= distance
		else:
			position += difference.normalized() * budget
			budget = 0

func drain_work(delta: float, untooled := false) -> void:
	person.energy = maxf(0, person.energy - delta * game.DATA.ENERGY_WORK * (game.DATA.TOOLLESS_ENERGY if untooled else 1.0))

func has_tool() -> bool:
	return not game.DATA.TOOLS.has(kind) or (person.tool == game.DATA.TOOLS[kind] and person.durability > 0)

func retry_route() -> void:
	var route: PackedVector2Array = game.route_to_cell(position, game.world_cell(path[-1]))
	if not route.is_empty():
		path = route
		status = "Contornando passagem bloqueada"
		return
	repath_attempts += 1
	repath_delay = game.DATA.ROUTE_RETRY_SECONDS
	status = "Passagem bloqueada — aguardando acesso"
	if repath_attempts >= game.DATA.ROUTE_RETRY_LIMIT:
		interrupt_task()
		think_timer = game.DATA.IDLE_RECHECK_SECONDS
		status = "Sem acesso — tarefa liberada para outra tentativa"

func can_finish_delivery() -> bool:
	if cargo <= 0 or state not in ["to_home", "to_deliver"] or person.energy <= game.DATA.EXHAUSTED_ENERGY: return false
	if repath_delay > 0: return false
	var distance: float = game.work_planner.route_length(position, path)
	return distance <= game.DATA.WALK_SPEED * game.DATA.FINISH_DELIVERY_SECONDS

func find_tool() -> bool:
	if has_tool(): return false
	var tool: String = game.DATA.TOOLS[kind]
	if spare_tools.get(tool, 0) > 0:
		if person.tool != "" and person.durability > 0: spare_tools[person.tool] = person.durability
		person.tool = tool
		person.durability = spare_tools[tool]
		spare_tools.erase(tool)
		return false
	var best = null
	var shortest := INF
	for building in game.buildings:
		if game.logistics.available(building, tool) <= 0: continue
		var route: PackedVector2Array = game.route_to_cell(position, building.door())
		if route.is_empty(): continue
		var distance: float = game.work_planner.route_length(position, route)
		if distance < shortest:
			best = building
			shortest = distance
	if best == null: return false
	ticket = game.logistics.reserve(self, best, best, tool, 1, false)
	if ticket.is_empty(): return false
	path = game.route_to_cell(position, best.door())
	state = "to_tool"
	status = "Buscando ferramenta no estoque mais próximo"
	return true

func take_logistics(destination = null) -> bool:
	ticket = game.logistics.claim(self, destination)
	if ticket.is_empty(): return false
	path = game.route_to_cell(position, ticket.source.door())
	state = "to_pickup"
	status = "Buscando " + game.DATA.RESOURCES[ticket.resource].name
	return true

func find_job() -> void:
	if cargo > 0:
		return_home()
		return
	if assignment != kind: apply_assignment()
	if game.clearance.claim(self): return
	if find_tool(): return
	if kind=="smelter":
		home=assigned_home
		if game.gold.bench_for(self)>=0:
			path=game.route_to_cell(position,home.door())
			if not path.is_empty():
				state="to_craft"
				status="Indo trabalhar na fundição"
				return
			game.gold.release_bench(self)
		status=game.gold.smelter_status(home) if is_instance_valid(home) and home.kind=="smelter" else "Aguardando fundição disponível"
		return
	if kind == "food" and game.settlement.food_units() < game.workers.size() * game.DATA.FOOD_RESERVE_PER_PERSON:
		if take_harvest():
			status = "Buscando Hortifruti — reserva alimentar baixa"
			return
	if kind in ["builder", "food", "stone"]:
		var best = null
		var best_route: PackedVector2Array = []
		var shortest := INF
		var best_priority := -1
		for job in game.jobs + game.buildings + game.gardens:
			if job.get("preparing_site") == true: continue
			if not job.needs_work() or not job.materials.ready(): continue
			var activity: String = job.activity if job is WORLD_JOB or job is GARDEN_JOB else "builder"
			if activity != kind or (is_instance_valid(job.reserved_by) and job.reserved_by != self): continue
			var route: PackedVector2Array = game.route_to_cell(position, job.door())
			if route.is_empty(): continue
			var distance: float = game.work_planner.route_length(position, route)
			if job.priority > best_priority or (job.priority == best_priority and distance < shortest):
				best_priority = job.priority
				best = job
				best_route = route
				shortest = distance
		if best != null:
			best.reserved_by = self
			target = best
			path = best_route
			state = "to_build"
			status = "Indo construir" if kind == "builder" else ("Investigando / abrindo pedreira" if kind == "stone" else "Indo plantar")
			return
	if kind == "workshop":
		home = assigned_home
		if home.kind != "workshop" or home.demolition_requested:
			status = "Aguardando oficina disponível"
			return
		if home.can_craft() and not is_instance_valid(home.craft_reserved_by):
			path = game.route_to_cell(position, home.door())
			if not path.is_empty():
				home.craft_reserved_by = self
				state = "to_craft"
				status = "Indo trabalhar na oficina"
				return
		if take_logistics(home): return
		status = "Bancada ocupada — aguardando" if is_instance_valid(home.craft_reserved_by) else ("Oficina cheia — aguardando retirada" if game.logistics.storage_free(home) <= 0 else "Oficina abastecida; aguardando demanda ou insumos")
		return
	if kind in ["builder", "carrier", "idle"]:
		if take_logistics(): return
		status = "Aguardando materiais / trabalho" if kind != "idle" else "Livre — disponível para transporte"
		return
	# A gatherer helps supply its own planting, not unrelated village deliveries.
	if kind in ["food", "stone"]:
		for job in game.jobs + game.gardens:
			if job.activity == kind and job.needs_work() and not job.materials.ready():
				if take_logistics(job): return
	take_harvest()

func take_harvest() -> bool:
	if kind=="gold_mining" and game.gold.post_space(assigned_home,self)<=0:
		status="Posto de mineração cheio ou indisponível — aguardando transporte"
		return false
	if game.logistics.storage_for(position, game.DATA.resource_for_activity(kind)) == null:
		status = "Depósitos cheios — aguardando espaço"
		return false
	var claim: Dictionary = game.work_planner.claim_harvest(self)
	if not claim.is_empty():
		target = claim.source
		preferred_source = target
		path = claim.route
		state = "to_source"
		status = "Indo coletar em posto reservado"
		timer = 0
		return true
	else:
		var productive: bool = (game.sources + game.gardens).any(func(source): return source.harvestable(kind))
		var resource: String = game.DATA.resource_for_activity(kind)
		var at_target: bool = game.automation.total_committed(resource) >= game.automation.production_limit(resource)
		status = "Meta de estoque atendida — produção pausada" if at_target else ("Postos ocupados ou sem acesso — aguardando" if productive else "Sem fonte disponível — aguarde o ciclo ou plante")
	return false

func finish_harvest() -> void:
	game.work_planner.release(self)
	target = null
	if kind!="gold_mining" and game.village_level >= 2 and game.activity_count("carrier") > 0 and cargo > 0:
		game.logistics.drop(game.world_cell(position), cargo_resource, cargo)
		cargo = 0
		state = "idle"
	else: return_home()

func return_home() -> void:
	if cargo>0 and trade_id>0 and game.commerce.resume_cargo(self): return
	if cargo == 0:
		state = "idle"
		return
	home = assigned_home if kind=="gold_mining" and assignment=="gold_mining" and is_instance_valid(assigned_home) and not assigned_home.demolition_requested else game.logistics.storage_for(position,cargo_resource)
	if home == null:
		interrupt_task()
		status = "Depósitos cheios — carga preservada no chão"
		return
	ticket = game.logistics.reserve_cargo(self, home)
	path = game.route_to_cell(position, home.door())
	state = "to_home"
	status = "Entregando em depósito com espaço reservado"
func _draw() -> void:
	if person == null: return
	var color: Color = game.DATA.ACTIVITIES[kind].color
	draw_circle(Vector2(0, 0), 4, Color(0, 0, 0, 0.2))
	draw_circle(Vector2(0, 2), 2, color)
	if selected: draw_arc(Vector2.ZERO, 7, 0, TAU, 16, Color("f3dc9b"), 1)
	if cargo > 0: draw_rect(Rect2(5, -10, 4, 5), color)
	if person.energy < game.DATA.REST_THRESHOLD: draw_rect(Rect2(-5,-37,10,2),Color("86bec9"))
	if person.nutrition < game.DATA.HUNGER_SLOW: draw_rect(Rect2(-5,-40,10,2),Color("e97b57"))
	if complaint_time > 0:
		draw_style_box(game.hud.MENU_THEME.panel(2),Rect2(-8,-49,16,12))
		draw_string(ThemeDB.fallback_font,Vector2(-2,-40),"!",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("914629"))

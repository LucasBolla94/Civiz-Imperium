extends Node2D
const MATERIALS = preload("res://Scripts/material_request.gd")
const FEEDBACK = preload("res://Scripts/building_feedback.gd")
var warning: Dictionary = {}
var warning_sprite: Sprite2D

func update_warning() -> void:
	warning = FEEDBACK.diagnose(self)
	if is_instance_valid(warning_sprite): warning_sprite.visible = not warning.is_empty()

func warning_hit(point: Vector2) -> bool:
	return is_instance_valid(warning_sprite) and warning_sprite.visible and Rect2(warning_sprite.global_position-Vector2(8,8),Vector2(16,16)).has_point(point)
var game
var entity_id := 0
var kind: String
var origin: Vector2i
var grid_size: Vector2i
var completed := false
var progress := 0.0
var stored: Dictionary = {}
var delivered := 0
var selected := false
var sprite: Sprite2D
var reserved_by = null
var level := 1
var upgrading := false
var materials = MATERIALS.new()
var tool_targets := {"axe": 5, "pickaxe": 5}
var craft_progress := 0.0
var crafting := ""
var craft_reserved_by = null
var tool_orders := {"axe": 0, "pickaxe": 0}
var priority := 1
var work_started := false
var demolition_requested := false
var demolition_started := false
var demolition_progress := 0.0

func request_demolition() -> bool:
	if kind == "base" or not completed or upgrading or demolition_requested: return false
	demolition_requested = true
	materials = MATERIALS.new()
	game.detach_building_tasks(self, false)
	game.settlement.tick_moves()
	if is_instance_valid(game.hud): game.hud.refresh()
	return true

func cancel_demolition() -> bool:
	if not demolition_requested or demolition_started: return false
	demolition_requested = false
	game.settlement.cancel_moves(self)
	game.detach_building_tasks(self, false)
	if is_instance_valid(game.hud): game.hud.refresh()
	return true

func demolition_ready() -> bool:
	return demolition_requested and game.settlement.residents(self).is_empty()

func demolition_status() -> String:
	var occupants: Array = game.settlement.residents(self)
	if not occupants.is_empty():
		if occupants.any(func(w): return is_instance_valid(w.move_destination)): return "Moradores em mudança"
		return "Precisamos de moradia para %d pessoas" % occupants.size()
	if demolition_started: return "Demolindo · %.1f/10s" % demolition_progress
	if game.route_to_cell(game.cell_center(game.base.door()), door()).is_empty(): return "Demolição aguardando acesso"
	return "Demolição aguardando construtor"

func setup(controller, building_kind: String, cell: Vector2i, ready_now := false) -> void:
	game = controller
	entity_id = 1
	for existing in game.buildings: entity_id = maxi(entity_id, existing.entity_id + 1)
	kind = building_kind
	origin = cell
	stored = game.DATA.empty_stock()
	grid_size = game.DATA.building_size(kind)
	completed = ready_now
	if not ready_now: materials.required = game.DATA.BUILDINGS[kind].cost.duplicate()
	position = Vector2(origin * 16) + Vector2(grid_size.x * 8, grid_size.y * 16)
	sprite = Sprite2D.new()
	sprite.texture = game.DATA.building_texture(kind)
	if kind in ["house", "workshop"]: sprite.scale = Vector2.ONE * 0.5
	sprite.position = Vector2(0, -sprite.texture.get_height() * sprite.scale.y * 0.5)
	add_child(sprite)
	warning_sprite = Sprite2D.new()
	var bubble := AtlasTexture.new()
	bubble.atlas = FEEDBACK.BUBBLES
	bubble.region = Rect2(0,112,16,16)
	warning_sprite.texture = bubble
	warning_sprite.position = Vector2(grid_size.x*8,-grid_size.y*16-8)
	warning_sprite.z_index = 20
	warning_sprite.hide()
	add_child(warning_sprite)
	refresh_visual()

func display_name() -> String:
	return "%s %02d" % [game.DATA.BUILDINGS[kind].short, entity_id]

func footprint() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for y in range(grid_size.y):
		for x in range(grid_size.x): result.append(origin + Vector2i(x, y))
	return result

func door() -> Vector2i: return origin + game.DATA.building_door(kind)
func housing_capacity() -> int:
	return 3 if kind == "base" else (game.DATA.HOUSE_CAPACITY + (level - 1) * game.DATA.HOUSE_UPGRADE_CAPACITY if kind == "house" else 0)
func capacity() -> int:
	return game.DATA.STORAGE_CAPACITY[kind] + (level - 1) * game.DATA.STORAGE_UPGRADE_CAPACITY if kind != "house" else 0
func used() -> int:
	var total := 0
	for resource in stored: total += stored[resource]
	return total
func accepts(resource: String) -> bool:
	if not completed or demolition_requested or capacity() == 0: return false
	if kind in ["base", "warehouse"]: return true
	if kind == "workshop": return resource in ["axe", "pickaxe"]
	return game.DATA.resource_for_activity(kind) == resource
func store(resource: String, amount: int) -> int:
	var accepted := mini(amount, maxi(0, capacity() - used()))
	stored[resource] = stored.get(resource, 0) + accepted
	return accepted
func needs_work() -> bool:
	return demolition_ready() if demolition_requested else (not completed or upgrading)
func enqueue() -> bool: return game.immigration.prepare_expedition() if kind == "base" and completed else false

func upgrade() -> bool:
	if not completed or upgrading or demolition_requested or level >= game.DATA.MAX_BUILDING_LEVEL or kind not in ["house", "warehouse", "food", "wood", "stone", "workshop"]: return false
	materials = MATERIALS.new()
	materials.required = upgrade_cost()
	upgrading = true
	progress = 0
	game.notify("Melhoria solicitada: materiais serão entregues fisicamente.")
	return true

func build(delta: float) -> void:
	if delta <= 0 or not needs_work() or not materials.ready(): return
	if demolition_requested:
		demolition_started = true
		demolition_progress += delta
		if demolition_progress >= game.DATA.DEMOLITION_SECONDS: game.remove_building(self, false)
		queue_redraw()
		return
	work_started = true
	progress += delta
	if progress >= game.DATA.BUILDINGS[kind].build_seconds:
		if upgrading: level += 1
		completed = true
		upgrading = false
		reserved_by = null
		game.notify(display_name() + " concluída!")
		for worker in game.workers: game.settlement.assign_residence(worker)
		refresh_visual()
	queue_redraw()

func upgrade_cost() -> Dictionary:
	if kind == "workshop": return {"wood": 15 * level, "stone": 15 * level}
	return (game.DATA.HOUSE_UPGRADE_COST if kind == "house" else game.DATA.STORAGE_UPGRADE_COST).duplicate()

func order_tool(tool: String, amount := 1) -> void:
	if kind == "workshop" and completed and not demolition_requested and game.DATA.RECIPES.has(tool):
		tool_orders[tool] = clampi(tool_orders[tool] + amount, 0, 20)

func desired_tools(tool: String) -> int:
	if level < 2: return 0
	if level == 2: return tool_targets[tool]
	var activity: String = "wood" if tool == "axe" else "stone"
	return ceili(game.activity_count(activity) * 0.5)

func tool_demand(tool: String) -> int:
	if tool_orders[tool] > 0: return tool_orders[tool]
	var projected := 0
	for building in game.buildings:
		projected += building.stored.get(tool, 0)
		if building.crafting == tool: projected += 1
		projected += building.tool_orders.get(tool, 0)
	return maxi(0, desired_tools(tool) - projected)

func input_demand(resource: String) -> int:
	if kind != "workshop" or not completed or upgrading or demolition_requested: return 0
	var need := 0
	for tool in tool_targets:
		need += game.DATA.RECIPES[tool].get(resource, 0) * mini(2, tool_demand(tool))
	return maxi(0, need - stored.get(resource, 0))

func next_recipe() -> String:
	if kind != "workshop" or not completed or upgrading or demolition_requested: return ""
	for tool in tool_targets:
		if tool_demand(tool) <= 0: continue
		var sufficient := true
		for resource in game.DATA.RECIPES[tool]:
			if game.logistics.available(self, resource) < game.DATA.RECIPES[tool][resource]: sufficient = false
		if sufficient and game.logistics.storage_free(self) > 0: return tool
	return ""

func workshop_status() -> String:
	var mode: String = ["Encomendas manuais", "Reposição por metas da vila", "Reserva conforme trabalhadores"][level - 1]
	var work: String = "Produzindo " + game.DATA.RESOURCES[crafting].name if crafting != "" else "Aguardando encomenda / meta"
	if crafting == "" and (tool_demand("axe") > 0 or tool_demand("pickaxe") > 0):
		var issue := FEEDBACK.diagnose(self)
		work = issue.text if not issue.is_empty() else "Aguardando produção"
	return "%s · %s · Fila: %d machados, %d picaretas · Prontos aqui: %d / %d" % [mode, work, tool_orders.axe, tool_orders.pickaxe, stored.axe, stored.pickaxe]

func can_craft() -> bool:
	if demolition_requested: return false
	if crafting != "": return craft_progress < game.DATA.CRAFT_SECONDS or game.logistics.storage_free(self) > 0
	return next_recipe() != ""

func craft(delta: float) -> bool:
	if upgrading or not can_craft(): return false
	if crafting == "":
		crafting = next_recipe()
		if crafting == "": return false
		tool_orders[crafting] = maxi(0, tool_orders[crafting] - 1)
		for resource in game.DATA.RECIPES[crafting]: stored[resource] -= game.DATA.RECIPES[crafting][resource]
	craft_progress += delta
	if craft_progress >= game.DATA.CRAFT_SECONDS and game.logistics.storage_free(self) > 0:
		store(crafting, 1)
		crafting = ""
		craft_progress = 0
	return true
func refresh_visual() -> void:
	sprite.modulate = Color.WHITE if completed else Color(1.0, 0.85, 0.6, 0.45)
	queue_redraw()

func _draw() -> void:
	if selected:
		draw_rect(Rect2(-grid_size.x * 8 - 1, -grid_size.y * 16 - 1, grid_size.x * 16 + 2, grid_size.y * 16 + 2), Color("f3dc9b"), false, 1)
	var color: Color = game.DATA.BUILDINGS[kind].color
	draw_circle(Vector2(0, -2), 3, color)
	if needs_work():
		draw_rect(Rect2(-20, -10, 40, 5), Color("233334"))
		var fraction: float = demolition_progress / game.DATA.DEMOLITION_SECONDS if demolition_requested else progress / game.DATA.BUILDINGS[kind].build_seconds
		draw_rect(Rect2(-20, -10, 40 * minf(fraction, 1.0), 5), color)
	elif capacity() > 0:
		draw_rect(Rect2(-16, 3, 32, 2), Color("233334"))
		draw_rect(Rect2(-16, 3, 32 * float(used()) / capacity(), 2), color)




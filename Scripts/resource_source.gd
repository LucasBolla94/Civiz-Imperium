extends Node2D
var game
var resource_kind: String
var remaining := 0
var cells: Array[Vector2i] = []
var terrain_visual: Node2D
var selected := false
var is_tree := false
var is_quarry := false
var initial_reserve := 480
var cut_requested := false
var cut_started := false

func request_cut() -> bool:
	if not is_tree or removed or stage != 4 or cut_requested: return false
	cut_requested = true
	# Release only uncollected food. Already collected cargo stays with its owner.
	for worker in game.work_planner.claims.keys():
		if game.work_planner.claims[worker].source == self:
			game.work_planner.release(worker)
	queue_redraw()
	game.hud.refresh()
	return true

func cancel_cut() -> bool:
	if not cut_requested or cut_started: return false
	cut_requested = false
	for worker in game.work_planner.claims.keys():
		if game.work_planner.claims[worker].source == self:
			game.work_planner.release(worker)
	game.hud.refresh()
	return true

func start_cut() -> void:
	if not cut_requested or cut_started or stage != 4: return
	cut_started = true
	set_stage(6)
	game.hud.refresh()

func harvest_stock(activity: String) -> int:
	return game.DATA.SOURCE_STOCK.wood if cut_requested and not cut_started and activity == "wood" else remaining

func setup_quarry(controller, cell: Vector2i, amount: int) -> void:
	game = controller
	origin = cell
	is_quarry = true
	resource_kind = "stone"
	remaining = amount
	initial_reserve = amount
	position = Vector2(cell * 16) + Vector2(24, 48)
	terrain_visual = Node2D.new()
	add_child(terrain_visual)
	for y in range(3):
		for x in range(3): cells.append(cell + Vector2i(x,y))

var stage := 0
var age := 0.0
var removed := false
var origin: Vector2i
var tree_sprite: Sprite2D

func setup(controller, layer: TileMapLayer, group: Array[Vector2i], kind: String) -> void:
	game = controller
	resource_kind = kind
	cells = group
	remaining = game.DATA.SOURCE_STOCK[kind]
	var bounds := Rect2i(group[0], Vector2i.ONE)
	for cell in group: bounds = bounds.merge(Rect2i(cell, Vector2i.ONE))
	origin = bounds.position
	position = Vector2(bounds.position * 16) + Vector2(bounds.size.x * 8, bounds.size.y * 16)
	var visual := TileMapLayer.new()
	visual.tile_set = layer.tile_set
	visual.position = -position
	visual.collision_enabled = false
	for cell in cells:
		visual.set_cell(cell, layer.get_cell_source_id(cell), layer.get_cell_atlas_coords(cell), layer.get_cell_alternative_tile(cell))
	terrain_visual = visual
	add_child(visual)

func setup_tree(controller, cell: Vector2i, initial_stage := 0) -> void:
	game = controller
	is_tree = true
	origin = cell
	for y in range(4):
		for x in range(3): cells.append(cell + Vector2i(x,y))
	position = Vector2(cell * 16) + Vector2(24,64)
	tree_sprite = Sprite2D.new()
	terrain_visual = tree_sprite
	add_child(tree_sprite)
	set_stage(initial_stage)

func set_stage(value: int) -> void:
	stage = 6 if value == 5 else value
	age = 0
	resource_kind = "produce" if stage == 4 else ("wood" if stage == 6 else "")
	remaining = game.DATA.SOURCE_STOCK.produce if stage == 4 else (game.DATA.SOURCE_STOCK.wood if stage == 6 else 0)
	tree_sprite.texture = game.DATA.CATALOG.entry("Tree-%d" % (stage + 1)).texture
	# Sort at the trunk's ground contact, keeping the artwork at its original location.
	position = Vector2(origin * 16) + Vector2(24,56)
	tree_sprite.position = Vector2(0, 8 - tree_sprite.texture.get_height() / 2.0)
	queue_redraw()

func _process(delta: float) -> void:
	if not is_tree or removed or stage >= 4 or game.simulation_paused: return
	age += delta * game.simulation_speed
	while stage < 4 and age >= game.DATA.TREE_SECONDS[stage]:
		var overflow: float = age - game.DATA.TREE_SECONDS[stage]
		set_stage(stage + 1)
		age = overflow if stage < 4 else 0.0
	queue_redraw()

func blocks_ground() -> bool:
	return not removed

func blocking_cells() -> Array[Vector2i]:
	if removed: return []
	# The canopy reserves space for planting/building, but is not an obstacle on the ground.
	if is_tree: return [origin + Vector2i(1,3)]
	return cells

func work_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in blocking_cells():
		for direction in game.CARDINALS:
			var spot: Vector2i = cell + direction
			if game.is_walkable(spot) and not result.has(spot): result.append(spot)
	return result

func harvestable(kind: String) -> bool:
	if is_tree and cut_requested and not cut_started: return not removed and kind == "wood"
	return not removed and resource_kind == game.DATA.resource_for_activity(kind) and remaining > 0

func take(amount: int, expected_kind := "") -> int:
	if cut_requested and not cut_started: return 0
	if removed or (expected_kind != "" and game.DATA.resource_for_activity(expected_kind) != resource_kind): return 0
	var harvested := mini(amount, remaining)
	remaining -= harvested
	if is_tree and stage == 4 and remaining == 0:
		set_stage(6)
		return harvested
	if remaining == 0 and (not is_tree or stage == 6):
		game.gold.mark(origin,"exhausted")
		removed = resource_kind!="gold_ore"
		if removed: terrain_visual.hide()
		game.rebuild_navigation()
		game.notify("Jazida esgotada. Selecione Liberar terreno para reutilizar a área." if resource_kind=="gold_ore" else "Fonte esgotada. O espaço está livre para novas construções ou plantio.")
	queue_redraw()
	return harvested

func description() -> String:
	if resource_kind=="gold_ore": return "Jazida de ouro · %d minérios restantes · até dois postos de extração"%remaining if remaining>0 else "Jazida esgotada — libere o terreno para construir."
	if removed: return "Recurso esgotado; espaço liberado."
	if not is_tree: return ("Pedreira aberta: " if is_quarry else "Jazida: ") + "%d pedras restantes." % remaining
	var text: String = game.DATA.TREE_NAMES[stage]
	if stage < 4: text += " · próximo estágio em %ds" % ceili(game.DATA.TREE_SECONDS[stage] - age)
	if stage == 4:
		text += " · %d Hortifruti restantes" % remaining
		if cut_requested: text += " · Corte solicitado; cancelável antes da primeira machadada."
		else: text += " · Cortar agora perde %d Hortifruti ao iniciar o corte." % remaining
	elif stage < 4: text += " · Hortifruti: ainda não produz"
	else: text += " · Hortifruti: 0"
	if cut_started: text += " · Corte iniciado; frutas perdidas. Plante outra árvore após liberar o local."
	if stage == 6: text += " · %d madeiras · somente lenhadores" % remaining
	return text

func _draw() -> void:
	if is_quarry and resource_kind=="gold_ore":
		if not removed: draw_texture_rect(game.DATA.gold_deposit_texture(remaining==0),Rect2(-24,-48,48,48),false)
	elif is_quarry:
		draw_colored_polygon(PackedVector2Array([Vector2(-18,-46),Vector2(12,-46),Vector2(12,-42),Vector2(21,-42),Vector2(21,-34),Vector2(24,-34),Vector2(24,-12),Vector2(18,-12),Vector2(18,-5),Vector2(-13,-5),Vector2(-13,-9),Vector2(-23,-9),Vector2(-23,-37),Vector2(-18,-37)]),Color("ad885d"))
		draw_colored_polygon(PackedVector2Array([Vector2(-15,-40),Vector2(13,-40),Vector2(13,-35),Vector2(19,-35),Vector2(19,-15),Vector2(12,-15),Vector2(12,-10),Vector2(-12,-10),Vector2(-12,-14),Vector2(-18,-14),Vector2(-18,-32),Vector2(-15,-32)]),Color("675343"))
		draw_rect(Rect2(-13,-33,28,19),Color("403d37"))
		for step in range(3):
			draw_rect(Rect2(-20+step*3,-20+step*4,9,3),Color("c09c6b"))
		if not removed:
			var rock: Texture2D = game.DATA.CATALOG.entry("Stone").texture
			draw_texture_rect(rock,Rect2(-10,-34,22,17),false)
			draw_texture_rect(rock,Rect2(2,-23,14,11),false)
	if removed: return
	if selected: draw_arc(Vector2(0,-4), 18, 0, TAU, 32, Color("f3dc9b"), 1)
	# Tree status belongs to the selection panel, never beneath the trunk artwork.
	if is_tree: return
	var fraction: float = float(remaining) / float(initial_reserve)
	var color := Color("a6cbe4")
	draw_rect(Rect2(-14,2,28,3), Color("233334"))
	draw_rect(Rect2(-14,2,28 * fraction,3), color)

func release_site() -> void:
	if not is_quarry or remaining>0: return
	removed=true
	game.gold.mark(origin,"exhausted")
	game.rebuild_navigation()
	game.select_entity(null)
	queue_redraw()

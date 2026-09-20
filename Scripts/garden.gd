extends "res://Scripts/resource_source.gd"
const MATERIALS = preload("res://Scripts/material_request.gd")
var materials = MATERIALS.new()
var kind := "garden"
var activity := "builder"
var phase := "installing"
var progress := 0.0
var reserved_by = null
var priority := 1
var auto_replant := false
var first_plant_pending := true
var completed := false
var preparing_site := false
var entity_id := -1

func setup_garden(controller, cell: Vector2i) -> void:
	game = controller
	for garden in game.gardens: entity_id = mini(entity_id,garden.entity_id-1)
	origin = cell
	resource_kind = "produce"
	# Relative to Simulation (z=1): above terrain by scene order, below residents.
	z_index = -1
	position = Vector2(cell * 16) + Vector2(16, 32)
	for y in range(2):
		for x in range(2): cells.append(cell + Vector2i(x, y))
	materials.required = game.DATA.GARDEN_COST.duplicate()

func door() -> Vector2i: return origin + Vector2i(0, 1)
func footprint() -> Array[Vector2i]: return cells.duplicate()
func refresh_visual() -> void: queue_redraw()
func blocks_ground() -> bool: return false
func blocking_cells() -> Array[Vector2i]: return []
func work_cells() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for cell in cells:
		if game.is_walkable(cell): result.append(cell)
	return result
func reserves_ground() -> bool: return true
func needs_work() -> bool: return phase in ["installing", "planting"]
func work_duration() -> float:
	return game.DATA.GARDEN_BUILD_SECONDS if phase == "installing" else game.DATA.GARDEN_PLANT_SECONDS

func request_plant() -> bool:
	if phase != "empty" or not game.can_afford(game.DATA.PLANT_COST): return false
	phase = "planting"
	activity = "food"
	progress = 0
	materials = MATERIALS.new()
	materials.required = game.DATA.PLANT_COST.duplicate()
	first_plant_pending = false
	return true

func build(delta: float) -> void:
	if preparing_site: return
	if delta <= 0 or not needs_work() or not materials.ready(): return
	progress += delta
	if progress >= work_duration():
		reserved_by = null
		materials = MATERIALS.new()
		if phase == "installing":
			completed = true
			phase = "empty"
			request_plant()
		else:
			phase = "growing"
			age = 0
	queue_redraw()

func _process(delta: float) -> void:
	if game.simulation_paused: return
	if phase == "growing":
		age = minf(game.DATA.GARDEN_GROW_SECONDS, age + delta * game.simulation_speed)
		if age >= game.DATA.GARDEN_GROW_SECONDS:
			phase = "ripe"
			remaining = game.DATA.GARDEN_YIELD
	elif phase == "empty" and (first_plant_pending or auto_replant):
		var reserve: int = game.workers.size() * game.DATA.FOOD_RESERVE_PER_PERSON
		if first_plant_pending or game.available_stock().produce >= reserve + game.DATA.PLANT_COST.produce:
			request_plant()
	queue_redraw()

func harvestable(work: String) -> bool:
	return phase == "ripe" and work in ["food", "produce"] and remaining > 0

func take(amount: int, expected_kind := "") -> int:
	if not harvestable(expected_kind if expected_kind != "" else "food"): return 0
	var harvested := mini(amount, remaining)
	remaining -= harvested
	if remaining == 0:
		phase = "empty"
		age = 0
	queue_redraw()
	return harvested

func description() -> String:
	match phase:
		"installing": return "Cercado: " + materials.text(game.DATA) + " · Construtor · 10s"
		"planting": return "Plantio: " + materials.text(game.DATA) + " · Comida · 4s"
		"growing": return "Horta crescendo · %ds para colher" % ceili(game.DATA.GARDEN_GROW_SECONDS - age)
		"ripe": return "Horta pronta · %d Hortifruti para colher" % remaining
	return "Canteiro vazio · Plantar: 2 Hortifruti" + (" · Aguardando reserva alimentar" if auto_replant else "")

func _draw() -> void:
	var soil: Texture2D = game.DATA.atlas("res://Assets/Tileset/Tilled Soil and wet soil.png", Rect2(32, 16, 16, 16))
	for y in range(2):
		for x in range(2):
			var point := Vector2(x * 16 - 16, y * 16 - 32)
			draw_texture(soil, point)
			if phase in ["growing", "ripe"]:
				var frame := 6 if phase == "ripe" else (1 + mini(4, int(age / 12.0)))
				var crop := "res://Assets/Crops/Spring/Carrot.png" if x == y else "res://Assets/Crops/Spring/Cabbage.png"
				draw_texture(game.DATA.atlas(crop, Rect2(frame * 16, 0, 16, 16)), point)
	# Decorative fences leave internal crossing and the front work entrance open.
	if phase != "installing":
		var fence: Texture2D = game.DATA.atlas("res://Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png", Rect2(48, 0, 16, 16))
		draw_texture(fence, Vector2(-16, -36))
		draw_texture(fence, Vector2(0, -36))
		var post: Texture2D = game.DATA.atlas("res://Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png", Rect2(0,16,16,16))
		for y in [-28,-12]:
			draw_texture(post,Vector2(-20,y))
			draw_texture(post,Vector2(4,y))
		draw_texture(fence,Vector2(0,-8))
	else:
		draw_rect(Rect2(-16,-32,32,32), Color(0.9,0.7,0.3,0.3))
	if selected: draw_rect(Rect2(-16,-32,32,32), Color("f3dc9b"), false)

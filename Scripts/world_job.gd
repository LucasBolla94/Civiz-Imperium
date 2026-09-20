extends Node2D
const MATERIALS = preload("res://Scripts/material_request.gd")
var materials = MATERIALS.new()
var game
var kind: String
var activity: String
var origin: Vector2i
var cells: Array[Vector2i] = []
var entry_cell: Vector2i
var reserved_by = null
var completed := false
var progress := 0.0
var selected := false
var duration := 4.0
var priority := 1
var deposit := 0
var deposit_resource := "stone"
var released := false
var brush_size := 3
var discovery_eligible := true # Legacy 3x3 expansion orders retain their behavior.

func setup_expansion(controller, cell: Vector2i, size: int, plan: Dictionary) -> void:
	setup(controller,"expand",cell,plan.entry)
	brush_size = size
	cells.assign(plan.cells)
	materials.required = plan.cost.duplicate()
	duration = plan.seconds
	discovery_eligible = plan.discovery
func reserves_ground() -> bool: return not completed or (kind == "survey" and not released)
func open_quarry() -> bool:
	if kind != "survey" or not completed or released: return false
	kind = "quarry"
	completed = false
	progress = 0
	duration = 24
	materials.required = {"wood": 10, "stone": 5}
	if deposit_resource=="gold_ore":
		activity="builder"
		duration=game.DATA.ECONOMY.GOLD_OPEN_SECONDS
		materials.required=game.DATA.ECONOMY.GOLD_OPEN_COST.duplicate()
	game.notify("Jazida de ouro marcada: entregue materiais e aloque um construtor." if deposit_resource=="gold_ore" else "Pedreira marcada: entregue materiais e aloque um mineiro.")
	queue_redraw()
	return true
func release_site() -> void:
	if kind != "survey" or not completed: return
	released = true
	game.gold.mark(origin,"released")
	game.rebuild_navigation()
	game.select_entity(null)
	queue_redraw()

func cancel_survey() -> bool:
	if kind!="survey" or completed: return false
	for worker in game.workers:
		if worker.target==self: worker.interrupt_task()
	game.jobs.erase(self)
	game.select_entity(null)
	game.rebuild_navigation()
	queue_free()
	return true
func setup(controller, type: String, cell: Vector2i, entry: Vector2i) -> void:
	game = controller
	kind = type
	materials.required = (game.DATA.PLANT_COST if kind == "plant" else game.DATA.EXPAND_COST).duplicate()
	activity = "food" if kind == "plant" else ("stone" if kind in ["survey", "quarry"] else "builder")
	if kind == "survey": materials.required = {}
	origin = cell
	entry_cell = entry
	duration = 4 if kind == "plant" else (12 if kind == "survey" else 10)
	deposit = [300, 600, 1000][posmod(cell.x * 73 + cell.y * 137, 3)]
	for y in range(4 if kind == "plant" else 3):
		for x in range(3): cells.append(cell + Vector2i(x,y))
	position = Vector2(origin * 16)
func door() -> Vector2i: return entry_cell
func needs_work() -> bool: return not completed
func build(delta: float) -> void:
	if completed or not materials.ready(): return
	progress += delta
	if progress >= duration:
		completed = true
		reserved_by = null
		game.complete_job(self)
	queue_redraw()
func _draw() -> void:
	if completed and (kind != "survey" or released): return
	if kind == "expand":
		for cell in cells:
			var rect := Rect2(Vector2((cell-origin)*16),Vector2(16,16))
			draw_rect(rect,Color(0.91,0.75,0.47,0.25))
			draw_rect(rect,Color("e8be78"),false,0.5)
			if selected: draw_rect(rect,Color("f3dc9b"),false,1)
		# Progress stays on a water cell even when the brush origin lies on land.
		if not cells.is_empty(): draw_rect(Rect2(Vector2((cells[0]-origin)*16)+Vector2(1,12),Vector2(14*progress/duration,2)),Color("e8be78"))
		return
	var size := Vector2(48,64 if kind == "plant" else 48)
	var color := Color("a6d887") if kind == "plant" else Color("e8be78")
	draw_rect(Rect2(Vector2.ZERO,size), Color(color,0.25))
	draw_rect(Rect2(Vector2.ZERO,size), color, false,1)
	# A surveyed deposit is visible before excavation, using the existing native art.
	if (kind == "survey" and completed) or kind == "quarry":
		var stone: Texture2D = game.DATA.gold_deposit_texture(false) if deposit_resource=="gold_ore" else game.DATA.CATALOG.entry("Stone").texture
		draw_texture(stone, (size - stone.get_size()) / 2.0)
	if not completed: draw_rect(Rect2(4,size.y - 5,40 * progress / duration,3),color)

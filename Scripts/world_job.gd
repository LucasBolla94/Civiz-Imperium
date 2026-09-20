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
var released := false
func reserves_ground() -> bool: return not completed or (kind == "survey" and not released)
func open_quarry() -> bool:
	if kind != "survey" or not completed or released: return false
	kind = "quarry"
	completed = false
	progress = 0
	duration = 24
	materials.required = {"wood": 10, "stone": 5}
	game.notify("Pedreira marcada: entregue materiais e aloque um mineiro.")
	queue_redraw()
	return true
func release_site() -> void:
	if kind != "survey" or not completed: return
	released = true
	game.rebuild_navigation()
	game.select_entity(null)
	queue_redraw()
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
	var size := Vector2(48,64 if kind == "plant" else 48)
	var color := Color("a6d887") if kind == "plant" else Color("e8be78")
	draw_rect(Rect2(Vector2.ZERO,size), Color(color,0.25))
	draw_rect(Rect2(Vector2.ZERO,size), color, false,1)
	draw_rect(Rect2(4,size.y - 5,40 * progress / duration,3),color)


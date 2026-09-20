extends Node2D
var stored: Dictionary = {}
var cell: Vector2i
var selected := false
var resource_kind := ""

func door() -> Vector2i: return cell
func _draw() -> void:
	var color := Color("bd8a55")
	if resource_kind == "stone": color = Color("a6cbe4")
	if resource_kind == "fruit": color = Color("d56b4d")
	draw_rect(Rect2(-5, -5, 10, 6), Color("543126"))
	draw_rect(Rect2(-4, -6, 8, 4), color)
	if selected: draw_rect(Rect2(-6,-7,12,9),Color("f3dc9b"),false)

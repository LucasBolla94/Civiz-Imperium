extends Node2D
var stored: Dictionary = {}
var cell: Vector2i
var selected := false
var resource_kind := ""
var trade_id := 0
var trade_leg := ""

func door() -> Vector2i: return cell
func _draw() -> void:
	var texture: Texture2D = preload("res://Scripts/game_data.gd").resource_texture(resource_kind, true)
	draw_texture(texture, Vector2(-8, -12))
	if selected: draw_rect(Rect2(-8,-12,16,16),Color("f3dc9b"),false)

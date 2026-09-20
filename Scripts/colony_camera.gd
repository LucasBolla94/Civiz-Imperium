extends Camera2D
## Camera motion uses real time, independently of pause and simulation speed.
const PAN_SPEED = 560.0 # Screen pixels per second at any zoom.
const INITIAL_ZOOM_FACTOR = 1.10
const MIN_ZOOM = 0.8
const MAX_ZOOM = 5.0
var game

func reset_view() -> void:
	var bounds: Rect2i = game.land.get_used_rect()
	var viewport := get_viewport_rect().size
	var area := Rect2(Vector2(300,150), viewport - Vector2(340,420))
	if is_instance_valid(game.hud): area = game.hud.map_visible_rect()
	var fit := minf(area.size.x / (bounds.size.x * 16.0), area.size.y / (bounds.size.y * 16.0))
	zoom = Vector2.ONE * clampf(fit * INITIAL_ZOOM_FACTOR, MIN_ZOOM, MAX_ZOOM)
	var centre := Vector2(bounds.position * 16) + Vector2(bounds.size * 16) / 2
	position = centre - (area.get_center() - viewport / 2) / zoom
	force_update_scroll()

func input_blocked() -> bool:
	if not is_instance_valid(game.hud): return true
	if game.hud.residents_window.visible or game.hud.extinction_panel.visible: return true
	if get_viewport().gui_get_focus_owner() is LineEdit or get_viewport().gui_get_focus_owner() is TextEdit: return true
	for child in game.hud.get_children():
		if child is Window and child.visible: return true
	return false

func pan(direction: Vector2, delta: float) -> void:
	position += direction.limit_length() * PAN_SPEED * delta / zoom

func _process(delta: float) -> void:
	if input_blocked() or not get_window().has_focus(): return
	var direction := Vector2(
		float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A)),
		float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W)))
	pan(direction, delta)

func change_zoom(multiplier: float) -> void:
	zoom = Vector2.ONE * clampf(zoom.x * multiplier, MIN_ZOOM, MAX_ZOOM)


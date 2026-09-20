extends Node
## Physical window sizing is separate from the responsive 1280x720 UI canvas.
const PREFERRED_SIZE = Vector2i(1920, 1080)
var previous_work_area := Rect2i()
var check_timer := 0.0
var editor_owned := false

static func fitted_rect(usable: Rect2i, requested: Vector2i) -> Rect2i:
	# Leave room for OS borders; monitor origins may be negative.
	var available := Vector2i(maxi(1, usable.size.x - 48), maxi(1, usable.size.y - 80))
	var factor := minf(1.0, minf(float(available.x) / maxi(1, requested.x), float(available.y) / maxi(1, requested.y)))
	var fitted := Vector2i(maxi(1, floori(requested.x * factor)), maxi(1, floori(requested.y * factor)))
	return Rect2i(usable.position + (usable.size - fitted) / 2, fitted)

func _ready() -> void:
	editor_owned = OS.get_cmdline_args().has("--wid") or get_window().is_embedded()
	if DisplayServer.get_name() == "headless" or editor_owned:
		set_process(false)
		return
	fit_monitor(true)

func fit_monitor(initial := false) -> void:
	var window := get_window()
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	if usable.size.x <= 0 or usable.size.y <= 0: return
	previous_work_area = usable
	var safe := fitted_rect(usable, PREFERRED_SIZE if initial else window.size)
	window.min_size = Vector2i(mini(640, safe.size.x), mini(360, safe.size.y))
	if window.mode != Window.MODE_WINDOWED: return
	if initial or not usable.encloses(Rect2i(window.position, window.size)):
		window.size = safe.size
		window.position = safe.position

func _process(delta: float) -> void:
	check_timer -= delta
	if check_timer > 0: return
	check_timer = 1.0
	# Refit only when the monitor or its usable area changes, not on ordinary resize.
	var usable := DisplayServer.screen_get_usable_rect(get_window().current_screen)
	if usable != previous_work_area: fit_monitor()

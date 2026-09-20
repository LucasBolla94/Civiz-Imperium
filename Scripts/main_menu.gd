extends Node2D
const MENU_THEME = preload("res://Scripts/menu_theme.gd")
var start_button: Button
var backdrop
func _ready() -> void:
	backdrop = preload("res://Scenes/main.tscn").instantiate()
	add_child(backdrop)
	backdrop.simulation_paused = true
	backdrop.process_mode = Node.PROCESS_MODE_DISABLED
	backdrop.hud.hide()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var shade := ColorRect.new()
	shade.color = Color(0.03,0.12,0.14,0.55)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	var panel := PanelContainer.new()
	panel.theme = MENU_THEME.create()
	panel.add_theme_stylebox_override("panel", MENU_THEME.panel(32))
	panel.custom_minimum_size = Vector2(490,440)
	center.add_child(panel)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 16)
	panel.add_child(rows)
	for text in ["C I V I Z", "I M P E R I U M"]:
		var title := Label.new()
		title.text = text
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.add_theme_font_size_override("font_size", 36 if text == "C I V I Z" else 28)
		title.add_theme_color_override("font_color", MENU_THEME.ACCENT)
		rows.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Uma ilha. Três pessoas. O começo de um reino.\n\nAlimente, construa e cuide de quem faz a vila viver."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 14)
	rows.add_child(subtitle)
	start_button = Button.new()
	start_button.text = "Fundar uma civilização"
	start_button.custom_minimum_size.y = 48
	start_button.pressed.connect(func(): get_tree().change_scene_to_file("res://Scenes/main.tscn"))
	rows.add_child(start_button)
	var continue_button := Button.new()
	continue_button.text = "Continuar civilização"
	continue_button.disabled = not FileAccess.file_exists(preload("res://Scripts/save_game.gd").PATH)
	continue_button.pressed.connect(func():
		get_tree().set_meta("continue_game", true)
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	)
	rows.add_child(continue_button)
	var exit_button := Button.new()
	exit_button.text = "Sair"
	exit_button.pressed.connect(func(): get_tree().quit())
	rows.add_child(exit_button)
	rows.add_child(get_node("/root/Localization").selector())
	var version := Label.new()
	version.text = "V0.0.5  ·  HORTAS E UMA VILA EM CRESCIMENTO\nSalve pela Vila · Salvamento automático a cada 2 minutos."
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.add_theme_font_size_override("font_size", 12)
	rows.add_child(version)
	get_node("/root/Localization").language_changed.connect(func(): get_node("/root/Localization").render(canvas))
	get_node("/root/Localization").render(canvas)


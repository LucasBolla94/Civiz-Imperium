extends Control
const GARDEN = preload("res://Scripts/garden.gd")
const MENU_THEME = preload("res://Scripts/menu_theme.gd")
const INK = MENU_THEME.INK
const MUTED = MENU_THEME.MUTED
const GOLD = MENU_THEME.ACCENT
var game
var stock_label: Label
var inspection_icon: TextureRect
var resource_labels := {}
var garden_button: Button
var cut_button: Button
var warning_button: Button
var replant_button: Button
var manual_plant_button: Button
var demolish_button: Button
var cancel_work_button: Button
var cancel_demolish_button: Button
var objective_label: Label
var notification_label: Label
var title_label: Label
var detail_label: Label
var progress: ProgressBar
var recruit_button: Button
var pause_button: Button
var speed_button: Button
var build_buttons: Dictionary = {}
var refresh_timer := 0.0
var top_panel: PanelContainer
var bottom_panel: PanelContainer
var workforce_panel: Panel
var workforce_summary: Label
var activity_controls: Dictionary = {}
var construction_menu: HFlowContainer
var building_actions: HFlowContainer
var plant_button: Button
var timber_button: Button
var expand_button: Button
var evolve_button: Button
var aid_button: Button
var upgrade_button: Button
var residents_button: Button
var save_button: Button
var load_button: Button
var survey_button: Button
var quarry_button: Button
var release_button: Button
var orchard_button: Button
var priority_button: Button
var order_buttons: Array[Button] = []
var policy_window: AcceptDialog
var policy_button: Button
var policy_box: HFlowContainer
var population_control: SpinBox
var policy_controls := {}
var tools_box: HBoxContainer
var tools_controls: Dictionary = {}
var residents_window: PanelContainer
var residents_shade: ColorRect
var residents_rows: VBoxContainer
var resident_controls: Dictionary = {}
var residence_filter = null
var extinction_panel: PanelContainer
var extinct_shown := false
var workforce_content: VBoxContainer
var bottom_scroll: ScrollContainer
var restart_dialog: ConfirmationDialog
var workforce_toggle: Button
var detail_header: HBoxContainer
var last_context := false
var game_menu: AcceptDialog
var menu_save_button: Button
var menu_quit_button: Button
var menu_save_status: Label
var paused_before_menu := false
var brand_label: Label
var workforce_view
var team_button: Button
var rotate_port_button: Button
var trade_button: Button
var trade_window

func scroll_content(parent: Node) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.follow_focus=true
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(scroll)
	return scroll

func layout_windows() -> void:
	if not is_instance_valid(residents_window): return
	var viewport := get_viewport_rect().size
	update_context_layout()
	workforce_panel.size = Vector2(minf(600,viewport.x-32), minf(530, viewport.y - 160))
	workforce_panel.position=(viewport-workforce_panel.size)/2
	brand_label.visible=viewport.x>=1000
	residents_window.size = Vector2(minf(760, viewport.x - 48), minf(440, viewport.y - 48))
	residents_window.position = (viewport - residents_window.size) / 2
	extinction_panel.reset_size()
	extinction_panel.position = (viewport - extinction_panel.size) / 2
	if restart_dialog.visible: restart_dialog.popup_centered()
	if is_instance_valid(game_menu) and game_menu.visible: game_menu.popup_centered(Vector2i(minf(360,viewport.x-48),220))
	if is_instance_valid(policy_window) and policy_window.visible: policy_window.popup_centered(Vector2i(minf(520,viewport.x-48),minf(330,viewport.y-48)))
	if is_instance_valid(trade_window) and trade_window.visible: trade_window.popup_centered(Vector2i(minf(740,viewport.x-40),minf(600,viewport.y-48)))
	objective_label.position=Vector2(18,top_panel.get_combined_minimum_size().y+12)
	objective_label.size = Vector2(364, 20)
	notification_label.position = Vector2(400, top_panel.get_combined_minimum_size().y+12)
	notification_label.size = Vector2(maxf(100, viewport.x - 418), 20)

func map_visible_rect() -> Rect2:
	var viewport := get_viewport_rect().size
	var top := top_panel.get_combined_minimum_size().y+32 if is_instance_valid(top_panel) else 116.0
	return Rect2(Vector2(10,top), Vector2(viewport.x-20,maxf(100,viewport.y-top-84)))

func toggle_workforce() -> void:
	workforce_panel.visible = not workforce_panel.visible
	workforce_toggle.set_pressed_no_signal(workforce_panel.visible)
	layout_windows()

func update_context_layout() -> void:
	var context: bool = is_instance_valid(game.selection) or not game.action_mode.is_empty() or not game.placement_kind.is_empty()
	bottom_panel.visible=not workforce_panel.visible
	detail_header.visible = context
	detail_label.visible = context
	bottom_panel.offset_top = -198 if context else -84
	if is_instance_valid(game.selection) and game.selection.has_method("description") and game.action_mode.is_empty() and game.placement_kind.is_empty():
		bottom_panel.offset_top = -198 if game.selection is GARDEN else (-174 if game.selection.is_tree else -120)
	bottom_panel.offset_bottom = -10
	var width := minf(1080, get_viewport_rect().size.x - 20)
	var margin := (get_viewport_rect().size.x - width) / 2
	bottom_panel.offset_left = margin
	bottom_panel.offset_right = -margin
	if context != last_context:
		bottom_scroll.scroll_vertical = 0
		last_context = context
	if not game.action_mode.is_empty() or not game.placement_kind.is_empty():
		workforce_panel.hide()
		workforce_toggle.set_pressed_no_signal(false)


func label(text: String, size := 16, color := INK) -> Label:
	var result := Label.new()
	result.text = text
	result.add_theme_font_size_override("font_size", size)
	result.add_theme_color_override("font_color", color)
	result.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return result

func button(text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 30
	result.add_theme_font_size_override("font_size", 15)
	result.focus_mode = Control.FOCUS_ALL
	result.pressed.connect(callback)
	return result

func panel() -> PanelContainer:
	var result := PanelContainer.new()
	result.add_theme_stylebox_override("panel", MENU_THEME.panel(8))
	return result

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	theme = MENU_THEME.create()
	top_panel = panel()
	top_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 10
	top_panel.offset_right = -10
	top_panel.offset_top = 8
	add_child(top_panel)
	var top_rows := VBoxContainer.new()
	top_rows.add_theme_constant_override("separation",5)
	top_panel.add_child(top_rows)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation",12)
	top_rows.add_child(heading)
	var emblem := TextureRect.new()
	emblem.texture=preload("res://Assets/UI/Brand/civiz_emblem.png")
	emblem.custom_minimum_size=Vector2(32,32)
	emblem.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	emblem.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	heading.add_child(emblem)
	brand_label=label("CIVIZ IMPERIUM",14,GOLD)
	brand_label.add_theme_font_override("font",MENU_THEME.TITLE)
	heading.add_child(brand_label)
	var resources := HBoxContainer.new()
	resources.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resources.alignment=BoxContainer.ALIGNMENT_END
	resources.add_theme_constant_override("separation",8)
	heading.add_child(resources)
	stock_label=label("Disponível",12)
	stock_label.hide()
	resources.add_child(stock_label)
	for resource in ["produce","wood","stone","gold_bar","gold_ore","axe","pickaxe"]:
		var item := HBoxContainer.new()
		resources.add_child(item)
		var icon := TextureRect.new()
		icon.texture=game.DATA.resource_texture(resource)
		icon.custom_minimum_size=Vector2(24,24)
		icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		item.add_child(icon)
		var amount := label("0",15)
		amount.custom_minimum_size.x=30
		amount.mouse_filter=Control.MOUSE_FILTER_STOP
		item.add_child(amount)
		resource_labels[resource]={"amount":amount,"icon":icon}
	var top := HBoxContainer.new()
	top_rows.add_child(top)
	workforce_toggle=button("Habitantes",toggle_workforce)
	workforce_toggle.toggle_mode=true
	top.add_child(workforce_toggle)
	top.add_child(button("Vila",func(): game.select_entity(game.base)))
	top.add_child(button("Aterrar",func(): game.begin_action("expand")))
	var spacer := Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	pause_button=button("Pausar",func():
		if not game.settlement.extinct: game.simulation_paused=not game.simulation_paused
	)
	top.add_child(pause_button)
	speed_button=button("1x",func(): game.simulation_speed=2.0 if game.simulation_speed==1.0 else 1.0)
	top.add_child(speed_button)
	top.add_child(button("Centrar",game.center_camera))
	top.add_child(button("Menu",open_game_menu))
	restart_dialog=ConfirmationDialog.new()
	restart_dialog.title="Recomeçar Civiz Imperium"
	restart_dialog.dialog_text="Reiniciar a civilização? O progresso não salvo será perdido."
	restart_dialog.ok_button_text="Reiniciar"
	restart_dialog.cancel_button_text="Continuar jogando"
	restart_dialog.confirmed.connect(func(): get_tree().reload_current_scene())
	add_child(restart_dialog)
	objective_label = label("", 12, Color("fff0d9"))
	objective_label.position = Vector2(18, 62)
	objective_label.clip_text = true
	objective_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	objective_label.add_theme_color_override("font_shadow_color", Color("253433"))
	objective_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(objective_label)
	objective_label.tooltip_text = "WASD: mover · Q/E ou roda: zoom · Shift: repetir · Home: centrar · Espaço: pausar · Esc: fechar / cancelar"
	# A fixed outer Control prevents dynamic list minimum sizes from growing the
	# whole window. Only the inner ScrollContainer may expand its content.
	workforce_panel = Panel.new()
	workforce_panel.add_theme_stylebox_override("panel", MENU_THEME.panel(8))
	workforce_panel.clip_contents = true
	workforce_panel.position = Vector2(10, 86)
	workforce_panel.z_index = 100
	workforce_panel.hide()
	add_child(workforce_panel)
	var workforce := VBoxContainer.new()
	workforce_content = workforce
	workforce.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workforce.add_theme_constant_override("separation", 3)
	workforce_panel.add_child(workforce)
	workforce.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	workforce.offset_left = 8
	workforce.offset_top = 8
	workforce.offset_right = -8
	workforce.offset_bottom = -8
	var workforce_heading := HBoxContainer.new()
	workforce.add_child(workforce_heading)
	var workforce_title := label("Equipes da ilha", 20, GOLD)
	workforce_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	workforce_heading.add_child(workforce_title)
	workforce_heading.add_child(button("×", toggle_workforce))
	workforce_summary = label("", 15, MUTED)
	workforce_summary.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	workforce.add_child(workforce_summary)
	workforce_view=preload("res://Scripts/workforce_view.gd").new()
	workforce_view.game=game
	scroll_content(workforce).add_child(workforce_view)
	activity_controls=workforce_view.controls
	workforce.add_child(button("Conhecer habitantes", func(): open_residents(null)))
	workforce.add_child(button("Vila: expandir / evoluir", func(): game.select_entity(game.base)))
	bottom_panel = panel()
	bottom_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 10
	bottom_panel.offset_right = -10
	bottom_panel.offset_top = -100
	bottom_panel.offset_bottom = -10
	add_child(bottom_panel)
	var bottom := VBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", 6)
	bottom_scroll = scroll_content(bottom_panel)
	bottom_scroll.add_child(bottom)
	detail_header = HBoxContainer.new()
	bottom.add_child(detail_header)
	title_label = label("", 16, GOLD)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_header.add_child(title_label)
	inspection_icon = TextureRect.new()
	inspection_icon.custom_minimum_size = Vector2(32,32)
	inspection_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	inspection_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	detail_header.add_child(inspection_icon)
	rotate_port_button=button("Girar porto · R",game.rotate_port)
	rotate_port_button.hide()
	detail_header.add_child(rotate_port_button)
	detail_header.add_child(button("Fechar", func():
		game.cancel_placement()
		game.select_entity(null)
	))
	detail_label = label("", 13, MUTED)
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.custom_minimum_size.y = 32
	bottom.add_child(detail_label)
	progress = ProgressBar.new()
	progress.custom_minimum_size.y = 5
	progress.show_percentage = false
	bottom.add_child(progress)
	construction_menu = HFlowContainer.new()
	construction_menu.add_theme_constant_override("h_separation", 6)
	construction_menu.add_theme_constant_override("v_separation", 8)
	bottom.add_child(construction_menu)
	construction_menu.add_child(label("CONSTRUIR", 12, MUTED))
	for kind in game.DATA.CONSTRUCTIBLE:
		var b := button("", game.begin_placement.bind(kind))
		b.custom_minimum_size = Vector2(82,56)
		b.toggle_mode = true
		b.add_theme_stylebox_override("normal",MENU_THEME.flat(Color("ede2c9"),Color("baa581"),4))
		b.add_theme_stylebox_override("hover",MENU_THEME.flat(Color("ffedba"),GOLD,4))
		b.add_theme_stylebox_override("pressed",MENU_THEME.flat(Color("efd28c"),GOLD,4))
		var contents := VBoxContainer.new()
		contents.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		contents.offset_top = 4
		contents.offset_bottom = -4
		contents.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(contents)
		var picture := TextureRect.new()
		picture.texture = game.DATA.building_texture(kind)
		picture.custom_minimum_size = Vector2(32,30)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
		contents.add_child(picture)
		var name_label := label(game.DATA.BUILDINGS[kind].short, 12)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		contents.add_child(name_label)
		construction_menu.add_child(b)
		build_buttons[kind] = b
	building_actions = HFlowContainer.new()
	building_actions.custom_minimum_size.y = 48
	building_actions.add_theme_constant_override("h_separation", 10)
	building_actions.add_theme_constant_override("v_separation", 8)
	bottom.add_child(building_actions)
	team_button=button("Gerenciar equipe",func():
		if not workforce_panel.visible: toggle_workforce()
		if is_instance_valid(game.selection): workforce_view.reveal(game.selection.kind)
	)
	building_actions.add_child(team_button)
	trade_button=button("Negociar no porto",func(): trade_window.open())
	building_actions.add_child(trade_button)
	recruit_button = button("Atrair colonos\n5 Hortifruti + 3 madeiras", func(): game.immigration.prepare_expedition())
	building_actions.add_child(recruit_button)
	plant_button = button("Plantar árvore\n2 Hortifruti", func(): game.begin_action("plant"))
	building_actions.add_child(plant_button)
	timber_button = button("Plantar árvore de madeira\n2 Hortifruti", func(): game.begin_action("plant_wood"))
	building_actions.add_child(timber_button)
	garden_button = button("Criar horta · 10 madeiras", func(): game.begin_action("garden"))
	building_actions.add_child(garden_button)
	cut_button = button("Cortar agora",func():
		if game.selection.cut_requested: game.selection.cancel_cut()
		else: game.selection.request_cut())
	building_actions.add_child(cut_button)
	warning_button = button("Ver impedimento",open_warning_action)
	building_actions.add_child(warning_button)
	manual_plant_button = button("Plantar · 2 Hortifruti", func(): game.selection.request_plant())
	building_actions.add_child(manual_plant_button)
	replant_button = button("Replantio automático", func(): game.selection.auto_replant = not game.selection.auto_replant)
	building_actions.add_child(replant_button)
	demolish_button = button("Demolir · 10s", func(): game.selection.request_demolition())
	building_actions.add_child(demolish_button)
	cancel_work_button = button("Cancelar obra", func():
		if game.selection.has_method("cancel_survey"): game.selection.cancel_survey()
		else: game.cancel_construction(game.selection)
	)
	building_actions.add_child(cancel_work_button)
	cancel_demolish_button = button("Cancelar demolição", func(): game.selection.cancel_demolition())
	building_actions.add_child(cancel_demolish_button)
	expand_button = button("Ampliar costa\nPincel ajustável", func(): game.begin_action("expand"))
	building_actions.add_child(expand_button)
	evolve_button = button("Evoluir vila", func(): game.upgrade_village())
	building_actions.add_child(evolve_button)
	aid_button = button("Coleta costeira\n+4 Hortifruti / 60s", func(): game.coastal_aid())
	building_actions.add_child(aid_button)
	upgrade_button = button("Melhorar", func(): game.selection.upgrade())
	building_actions.add_child(upgrade_button)
	residents_button = button("Moradores / descanso", func(): open_residents(game.selection))
	building_actions.add_child(residents_button)
	survey_button = button("Investigar terreno", func(): game.begin_action("survey"))
	building_actions.add_child(survey_button)
	quarry_button = button("Abrir pedreira · 10 madeiras + 5 pedras", func(): game.selection.open_quarry())
	building_actions.add_child(quarry_button)
	release_button = button("Liberar terreno", func(): game.selection.release_site())
	building_actions.add_child(release_button)
	orchard_button = button("Renovar pomar", func(): game.automation.toggle_orchard(game.selection.origin))
	building_actions.add_child(orchard_button)
	priority_button = button("Prioridade", func(): game.selection.priority = (game.selection.priority + 1) % 3)
	building_actions.add_child(priority_button)
	for tool in ["axe", "pickaxe"]:
		for amount in [1, -1]:
			var order = button(("+1 " if amount > 0 else "−1 ") + game.DATA.RESOURCES[tool].name, func(): game.selection.order_tool(tool, amount))
			order.icon = game.DATA.resource_texture(tool)
			order.expand_icon = true
			order.add_theme_constant_override("icon_max_width", 32)
			order.tooltip_text = "Encomenda: " + game.DATA.cost_text(game.DATA.RECIPES[tool]) + ". O artesão recebe materiais; trabalhadores retiram ferramentas prontas."
			building_actions.add_child(order)
			order_buttons.append(order)
	save_button = button("Salvar partida", func(): game.saves.save_file())
	building_actions.add_child(save_button)
	load_button = button("Carregar partida", func(): game.saves.load_file())
	building_actions.add_child(load_button)
	policy_window = AcceptDialog.new()
	policy_window.title = "Planos e progresso da vila"
	policy_window.theme = MENU_THEME.create()
	policy_window.exclusive = true
	add_child(policy_window)
	var policy_scroll = scroll_content(policy_window)
	policy_box = HFlowContainer.new()
	policy_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	policy_box.add_theme_constant_override("v_separation", 16)
	policy_box.add_theme_constant_override("h_separation", 12)
	policy_scroll.add_child(policy_box)
	save_button.reparent(policy_box)
	load_button.reparent(policy_box)
	policy_button = button("Planos / salvar", func(): policy_window.popup_centered(Vector2i(minf(520,get_viewport_rect().size.x - 48), minf(330,get_viewport_rect().size.y - 48))))
	building_actions.add_child(policy_button)
	policy_box.add_child(label("Mais casas com vagas permitem mais habitantes.", 13))
	for resource in ["produce", "wood", "stone"]:
		var row := HBoxContainer.new()
		policy_box.add_child(row)
		row.add_child(label("Meta " + game.DATA.RESOURCES[resource].name, 13))
		var control := SpinBox.new()
		control.max_value = 2000
		control.step = 5
		control.tooltip_text = "0 = sem limite. Obras e reserva alimentar são somadas automaticamente."
		control.value_changed.connect(func(value): game.automation.stock_targets[resource] = int(value))
		row.add_child(control)
		policy_controls[resource] = control
	var policy_help = label("Metas de estoque: 0 significa sem limite.\nA vila soma a reserva alimentar e os materiais das obras.\nCasas com vagas permitem novas chegadas; mantenha comida disponível.", 13)
	policy_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	policy_help.custom_minimum_size.x = 440
	policy_box.add_child(policy_help)
	tools_box = HBoxContainer.new()
	building_actions.add_child(tools_box)
	tools_box.add_child(label("Manter em estoque:", 13))
	for tool in ["axe", "pickaxe"]:
		tools_box.add_child(label(game.DATA.RESOURCES[tool].name,13))
		var spin := SpinBox.new()
		spin.min_value = 0
		spin.max_value = 20
		spin.step = 1
		spin.custom_minimum_size.x = 78
		spin.value_changed.connect(func(value):
			if is_instance_valid(game.selection) and game.selection.has_method("craft"):
				game.selection.tool_targets[tool] = int(value)
		)
		tools_box.add_child(spin)
		tools_controls[tool] = spin
	building_actions.add_child(button("Construções", func(): game.select_entity(null)))
	notification_label = label("", 12, Color("fff0d9"))
	notification_label.clip_text = true
	notification_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	notification_label.add_theme_color_override("font_shadow_color", Color("253433"))
	notification_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(notification_label)
	create_residents_window()
	create_extinction_panel()
	create_game_menu()
	trade_window=preload("res://Scripts/trade_view.gd").new()
	trade_window.game=game
	add_child(trade_window)
	refresh()
	for child in building_actions.get_children():
		if child is Button: child.add_theme_font_size_override("font_size", 13)
	get_viewport().size_changed.connect(func(): layout_windows.call_deferred())
	get_node("/root/Localization").language_changed.connect(refresh)
	layout_windows.call_deferred()

func create_game_menu() -> void:
	game_menu = AcceptDialog.new()
	game_menu.title = "Jogo pausado"
	game_menu.theme = MENU_THEME.create()
	game_menu.exclusive = true
	game_menu.get_ok_button().text = "Continuar jogando"
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		game_menu.get_ok_button().add_theme_color_override(state, INK)
	add_child(game_menu)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	game_menu.add_child(content)
	menu_save_button = button("Salvar jogo", save_from_game_menu)
	menu_save_button.custom_minimum_size.y = 42
	content.add_child(menu_save_button)
	var settings_panel = preload("res://Scripts/settings_panel.gd").new()
	game_menu.add_child(settings_panel)
	content.add_child(button("Configurações",func(): settings_panel.popup_centered(Vector2i(480,460))))
	content.add_child(button("Salvar e voltar ao menu",func():
		if game.saves.save_file(): get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")
		else:
			menu_save_status.text=game.get_node("/root/IslandSaves").error
			get_node("/root/Localization").render(game_menu)
	))
	menu_quit_button = button("Fechar jogo", func(): get_tree().quit())
	menu_quit_button.custom_minimum_size.y = 42
	content.add_child(menu_quit_button)
	menu_save_status = label("",13)
	menu_save_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	menu_save_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(menu_save_status)
	game_menu.visibility_changed.connect(func():
		if not game_menu.visible:
			game.simulation_paused = paused_before_menu or game.settlement.extinct
			refresh()
	)

func open_game_menu() -> void:
	if game_menu.visible: return
	paused_before_menu = game.simulation_paused
	game.simulation_paused = true
	menu_save_status.text = ""
	refresh()
	game_menu.popup_centered(Vector2i(minf(360,get_viewport_rect().size.x-48),220))

func save_from_game_menu() -> void:
	menu_save_status.text = "Partida salva." if game.saves.save_file() else "Não foi possível salvar a partida."
	get_node("/root/Localization").render(game_menu)

func create_residents_window() -> void:
	residents_shade = ColorRect.new()
	residents_shade.color = Color(0.03,0.12,0.14,0.4)
	residents_shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	residents_shade.z_index = 200
	add_child(residents_shade)
	residents_window = panel()
	residents_window.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	residents_window.z_index = 201
	add_child(residents_window)
	var content := VBoxContainer.new()
	residents_window.add_child(content)
	var heading := HBoxContainer.new()
	content.add_child(heading)
	var title := label("HABITANTES E RESIDÊNCIAS", 18,GOLD)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	heading.add_child(button("Fechar", func(): close_residents()))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	content.add_child(scroll)
	residents_rows = VBoxContainer.new()
	residents_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(residents_rows)
	close_residents()

func close_residents() -> void:
	residents_window.hide()
	residents_shade.hide()
func open_residents(building) -> void:
	workforce_panel.hide()
	workforce_toggle.set_pressed_no_signal(false)
	residence_filter = building
	for child in residents_rows.get_children():
		residents_rows.remove_child(child)
		child.queue_free()
	resident_controls.clear()
	for worker in game.workers:
		if is_instance_valid(building) and worker.residence != building: continue
		var row := HBoxContainer.new()
		residents_rows.add_child(row)
		var description := label("", 13)
		description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(description)
		var wake_button := button("Acordar", func():
			if is_instance_valid(worker): worker.wake()
		)
		row.add_child(wake_button)
		resident_controls[worker] = {"label": description, "wake": wake_button}
	refresh_residents()
	get_node("/root/Localization").render(residents_window)
	layout_windows()
	residents_window.show()
	residents_shade.show()

func resident_text(worker) -> String:
	var p = worker.person
	return "%s%s · %s · XP %.0f\nEnergia %d%% · Alimentação %d%% · %s\n%s · %s" % ["Rei " if p.is_king else "", p.display_name, game.DATA.ACTIVITIES[worker.assignment].profession, p.experience.get(worker.assignment,0), p.energy, p.nutrition, worker.residence.display_name() if is_instance_valid(worker.residence) else "Sem residência", worker.status, "%s %d/%d" % [game.DATA.RESOURCES[p.tool].name, p.durability,game.DATA.TOOL_DURABILITY] if p.tool != "" else "Sem ferramenta equipada"]

func refresh_residents() -> void:
	var expected: Array = game.settlement.residents(residence_filter) if is_instance_valid(residence_filter) else game.workers
	if expected.size() != resident_controls.size() or expected.any(func(w): return not resident_controls.has(w)):
		open_residents(residence_filter)
		return
	for worker in resident_controls:
		var controls: Dictionary = resident_controls[worker]
		if not is_instance_valid(worker) or not game.workers.has(worker):
			controls.label.text = "Habitante falecido"
			controls.wake.disabled = true
		else:
			controls.label.text = resident_text(worker)
			controls.wake.disabled = worker.state != "resting"

func create_extinction_panel() -> void:
	extinction_panel = panel()
	extinction_panel.z_index = 300
	extinction_panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	extinction_panel.custom_minimum_size = Vector2(460,200)
	add_child(extinction_panel)
	var rows := VBoxContainer.new()
	extinction_panel.add_child(rows)
	rows.add_child(label("CIVILIZAÇÃO EXTINTA", 26, GOLD))
	rows.add_child(label("Nenhum habitante sobreviveu.\nUma nova ilha espera por outro começo.",16))
	rows.add_child(button("Começar novamente", func(): get_tree().reload_current_scene()))
	rows.add_child(button("Menu principal", func(): get_tree().change_scene_to_file("res://Scenes/main_menu.tscn")))
	extinction_panel.hide()

func _process(delta: float) -> void:
	refresh_timer -= delta
	if refresh_timer <= 0:
		refresh_timer = 0.2
		refresh()

func blocks_world_input(point: Vector2) -> bool:
	return residents_window.visible or extinction_panel.visible or top_panel.get_global_rect().has_point(point) or bottom_panel.get_global_rect().has_point(point) or (workforce_panel.visible and workforce_panel.get_global_rect().has_point(point))

func refresh() -> void:
	for building in game.buildings: building.update_warning()
	var free_workers: int = game.activity_count("idle")
	var resting := 0
	for worker in game.workers:
		if worker.state == "resting": resting += 1
	var unavailable: int=game.workers.filter(func(w): return w.state in ["resting","to_rest"] or w.person.nutrition<=game.DATA.HUNGER_STOP).size()
	var active: int=game.workers.filter(func(w): return w.assignment!="idle" and w.state not in ["idle","resting","to_rest"] and w.person.nutrition>game.DATA.HUNGER_STOP).size()
	workforce_summary.text="%d habitantes · %d livres · %d atribuídos\n%d ativos · %d indisponíveis · Moradia %d/%d"%[game.workers.size(),free_workers,game.workers.size()-free_workers,active,unavailable,game.workers.size(),game.population_limit()]
	for activity in activity_controls:
		var controls: Dictionary = activity_controls[activity]
		var count: int = game.activity_count(activity)
		controls.amount.text = str(count)
		controls.minus.disabled = count == 0
		var reason: String=game.allocation_reason(activity)
		controls.plus.disabled=not reason.is_empty()
		controls.plus.tooltip_text=reason if not reason.is_empty() else "Alocar habitante livre"
	workforce_view.refresh()
	stock_label.text = "Disponível"
	var tooltips: PackedStringArray = []
	for resource in resource_labels:
		var values: Dictionary = game.resource_breakdown(resource)
		var info: String = "%s\nDisponível para gastar: %d\nTotal armazenado: %d\nReservado para tarefas: %d\nEm transporte: %d" % [game.DATA.RESOURCES[resource].name,values.available,values.stored,values.reserved,values.carried]
		resource_labels[resource].amount.text = str(values.available)
		resource_labels[resource].amount.tooltip_text = info
		resource_labels[resource].icon.tooltip_text = info
		tooltips.append(info)
	stock_label.tooltip_text = "\n\n".join(tooltips)
	pause_button.text = "Continuar" if game.simulation_paused else "Pausar"
	pause_button.disabled = game.settlement.extinct
	speed_button.text = "%dx" % game.simulation_speed
	objective_label.text = game.progression_text()
	for kind in build_buttons:
		build_buttons[kind].disabled=kind in ["gold_mining","smelter","trading_port"] and game.village_level<3
		build_buttons[kind].tooltip_text = "%s\n%s\nMateriais: %s\n%s" % [game.DATA.BUILDINGS[kind].name,game.DATA.BUILDINGS[kind].description,game.DATA.cost_text(game.DATA.BUILDINGS[kind].cost),game.cost_status(game.DATA.BUILDINGS[kind].cost)]
		build_buttons[kind].set_pressed_no_signal(game.placement_kind == kind)
	var selected = game.selection
	inspection_icon.hide()
	rotate_port_button.visible=game.placement_kind=="trading_port"
	if is_instance_valid(selected) and selected.has_method("wake") and selected.person.tool != "":
		inspection_icon.texture = game.DATA.resource_texture(selected.person.tool)
		inspection_icon.show()
	var is_building: bool = is_instance_valid(selected) and selected.has_method("enqueue")
	var is_base: bool = is_building and selected.completed and selected.kind == "base"
	var is_garden: bool = is_instance_valid(selected) and selected is GARDEN
	team_button.visible=is_building and selected.completed and selected.kind in ["food","wood","stone","gold_mining","smelter","workshop"]
	trade_button.visible=is_building and selected.completed and selected.kind=="trading_port"
	garden_button.visible = is_building and selected.kind == "food" and selected.completed and not selected.demolition_requested
	garden_button.disabled = not game.gardens_unlocked() or not game.can_afford(game.DATA.GARDEN_COST)
	garden_button.tooltip_text = "Melhore um depósito de comida para o nível 2 para criar hortas." if not game.gardens_unlocked() else "Cercado: 10 madeiras uma vez. Plantio: 2 Hortifruti por ciclo. 60s; 15 Hortifruti."
	var tree: bool = is_instance_valid(selected) and selected.has_method("request_cut") and selected.is_tree and not selected.is_timber and not selected.removed
	cut_button.visible = tree and (selected.stage == 4 or selected.cut_requested)
	cut_button.disabled = tree and selected.cut_started
	cut_button.text = "Cancelar corte" if tree and selected.cut_requested and not selected.cut_started else ("Corte iniciado" if tree and selected.cut_started else "Cortar agora")
	cut_button.tooltip_text = "Frutas restantes são perdidas na primeira machadada. Lenhadores executam o corte."
	warning_button.visible = is_building and not selected.warning.is_empty()
	if warning_button.visible:
		warning_button.text = {"inhabitants":"Abrir Habitantes","tools":"Ver ferramentas","policies":"Ver metas","building":"Ver armazenamento / obra"}[selected.warning.action]
		warning_button.tooltip_text = selected.warning.text
	manual_plant_button.visible = is_garden and selected.phase == "empty"
	manual_plant_button.disabled = not game.can_afford(game.DATA.PLANT_COST)
	replant_button.visible = is_garden
	if is_garden: replant_button.text = "Replantio automático: " + ("ligado" if selected.auto_replant else "desligado")
	demolish_button.visible = is_building and selected.completed and selected.kind != "base" and not selected.demolition_requested
	demolish_button.disabled = is_building and selected.upgrading
	demolish_button.tooltip_text = "Conclua a melhoria antes de demolir." if is_building and selected.upgrading else "Construtor: 10s. Moradores se mudam; estoque fica no chão. Sem reembolso da construção."
	cancel_work_button.visible = is_building and not selected.completed and selected.kind != "base"
	var surveying: bool=is_instance_valid(selected) and selected.has_method("cancel_survey") and selected.kind=="survey" and not selected.completed
	cancel_work_button.visible=cancel_work_button.visible or surveying
	cancel_work_button.text="Cancelar investigação" if surveying else "Cancelar obra"
	cancel_work_button.tooltip_text = "Antes da primeira martelada, materiais entregues ficam no chão; depois, são perdidos. Reservas e cargas em trânsito são preservadas."
	cancel_demolish_button.visible = is_building and selected.demolition_requested
	cancel_demolish_button.disabled = is_building and selected.demolition_started
	cancel_demolish_button.tooltip_text = "Só pode cancelar antes da primeira martelada."
	construction_menu.visible = not is_building and not (is_instance_valid(selected) and selected.has_method("description"))
	building_actions.visible = is_building or is_garden or (is_instance_valid(selected) and (selected.has_method("reserves_ground") or (selected.has_method("description") and selected.is_tree)))
	recruit_button.visible = is_base
	recruit_button.disabled = game.immigration.expedition_reason() != ""
	recruit_button.tooltip_text = game.immigration.expedition_reason()
	plant_button.visible = is_base or (is_building and selected.completed and selected.kind == "food")
	timber_button.visible = is_base or (is_building and selected.completed and selected.kind == "wood")
	expand_button.visible = is_base
	evolve_button.visible = is_base
	aid_button.visible = is_base
	residents_button.visible = is_building and selected.completed and selected.housing_capacity() > 0
	upgrade_button.visible = is_building and selected.completed and selected.kind in ["house", "warehouse", "food", "wood", "stone", "workshop"]
	upgrade_button.disabled = is_building and (selected.level >= 3 or selected.upgrading or selected.demolition_requested)
	upgrade_button.text = "Melhorar"
	if is_building and selected.kind == "workshop": upgrade_button.text = "Liberar metas · nível 2" if selected.level == 1 else ("Reserva automática · nível 3" if selected.level == 2 else "Nível máximo")
	if is_building and selected.kind == "stone" and selected.level == 1: upgrade_button.text = "Liberar pedreiras · nível 2"
	upgrade_button.tooltip_text = selected.FEEDBACK.next_level(selected) + "\n" + game.DATA.cost_text(selected.upgrade_cost()) if is_building else ""
	var workshop: bool = is_building and selected.completed and not selected.demolition_requested and selected.kind == "workshop"
	for order in order_buttons: order.visible = workshop
	tools_box.visible = workshop and selected.level == 2
	survey_button.visible = is_building and selected.completed and selected.kind == "stone"
	survey_button.disabled = is_building and selected.level < 2
	survey_button.tooltip_text = "Requer depósito de pedra nível 2; aloque um mineiro."
	var report: bool = is_instance_valid(selected) and selected.has_method("open_quarry") and selected.kind == "survey" and selected.completed and not selected.released
	quarry_button.visible = report
	if report: quarry_button.text="Abrir jazida · 10 madeiras + 10 pedras" if selected.deposit_resource=="gold_ore" else "Abrir pedreira · 10 madeiras + 5 pedras"
	var depleted_gold: bool=is_instance_valid(selected) and selected.has_method("take") and selected.get("resource_kind")=="gold_ore" and selected.remaining==0 and not selected.removed
	release_button.visible = report or depleted_gold
	if depleted_gold: building_actions.show()
	orchard_button.visible = is_instance_valid(selected) and ((selected.has_method("description") and selected.is_tree and not selected.is_timber) or (selected.has_method("open_quarry") and selected.kind == "plant"))
	if orchard_button.visible: orchard_button.text = "Renovação do pomar: " + ("ligada" if game.automation.orchards.has(selected.origin) else "desligada")
	priority_button.visible = is_instance_valid(selected) and selected.has_method("needs_work") and selected.needs_work()
	if priority_button.visible: priority_button.text = "Prioridade: " + ["baixa", "normal", "urgente"][selected.priority]
	save_button.visible = is_base
	load_button.visible = is_base
	policy_button.visible = is_base
	policy_box.visible = true
	if is_base:
		for resource in policy_controls: policy_controls[resource].set_value_no_signal(game.automation.stock_targets[resource])
	if tools_box.visible:
		for tool in tools_controls: tools_controls[tool].set_value_no_signal(selected.tool_targets[tool])
	plant_button.disabled = not game.can_afford(game.DATA.PLANT_COST)
	timber_button.disabled = not game.can_afford(game.DATA.PLANT_COST)
	timber_button.tooltip_text = "Cresce em %ds sem nunca frutificar e rende %d madeiras. Exige depósito de madeira; lenhadores plantam e cortam." % [game.DATA.timber_growth_seconds(), game.DATA.TIMBER_STOCK]
	expand_button.disabled = not game.can_afford(game.expansion_brush.cost(1))
	expand_button.tooltip_text = "Ctrl + roda ajusta o pincel; o custo depende apenas da água preenchida."
	evolve_button.disabled = not game.upgrade_ready()
	evolve_button.text = "Evoluir vila\nNível %d" % mini(3,game.village_level+1) if game.village_level < 3 else "Vila próspera"
	evolve_button.tooltip_text = game.DATA.cost_text(game.upgrade_cost()) + " · " + game.cost_status(game.upgrade_cost()) + " · " + game.base.FEEDBACK.next_level(game.base)
	aid_button.disabled = game.aid_cooldown > 0
	aid_button.tooltip_text = "Disponível em %ds" % ceili(game.aid_cooldown)
	progress.visible = false
	if not game.action_mode.is_empty() or not game.placement_kind.is_empty():
		title_label.text = "Criar horta" if game.action_mode == "garden" else ("Plantar árvore de madeira" if game.action_mode == "plant_wood" else ("Plantar árvore" if game.action_mode == "plant" else ("Ampliar a costa" if game.action_mode == "expand" else ("Investigar terreno" if game.action_mode == "survey" else "Construir " + game.DATA.BUILDINGS[game.placement_kind].name))))
		detail_label.text = "Marque no mapa. Shift repete; Esc cancela. Materiais serão levados ao local." if game.preview_valid else game.placement_reason
		if not game.placement_kind.is_empty():
			var size: Vector2i = game.DATA.building_size(game.placement_kind)
			detail_label.text = "Área: %d × %d células + entrada livre na frente.\n" % [size.x,size.y] + detail_label.text
			detail_label.text += "\nMateriais soltos serão retirados; habitantes sairão antes da construção."
			if game.placement_kind=="trading_port":
				detail_label.text="Mar ao %s · 5 × 2 em terra; 5 × 3 em água · R para girar\n"%game.port_layout.LABELS[game.placement_orientation]+("Ponto de carga marcado em dourado. Clique para construir." if game.preview_valid else game.placement_reason)
		if game.action_mode == "expand":
			var plan: Dictionary = game.expansion_preview
			title_label.text = "Aterrar terreno · Pincel %d × %d" % [game.expansion_brush_size,game.expansion_brush_size]
			var cost: Dictionary = plan.get("cost",{})
			detail_label.text = "Células: %d · Pedras: %d · Madeiras: %d · Trabalho: %.1fs\nCtrl + roda: tamanho · Shift + arraste: pintar · Esc: cancelar" % [plan.get("cells",[]).size(),cost.get("stone",0),cost.get("wood",0),plan.get("seconds",0.0)]
			if not game.preview_valid: detail_label.text += "\n" + game.placement_reason
	elif is_building:
		title_label.text = "%s · nível %d" % [selected.display_name(), selected.level]
		if selected.demolition_requested:
			detail_label.text = selected.demolition_status()
			progress.visible = true
			progress.value = selected.demolition_progress * 10
		elif selected.preparing_site:
			detail_label.text = game.clearance.description(selected)
		elif selected.needs_work():
			detail_label.text = "Entregues: " + selected.materials.text(game.DATA) + (" · Construindo" if selected.materials.ready() else " · Aguardando transporte / materiais")
			progress.visible = true
			progress.value = 100 * selected.progress / game.DATA.BUILDINGS[selected.kind].build_seconds
		elif selected.housing_capacity() > 0:
			var occupants: Array = game.settlement.residents(selected)
			var inside: int = occupants.filter(func(w): return w.state == "resting").size()
			detail_label.text = "%d/%d moradores · %d dentro, descansando. " % [occupants.size(),selected.housing_capacity(),inside]
			if is_base: detail_label.text += game.immigration.description() + ". Estoque %d/%d." % [selected.used(),selected.capacity()]
		else:
			detail_label.text = "%d/%d — %s. %s" % [selected.used(),selected.capacity(),"Cheio" if selected.used() >= selected.capacity() else "Espaço disponível",game.DATA.cost_text(selected.stored)]
			if selected.kind == "workshop": detail_label.text = selected.workshop_status()
			if selected.kind=="trading_port": detail_label.text=game.merchant.description()+"\n"+game.DATA.cost_text(selected.stored)
			if selected.kind=="smelter": detail_label.text=game.gold.smelter_status(selected)+"\n5 minérios + 2 madeiras → 1 barra · 15s por bancada\n"+game.DATA.cost_text(selected.stored)
			if selected.kind=="smelter":
				var batches: Array=selected.smelting_batches
				progress.visible=batches.any(func(b): return b.active)
				progress.value=maxf(batches[0].progress,batches[1].progress)/game.DATA.ECONOMY.SMELTER_SECONDS*100
				progress.tooltip_text="Bancadas: %.1f/15s · %.1f/15s"%[batches[0].progress,batches[1].progress]
		if selected.completed and not selected.demolition_requested:
			detail_label.text += "\n" + selected.FEEDBACK.next_level(selected)
		if not selected.warning.is_empty() and not detail_label.text.contains(selected.warning.text): detail_label.text += "\n" + selected.warning.text
	elif is_instance_valid(selected) and selected.has_method("wake"):
		title_label.text = ("Rei " if selected.person.is_king else "") + selected.person.display_name
		detail_label.text = resident_text(selected).replace("\n"," · ")
	elif is_garden:
		title_label.text = "Horta 2 × 2"
		detail_label.text = game.clearance.description(selected) if selected.preparing_site else selected.description()
		progress.visible = true
		progress.value = 100.0 * selected.age / game.DATA.GARDEN_GROW_SECONDS if selected.phase == "growing" else (100.0 * selected.remaining / game.DATA.GARDEN_YIELD if selected.phase == "ripe" else 100.0 * selected.progress / selected.work_duration())
	elif is_instance_valid(selected) and selected.has_method("description"):
		title_label.text = ("Ciclo da árvore de madeira" if selected.is_timber else "Ciclo da árvore") if selected.is_tree else ("Jazida de ouro" if selected.resource_kind=="gold_ore" else "Jazida de pedra")
		detail_label.text = selected.description()
		if selected.is_tree and not selected.removed:
			progress.visible = true
			var reserve: int = game.DATA.TIMBER_STOCK if selected.is_timber else (game.DATA.SOURCE_STOCK.produce if selected.stage == 4 else game.DATA.SOURCE_STOCK.wood)
			progress.value = 100.0 * selected.age / selected.growth_seconds(selected.stage) if selected.stage < 4 else 100.0 * selected.remaining / reserve
		progress.tooltip_text = "Evolução até o próximo estágio" if selected.stage < 4 else "Estoque restante para coleta"
	elif is_instance_valid(selected) and selected.has_method("needs_work"):
		title_label.text = {"plant": "Plantio", "plant_wood": "Plantio de madeira", "expand": "Expansão costeira", "survey": "Investigação de jazida", "quarry": "Abertura de pedreira"}[selected.kind]
		detail_label.text = ("Reserva: %d %s. Abrir consome materiais e trabalho." % [selected.deposit,game.DATA.RESOURCES[selected.deposit_resource].name]) if report else selected.materials.text(game.DATA)
	elif is_instance_valid(selected) and selected.get("stored") != null:
		title_label.text = "Materiais aguardando transporte"
		detail_label.text = game.DATA.cost_text(selected.stored)
	else:
		title_label.text = "Uma pequena comunidade. Um futuro império."
		detail_label.text = "Construa casas para receber colonos. Renove os pomares e distribua o trabalho. O Rei também participa da vida da vila."
	notification_label.text = game.message if game.message_time > 0 else "WASD mover · Q/E zoom · Shift repetir · Home centrar · Espaço pausar"
	update_context_layout()
	if is_instance_valid(trade_window) and trade_window.visible: trade_window.refresh()
	if residents_window.visible: refresh_residents()
	if game.settlement.extinct and not extinct_shown:
		extinct_shown = true
		close_residents()
		residents_shade.show()
		extinction_panel.reset_size()
		extinction_panel.position = (get_viewport_rect().size - extinction_panel.size) / 2
		extinction_panel.show()
	get_node("/root/Localization").render(self)

func open_warning_action() -> void:
	var building = game.selection
	if not is_instance_valid(building) or not building.has_method("update_warning"): return
	building.update_warning()
	if building.warning.is_empty(): return
	match building.warning.action:
		"inhabitants":
			if not workforce_panel.visible: toggle_workforce()
		"policies": policy_window.popup_centered()
		"tools":
			var workshop = game.workplace_for("workshop")
			if workshop != null: game.select_entity(workshop)
			else: game.begin_placement("workshop")
		_: game.select_entity(building)

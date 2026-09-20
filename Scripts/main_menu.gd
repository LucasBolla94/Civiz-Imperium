extends Node2D
const MENU_THEME = preload("res://Scripts/menu_theme.gd")
@onready var home: PanelContainer = $Interface/Center/Home
@onready var start_button: Button = $Interface/Center/Home/Rows/Buttons/Play
@onready var slots_panel: PanelContainer = $Interface/Center/Islands
@onready var slot_rows: VBoxContainer = $Interface/Center/Islands/Rows/Slots
@onready var notice: Label = $Interface/Center/Islands/Rows/Notice
var backdrop: Node2D
var settings_panel
var name_dialog := ConfirmationDialog.new()
var delete_dialog := ConfirmationDialog.new()
var name_input := LineEdit.new()
var name_error := Label.new()
var new_index := -1
var delete_id := ""
var saves

func _ready() -> void:
	saves=get_node("/root/IslandSaves")
	$Interface/Center.theme=MENU_THEME.create()
	backdrop=preload("res://Scripts/menu_backdrop.gd").new()
	$Background.add_child(backdrop)
	start_button.pressed.connect(show_islands)
	$Interface/Center/Home/Rows/Buttons/Settings.pressed.connect(open_settings)
	$Interface/Center/Home/Rows/Buttons/Exit.pressed.connect(func(): get_tree().quit())
	$Interface/Center/Islands/Rows/Back.pressed.connect(show_home)
	settings_panel=preload("res://Scripts/settings_panel.gd").new()
	add_child(settings_panel)
	settings_panel.visibility_changed.connect(func():
		if not settings_panel.visible: $Interface/Center/Home/Rows/Buttons/Settings.grab_focus()
	)
	name_dialog.title="Criar uma ilha"
	name_dialog.get_ok_button().text="Criar e jogar"
	name_dialog.get_cancel_button().text="Cancelar"
	name_dialog.theme=MENU_THEME.create()
	name_dialog.exclusive=true
	add_child(name_dialog)
	var form := VBoxContainer.new()
	form.add_theme_constant_override("separation",12)
	name_dialog.add_child(form)
	var label := Label.new()
	label.text="Nome da ilha"
	form.add_child(label)
	name_input.max_length=40
	name_input.custom_minimum_size.x=380
	form.add_child(name_input)
	name_error.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	form.add_child(name_error)
	name_input.text_changed.connect(func(value):
		name_dialog.get_ok_button().disabled=not saves.valid_name(value)
		name_error.text="" if saves.valid_name(value) else "Use um nome de 1 a 40 caracteres, sem barras ou quebras de linha."
		refresh_language()
	)
	name_input.text_submitted.connect(func(_value):
		if not name_dialog.get_ok_button().disabled: create_island()
	)
	name_dialog.confirmed.connect(create_island)
	name_dialog.visibility_changed.connect(func():
		if not name_dialog.visible: focus_slots.call_deferred()
	)
	delete_dialog.theme=MENU_THEME.create()
	delete_dialog.title="Apagar ilha?"
	delete_dialog.get_ok_button().text="Apagar definitivamente"
	delete_dialog.get_cancel_button().text="Cancelar"
	delete_dialog.exclusive=true
	add_child(delete_dialog)
	delete_dialog.confirmed.connect(func():
		if saves.delete_island(delete_id): notice.text=""
		else: notice.text=saves.error
		refresh_slots()
	)
	delete_dialog.visibility_changed.connect(func():
		if not delete_dialog.visible: focus_slots.call_deferred()
	)
	get_node("/root/Localization").language_changed.connect(func(): refresh_language(); refresh_slots())
	refresh_language()
	start_button.grab_focus()
	if not saves.error.is_empty(): show_islands()

func refresh_language() -> void: get_node("/root/Localization").render(self)
func show_home() -> void:
	slots_panel.hide()
	home.show()
	start_button.grab_focus()
func show_islands() -> void:
	home.hide()
	slots_panel.show()
	notice.text=saves.error
	refresh_slots()
	focus_slots.call_deferred()
func focus_slots() -> void:
	if is_inside_tree() and slots_panel.visible and slot_rows.get_child_count()>0:
		slot_rows.get_child(0).get_node("Action").grab_focus()
func open_settings() -> void: settings_panel.popup_centered(Vector2i(480,460))

func refresh_slots() -> void:
	for child in slot_rows.get_children(): child.free()
	for i in saves.LIMIT:
		var slot: Dictionary=saves.catalog.slots[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation",12)
		slot_rows.add_child(row)
		var thumbnail := TextureRect.new()
		thumbnail.custom_minimum_size=Vector2(128,72)
		thumbnail.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		thumbnail.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(thumbnail)
		var info := VBoxContainer.new()
		info.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		row.add_child(info)
		var name_label := Label.new()
		name_label.text="Espaço livre" if slot.is_empty() else slot.name
		if not slot.is_empty(): name_label.set_meta("l10n_skip",true)
		name_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		name_label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		name_label.custom_minimum_size.x=170
		info.add_child(name_label)
		var summary := Label.new()
		info.add_child(summary)
		var action := Button.new()
		action.name="Action"
		action.custom_minimum_size.x=120
		row.add_child(action)
		if slot.is_empty():
			summary.text="Uma nova civilização"
			action.text="Criar ilha"
			action.disabled=not saves.writable
			action.pressed.connect(func():
				new_index=i
				name_input.text=""
				name_error.text="Use um nome de 1 a 40 caracteres, sem barras ou quebras de linha."
				name_dialog.get_ok_button().disabled=true
				refresh_language()
				name_dialog.popup_centered(Vector2i(460,200))
				name_input.grab_focus()
			)
		else:
			var record: Dictionary=saves.island(i)
			summary.text="Arquivo indisponível" if record.is_empty() else "%d habitantes · Base nível %d"%[record.population,record.level]
			if not record.is_empty():
				var image := Image.new()
				if image.load_png_from_buffer(record.thumbnail)==OK: thumbnail.texture=ImageTexture.create_from_image(image)
			action.text="Continuar"
			action.disabled=record.is_empty()
			action.pressed.connect(func():
				if saves.activate(i):
					get_tree().set_meta("continue_game",true)
					get_tree().change_scene_to_file("res://Scenes/main.tscn")
				else: notice.text=saves.error; refresh_language()
			)
			var remove := Button.new()
			remove.text="Apagar"
			remove.disabled=not saves.writable
			row.add_child(remove)
			remove.pressed.connect(func():
				delete_id=slot.id
				delete_dialog.set_meta("l10n_skip_properties",["dialog_text"])
				delete_dialog.dialog_text=get_node("/root/Localization").text("Apagar a ilha %s? Todo o progresso será perdido.")%slot.name
				delete_dialog.popup_centered(Vector2i(540,190))
				delete_dialog.get_cancel_button().grab_focus()
			)
	refresh_language()

func create_island() -> void:
	if saves.begin_new(new_index,name_input.text):
		name_dialog.hide()
		get_tree().change_scene_to_file("res://Scenes/main.tscn")
	else:
		name_error.text=saves.error
		refresh_language()
		name_dialog.popup_centered(Vector2i(460,220))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and slots_panel.visible:
		show_home()
		get_viewport().set_input_as_handled()

extends AcceptDialog
var settings
var resolution: OptionButton
var fullscreen: CheckBox
var confirmation := ConfirmationDialog.new()
var status := Label.new()
var choices: Array[Vector2i]=[]

func _ready() -> void:
	settings=get_node("/root/AppSettings")
	theme=preload("res://Scripts/menu_theme.gd").create()
	title="Configurações"
	exclusive=true
	get_ok_button().text="Voltar"
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation",12)
	add_child(rows)
	for spec in [["Música","Music",settings.music],["Efeitos sonoros","Effects",settings.effects]]:
		var line := HBoxContainer.new()
		rows.add_child(line)
		var label := Label.new()
		label.text=spec[0]
		label.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		line.add_child(label)
		var value := Label.new()
		value.custom_minimum_size.x=50
		value.text="%d%%"%roundi(spec[2]*100)
		line.add_child(value)
		var slider := HSlider.new()
		slider.name=spec[1]
		slider.min_value=0
		slider.max_value=100
		slider.value=spec[2]*100
		slider.custom_minimum_size.y=24
		slider.value_changed.connect(func(amount):
			value.text="%d%%"%roundi(amount)
			settings.set_volume(spec[1],amount/100.0)
			status.text=settings.error
			translate()
		)
		rows.add_child(slider)
	var video := Label.new()
	video.text="Resolução em janela"
	rows.add_child(video)
	resolution=OptionButton.new()
	choices=settings.supported_resolutions()
	for choice in choices: resolution.add_item("%d × %d"%[choice.x,choice.y])
	rows.add_child(resolution)
	fullscreen=CheckBox.new()
	fullscreen.text="Tela cheia"
	fullscreen.toggled.connect(func(value): resolution.disabled=value)
	rows.add_child(fullscreen)
	var mode_hint := Label.new()
	mode_hint.text="Em tela cheia, usamos a resolução do monitor."
	rows.add_child(mode_hint)
	var apply := Button.new()
	apply.text="Aplicar vídeo"
	apply.pressed.connect(func():
		settings.begin_video(choices[resolution.selected],fullscreen.button_pressed)
		confirmation.popup_centered(Vector2i(460,180))
		confirmation.get_cancel_button().grab_focus()
	)
	rows.add_child(apply)
	var language := Label.new()
	language.text="Idioma"
	rows.add_child(language)
	rows.add_child(get_node("/root/Localization").selector())
	status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rows.add_child(status)
	confirmation.title="Manter estas configurações?"
	confirmation.get_ok_button().text="Manter"
	confirmation.get_cancel_button().text="Reverter"
	confirmation.exclusive=true
	add_child(confirmation)
	confirmation.confirmed.connect(settings.confirm_video)
	confirmation.canceled.connect(settings.revert_video)
	settings.video_finished.connect(func(): confirmation.hide(); sync_video(); status.text=settings.error; translate())
	visibility_changed.connect(func():
		if visible: sync_video(); get_ok_button().grab_focus()
		elif settings.trial: settings.revert_video()
	)
	get_node("/root/Localization").language_changed.connect(translate)
	sync_video()
	translate()

func sync_video() -> void:
	resolution.select(maxi(0,choices.find(settings.resolution)))
	fullscreen.button_pressed=settings.fullscreen

func translate() -> void: get_node("/root/Localization").render(self)

func _process(_delta: float) -> void:
	if settings.trial:
		confirmation.dialog_text="Revertendo em %d segundos."%maxi(0,ceili(settings.remaining))
		translate()

extends Node
signal changed
signal video_finished
const PATH = "user://settings_v006.cfg"
const RESOLUTIONS = [Vector2i(960,540),Vector2i(1280,720),Vector2i(1366,768),Vector2i(1600,900),Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3840,2160)]
var music := 0.7
var effects := 0.8
var resolution := Vector2i(1280,720)
var fullscreen := false
var trial := false
var remaining := 0.0
var deadline_msec := 0
var previous := {}
var proposed := {}
var error := ""

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for bus in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	var config := ConfigFile.new()
	if config.load(PATH)==OK:
		var saved_music = config.get_value("audio","music",0.7)
		var saved_effects = config.get_value("audio","effects",0.8)
		var saved_resolution = config.get_value("video","resolution",Vector2i(1280,720))
		var saved_fullscreen = config.get_value("video","fullscreen",false)
		if saved_music is float or saved_music is int: music=clampf(saved_music,0,1)
		if saved_effects is float or saved_effects is int: effects=clampf(saved_effects,0,1)
		if saved_resolution is Vector2i: resolution=saved_resolution
		if saved_fullscreen is bool: fullscreen=saved_fullscreen
	var supported := supported_resolutions()
	if not supported.has(resolution): resolution=supported.back()
	apply_volume("Music",music)
	apply_volume("Effects",effects)
	apply_video.call_deferred(resolution,fullscreen)

func supported_resolutions() -> Array[Vector2i]:
	var maximum := Vector2i(1920,1080) if DisplayServer.get_name()=="headless" else DisplayServer.screen_get_usable_rect(get_window().current_screen).size-Vector2i(48,80)
	var result: Array[Vector2i]=[]
	for size in RESOLUTIONS:
		if size.x<=maximum.x and size.y<=maximum.y: result.append(size)
	if result.is_empty(): result.append(Vector2i(640,360))
	return result

func apply_volume(bus: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus)
	AudioServer.set_bus_volume_linear(index,value)
	AudioServer.set_bus_mute(index,value<=0)

func set_volume(bus: String, value: float) -> void:
	value=clampf(value,0,1)
	if bus=="Music": music=value
	elif bus=="Effects": effects=value
	else: return
	apply_volume(bus,value)
	persist()
	changed.emit()

func persist() -> bool:
	var config := ConfigFile.new()
	config.set_value("audio","music",music)
	config.set_value("audio","effects",effects)
	# Confirmed video only; changing sound during a trial cannot publish the trial.
	config.set_value("video","resolution",resolution)
	config.set_value("video","fullscreen",fullscreen)
	if config.save(PATH+".tmp")!=OK: error="Não foi possível salvar as configurações."; return false
	if DirAccess.rename_absolute(PATH+".tmp",PATH)!=OK: error="Não foi possível salvar as configurações."; return false
	error=""
	return true

func apply_video(size: Vector2i, full: bool) -> void:
	if DisplayServer.get_name()=="headless" or get_node("/root/WindowLayout").editor_owned: return
	var window := get_window()
	window.mode=Window.MODE_WINDOWED
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var fit := preload("res://Scripts/window_layout.gd").fitted_rect(usable,size)
	window.size=fit.size
	window.position=fit.position
	if full: window.mode=Window.MODE_FULLSCREEN

func begin_video(size: Vector2i, full: bool) -> void:
	if trial: revert_video()
	previous={"resolution":resolution,"fullscreen":fullscreen,"size":get_window().size,"position":get_window().position,"mode":get_window().mode}
	proposed={"resolution":size,"fullscreen":full}
	trial=true
	remaining=15.0
	deadline_msec=Time.get_ticks_msec()+15000
	apply_video(size,full)
	changed.emit()

func confirm_video() -> void:
	if not trial: return
	resolution=proposed.resolution
	fullscreen=proposed.fullscreen
	if not persist():
		resolution=previous.resolution
		fullscreen=previous.fullscreen
		revert_video()
		return
	trial=false
	video_finished.emit()
	changed.emit()

func revert_video() -> void:
	if not trial: return
	apply_video(previous.resolution,previous.fullscreen)
	if DisplayServer.get_name()!="headless" and not get_node("/root/WindowLayout").editor_owned:
		get_window().mode=Window.MODE_WINDOWED
		get_window().size=previous.size
		get_window().position=previous.position
		get_window().mode=previous.mode
	trial=false
	video_finished.emit()
	changed.emit()

func _process(_delta: float) -> void:
	if trial:
		remaining=maxf(0.0,(deadline_msec-Time.get_ticks_msec())/1000.0)
		if remaining<=0: revert_video()

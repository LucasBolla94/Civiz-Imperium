extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	AudioServer.set_bus_mute(0,true)
	var music=root.get_node("Music")
	var settings=root.get_node("AppSettings")
	settings.apply_volume("Music",1.0)
	var capture := AudioEffectCapture.new()
	capture.buffer_length=1.0
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"),capture)
	var menu=load("res://Scenes/main_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene=menu
	var started := Time.get_ticks_msec()
	var last := -2
	var changes := []
	var longest_silence := 0
	var silent_frames := 0
	var last_log := 0
	var captured := 0
	var audible := 0
	while Time.get_ticks_msec()-started<170000:
		await process_frame
		var elapsed := Time.get_ticks_msec()-started
		var playback=music.player.get_stream_playback()
		var clip: int=playback.get_current_clip_index()
		if clip!=last:
			changes.append(clip)
			print("LIVE ",elapsed,"ms clip=",clip," playing=",music.player.playing," queued=",music.queued)
			last=clip
		if elapsed-last_log>=10000:
			print("LIVE heartbeat ",elapsed,"ms; longest silence ",float(longest_silence)/AudioServer.get_mix_rate(),"s")
			last_log=elapsed
		if capture.can_get_buffer(1024):
			var frames := capture.get_buffer(capture.get_frames_available())
			captured+=frames.size()
			for frame in frames:
				if frame.length_squared()<0.000000001: silent_frames+=1
				else: silent_frames=0; audible+=1
				longest_silence=maxi(longest_silence,silent_frames)
	print("LIVE final changes ",changes," max silence ",float(longest_silence)/AudioServer.get_mix_rate(),"s")
	assert(changes.size()>=5 and not changes.has(-1))
	assert(captured>AudioServer.get_mix_rate()*160 and audible>captured*0.99)
	assert(longest_silence<AudioServer.get_mix_rate()/10)
	print("V0.0.6 live music passed")
	quit()

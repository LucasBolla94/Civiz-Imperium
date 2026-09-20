extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var music=root.get_node("Music")
	music.player.stop()
	music.set_process(false)
	music.bag.clear()
	music.previous=-1
	music.stream.initial_clip=music.next_track()
	var playback: AudioStreamPlaybackInteractive=music.stream.instantiate_playback()
	playback.start()
	var rate := AudioServer.get_mix_rate()
	var output := FileAccess.open("res://Tests/v006_audio.pcm",FileAccess.WRITE)
	var changes := []
	var last := -1
	var samples := 0
	var stop_at := int(rate*170)
	while samples<stop_at:
		var frames := playback.mix_audio(1.0,512)
		assert(frames.size()==512,"Audio must remain continuous")
		output.store_buffer(frames.to_byte_array())
		var current := playback.get_current_clip_index()
		if current!=last:
			assert(current>=0,"No silent stopped state between tracks")
			changes.append({"track":current,"sample":samples})
			last=current
			playback.switch_to_clip(music.next_track())
			print("Transition ",changes.size(),": track ",current+1," at ",float(samples)/rate,"s")
		samples+=512
	output.close()
	playback.stop()
	assert(changes.size()==5)
	var seen := {}
	for i in 4:
		assert(not seen.has(changes[i].track))
		seen[changes[i].track]=true
	assert(changes[3].track!=changes[4].track)
	var report := FileAccess.open("res://Tests/v006_audio_report.json",FileAccess.WRITE)
	report.store_string(JSON.stringify({"sample_rate":rate,"samples":samples,"transitions":changes}))
	report.close()
	print("V0.0.6 audio: original four tracks and round boundary passed")
	quit()

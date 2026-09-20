extends SceneTree
var failures := 0
var checks := 0

func _initialize() -> void: call_deferred("run")

func check(condition: bool, message: String) -> void:
	checks+=1
	if not condition:
		failures+=1
		push_error(message)

func run() -> void:
	var music=root.get_node("Music")
	var settings=root.get_node("AppSettings")
	music.set_process(false)
	music.player.stop()
	# Reproduce the previous failure: one queued transition and no native
	# successors run out after two tracks if the main thread cannot schedule.
	var previous_stream := music.stream.duplicate() as AudioStreamInteractive
	previous_stream.initial_clip=0
	for i in 4: previous_stream.set_clip_auto_advance(i,AudioStreamInteractive.AUTO_ADVANCE_DISABLED)
	var previous_playback := previous_stream.instantiate_playback() as AudioStreamPlaybackInteractive
	previous_playback.start()
	previous_playback.mix_audio(1.0,1024)
	previous_playback.switch_to_clip(1)
	var baseline_silence := 0
	for block in int(AudioServer.get_mix_rate()*90/1024.0)+1:
		for frame in previous_playback.mix_audio(1.0,1024):
			if frame.length_squared()<0.000000001: baseline_silence+=1
			else: baseline_silence=0
	print("Baseline without scheduling: final silence ",float(baseline_silence)/AudioServer.get_mix_rate(),"s; clip ",previous_playback.get_current_clip_index(),"; playing ",previous_playback.is_playing())
	check(baseline_silence>AudioServer.get_mix_rate(),"Baseline must reproduce an exhausted transition queue")
	previous_playback.stop()
	# Exercise the actual four imported files and transition graph without a
	# single main-thread scheduling call for more than one complete round.
	var playback: AudioStreamPlaybackInteractive=music.stream.instantiate_playback()
	playback.start()
	var rate := AudioServer.get_mix_rate()
	var mixed := 0
	var silent := 0
	var longest := 0
	var clips: Array[int]=[]
	var last := -1
	while mixed<rate*170:
		var frames := playback.mix_audio(1.0,1024)
		check(frames.size()==1024,"Native continuation returned a short buffer")
		var clip := playback.get_current_clip_index()
		check(clip>=0,"Music stopped without a scheduling frame")
		if clip!=last:
			clips.append(clip)
			last=clip
		for frame in frames:
			if frame.length_squared()<0.000000001: silent+=1
			else: silent=0
			longest=maxi(longest,silent)
		mixed+=frames.size()
	check(clips.size()>=5,"Native chain must cross the end of the fourth file")
	check(longest<rate/10,"Unexpected silence in native transitions")
	playback.stop()
	# Explicit stop does not emit finished: it must recover on the next frame.
	var recoveries: int=music.recovery_count
	music._process(1.0/60.0)
	check(music.player.playing,"Stopped player did not restart")
	check(music.recovery_count==recoveries+1,"Recovery should happen exactly once")
	settings.apply_volume("Music",0.0)
	music._process(1.0/60.0)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")),"Recovery must preserve user mute")
	paused=true
	music.set_process(true)
	await create_timer(0.2,true).timeout
	check(music.player.playing,"Simulation pause interrupted the music")
	check(music.recovery_count==recoveries+1,"Muted music must not trigger restart loops")
	paused=false
	print("Music resilience: ",checks," checks, ",failures," failures; native clips ",clips,"; longest silence ",float(longest)/rate,"s")
	quit(0 if failures==0 else 1)

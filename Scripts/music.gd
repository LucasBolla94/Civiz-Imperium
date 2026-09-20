extends Node
## One persistent player. Native end-to-start transitions run on the audio thread.
var player := AudioStreamPlayer.new()
var stream := AudioStreamInteractive.new()
var bag: Array[int]=[]
var previous := -1
var current := -1
var queued := -1
var history: Array[int]=[]
var inactive_seconds := 0.0
var recovery_count := 0

func next_track() -> int:
	if bag.is_empty():
		bag.assign([0,1,2,3])
		bag.shuffle()
		if bag[0]==previous:
			var index := randi_range(1,3)
			var first := bag[0]
			bag[0]=bag[index]
			bag[index]=first
	previous=bag.pop_front()
	return previous

func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	if OS.get_environment("CIVIZ_SILENT_TEST")=="1": AudioServer.set_bus_mute(0,true)
	stream.clip_count=4
	for i in 4:
		stream.set_clip_name(i,"Ambience %02d"%(i+1))
		stream.set_clip_stream(i,load("res://Assets/Musics/Ambience/%02d.ogg"%(i+1)))
		# The audio thread must always have a successor, even while the main
		# thread is loading an island or suspended by the window manager.
		stream.set_clip_auto_advance(i,AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
		stream.set_clip_auto_advance_next_clip(i,(i+1)%4)
	stream.add_transition(AudioStreamInteractive.CLIP_ANY,AudioStreamInteractive.CLIP_ANY,AudioStreamInteractive.TRANSITION_FROM_TIME_END,AudioStreamInteractive.TRANSITION_TO_TIME_START,AudioStreamInteractive.FADE_DISABLED,0)
	stream.initial_clip=next_track()
	player.bus="Music"
	player.stream=stream
	add_child(player)
	player.finished.connect(resume_after_interruption)
	player.play()

func resume_after_interruption() -> void:
	# Normally the queued native transition never finishes the player. Recover if
	# a suspended main thread missed an entire clip or playback was interrupted.
	stream.initial_clip=next_track()
	current=-1
	queued=-1
	inactive_seconds=0.0
	recovery_count+=1
	player.play()

func _process(delta: float) -> void:
	# stop() does not emit finished; a stopped interactive stream can also
	# retain its playback object. Check both instead of waiting indefinitely.
	if not player.playing or not player.has_stream_playback():
		resume_after_interruption()
		return
	var playback := player.get_stream_playback() as AudioStreamPlaybackInteractive
	var clip := playback.get_current_clip_index()
	if clip<0:
		inactive_seconds+=delta
		if inactive_seconds>=0.25: resume_after_interruption()
		return
	inactive_seconds=0.0
	if clip>=0 and clip!=current:
		current=clip
		history.append(clip)
		if history.size()>32: history.pop_front()
		queued=next_track()
		# Native fallback may have advanced several clips during a long stall.
		if queued==clip: queued=next_track()
		playback.switch_to_clip(queued)

func _exit_tree() -> void:
	player.stop()
	player.stream=null
	stream=null

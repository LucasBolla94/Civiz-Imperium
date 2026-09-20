extends "res://Tests/test_v005.gd"
func run() -> void:
	var slots=root.get_node("IslandSaves")
	slots.directory="user://test-v006-recovery-"+slots.token()
	slots.open_catalog()
	fresh()
	check(slots.begin_new(0,"Recovery") and game.saves.save_file(),"create recovery fixture")
	game.base.stored.wood=43
	check(game.saves.save_file(),"second revision stored")
	var old: Dictionary=slots.read_record(slots.catalog_path()+".bak")
	var corrupt := FileAccess.open(slots.catalog_path(),FileAccess.WRITE)
	corrupt.store_string("interrupted")
	corrupt.close()
	slots.open_catalog()
	check(slots.writable and slots.catalog==old and slots.island(0).data.buildings[0].stored.wood==20,"damaged catalog recovers known-good revision")
	check(slots.activate(0) and game.saves.load_file(),"recovered island remains playable")
	game.base.stored.wood=57
	check(game.saves.save_file() and slots.island(0).data.buildings[0].stored.wood==57,"save after recovery")
	var legacy := "res://Tests/user_diagnostic.save"
	if FileAccess.file_exists(legacy):
		var hash_before := FileAccess.get_sha256(legacy)
		check(slots.migrate(legacy),"migrate existing user diagnostic COPY")
		check(FileAccess.get_sha256(legacy)==hash_before,"diagnostic copy unchanged")
		check(slots.activate(1) and game.saves.load_file(),"imported actual progress loads")
	var broken: Dictionary=game.saves.snapshot()
	broken.land=[null]
	check(not game.saves.valid(broken),"malformed land rejected without restore")
	broken=game.saves.snapshot()
	broken.workers[0].person={}
	check(not game.saves.valid(broken),"malformed resident rejected")
	var settings=root.get_node("AppSettings")
	settings.set_volume("Music",0.24)
	settings.set_volume("Effects",0.62)
	await process_frame
	await process_frame
	var old_mode: int=root.mode
	var old_size: Vector2i=root.size
	settings.begin_video(Vector2i(960,540),not settings.fullscreen)
	paused=true
	var start := Time.get_ticks_msec()
	while Time.get_ticks_msec()-start<15200: await process_frame
	paused=false
	print("Video timeout observed: ",Time.get_ticks_msec()-start,"ms; trial=",settings.trial,"; remaining=",settings.remaining,"; mode=",root.mode,"/",old_mode,"; size=",root.size,"/",old_size)
	check(Time.get_ticks_msec()-start>=15000 and not settings.trial,"real fifteen-second timeout while entire tree paused")
	check(root.mode==old_mode and root.size==old_size,"actual window size and mode restored")
	var duplicate_settings=load("res://Scripts/app_settings.gd").new()
	root.add_child(duplicate_settings)
	check(is_equal_approx(duplicate_settings.music,0.24) and is_equal_approx(duplicate_settings.effects,0.62),"volumes restored by fresh settings instance")
	duplicate_settings.queue_free()
	finish()

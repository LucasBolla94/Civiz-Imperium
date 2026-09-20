extends "res://Tests/test_v005.gd"
var slots
var ids: Array[String]=[]
var images: Array[PackedByteArray]=[]

func run() -> void:
	slots=root.get_node("IslandSaves")
	slots.directory="user://test-v006-"+slots.token()
	slots.open_catalog()
	check(slots.valid_name("  Ilha da Madeira  ") and not slots.valid_name(" ") and not slots.valid_name("a/b"),"island name validation")
	for i in 5:
		fresh()
		game.village_level=1+i%3
		game.base.stored.wood=20+i*11
		for extra in i: game.spawn_worker("idle",game.base,game.cell_center(Vector2i(60+extra,30+i)))
		game.add_building("house",Vector2i(43+i*4,36),true)
		check(slots.begin_new(i,"Ilha %d"%i),"reserve independent island")
		check(game.saves.save_file(),"save active island")
		var record: Dictionary=slots.island(i)
		check(not record.is_empty(),"read verified island")
		if record.is_empty(): finish(); return
		ids.append(record.id)
		images.append(record.thumbnail)
		check(record.population==3+i and record.level==1+i%3,"metadata same revision")
		check(i==0 or images[i]!=images[i-1],"thumbnail represents different island")
	check(not slots.begin_new(0,"Overwrite"),"full slots cannot overwrite")
	for i in 5:
		check(slots.activate(i) and game.saves.load_file(),"load each independent island")
		check(game.workers.size()==3+i and game.village_level==1+i%3 and game.base.stored.wood==20+i*11,"isolated progress restored")
	check(slots.activate(2),"activate autosave target")
	game.saves.load_file()
	game.base.stored.wood=117
	game.saves.tick(121)
	check(slots.island(2).data.buildings[0].stored.wood==117 and slots.island(1).data.buildings[0].stored.wood==31,"autosave targets only active island")
	var before: Dictionary=slots.catalog.duplicate(true)
	slots.fail_writes=true
	game.base.stored.wood=999
	check(not game.saves.save_file() and slots.catalog==before and slots.island(2).data.buildings[0].stored.wood==117,"failed write preserves prior revision")
	check(not slots.delete_island(ids[2]) and slots.catalog==before,"failed deletion preserves island")
	slots.fail_writes=false
	slots.fail_catalog_write=true
	check(not game.saves.save_file() and slots.catalog==before and slots.island(2).data.buildings[0].stored.wood==117,"catalog publication failure preserves previous committed state")
	slots.fail_catalog_write=false
	check(slots.delete_island(ids[2]),"delete selected island")
	check(slots.catalog.slots[2].is_empty() and slots.island(1).id==ids[1],"delete preserves neighbors")
	fresh()
	check(slots.begin_new(2,"Replacement") and game.saves.save_file() and slots.island(2).id!=ids[2],"new island gets new stable ID")
	var legacy: String = slots.directory.path_join("legacy.save")
	check(game.saves.save_file(legacy),"legacy test copy saved")
	var original := FileAccess.get_file_as_bytes(legacy)
	check(not slots.migrate(legacy) and not slots.catalog.migrated,"full slots defer migration")
	slots.delete_island(ids[0])
	check(slots.migrate(legacy) and slots.catalog.migrated,"import after freeing slot")
	var imported: String=slots.island(0).id
	check(FileAccess.get_file_as_bytes(legacy)==original,"original untouched")
	slots.open_catalog()
	check(slots.migrate(legacy) and slots.island(0).id==imported,"migration idempotent across reopen")
	check(slots.delete_island(imported),"delete imported island")
	slots.open_catalog()
	check(slots.migrate(legacy) and slots.catalog.slots[0].is_empty(),"deleted import never reappears")
	var previous_directory: String=slots.directory
	slots.directory="user://test-v006-corrupt-"+slots.token()
	slots.open_catalog()
	var corrupt: String = slots.directory.path_join("legacy.save")
	var file := FileAccess.open(corrupt,FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(not slots.migrate(corrupt) and not slots.catalog.migrated and FileAccess.file_exists(corrupt),"corrupt import preserved")
	slots.fail_writes=true
	check(not slots.migrate(legacy) and not slots.catalog.migrated,"failed migration retry remains available")
	slots.fail_writes=false
	check(slots.migrate(legacy),"retry migration succeeds")
	slots.directory=previous_directory
	slots.open_catalog()
	var settings=root.get_node("AppSettings")
	settings.set_volume("Music",0)
	settings.set_volume("Effects",0.73)
	check(AudioServer.is_bus_mute(AudioServer.get_bus_index("Music")) and not AudioServer.is_bus_mute(AudioServer.get_bus_index("Effects")),"independent audio buses")
	var confirmed_resolution: Vector2i=settings.resolution
	var confirmed_mode: bool=settings.fullscreen
	settings.begin_video(Vector2i(960,540),not confirmed_mode)
	settings.set_volume("Music",0.31)
	var config := ConfigFile.new()
	config.load(settings.PATH)
	check(config.get_value("video","resolution")==confirmed_resolution and config.get_value("video","fullscreen")==confirmed_mode,"video trial never persisted by volume change")
	settings.deadline_msec=Time.get_ticks_msec()-1
	settings._process(0.1)
	check(not settings.trial and settings.resolution==confirmed_resolution and settings.fullscreen==confirmed_mode,"timeout restores video pair")
	settings.begin_video(Vector2i(960,540),not confirmed_mode)
	settings.confirm_video()
	config.load(settings.PATH)
	check(config.get_value("video","resolution")==Vector2i(960,540) and config.get_value("video","fullscreen")==not confirmed_mode,"confirmed video persists")
	settings.begin_video(Vector2i(1280,720),confirmed_mode)
	settings.revert_video()
	check(settings.resolution==Vector2i(960,540),"explicit revert preserves confirmed preferences")
	var music=root.get_node("Music")
	music.bag.clear()
	music.previous=-1
	var last := -1
	for round_index in 100:
		var seen := {}
		for i in 4:
			var track: int=music.next_track()
			check(not seen.has(track) and (i!=0 or track!=last),"shuffle round uniqueness and boundary")
			seen[track]=true
			last=track
	check(music.get_child_count()==1 and music.player.bus=="Music","one persistent music player")
	finish()

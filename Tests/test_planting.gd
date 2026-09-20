extends "res://Tests/test_v003.gd"
func run() -> void:
	fresh()
	var job = game.place_job("plant", Vector2i(43,24))
	check(job != null, "Fresh colony accepts an open planting site")
	if job != null:
		tick(90)
		check(job.completed and game.planted_count == 1, "Fresh colony delivers seeds and finishes planting")
		print("Plant state: ",job.completed," materials: ",job.materials.delivered)
		for worker in game.workers: print(worker.kind," ",worker.state," ",worker.status)
	finish()

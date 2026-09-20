extends RefCounted
var meal_retry := 0.0
var wake_grace := 0.0

## Returns true when survival/rest owns this frame instead of the work state machine.
func tick(worker, delta: float) -> bool:
	var p = worker.person
	var data = worker.game.DATA
	wake_grace = maxf(0, wake_grace - delta)
	p.nutrition = maxf(0, p.nutrition - data.HUNGER_DRAIN * delta)
	meal_retry -= delta
	if p.nutrition <= data.MEAL_THRESHOLD and meal_retry <= 0:
		worker.game.settlement.feed(worker)
		meal_retry = 3.0
	if p.nutrition <= 0:
		p.starvation += delta
		if p.starvation >= data.STARVATION_SECONDS:
			worker.game.settlement.remove(worker)
			return true
	else:
		p.starvation = maxf(0, p.starvation - delta * 2)
	if worker.state == "resting":
		p.energy = minf(100, p.energy + data.REST_RECOVERY * delta)
		worker.status = "Descansando em " + worker.residence.display_name()
		if p.energy >= data.REST_FINISH: worker.wake(false)
		return true
	if worker.state == "to_rest" or is_instance_valid(worker.move_destination): return false
	if p.energy <= data.REST_THRESHOLD and wake_grace <= 0 and not worker.can_finish_delivery():
		if worker.go_rest(): return false
		worker.interrupt_task()
		return true
	if p.nutrition <= data.HUNGER_STOP:
		worker.interrupt_task()
		worker.status = "Preciso comer — fraco demais para trabalhar"
		return true
	return false

func productivity(worker) -> float:
	return 0.5 if worker.person.nutrition < worker.game.DATA.HUNGER_SLOW else 1.0



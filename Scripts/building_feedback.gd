extends RefCounted
const BUBBLES = preload("res://Assets/UI/speech bubble, emojis, reaction.png")

static func notice(text: String, action := "building") -> Dictionary:
	return {"text":text,"action":action}

static func diagnose(building) -> Dictionary:
	var game = building.game
	if building.demolition_requested: return notice(building.demolition_status())
	if game.route_to_cell(game.cell_center(game.base.door()),building.door()).is_empty():
		return notice("Entrada sem acesso; libere o caminho.")
	if building.needs_work():
		if not building.materials.ready(): return notice("Obra aguardando materiais e transporte.")
		if game.activity_count("builder") == 0: return notice("Falta construtor.","inhabitants")
		return {}
	if building.capacity() > 0 and game.logistics.storage_free(building) <= 0:
		return notice("Depósito cheio; libere espaço ou melhore o armazenamento.")
	if building.kind not in ["food","wood","stone","workshop"]: return {}
	var activity: String = building.kind
	var workers: Array = game.workers.filter(func(w): return w.assignment == activity and (activity != "workshop" or w.assigned_home == building))
	if activity == "workshop":
		if building.crafting == "" and building.tool_demand("axe") == 0 and building.tool_demand("pickaxe") == 0: return {}
		if building.crafting == "" and building.next_recipe() == "": return notice("Oficina aguardando madeira / pedra.")
	else:
		var resource: String = game.DATA.resource_for_activity(activity)
		if game.automation.total_committed(resource) >= game.automation.production_limit(resource):
			return notice("Meta de estoque atendida; produção pausada.","policies")
		var sources: Array = (game.sources + game.gardens).filter(func(s): return s.harvestable(activity))
		var work: bool = (game.jobs + game.gardens).any(func(j): return j.activity == activity and j.needs_work())
		if sources.is_empty() and not work: return notice("Sem fonte disponível; aguarde o ciclo ou prepare uma nova fonte.")
		if not sources.is_empty() and not sources.any(func(s): return not game.route_to_source(game.cell_center(building.door()),s).is_empty()):
			return notice("Fonte sem acesso; libere o caminho.")
		if game.logistics.storage_for(game.cell_center(building.door()),resource) == null:
			return notice("Depósitos sem espaço acessível para esta coleta.")
	if workers.is_empty(): return notice("Falta trabalhador.","inhabitants")
	if workers.all(func(w): return w.state in ["resting","to_rest"]): return notice("Trabalhadores descansando.","inhabitants")
	if game.DATA.TOOLS.has(activity) and workers.all(func(w): return not w.has_tool()):
		return notice("Sem ferramenta; trabalho mais lento.","tools")
	return {}

static func next_level(building) -> String:
	var game = building.game
	if building.kind == "base":
		if game.village_level >= 3: return "Nível máximo."
		return "Próximo nível: transportadores e carga de 5 → 7." if game.village_level == 1 else "Próximo nível: nível 3 da vila; sem bônus adicional de produção."
	if building.level >= game.DATA.MAX_BUILDING_LEVEL: return "Nível máximo."
	if building.kind == "house":
		return "Próximo nível: vagas %d → %d." % [building.housing_capacity(),building.housing_capacity()+game.DATA.HOUSE_UPGRADE_CAPACITY]
	var text := "Próximo nível: armazenamento %d → %d." % [building.capacity(),building.capacity()+game.DATA.STORAGE_UPGRADE_CAPACITY]
	if building.level == 1:
		match building.kind:
			"food": text += " Libera criar hortas."
			"stone": text += " Libera investigar terreno e abrir pedreiras."
			"workshop": text += " Libera reposição por metas."
	elif building.kind == "workshop": text += " Reserva automática: 1 ferramenta a cada 2 trabalhadores da profissão, arredondando para cima."
	return text

extends VBoxContainer
## One shared allocation state drives both central and per-building controls.
const SKIN = preload("res://Scripts/menu_theme.gd")
const ACTIVITIES = ["builder","food","wood","stone","gold_mining","smelter","workshop","carrier"]
var game
var controls := {}
var sections := {}
var expanded := {}
var building_rows := {}

func action(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text=text
	button.custom_minimum_size=Vector2(34,30)
	button.pressed.connect(callback)
	return button

func _ready() -> void:
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",8)
	for activity in ACTIVITIES:
		var section := VBoxContainer.new()
		add_child(section)
		var row := HBoxContainer.new()
		section.add_child(row)
		var fold := action("▸",func(): toggle(activity))
		row.add_child(fold)
		var title := Label.new()
		title.text=game.DATA.ACTIVITIES[activity].name
		title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		title.add_theme_font_override("font",SKIN.BOLD)
		row.add_child(title)
		var minus := action("−",func(): game.change_allocation(activity,-1))
		row.add_child(minus)
		var amount := Label.new()
		amount.custom_minimum_size.x=36
		amount.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		row.add_child(amount)
		var plus := action("+",func(): game.change_allocation(activity,1))
		row.add_child(plus)
		var state := Label.new()
		state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		state.custom_minimum_size.y=38
		state.add_theme_font_size_override("font_size",14)
		state.add_theme_color_override("font_color",SKIN.MUTED)
		section.add_child(state)
		var buildings := VBoxContainer.new()
		buildings.hide()
		section.add_child(buildings)
		controls[activity]={"minus":minus,"plus":plus,"amount":amount}
		sections[activity]={"fold":fold,"state":state,"buildings":buildings}
	refresh()

func toggle(activity: String) -> void:
	expanded[activity]=not expanded.get(activity,false)
	sections[activity].buildings.visible=expanded[activity]
	sections[activity].fold.text="▾" if expanded[activity] else "▸"
	refresh()

func reveal(activity: String) -> void:
	if sections.has(activity) and not expanded.get(activity,false): toggle(activity)

func refresh() -> void:
	for activity in sections:
		var team: Array=game.workers.filter(func(w): return w.assignment==activity)
		var working := 0
		var travel := 0
		var resting := 0
		var waiting := 0
		var pending := 0
		var reason := ""
		for worker in team:
			if worker.assignment!=worker.kind: pending+=1
			elif worker.state in ["resting","to_rest"]: resting+=1
			elif not worker.path.is_empty(): travel+=1
			elif worker.state in ["building","harvesting","crafting"]: working+=1
			else: waiting+=1; reason=worker.status
		var text := "%d trabalhando · %d a caminho · %d descansando · %d aguardando"%[working,travel,resting,waiting]
		if pending>0: text+=" · %d mudanças pendentes"%pending
		if waiting>0 and not reason.is_empty(): text+="\n"+reason
		var targets: Array=game.buildings.filter(func(b): return game.workplace_capacity(b,activity)>0)
		if activity=="carrier" and game.village_level<2: targets.clear()
		if targets.is_empty(): text="Conclua um posto acessível para esta atividade."
		if activity in ["gold_mining","smelter"]:
			var capacity := 0
			for b in targets: capacity+=game.workplace_capacity(b,activity)
			text="%d/%d vagas ocupadas · "%[team.size(),capacity]+text
		sections[activity].state.text=text
		if not expanded.get(activity,false): continue
		var ids: Array=targets.map(func(b): return b.entity_id)
		var group: VBoxContainer=sections[activity].buildings
		if group.get_meta("ids",[])!=ids:
			for child in group.get_children(): child.free()
			group.set_meta("ids",ids)
			building_rows[activity]={}
			for building in targets:
				var row := HBoxContainer.new()
				group.add_child(row)
				var title := Label.new()
				title.text="    "+building.display_name()
				title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
				row.add_child(title)
				var minus := action("−",func(): game.change_allocation(activity,-1,building))
				row.add_child(minus)
				var count := Label.new()
				count.custom_minimum_size.x=36
				count.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
				row.add_child(count)
				var plus := action("+",func(): game.change_allocation(activity,1,building))
				row.add_child(plus)
				building_rows[activity][building.entity_id]={"plus":plus,"minus":minus,"count":count}
		for building in targets:
			var item: Dictionary=building_rows[activity][building.entity_id]
			var count: int=game.workplace_count(building,activity)
			item.count.text=str(count)
			item.minus.disabled=count==0
			item.plus.disabled=count>=game.workplace_capacity(building,activity) or not game.workers.any(func(w): return w.assignment=="idle" and not game.route_to_cell(w.position,building.door()).is_empty())

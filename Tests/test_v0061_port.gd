extends "res://Tests/test_v003.gd"
const PORT = preload("res://Scripts/port_layout.gd")
const POSITIONS = [Vector2i(44,37),Vector2i(39,27),Vector2i(57,20),Vector2i(69,23)]

func provision() -> void:
	game.village_level=3
	game.base.stored.wood=100
	game.base.stored.stone=100
	game.base.stored.gold_bar=10
	stop_workers()

func run() -> void:
	root.size=Vector2i(1280,720)
	for facing in 4:
		fresh()
		provision()
		game.placement_orientation=facing
		var origin: Vector2i=POSITIONS[facing]
		var mask := PORT.layout(origin,facing)
		check(mask.land.size()==10 and mask.water.size()==15 and mask.reserved.size()==31,"Port masks preserve the 10/15 coast contract")
		check(game.can_place("trading_port",origin),"Orientation %d fits real coast: %s"%[facing,game.placement_reason])
		if not game.placement_reason.is_empty(): continue
		var route: Array[Vector2i]=game.port_layout.water_route(origin,facing)
		check(not route.is_empty() and route[0]==mask.dock,"Water route starts at the dock")
		check(PORT.is_edge(route[-1],game.get_node("Water/Water").get_used_rect()),"Boat route reaches actual map edge")
		for i in range(1,route.size()):
			check((route[i]-route[i-1]).length_squared()==1 and game.land.get_cell_source_id(route[i])<0,"Continuous cardinal water-only route")
		var port=game.place_building("trading_port",origin)
		check(port!=null and port.orientation==facing and port.door()==mask.loading,"Placed port uses the rotated loading cell")
		check(port.materials.required=={"wood":40,"stone":30,"gold_bar":5},"Port exact construction cost")
		check(game.is_walkable(port.door()) and not game.route_to_cell(game.cell_center(game.base.door()),port.door()).is_empty(),"Loading aisle stays reachable")
		check(not game.can_place("trading_port",origin) and "apenas um" in game.placement_reason,"Second port forbidden during construction")
		for cell in mask.water+mask.approach:
			check("porto" in game.expansion_brush.inspect(cell,1).reason,"Expansion cannot occupy port water or approach")
		check(not game.can_place("house",mask.loading),"Construction cannot occupy the walkable port aisle")
		var saved: Dictionary=game.saves.snapshot()
		check(game.saves.valid(saved),"Port construction snapshot is valid")
		game.saves.restore(saved)
		port=game.buildings[-1]
		check(port.orientation==facing and port.door()==mask.loading,"Restore preserves orientation and path")
		check(port.sprite.texture.get_size()==Vector2(80,96),"Each port orientation uses exact native sprite dimensions")
		port.materials.delivered=port.materials.required.duplicate()
		port.build(29.9)
		check(not port.completed,"Port needs thirty work seconds")
		port.build(0.1)
		check(port.completed and game.port_layout.access_reason(port).is_empty(),"Completed port has both land and sea access")
		port.stored.gold_bar=2
		check(game.logistics.available(port,"gold_bar")==0 and not port.accepts("gold_bar"),"Receiving goods cannot pay ordinary village costs")
		check(port.request_demolition(),"Port accepts a demolition request")
		check(not game.can_place("trading_port",origin),"Demolishing port still counts toward one-port limit")
		check(port.cancel_demolition(),"Demolition can be cancelled before work starts")
		port.request_demolition()
		port.build(10)
		check(not game.buildings.has(port),"Ten work seconds remove the empty port")
		check(game.logistics.piles.all(func(p): return game.land.get_cell_source_id(p.cell)>=0),"Salvage is always on land in all four orientations")
		check(game.can_place("trading_port",origin),"Actual removal allows rebuilding the port")
		var corrupt: Dictionary=saved.duplicate(true)
		corrupt.buildings[-1].orientation=4
		check(not game.saves.valid(corrupt),"Invalid orientation rejected")
		corrupt=saved.duplicate(true)
		corrupt.buildings.append(saved.buildings[-1].duplicate(true))
		check(not game.saves.valid(corrupt),"Duplicate saved port rejected")
	fresh()
	provision()
	game.village_level=2
	check(not game.can_place("trading_port",POSITIONS[0]),"Port requires base level three")
	game.village_level=3
	var origin: Vector2i=POSITIONS[0]
	var mask := PORT.layout(origin,0)
	game.land.erase_cell(mask.land[0])
	game.rebuild_navigation()
	var inspection: Dictionary=game.port_layout.inspect(origin,0)
	check(not inspection.reason.is_empty() and not inspection.cells[mask.land[0]],"Irregular shore highlights the wrong cell")
	fresh()
	provision()
	# A genuine inland lake still has water tiles, but no connected route to sea.
	for y in range(33,46):
		for x in range(42,54): game.land.set_cell(Vector2i(x,y),game.ground_source,game.ground_atlas)
	origin=Vector2i(44,36)
	mask=PORT.layout(origin,0)
	for cell in mask.water+mask.approach: game.land.erase_cell(cell)
	game.rebuild_navigation()
	inspection=game.port_layout.inspect(origin,0)
	check("lago" in inspection.reason,"An enclosed lake is rejected: "+inspection.reason)
	fresh()
	provision()
	game.begin_placement("trading_port")
	for i in 4: game.rotate_port()
	check(game.placement_orientation==0,"Four rotations restore original orientation")
	game.hud.refresh()
	check(game.hud.rotate_port_button.visible,"Placement exposes an accessible rotate button")
	# The editable art metadata must describe exactly the runtime masks.
	var metadata=JSON.parse_string(FileAccess.get_file_as_string("res://Assets/Buildings/Port/trading_port_layout.json"))
	check(metadata.size==[80.0,96.0] and metadata.grid_origin==[0.0,16.0],"Art metadata exposes native size and grid origin")
	for facing in 4:
		var reference: Dictionary=metadata.orientations[PORT.DIRECTIONS[facing]]
		mask=PORT.layout(Vector2i.ZERO,facing)
		for pair in [["land_cells","land"],["water_cells","water"],["approach_cells","approach"]]:
			var cells: Array[Vector2i]=[]
			for coordinates in reference[pair[0]]: cells.append(Vector2i(coordinates[0],coordinates[1]))
			check(cells==mask[pair[1]],"Exported art mask matches runtime "+PORT.DIRECTIONS[facing]+" "+pair[0])
		check(Vector2i(reference.loading_cell[0],reference.loading_cell[1])==mask.loading,"Visible loading point agrees with navigation")
		var image: Image=game.DATA.port_texture(facing).get_image()
		check(image.get_size()==Vector2i(80,96) and image.detect_alpha()!=Image.ALPHA_NONE,"Native RGBA port has real transparent pixels")
	fresh()
	provision()
	var site=game.place_building("trading_port",POSITIONS[0])
	game.workers[0].assign_to("builder",game.base)
	game.workers[1].assign_to("carrier",game.base)
	var before: Dictionary=game.stock.duplicate()
	for i in 3000:
		if site.completed: break
		tick(0.1)
	check(site.completed and site.materials.ready(),"Real workers supply all port materials and finish construction")
	check(game.stock.gold_bar==before.gold_bar-5 and game.stock.wood==before.wood-40 and game.stock.stone==before.stone-30,"Construction physically consumes exactly the approved materials")
	check(game.merchant.visit_id==0,"No instant merchant on construction completion")
	finish()

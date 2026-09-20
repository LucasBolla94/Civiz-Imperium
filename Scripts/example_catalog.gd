extends RefCounted
## Reads painted examples directly; no hardcoded sprite-sheet crops or world-node dependencies.
static var entries: Dictionary = {}

static func groups(cells: Array[Vector2i]) -> Array:
	var unseen := {}
	for cell in cells: unseen[cell] = true
	var result := []
	while not unseen.is_empty():
		var group: Array[Vector2i] = []
		var pending: Array[Vector2i] = [unseen.keys()[0]]
		unseen.erase(pending[0])
		while not pending.is_empty():
			var cell: Vector2i = pending.pop_back()
			group.append(cell)
			for offset in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
				var next: Vector2i = cell + offset
				if unseen.has(next):
					unseen.erase(next)
					pending.append(next)
		result.append(group)
	return result

static func register_layer(key: String, layer: TileMapLayer, cells: Array[Vector2i]) -> void:
	var bounds := Rect2i(cells[0], Vector2i.ONE)
	for cell in cells: bounds = bounds.merge(Rect2i(cell, Vector2i.ONE))
	var image := Image.create(bounds.size.x * 16, bounds.size.y * 16, false, Image.FORMAT_RGBA8)
	var tiles := []
	var images := {}
	for cell in cells:
		var source_id := layer.get_cell_source_id(cell)
		var source: TileSetAtlasSource = layer.tile_set.get_source(source_id)
		var atlas := layer.get_cell_atlas_coords(cell)
		if not images.has(source_id):
			var source_image := source.texture.get_image()
			if source_image.is_compressed(): source_image.decompress()
			source_image.convert(Image.FORMAT_RGBA8)
			images[source_id] = source_image
		image.blit_rect(images[source_id], source.get_tile_texture_region(atlas), (cell - bounds.position) * 16)
		tiles.append({"cell": cell - bounds.position, "source": source_id, "atlas": atlas, "alternative": layer.get_cell_alternative_tile(cell)})
	entries[key] = {"size": bounds.size, "texture": ImageTexture.create_from_image(image), "tiles": tiles, "tile_set": layer.tile_set}

static func ensure_loaded() -> void:
	if not entries.is_empty(): return
	var buildings = preload("res://Scenes/buildings_exemples.tscn").instantiate()
	for layer in buildings.get_children():
		if layer is TileMapLayer and str(layer.name).begins_with("Building-"):
			register_layer(str(layer.name), layer, layer.get_used_cells())
	buildings.free()
	var objects = preload("res://Scenes/Objects_Exemple.tscn").instantiate()
	var stone: TileMapLayer = objects.get_node("Stone")
	register_layer("Stone", stone, stone.get_used_cells())
	var trees: TileMapLayer = objects.get_node("Life_tree")
	var index := 1
	# Adjacent examples can touch on the canvas: identify stages by atlas bands,
	# not flood fill, otherwise the young and adult trees become one giant sprite.
	var tree_groups := []
	for band in [Vector2i(4,4),Vector2i(6,8),Vector2i(9,11),Vector2i(12,14),Vector2i(18,20),Vector2i(21,23),Vector2i(1,1)]:
		var stage_cells: Array[Vector2i] = []
		for cell in trees.get_used_cells():
			var atlas := trees.get_cell_atlas_coords(cell)
			if atlas.x >= band.x and atlas.x <= band.y: stage_cells.append(cell)
		tree_groups.append(stage_cells)
	for group in tree_groups:
		var key := "Tree-%d" % index
		register_layer(key, trees, group)
		for cell in group:
			if trees.get_cell_atlas_coords(cell) == Vector2i(18, 1):
				entries["Fruit"] = entries[key]
		index += 1
	objects.free()

static func entry(key: String) -> Dictionary:
	ensure_loaded()
	return entries[key]

static func resource_layer(key: String, origin: Vector2i) -> TileMapLayer:
	var definition := entry(key)
	var layer := TileMapLayer.new()
	layer.tile_set = definition.tile_set
	for tile in definition.tiles:
		layer.set_cell(origin + tile.cell, tile.source, tile.atlas, tile.alternative)
	return layer

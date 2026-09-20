extends RefCounted
## Renders the saved state with the game's textures, without a HUD or simulation.
const DATA = preload("res://Scripts/game_data.gd")
const VISUAL = preload("res://Scripts/resident_visual.gd")
static var tile_set: TileSet
static var texture_cache := {}

static func pixels(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		return pixels(texture.atlas).get_region(texture.region)
	var key := texture.get_instance_id()
	if not texture_cache.has(key):
		var image := texture.get_image()
		if image.is_compressed(): image.decompress()
		image.convert(Image.FORMAT_RGBA8)
		texture_cache[key] = image
	return texture_cache[key]

static func stamp(canvas: Image, texture: Texture2D, point: Vector2i, size := Vector2i.ZERO) -> void:
	var image := pixels(texture)
	if size != Vector2i.ZERO and size != image.get_size():
		image = image.duplicate()
		image.resize(size.x, size.y, Image.INTERPOLATE_NEAREST)
	canvas.blend_rect(image, Rect2i(Vector2i.ZERO, image.get_size()), point)

static func render(data: Dictionary) -> PackedByteArray:
	if tile_set == null:
		var world = preload("res://Scenes/world.tscn").instantiate()
		tile_set = world.get_node("TileMapLayer").tile_set
		world.free()
	var bounds := Rect2i(data.land[0][0], Vector2i.ONE)
	for tile in data.land: bounds = bounds.merge(Rect2i(tile[0], Vector2i.ONE))
	bounds = bounds.grow(2)
	# Bound memory for very large expansions, while preserving the entire island.
	var factor := minf(1.0, 2048.0 / maxf(bounds.size.x * 16, bounds.size.y * 16))
	var tile_pixels := maxi(1, floori(16 * factor))
	var canvas := Image.create(bounds.size.x * tile_pixels, bounds.size.y * tile_pixels, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("0095cd"))
	for tile in data.land:
		if not tile_set.has_source(tile[1]): continue
		var atlas := tile_set.get_source(tile[1]) as TileSetAtlasSource
		if atlas == null or not atlas.has_tile(tile[2]): continue
		var texture := AtlasTexture.new()
		texture.atlas = atlas.texture
		texture.region = atlas.get_tile_texture_region(tile[2])
		stamp(canvas, texture, (tile[0]-bounds.position)*tile_pixels, Vector2i.ONE*tile_pixels)
	# Gardens form the ground layer; residents and buildings follow in depth order.
	for garden in data.gardens:
		var point: Vector2i = (garden.origin-bounds.position)*tile_pixels
		var soil := DATA.atlas("res://Assets/Tileset/Tilled Soil and wet soil.png",Rect2(32,16,16,16))
		for y in 2:
			for x in 2:
				var cell := point+Vector2i(x,y)*tile_pixels
				stamp(canvas,soil,cell,Vector2i.ONE*tile_pixels)
				if garden.phase in ["growing","ripe"]:
					var frame := 6 if garden.phase=="ripe" else (1+mini(4,int(garden.age/12.0)))
					var crop := "res://Assets/Crops/Spring/Carrot.png" if x==y else "res://Assets/Crops/Spring/Cabbage.png"
					stamp(canvas,DATA.atlas(crop,Rect2(frame*16,0,16,16)),cell,Vector2i.ONE*tile_pixels)
		if garden.phase!="installing":
			var fence := DATA.atlas("res://Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png",Rect2(48,0,16,16))
			for offset in [Vector2i(0,-4),Vector2i(16,-4),Vector2i(16,24)]:
				stamp(canvas,fence,point+Vector2i(Vector2(offset)*tile_pixels/16.0),Vector2i.ONE*tile_pixels)
			var post := DATA.atlas("res://Assets/Objects/Exterior/Fence and Bridge/Fence Wood.png",Rect2(0,16,16,16))
			for offset in [Vector2i(-4,4),Vector2i(20,4),Vector2i(-4,20),Vector2i(20,20)]:
				stamp(canvas,post,point+Vector2i(Vector2(offset)*tile_pixels/16.0),Vector2i.ONE*tile_pixels)
	var objects: Array = []
	for b in data.buildings:
		var texture: Texture2D=DATA.building_texture(b.kind)
		var art_size := Vector2i(texture.get_size()) if b.kind in ["gold_mining","smelter"] else DATA.building_size(b.kind)*16
		var offset := Vector2i(-8,-32) if b.kind in ["gold_mining","smelter"] else Vector2i.ZERO
		if b.kind=="trading_port":
			texture=DATA.port_texture(b.get("orientation",0))
			art_size=Vector2i(80,96)
			offset=Vector2i(0,-16)
		objects.append({"p":Vector2(b.origin*16+offset),"t":texture,"s":art_size})
	for s in data.sources:
		if s.get("removed",false): continue
		var texture: Texture2D = DATA.timber_texture(s.stage) if s.get("is_timber",false) else DATA.CATALOG.entry("Tree-%d" % (s.stage+1) if s.is_tree else "Stone").texture
		if s.get("resource_kind","")=="gold_ore": texture=DATA.gold_deposit_texture(s.remaining==0)
		objects.append({"p":Vector2(s.origin*16),"t":texture,"s":Vector2i(texture.get_size())})
	for p in data.piles:
		objects.append({"p":Vector2(p.cell*16)+Vector2(0,-4),"t":DATA.resource_texture(p.resource,true),"s":Vector2i(16,16)})
	for w in data.workers:
		var visual = VISUAL.new()
		visual.configure(w.person.appearance_id)
		objects.append({"p":w.position-Vector2(16,32),"t":visual.sprite.sprite_frames.get_frame_texture("Idle",0),"s":Vector2i(32,32)})
		visual.free()
	objects.sort_custom(func(a,b): return a.p.y+a.s.y < b.p.y+b.s.y)
	for obj in objects:
		stamp(canvas,obj.t,Vector2i((obj.p-Vector2(bounds.position*16))*tile_pixels/16.0),Vector2i(Vector2(obj.s)*tile_pixels/16.0).max(Vector2i.ONE))
	var result := Image.create(256,144,false,Image.FORMAT_RGBA8)
	result.fill(Color("0095cd"))
	var scale := minf(256.0/canvas.get_width(),144.0/canvas.get_height())
	canvas.resize(maxi(1,roundi(canvas.get_width()*scale)),maxi(1,roundi(canvas.get_height()*scale)),Image.INTERPOLATE_NEAREST)
	result.blit_rect(canvas,Rect2i(Vector2i.ZERO,canvas.get_size()),(result.get_size()-canvas.get_size())/2)
	return result.save_png_to_buffer()

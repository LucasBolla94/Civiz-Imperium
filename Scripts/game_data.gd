extends RefCounted
const CATALOG = preload("res://Scripts/example_catalog.gd")
const ECONOMY = preload("res://Scripts/economy_data.gd")
## Catálogo e balanceamento da V0.0.3. Recursos alimentares possuem identidade própria.

const STARTING_STOCK = {"produce": 18, "stone": 45, "wood": 20, "axe": 2, "pickaxe": 2}
const WALK_SPEED = 46.0
const CARRY_CAPACITY = 5
const HARVEST_SECONDS = 0.8
const SOURCE_STOCK = {"produce": 50, "stone": 480, "wood": 30}
const TREE_SECONDS = [30.0, 40.0, 50.0, 60.0, 0.0, 0.0, 0.0]
const GARDEN_COST = {"wood": 10}
const GARDEN_BUILD_SECONDS = 10.0
const GARDEN_PLANT_SECONDS = 4.0
const GARDEN_GROW_SECONDS = 60.0
const GARDEN_YIELD = 15
const DEMOLITION_SECONDS = 10.0
const TREE_NAMES = ["Broto", "Muda", "Árvore jovem", "Árvore adulta", "Frutificação", "Envelhecendo", "Madeira: pronta para corte"]
const PLANT_COST = {"produce": 2}
## Árvore de madeira: espécie plantada que nunca frutifica. Cresce no mesmo tempo
## total da frutífera e entrega mais madeira; o lenhador planta e corta.
const TIMBER_SHEET = "res://Assets/Crops/Fruits Tree/Fall/Apple Tree.png"
const TIMBER_FRAME_SIZE = Vector2(32, 48)
# Quadros do sheet: semente, broto, muda, copa verde e copa madura (sem frutas).
const TIMBER_FRAMES = [0, 1, 2, 4, 5]
const TIMBER_SECONDS = [30.0, 40.0, 50.0, 60.0, 0.0]
const TIMBER_STOCK = 45
const TIMBER_NAMES = ["Semente plantada", "Broto", "Muda de madeira", "Árvore jovem", "Madeira: pronta para corte"]
const TIMBER_MATURE_STAGE = 4
const EXPAND_COST = {"stone": 10, "wood": 5}
const CONSTRUCTIBLE = ["house", "food", "stone", "wood", "workshop", "warehouse", "gold_mining", "smelter", "trading_port"]
const ACTIVITIES = {
	"builder": {"name": "Construção", "profession": "Construtor", "color": Color("e8be78")},
	"food": {"name": "Comida", "profession": "Coletor", "color": Color("a6d887")},
	"stone": {"name": "Pedra", "profession": "Mineiro", "color": Color("a6cbe4")},
	"wood": {"name": "Madeira", "profession": "Lenhador", "color": Color("bb8757")},
	"carrier": {"name": "Transporte", "profession": "Transportador", "color": Color("dcb9e8")},
	"workshop": {"name": "Oficina", "profession": "Artesão", "color": Color("dfae72")},
	"idle": {"name": "Livres", "profession": "Trabalhador", "color": Color("cccccc")},
	"gold_mining": {"name":"Mineração de ouro","profession":"Mineiro de ouro","color":Color("e7bd58")},
	"smelter": {"name":"Fundição","profession":"Fundidor","color":Color("e6a06a")},
}
const BUILDINGS = {
	"trading_port": {"name":"Porto comercial","short":"Porto","worker":"Transportador","description":"Entreposto na costa. Recebe comerciantes e até 200 unidades de carga; requer base nível 3.","cost":ECONOMY.PORT_COST,"build_seconds":ECONOMY.PORT_BUILD_SECONDS,"color":Color("71bdc4"),"example":"Building-1","texture":"res://Assets/Buildings/Port/trading_port_south.png"},
	"gold_mining": {"name":"Posto de mineração de ouro","short":"Ouro","worker":"Mineiro de ouro","description":"Até três mineiros. Entregam minério aqui; requer base nível 3.","cost":ECONOMY.GOLD_POST_COST,"build_seconds":ECONOMY.GOLD_POST_SECONDS,"color":Color("e7bd58"),"example":"Building-3","texture":"res://Assets/Buildings/Gold/gold_mining_post.png"},
	"smelter": {"name":"Fundição","short":"Fundição","worker":"Fundidor","description":"Duas bancadas: 5 minérios + 2 madeiras → 1 barra. Requer base nível 3.","cost":ECONOMY.SMELTER_COST,"build_seconds":ECONOMY.SMELTER_BUILD_SECONDS,"color":Color("e6a06a"),"example":"Building-5","texture":"res://Assets/Buildings/Gold/smelter.png"},
	"house": {"name": "Casa", "short": "Moradia", "worker": "Morador", "description": "Residência para quatro habitantes. Pode ser melhorada.", "cost": {"wood": 20, "stone": 10}, "build_seconds": 14.0, "color": Color("e6ba77"), "example": "Building-4"},
	"workshop": {"name": "Oficina de ferramentas", "short": "Oficina", "worker": "Artesão", "description": "Encomende ferramentas. Melhorias liberam metas e reserva automática.", "cost": {"wood": 15, "stone": 15}, "build_seconds": 16.0, "color": Color("d9a76c"), "example": "Building-5"},
	"warehouse": {"name": "Depósito geral", "short": "Depósito", "worker": "Transportador", "description": "Armazena até 200 unidades. Pode ser melhorado.", "cost": {"wood": 12, "stone": 10}, "build_seconds": 12.0, "color": Color("b78d68"), "example": "Building-1"},
	"wood": {
		"name": "Depósito de madeira", "short": "Madeira", "worker": "Lenhador",
		"description": "Lenhadores cortam árvores esgotadas ou marcadas com Cortar agora, e plantam árvores de madeira.",
		"cost": {"stone": 15}, "build_seconds": 10.0,
		"color": Color("bb8757"), "example": "Building-1",
	},
	"base": {
		"name": "Base principal", "short": "Base", "worker": "Trabalhador",
		"description": "Abrigo dos fundadores, reserva coletiva e expedições para atrair colonos.",
		"cost": {"stone": 20}, "build_seconds": 8.0,
		"color": Color("e8be78"), "example": "Building-6", "door_x": 3,
	},
	"food": {
		"name": "Depósito de Hortifruti", "short": "Comida", "worker": "Coletor de comida",
		"description": "Organiza a coleta de Hortifruti e armazena as entregas.",
		"cost": {"stone": 20}, "build_seconds": 8.0,
		"color": Color("a6d887"), "example": "Building-2",
	},
	"stone": {
		"name": "Depósito de pedra", "short": "Pedra", "worker": "Coletor de pedra",
		"description": "Armazena pedra. No nível 2, libera investigação e pedreiras.",
		"cost": {"stone": 25}, "build_seconds": 10.0,
		"color": Color("a6cbe4"), "example": "Building-3",
	},
}

static func building_texture(kind: String) -> Texture2D:
	if BUILDINGS[kind].has("texture") and ResourceLoader.exists(BUILDINGS[kind].texture): return load(BUILDINGS[kind].texture)
	return CATALOG.entry(BUILDINGS[kind].example).texture

static func port_texture(orientation: int) -> Texture2D:
	var path := "res://Assets/Buildings/Port/trading_port_%s.png"%preload("res://Scripts/port_layout.gd").DIRECTIONS[posmod(orientation,4)]
	return load(path) if ResourceLoader.exists(path) else building_texture("trading_port")

static func building_size(kind: String) -> Vector2i:
	if kind=="trading_port": return Vector2i(5,5)
	if kind in ["gold_mining","smelter"]: return Vector2i(3,3)
	var size: Vector2i = CATALOG.entry(BUILDINGS[kind].example).size
	return Vector2i(ceili(size.x * 0.5), ceili(size.y * 0.5)) if kind in ["house", "workshop"] else size

static func building_art_rect(kind: String, origin: Vector2i, texture: Texture2D) -> Rect2:
	var grid := building_size(kind)
	var size := texture.get_size()*(0.5 if kind in ["house","workshop"] else 1.0)
	var foot := Vector2(origin*16)+Vector2(grid.x*8,grid.y*16)
	return Rect2(foot-Vector2(size.x/2,size.y),size)

static func building_door(kind: String) -> Vector2i:
	var size := building_size(kind)
	return Vector2i(BUILDINGS[kind].get("door_x", size.x / 2), size.y)

static func cost_text(cost: Dictionary) -> String:
	var parts: PackedStringArray = []
	for resource in cost:
		if cost[resource] > 0:
			parts.append("%d %s" % [cost[resource], RESOURCES.get(resource, {"name": resource}).name])
	return " + ".join(parts)

const RESOURCES = {
	"produce": {"name": "Hortifruti", "nutrition": 25.0},
	"stone": {"name": "pedras"}, "wood": {"name": "madeiras"},
	"axe": {"name": "machados"}, "pickaxe": {"name": "picaretas"},
	"gold_ore": {"name":"Minério de ouro"}, "gold_bar": {"name":"Barras de ouro"},
}
const TOOLS = {"wood": "axe", "stone": "pickaxe", "gold_mining":"pickaxe"}
const RECIPES = {"axe": {"wood": 2, "stone": 1}, "pickaxe": {"wood": 1, "stone": 2}}
const TOOL_DURABILITY = 45
const CRAFT_SECONDS = 8.0
const TOOLLESS_SPEED = 0.28
const TOOLLESS_ENERGY = 2.8
const HUNGER_DRAIN = 0.18
const MEAL_THRESHOLD = 75.0
const HUNGER_SLOW = 40.0
const HUNGER_STOP = 15.0
const STARVATION_SECONDS = 180.0
const ENERGY_WORK = 0.22
const ENERGY_WALK = 0.06
const REST_THRESHOLD = 20.0
const REST_RECOVERY = 3.0
const REST_FINISH = 95.0
const XP_PER_ACTION = 1.0
const XP_STEP = 30.0
const XP_MAX_BONUS = 0.5
const IMMIGRATION_INTERVAL = 180.0
const EXPEDITION_SECONDS = 35.0
const VOYAGE_SECONDS = 12.0
const EXPEDITION_COST = {"produce": 5, "wood": 3}
const FOOD_RESERVE_PER_PERSON = 3
const HOUSE_CAPACITY = 4
const HOUSE_UPGRADE_COST = {"wood": 12, "stone": 8}
const STORAGE_UPGRADE_COST = {"wood": 10, "stone": 10}

static func timber_growth_seconds() -> int:
	var total := 0.0
	for seconds in TIMBER_SECONDS: total += seconds
	return int(total)

static func timber_texture(stage: int) -> Texture2D:
	var frame: int = TIMBER_FRAMES[clampi(stage, 0, TIMBER_MATURE_STAGE)]
	return atlas(TIMBER_SHEET, Rect2(Vector2(frame * TIMBER_FRAME_SIZE.x, 0), TIMBER_FRAME_SIZE))

static func empty_stock() -> Dictionary:
	var result := {}
	for key in RESOURCES: result[key] = 0
	return result

static func resource_for_activity(activity: String) -> String:
	if activity=="gold_mining": return "gold_ore"
	return "produce" if activity == "food" else activity


const STORAGE_CAPACITY = {"base":120,"house":0,"workshop":60,"warehouse":200,"food":200,"wood":200,"stone":200,"gold_mining":ECONOMY.GOLD_POST_CAPACITY,"smelter":62,"trading_port":ECONOMY.PORT_CAPACITY}
const STORAGE_UPGRADE_CAPACITY = 100
const HOUSE_UPGRADE_CAPACITY = 2
const MAX_BUILDING_LEVEL = 3



# Worker decision pacing, work sites and route recovery.
const TREE_WORK_SLOTS = 1
const MINE_WORK_SLOTS = 2
const FAMILIAR_SOURCE_FACTOR = 0.85
const IDLE_RECHECK_SECONDS = 1.2
const ROUTE_RETRY_SECONDS = 1.0
const ROUTE_RETRY_LIMIT = 3

static var atlas_cache := {}
static var resource_texture_cache := {}
static func atlas(path: String, region: Rect2) -> Texture2D:
	var key := path + str(region)
	if not atlas_cache.has(key):
		var texture := AtlasTexture.new()
		texture.atlas = load(path)
		texture.region = region
		atlas_cache[key] = texture
	return atlas_cache[key]

static func resource_texture(resource: String, pile := false) -> Texture2D:
	if resource in ["gold_ore","gold_bar"]:
		var gold_path: String="res://Assets/Items/Piles/%s_pile.png"%resource if pile else "res://Assets/Items/Resources/%s.png"%resource
		if ResourceLoader.exists(gold_path):
			if not resource_texture_cache.has(gold_path): resource_texture_cache[gold_path]=load(gold_path)
			return resource_texture_cache[gold_path]
		return atlas("res://Assets/Objects/Exterior/Mine and Dungeon/stone with minerals.png",Rect2(32,16 if resource=="gold_ore" else 32,16,16))
	if resource == "produce":
		var path := "res://Assets/Items/Piles/produce_pile.png" if pile else "res://Assets/Items/Resources/produce.png"
		# Canvas draw commands retain the RID, not the Resource. Keep both variants
		# alive after _draw returns, including when no HUD icon holds the texture.
		if not resource_texture_cache.has(path): resource_texture_cache[path] = load(path)
		return resource_texture_cache[path]
	var paths := {
		"wood": "res://Assets/Icons/RPG icons/Extras/Wood.png",
		"stone": "res://Assets/Icons/RPG icons/Extras/Stones.png",
		"axe": "res://Assets/Icons/RPG icons/Weapons and Armor/1. Wood/Axe.png",
		"pickaxe": "res://Assets/Icons/RPG icons/Weapons and Armor/1. Wood/Pickaxe.png"}
	return atlas(paths[resource], Rect2(0, 0, 16, 16))
const FINISH_DELIVERY_SECONDS = 5.0
const EXHAUSTED_ENERGY = 5.0

static func gold_deposit_texture(depleted: bool) -> Texture2D:
	var path := "res://Assets/Objects/Resources/Gold/gold_deposit_depleted.png" if depleted else "res://Assets/Objects/Resources/Gold/gold_deposit.png"
	if not resource_texture_cache.has(path): resource_texture_cache[path]=load(path)
	return resource_texture_cache[path]

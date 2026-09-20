extends RefCounted
const CATALOG = preload("res://Scripts/example_catalog.gd")
## Catálogo e balanceamento da V0.0.3. Recursos alimentares possuem identidade própria.

const STARTING_STOCK = {"fruit": 18, "stone": 45, "wood": 20, "axe": 2, "pickaxe": 2}
const WALK_SPEED = 46.0
const CARRY_CAPACITY = 5
const HARVEST_SECONDS = 0.8
const SOURCE_STOCK = {"fruit": 80, "stone": 480, "wood": 30}
const TREE_SECONDS = [8.0, 12.0, 16.0, 20.0, 160.0, 20.0, 0.0]
const TREE_NAMES = ["Broto", "Muda", "Árvore jovem", "Árvore adulta", "Frutificação", "Envelhecendo", "Madeira: pronta para corte"]
const PLANT_COST = {"fruit": 2}
const EXPAND_COST = {"stone": 10, "wood": 5}
const CONSTRUCTIBLE = ["house", "food", "stone", "wood", "workshop", "warehouse"]
const ACTIVITIES = {
	"builder": {"name": "Construção", "profession": "Construtor", "color": Color("e8be78")},
	"food": {"name": "Comida", "profession": "Coletor", "color": Color("a6d887")},
	"stone": {"name": "Pedra", "profession": "Mineiro", "color": Color("a6cbe4")},
	"wood": {"name": "Madeira", "profession": "Lenhador", "color": Color("bb8757")},
	"carrier": {"name": "Transporte", "profession": "Transportador", "color": Color("dcb9e8")},
	"workshop": {"name": "Oficina", "profession": "Artesão", "color": Color("dfae72")},
	"idle": {"name": "Livres", "profession": "Trabalhador", "color": Color("cccccc")},
}
const BUILDINGS = {
	"house": {"name": "Casa", "short": "Moradia", "worker": "Morador", "description": "Residência para quatro habitantes. Pode ser melhorada.", "cost": {"wood": 20, "stone": 10}, "build_seconds": 14.0, "color": Color("e6ba77"), "example": "Building-4"},
	"workshop": {"name": "Oficina de ferramentas", "short": "Oficina", "worker": "Artesão", "description": "Encomende ferramentas. Melhorias liberam metas e reserva automática.", "cost": {"wood": 15, "stone": 15}, "build_seconds": 16.0, "color": Color("d9a76c"), "example": "Building-5"},
	"warehouse": {"name": "Depósito geral", "short": "Depósito", "worker": "Transportador", "description": "Armazena até 200 unidades. Pode ser melhorado.", "cost": {"wood": 12, "stone": 10}, "build_seconds": 12.0, "color": Color("b78d68"), "example": "Building-1"},
	"wood": {
		"name": "Depósito de madeira", "short": "Madeira", "worker": "Lenhador",
		"description": "Lenhadores cortam apenas árvores no último estágio.",
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
		"name": "Depósito de frutas", "short": "Comida", "worker": "Coletor de comida",
		"description": "Organiza a coleta de frutas e armazena as entregas.",
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
	return CATALOG.entry(BUILDINGS[kind].example).texture

static func building_size(kind: String) -> Vector2i:
	var size: Vector2i = CATALOG.entry(BUILDINGS[kind].example).size
	return Vector2i(ceili(size.x * 0.5), ceili(size.y * 0.5)) if kind in ["house", "workshop"] else size

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
	"fruit": {"name": "frutas", "nutrition": 25.0},
	"stone": {"name": "pedras"}, "wood": {"name": "madeiras"},
	"axe": {"name": "machados"}, "pickaxe": {"name": "picaretas"},
}
const TOOLS = {"wood": "axe", "stone": "pickaxe"}
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
const EXPEDITION_COST = {"fruit": 5, "wood": 3}
const FOOD_RESERVE_PER_PERSON = 3
const HOUSE_CAPACITY = 4
const HOUSE_UPGRADE_COST = {"wood": 12, "stone": 8}
const STORAGE_UPGRADE_COST = {"wood": 10, "stone": 10}

static func empty_stock() -> Dictionary:
	var result := {}
	for key in RESOURCES: result[key] = 0
	return result

static func resource_for_activity(activity: String) -> String:
	return "fruit" if activity == "food" else activity


const STORAGE_CAPACITY = {"base":120,"house":0,"workshop":60,"warehouse":200,"food":200,"wood":200,"stone":200}
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
const FINISH_DELIVERY_SECONDS = 5.0
const EXHAUSTED_ENERGY = 5.0

extends RefCounted
## Shared background from menu_ex.tscn: Banner atlas tiles (0..2, 0..2).
const BACKGROUND = preload("res://Assets/UI/Inventory/Banner.png")
const FRAMES = preload("res://Assets/UI/Extras.png")
const INK = Color("543126")
const MUTED = Color("795345")
const ACCENT = Color("914629")

static func texture_style(texture: Texture2D, region: Rect2, padding: int, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.region_rect = region
	style.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 16)
		style.set_content_margin(side, padding)
	return style

static func panel(padding := 16) -> StyleBoxTexture:
	return texture_style(BACKGROUND, Rect2(0, 0, 48, 48), padding)

static func icon_frame(tint := Color.WHITE) -> StyleBoxTexture:
	# Same eight corner/edge tiles used in MenuEx/TileMapLayer2.
	return texture_style(FRAMES, Rect2(320, 0, 48, 48), 4, tint)

static func create() -> Theme:
	var result := Theme.new()
	result.default_font_size = 15
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_stylebox("panel", "AcceptDialog", panel())
	result.set_stylebox("panel", "TooltipPanel", panel(10))
	result.set_color("font_color", "Label", INK)
	result.set_color("font_color", "TooltipLabel", INK)
	result.set_color("font_color", "Button", INK)
	result.set_color("font_hover_color", "Button", ACCENT)
	result.set_color("font_pressed_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("9b8171"))
	result.set_stylebox("normal", "Button", panel(10))
	result.set_stylebox("hover", "Button", texture_style(BACKGROUND, Rect2(0, 0, 48, 48), 10, Color("fff1d2")))
	result.set_stylebox("pressed", "Button", texture_style(BACKGROUND, Rect2(0, 0, 48, 48), 10, Color("eac4a0")))
	result.set_stylebox("disabled", "Button", texture_style(BACKGROUND, Rect2(0, 0, 48, 48), 10, Color("e4d7cc")))
	var separator := StyleBoxLine.new()
	separator.color = Color("c49b83")
	separator.thickness = 1
	result.set_stylebox("separator", "HSeparator", separator)
	return result

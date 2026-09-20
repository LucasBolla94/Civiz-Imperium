extends RefCounted
## Calm, high-contrast panels shared by the menu and in-game management.
const BACKGROUND = preload("res://Assets/UI/Inventory/Banner.png")
const FRAMES = preload("res://Assets/UI/Extras.png")
const INK = Color("173b40")
const MUTED = Color("496366")
const ACCENT = Color("89541f")
const PAPER = Color("f6eedc")
const TEAL = Color("205660")
const FONT = preload("res://Assets/UI/Fonts/AtkinsonHyperlegible-Regular.ttf")
const BOLD = preload("res://Assets/UI/Fonts/AtkinsonHyperlegible-Bold.ttf")
const TITLE = preload("res://Assets/UI/Fonts/Cinzel.ttf")

static func texture_style(texture: Texture2D, region: Rect2, padding: int, tint := Color.WHITE) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.region_rect = region
	style.modulate_color = tint
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		style.set_texture_margin(side, 16)
		style.set_content_margin(side, padding)
	return style

static func flat(color: Color, border: Color, padding := 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color=color
	style.border_color=border
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: style.set_content_margin(side,padding)
	return style

static func panel(padding := 16) -> StyleBoxFlat:
	var style := flat(PAPER,Color("ac956e"),padding)
	style.shadow_color=Color(0.01,0.06,0.07,0.24)
	style.shadow_size=3
	style.shadow_offset=Vector2(0,2)
	return style

static func icon_frame(tint := Color.WHITE) -> StyleBoxTexture:
	# Same eight corner/edge tiles used in MenuEx/TileMapLayer2.
	return texture_style(FRAMES, Rect2(320, 0, 48, 48), 4, tint)

static func create() -> Theme:
	var result := Theme.new()
	result.default_font=FONT
	result.default_font_size = 16
	result.set_stylebox("panel", "PanelContainer", panel())
	result.set_stylebox("panel", "AcceptDialog", panel())
	result.set_stylebox("panel", "TooltipPanel", panel(10))
	result.set_color("font_color", "Label", INK)
	result.set_color("font_color", "TooltipLabel", INK)
	result.set_color("font_color", "Button", INK)
	result.set_color("font_hover_color", "Button", INK)
	result.set_color("font_pressed_color", "Button", PAPER)
	result.set_color("font_focus_color", "Button", INK)
	result.set_color("font_disabled_color", "Button", Color("727971"))
	result.set_stylebox("normal", "Button", flat(Color("ede2c9"),Color("baa581"),8))
	result.set_stylebox("hover", "Button", flat(Color("ffedba"),ACCENT,8))
	result.set_stylebox("pressed", "Button", flat(TEAL,INK,8))
	result.set_stylebox("disabled", "Button", flat(Color("e7e2d6"),Color("c5bba7"),8))
	var focus := flat(Color.TRANSPARENT,TEAL,0)
	focus.set_border_width_all(2)
	result.set_stylebox("focus","Button",focus)
	result.set_type_variation("PrimaryButton","Button")
	result.set_stylebox("normal","PrimaryButton",flat(TEAL,INK,10))
	result.set_stylebox("hover","PrimaryButton",flat(Color("2f6e76"),INK,10))
	result.set_color("font_color","PrimaryButton",PAPER)
	result.set_color("font_hover_color","PrimaryButton",Color.WHITE)
	result.set_color("font_focus_color","PrimaryButton",PAPER)
	result.set_color("font_pressed_color","PrimaryButton",PAPER)
	result.set_font("font","PrimaryButton",BOLD)
	result.set_stylebox("normal","LineEdit",flat(Color("fffaf0"),Color("ad9b7e"),8))
	result.set_stylebox("focus","LineEdit",focus)
	result.set_color("font_color","LineEdit",INK)
	result.set_color("caret_color","LineEdit",INK)
	result.set_color("font_placeholder_color","LineEdit",MUTED)
	result.set_stylebox("tab_selected","TabBar",flat(TEAL,INK,10))
	result.set_stylebox("tab_unselected","TabBar",flat(Color("ede2c9"),Color("baa581"),10))
	result.set_stylebox("tab_hovered","TabBar",flat(Color("ffedba"),ACCENT,10))
	result.set_color("font_selected_color","TabBar",PAPER)
	result.set_color("font_unselected_color","TabBar",INK)
	result.set_color("font_hovered_color","TabBar",INK)
	result.set_stylebox("background","ProgressBar",flat(Color("d4d2bc"),Color("c4bea5"),0))
	result.set_stylebox("fill","ProgressBar",flat(TEAL,TEAL,0))
	var separator := StyleBoxLine.new()
	separator.color = Color("c9b993")
	separator.thickness = 1
	result.set_stylebox("separator", "HSeparator", separator)
	return result

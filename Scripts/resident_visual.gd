extends Node2D
## Native 32px frames, grounded at the worker's navigation position.
const PREFIXES = ["Pink_Monster", "Dude_Monster", "Owlet_Monster"]
const CLIPS = {
	"Idle": ["Idle_4", 4, 5.0], "Walk": ["Walk_6", 6, 8.0],
	"Work": ["Push_6", 6, 7.0], "Run": ["Run_6", 6, 10.0],
	"Attack": ["Attack1_4", 4, 8.0], "Attack2": ["Attack2_6", 6, 8.0],
	"WalkAttack": ["Walk+Attack_6", 6, 8.0], "Throw": ["Throw_4", 4, 8.0],
	"Jump": ["Jump_8", 8, 10.0], "Climb": ["Climb_4", 4, 8.0],
	"Hurt": ["Hurt_4", 4, 8.0], "Death": ["Death_8", 8, 8.0],
}
const CROWN = preload("res://Assets/Characters/Accessories/king_crown.svg")
# Crown band overlaps the scalp by two pixels, following each animation frame.
const HEAD_Y = {"Idle": [6, 5, 5, 6], "Walk": [7, 6, 5, 7, 6, 5], "Work": [7, 6, 5, 7, 6, 5]}
static var frame_cache: Dictionary = {}
var appearance_id := -1
var sprite := AnimatedSprite2D.new()
var crown := Sprite2D.new()

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.position = Vector2(0, -16)
	add_child(sprite)
	crown.texture = CROWN
	crown.centered = false
	crown.visible = false
	add_child(crown)
	sprite.frame_changed.connect(update_crown)
	sprite.animation_changed.connect(update_crown)

func configure(variant: int) -> void:
	variant = posmod(variant, PREFIXES.size())
	if appearance_id == variant: return
	appearance_id = variant
	if not frame_cache.has(variant):
		var frames := SpriteFrames.new()
		frames.remove_animation("default")
		for clip in CLIPS:
			var spec: Array = CLIPS[clip]
			var sheet: Texture2D = load("res://Assets/Characters/char-%d/%s_%s.png" % [variant + 1, PREFIXES[variant], spec[0]])
			frames.add_animation(clip)
			frames.set_animation_speed(clip, spec[2])
			frames.set_animation_loop(clip, clip in ["Idle", "Walk", "Work", "Run", "Climb", "WalkAttack"])
			for frame in range(spec[1]):
				var atlas := AtlasTexture.new()
				atlas.atlas = sheet
				atlas.region = Rect2(frame * 32, 0, 32, 32)
				frames.add_frame(clip, atlas)
		frame_cache[variant] = frames
	sprite.sprite_frames = frame_cache[variant]
	sprite.play("Idle")
	update_crown()

func face(direction: Vector2) -> void:
	if absf(direction.x) > 0.001: sprite.flip_h = direction.x < 0
	update_crown()

func update_crown() -> void:
	var clip := String(sprite.animation)
	if not HEAD_Y.has(clip): return # Reserved clips are not used by colony actions yet.
	var heights: Array = HEAD_Y[clip]
	var head_x := 18 if clip == "Work" else 15
	var head_y: int = heights[mini(sprite.frame, heights.size() - 1)]
	var x := float(head_x - 16)
	if sprite.flip_h: x = -x
	crown.flip_h = sprite.flip_h
	crown.position = Vector2(x - 5, head_y + 2 - 32 - 6)

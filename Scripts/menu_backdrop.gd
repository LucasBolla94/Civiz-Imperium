extends Node2D
## Presentation only: static scenery and decorative animated residents, no colony controller.
const DATA = preload("res://Scripts/game_data.gd")
var camera := Camera2D.new()
var elapsed := 0.0

func _ready() -> void:
	add_child(preload("res://Scenes/world.tscn").instantiate())
	for item in [["base",Vector2i(49,26)],["house",Vector2i(44,25)],["house",Vector2i(65,34)],["workshop",Vector2i(63,25)]]:
		var sprite := Sprite2D.new()
		sprite.centered=false
		sprite.texture=DATA.building_texture(item[0])
		sprite.position=item[1]*16
		sprite.scale=Vector2(DATA.building_size(item[0])*16)/sprite.texture.get_size()
		add_child(sprite)
	for origin in [Vector2i(44,31),Vector2i(64,29),Vector2i(58,34),Vector2i(60,25)]:
		add_child(DATA.CATALOG.resource_layer("Tree-5",origin))
	for i in 3:
		var person := preload("res://Scripts/resident_visual.gd").new()
		person.configure(i)
		person.sprite.play("Walk")
		person.position=Vector2(750+i*100,580-i*15)
		add_child(person)
		var begin: Vector2=person.position
		var end := begin+Vector2(70,0)
		var tween := create_tween().set_loops()
		tween.tween_callback(func(): person.face(Vector2.RIGHT))
		tween.tween_property(person,"position",end,6+i)
		tween.tween_callback(func(): person.face(Vector2.LEFT))
		tween.tween_property(person,"position",begin,6+i)
	camera.position=Vector2(56.5*16,31*16)
	add_child(camera)
	fit()
	get_viewport().size_changed.connect(fit)

func fit() -> void:
	var size := get_viewport_rect().size
	camera.zoom=Vector2.ONE*maxf(1.0,minf(size.x/650.0,size.y/430.0))

func _process(delta: float) -> void:
	elapsed+=delta
	camera.offset=Vector2(sin(elapsed*0.08)*12,cos(elapsed*0.1)*6)

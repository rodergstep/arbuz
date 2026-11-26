class_name EnglandTown
extends GreyboxVillage
## The English town (Phase 4, greybox first): red-brick houses, the bakery and café, the toy
## shop, the clock tower on the square, a red bus stop, the harbour where the ferry arrived, a
## farm with a barn. Everything else (hero, car, Tygrytsa, learning moments, doors, finds,
## quests) is the shared town machinery from GreyboxVillage.

const PRACTICE_PATH: String = "res://content/chapters/england_practice.tres"
const SEA_Z: float = -31.0
const BAKERY_POS: Vector3 = Vector3(-8, 0, -12)
const CAFE_POS: Vector3 = Vector3(8, 0, -12)
const TOY_SHOP_POS: Vector3 = Vector3(-30, 0, 6)
const CLOCK_POS: Vector3 = Vector3(0, 0, 4)
const BUS_STOP_POS: Vector3 = Vector3(27.5, 0, -2)
const BARN_POS: Vector3 = Vector3(31, 0, 30)
const FERRY_BERTH: Vector3 = Vector3(-4, 0, -34)
const HOUSES: Array[Vector3] = [
	Vector3(-14, 0, 30),
	Vector3(-4, 0, 30),
	Vector3(8, 0, 31),
	Vector3(-31, 0, -14),
	Vector3(31, 0, -14),
	Vector3(16, 0, 10)
]
const TREES: Array[Vector3] = [
	Vector3(-18, 0, 12),
	Vector3(-34, 0, 18),
	Vector3(-26, 0, 30),
	Vector3(18, 0, 20),
	Vector3(34, 0, 12),
	Vector3(-12, 0, 6)
]
const LAMPS: Array[Vector3] = [
	Vector3(-4, 0, 1), Vector3(4, 0, 1), Vector3(-20.5, 0, -18), Vector3(20.5, 0, -18)
]


func _configure() -> void:
	door_pos = BAKERY_POS + Vector3(1.4, 0, 2.6)
	hero_start = Vector3(-4, 0, -27)
	car_start = Vector3(-8, 0, -26)
	door_words = [&"tree", &"house", &"car", &"road", &"clock", &"bus", &"shop", &"lamp", &"sea", &"boat"]
	learning_spots = [
		[&"sea", Vector3(10, 0, -29), 3.0, Vector3(-4, 5, 6)],
		[&"boat", Vector3(4, 0, -29.5), 2.5, Vector3(-4, 4, 6)],
		[&"clock", CLOCK_POS + Vector3(0, 0, 3), 3.0, Vector3(5, 6, 8)],
		[&"bus", BUS_STOP_POS + Vector3(-2, 0, 0), 3.0, Vector3(-5, 4, 5)],
		[&"bakery", BAKERY_POS + Vector3(0, 0, 4), 2.5, Vector3(4, 4, 7)],
		[&"shop", TOY_SHOP_POS + Vector3(4, 0, 0), 2.5, Vector3(6, 4, 6)],
		[&"farm", BARN_POS + Vector3(-5, 0, -4), 3.0, Vector3(-6, 5, -6)],
		[&"road", Vector3(-24, 0, 8), 3.0, Vector3(6, 5, 6)],
	]


func _first_chapter_path() -> String:
	return PRACTICE_PATH


func _ready() -> void:
	super._ready()
	Speech.stop()
	Speech.line("england:arrive")
	_fade_in()


func _fade_in() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 8
	var rect: ColorRect = ColorRect.new()
	rect.color = UiTokens.BG_SKY
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)
	var tween: Tween = create_tween()
	tween.tween_property(rect, "color:a", 0.0, 1.5)
	tween.tween_callback(layer.queue_free)


## The harbour: the sea along the north edge (solid water), a stone quay and the ferry at its berth.
func _build_river() -> void:
	Blocks.solid_box(
		_nav, Vector3(0, 0.1, (SEA_Z - 40.0) / 2.0), Vector3(84, 0.4, 40.0 + SEA_Z), Color(0.33, 0.56, 0.82)
	)
	add_child(Blocks.box_mesh(Vector3(80, 0.3, 1.2), Color(0.72, 0.70, 0.66), Vector3(0, 0.15, SEA_Z + 0.6)))
	ferry = Node3D.new()
	ferry.add_child(Blocks.prop("ferry", Vector3.ZERO))
	add_child(ferry)
	ferry.global_position = FERRY_BERTH


func _build_houses() -> void:
	for spot: Vector3 in HOUSES:
		Blocks.hidden_solid(_nav, spot + Vector3(0, 2.1, 0), Vector3(5, 4.2, 4.5))
		add_child(Blocks.prop("english_house", spot, 180.0))
	for shop: Array in [["bakery", BAKERY_POS], ["cafe", CAFE_POS], ["toy_shop", TOY_SHOP_POS]]:
		Blocks.hidden_solid(_nav, shop[1] + Vector3(0, 2.0, 0), Vector3(6, 4, 5))
		add_child(Blocks.prop(shop[0], shop[1], 180.0 if shop[0] != "toy_shop" else 90.0))
	Blocks.hidden_solid(_nav, CLOCK_POS + Vector3(0, 4.5, 0), Vector3(2.6, 9, 2.6))
	add_child(Blocks.prop("clock_tower", CLOCK_POS, 180.0))
	Blocks.hidden_solid(_nav, BUS_STOP_POS + Vector3(0, 1.2, -0.6), Vector3(2.8, 2.4, 0.4))
	add_child(Blocks.prop("bus_stop", BUS_STOP_POS, 90.0))
	Blocks.hidden_solid(_nav, BARN_POS + Vector3(0, 2.2, 0), Vector3(6.5, 4.4, 6))
	add_child(Blocks.prop("barn", BARN_POS, 225.0))
	for lamp: Vector3 in LAMPS:
		Blocks.hidden_solid(_nav, lamp + Vector3(0, 1.6, 0), Vector3(0.2, 3.2, 0.2))
		add_child(Blocks.prop("lamp", lamp))
	for t: Vector3 in TREES:
		Blocks.hidden_solid(_nav, t + Vector3(0, 1, 0), Vector3(0.5, 2, 0.5))
		add_child(Blocks.prop("tree", t, t.x * 37.0, Vector3.ONE, [LEAF_COLOR]))
	_make_door()


func _build_grass() -> void:
	var grass: WindGrass = WindGrass.new()
	add_child(grass)
	grass.scatter(Rect2(-38, -30, 76, 68), 2200, _grass_blocked)
	_build_hedge_ring()
	add_child(PerfMonitor.new())


## A trimmed green hedge round the town (instead of the village's wicker fence).
func _build_hedge_ring() -> void:
	for side: Array in [
		[Vector3(0, 0.6, 39.5), Vector3(80, 1.2, 1.0)],
		[Vector3(-39.5, 0.6, 4), Vector3(1.0, 1.2, 72)],
		[Vector3(39.5, 0.6, 4), Vector3(1.0, 1.2, 72)],
	]:
		add_child(Blocks.box_mesh(side[1], Color(0.30, 0.55, 0.30), side[0]))
	for child: Node in _nav.get_children():
		# The plain edge boards from the base ground are only collision here.
		if child is StaticBody3D and absf((child as StaticBody3D).position.y - 0.4) < 0.01:
			(child.get_child(1) as MeshInstance3D).visible = false


func _grass_blocked(p: Vector2) -> bool:
	if p.y < SEA_Z + 1.5:
		return true
	var road: bool = (absf(p.y + 22) < 3.2 or absf(p.y - 22) < 3.2) and absf(p.x) < 27.0
	road = road or ((absf(p.x + 24) < 3.2 or absf(p.x - 24) < 3.2) and absf(p.y) < 25.0)
	var buildings: Array[Vector3] = HOUSES.duplicate()
	buildings.append_array([BAKERY_POS, CAFE_POS, TOY_SHOP_POS, BARN_POS, CLOCK_POS])
	for spot: Vector3 in buildings:
		if absf(p.x - spot.x) < 3.8 and absf(p.y - spot.z) < 3.5:
			return true
	return road


func _clickable_things() -> Array[Dictionary]:
	return [
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(-20, 0, 2)},
		{"id": &"ball", "uk": "м'яч", "en": "ball", "pos": Vector3(-30, 0, 14)},
		{"id": &"duck", "uk": "качка", "en": "duck", "pos": Vector3(14, 0, -29)},
		{"id": &"dog", "uk": "собака", "en": "dog", "pos": Vector3(10, 0, 16)},
		{"id": &"house", "uk": "будинок", "en": "house", "pos": HOUSES[5]},
		{"id": &"flower", "uk": "квітка", "en": "flower", "pos": Vector3(-6, 0, 18)},
	]


## No postman here; the ferry is moored in the harbour.
func _build_story_cast() -> void:
	say_hud = CanvasLayer.new()
	say_hud.layer = 4
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	center.position.y -= 160
	say_hud.add_child(center)
	_say_mic = MicBubble.new()
	_say_mic.visible = false
	center.add_child(_say_mic)
	add_child(say_hud)

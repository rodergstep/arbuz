class_name EnglandTown
extends GreyboxVillage
## The English town (Phase 4, greybox first): red-brick houses, the bakery and café, the toy
## shop, the clock tower on the square, a red bus stop, the harbour where the ferry arrived, a
## farm with a barn. Everything else (hero, car, Tygrytsa, learning moments, doors, finds,
## quests) is the shared town machinery from GreyboxVillage.

const PRACTICE_PATH: String = "res://content/chapters/england_practice.tres"
const CHAPTER1_PATH: String = "res://content/chapters/chapter1_bakery.tres"
const CHAPTER1_DONE: String = "chapter:bakery"
const CHAPTER2_PATH: String = "res://content/chapters/chapter2_balloons.tres"
const CHAPTER2_DONE: String = "chapter:balloons"
const TOY_MAKER_POS: Vector3 = Vector3(-30, 0, 11)
const CHAPTER3_PATH: String = "res://content/chapters/chapter3_animals.tres"
const CHAPTER3_DONE: String = "chapter:animals"
const FARMER_POS: Vector3 = Vector3(24, 0, 25)
const CHAPTER4_PATH: String = "res://content/chapters/chapter4_clock.tres"
const CHAPTER4_DONE: String = "chapter:clock"
const CLOCK_MAKER_POS: Vector3 = Vector3(3, 0, 7)
const CHAPTER5_PATH: String = "res://content/chapters/chapter5_festival.tres"
const CHAPTER5_DONE: String = "chapter:festival"
const FESTIVAL_ID: StringName = &"chapter5_festival"
## Where every friend stands at the festival, round the square in front of the clock tower.
const FESTIVAL_SPOTS: Dictionary[String, Vector3] = {
	"postman": Vector3(-6, 0, 9.5),
	"baker": Vector3(-4, 0, 7.6),
	"toy_maker": Vector3(-1.8, 0, 6.8),
	"clock_maker": Vector3(1.8, 0, 6.8),
	"farmer": Vector3(4, 0, 7.6),
}
const FESTIVAL_HERO: Vector3 = Vector3(0, 0, 12)
const BAKER_POS: Vector3 = Vector3(-5.5, 0, -8.5)
const SEA_Z: float = -31.0
const BAKERY_POS: Vector3 = Vector3(-8, 0, -12)
const CAFE_POS: Vector3 = Vector3(8, 0, -12)
const TOY_SHOP_POS: Vector3 = Vector3(-30, 0, 6)
const CLOCK_POS: Vector3 = Vector3(0, 0, 4)
const BUS_STOP_POS: Vector3 = Vector3(27.5, 0, -2)
const BARN_POS: Vector3 = Vector3(31, 0, 30)
const FERRY_BERTH: Vector3 = Vector3(-4, 0, -34)
## Chapter conversations by talk id: who speaks, their lines (catalogue keys), whether he says
## a word back (microphone, never judged), an optional learning card and a cheer.
const TALKS: Dictionary = {
	&"baker_intro":
	{"who": "baker", "lines": ["ch1:baker_hello", "ch1:baker_help", "ch1:help_baker"], "say_back": &"hello"},
	&"baker_thanks":
	{
		"who": "baker",
		"lines": ["ch1:baker_thanks", "ch1:baker_cake"],
		"card": &"cake",
		"after": ["ch1:hooray"]
	},
	&"toy_intro":
	{"who": "toy_maker", "lines": ["ch2:toy_hello", "ch2:toy_help", "ch2:help_toy"], "say_back": &"hello"},
	&"toy_thanks":
	{"who": "toy_maker", "lines": ["ch2:toy_thanks"], "card": &"balloon", "after": ["ch2:hooray"]},
	&"farmer_intro":
	{
		"who": "farmer",
		"lines": ["ch3:farmer_hello", "ch3:farmer_help", "ch3:help_farmer"],
		"say_back": &"hello"
	},
	&"farmer_thanks":
	{"who": "farmer", "lines": ["ch3:farmer_thanks"], "card": &"farm", "after": ["ch3:hooray"]},
	&"clock_intro":
	{
		"who": "clock_maker",
		"lines": ["ch4:clock_hello", "ch4:clock_help", "ch4:help_clock"],
		"say_back": &"hello"
	},
	&"clock_thanks":
	{
		"who": "clock_maker",
		"lines": ["ch4:clock_thanks", "ch4:count_ten"],
		"card": &"clock",
		"after": ["ch4:clock_works"]
	},
	# The finale: each friend he helped says thank you in turn ([who, line] parts).
	&"festival":
	{
		"who": "clock_maker",
		"lines":
		[
			["postman", "ch5:postman"],
			["baker", "ch5:baker"],
			["toy_maker", "ch5:toy"],
			["farmer", "ch5:farmer"],
			["clock_maker", "ch5:clock"],
		],
		"say_back": &"hello",
		"say_line": "ch5:say_hello",
		"card": &"party",
		"after": ["ch5:hooray"],
		"cheer": true
	},
}
const HOUSES: Array[Vector3] = [Vector3(-31, 0, -14), Vector3(31, 0, -14), Vector3(16, 0, 10)]
## Rows of three joined terrace houses along the south edge.
const TERRACES: Array[Vector3] = [Vector3(-9, 0, 31), Vector3(6.5, 0, 31)]
## England: soft, cooler light under a cloudier sky, deep green lawns, grey streets with
## pavements, green patchwork fields with hedgerows beyond the town.
const ENGLAND_LOOK: Dictionary = {
	"sky_top": Color(0.46, 0.62, 0.84),
	"sky_horizon": Color(0.88, 0.90, 0.92),
	"cloud_cover": 0.66,
	"sun": Color(1.0, 0.95, 0.88),
	"sun_energy": 0.88,
	"ambient": Color(0.62, 0.68, 0.84),
	"saturation": 1.0,
	"ground": Color(0.36, 0.62, 0.34),
	"grass": Color(0.34, 0.60, 0.30),
	"road": Color(0.42, 0.43, 0.46),
	"hills": [Color(0.32, 0.56, 0.30), Color(0.40, 0.62, 0.34), Color(0.28, 0.50, 0.30)],
	"fields":
	[Color(0.38, 0.62, 0.32), Color(0.48, 0.68, 0.36), Color(0.90, 0.84, 0.30), Color(0.34, 0.56, 0.30)],
}
const PAVEMENT: Color = Color(0.74, 0.72, 0.68)
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

var baker: StoryNpc
var toy_maker: StoryNpc
var farmer: StoryNpc
var clock_maker: StoryNpc
## The postman at the festival (the prologue's PostmanNpc stays in the village).
var festival_postman: StoryNpc
var festival: FestivalDecor
var _collect_items: Array[CollectItem] = []
var _collect_word: WordEntry
var _collect_count: int = 0
var _collect_total: int = 0
var _found_line: String = ""
var _hint_line: String = ""


func _configure() -> void:
	look = ENGLAND_LOOK
	treasures = [
		[&"umbrella", Vector3(-27.8, 0, -14.8)],
		[&"teapot", Vector3(11.6, 0, -13.2)],
		[&"crown", Vector3(35.2, 0, 27.5)]
	]
	door_pos = BAKERY_POS + Vector3(-1.4, 0, 2.6)
	hero_start = Vector3(-4, 0, -27)
	car_start = Vector3(-8, 0, -26)
	door_words = [
		&"tree",
		&"house",
		&"car",
		&"road",
		&"clock",
		&"bus",
		&"shop",
		&"lamp",
		&"sea",
		&"boat",
		&"apple",
		&"egg",
		&"milk",
		&"flour"
	]
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
	if not SaveSystem.has_encountered(CHAPTER1_DONE):
		return CHAPTER1_PATH
	if not SaveSystem.has_encountered(CHAPTER2_DONE):
		return CHAPTER2_PATH
	if not SaveSystem.has_encountered(CHAPTER3_DONE):
		return CHAPTER3_PATH
	if not SaveSystem.has_encountered(CHAPTER4_DONE):
		return CHAPTER4_PATH
	if not SaveSystem.has_encountered(CHAPTER5_DONE):
		return CHAPTER5_PATH
	return PRACTICE_PATH


func _talking() -> bool:
	for npc: StoryNpc in [baker, toy_maker, farmer, clock_maker, festival_postman]:
		if npc != null and npc.is_talking():
			return true
	return false


func _talk_script(talk_id: StringName) -> Dictionary:
	return TALKS.get(talk_id, {})


func start_talk(talk_id: StringName = &"") -> void:
	var talk: Dictionary = _talk_script(talk_id)
	if talk.is_empty():
		quest.notify_talk_done()
		return
	var npcs: Dictionary[String, StoryNpc] = _npcs()
	var npc: StoryNpc = npcs[talk["who"]]
	hero.stop()
	hero.keyboard_enabled = false
	set_hint(null, "")
	npc.talking = true
	var alive: Callable = func() -> bool: return is_inside_tree()
	npc.face(hero.global_position)
	npc.wave(2.5)
	Speech.stop()
	for part: Variant in talk["lines"]:
		# A plain key is the main speaker's line; [who, key] lets another friend speak.
		var key: String = part if part is String else part[1]
		if part is Array:
			var speaker: StoryNpc = npcs[part[0]]
			speaker.face(hero.global_position)
			speaker.wave(2.5)
		Speech.line(key)
		await SayItBack.wait_until_quiet(self, alive)
	if talk.has("say_back"):
		var word: WordEntry = WordDB.get_word(talk["say_back"])
		Speech.line(talk.get("say_line", "talk:say_hello"), word)
		await SayItBack.wait_until_quiet(self, alive)
		var heard: bool = await SayItBack.wait_for_word(self, word, _say_mic, alive)
		await SayItBack.praise(self, word, heard, alive)
	if talk.has("card"):
		var pos: Vector3 = npc.global_position
		if learning.request(talk["card"], pos, pos + Vector3(2.5, 2.2, 3.0), true):
			await learning.moment_closed
	if talk.has("after"):
		npc.wave(3.0)
		if talk.get("cheer", false) and festival != null:
			for friend: StoryNpc in npcs.values():
				friend.wave(4.0)
			festival.cheer()
		else:
			Sfx.play(&"door")
		for key: String in talk["after"]:
			Speech.line(key)
			await SayItBack.wait_until_quiet(self, alive)
	npc.talking = false
	hero.keyboard_enabled = true
	quest.notify_talk_done()


## Find and count: the things are put at the step's spots; each click collects one and counts
## it aloud ("One apple! Two apples!"). Teach before test: the first one opens its learning
## card if he hasn't met the word yet.
func start_collect(step: QuestStep) -> void:
	_collect_word = WordDB.get_word(step.word)
	_collect_total = step.spots.size()
	_collect_count = 0
	_collect_items.clear()
	for i: int in step.spots.size():
		var spot: Vector3 = step.spots[i]
		var item: CollectItem = CollectItem.new()
		item.setup(step.word)
		if i < step.homes.size():
			item.home = step.homes[i]
		add_child(item)
		item.global_position = spot
		_collect_items.append(item)
	_remember_place(step.word, step.spots[0], step.spots[0] + Vector3(2.0, 1.8, 2.6))
	var default_find: String = "ch1:find_items" if _collect_total > 1 else "ch1:find_one"
	_found_line = step.found_line if not step.found_line.is_empty() else "count:found"
	_hint_line = step.hint_line if not step.hint_line.is_empty() else "ch1:find_one"
	say_when_free_word(step.find_line if not step.find_line.is_empty() else default_find, _collect_word)
	_point_companion_at_next()


func _on_collect_click(item: CollectItem) -> void:
	if item.is_collected() or _collect_word == null or item.word_id != _collect_word.id:
		return
	item.collect()
	_collect_items.erase(item)
	_collect_count += 1
	EventLog.log_event(&"collect", {"word": String(item.word_id), "n": _collect_count})
	if _collect_count == 1 and not learning.was_taught(item.word_id):
		learning.request(
			item.word_id, item.global_position, item.global_position + Vector3(2.0, 1.8, 2.6), true
		)
	# A single thing is found, not counted: "Here is the milk!" (never "One milk!").
	var keys: Array[String] = ["count:one", "count:two", "count:three"]
	var key: String = _found_line if _collect_total == 1 else keys[mini(_collect_count, 3) - 1]
	say_when_free_word(key, _collect_word)
	LearningTracker.record_heard(item.word_id)
	if _collect_count >= _collect_total:
		# "We found them all!" only after a step with several things (not after each balloon).
		if _collect_total > 1:
			say_when_free_word("ch1:all_found", _collect_word)
		_collect_word = null
		companion.set_goal(null)
		quest.notify_collected()
	else:
		_point_companion_at_next()


func _point_companion_at_next() -> void:
	if _collect_items.is_empty():
		return
	var nearest: CollectItem = _collect_items[0]
	for item: CollectItem in _collect_items:
		if (
			item.global_position.distance_to(hero.global_position)
			< nearest.global_position.distance_to(hero.global_position)
		):
			nearest = item
	companion.set_goal(nearest, _hint_line, _collect_word)


func _npcs() -> Dictionary[String, StoryNpc]:
	return {
		"baker": baker,
		"toy_maker": toy_maker,
		"farmer": farmer,
		"clock_maker": clock_maker,
		"postman": festival_postman,
	}


func _ready() -> void:
	super._ready()
	Speech.stop()
	Speech.line("england:arrive")
	_fade_in()
	# After the finale the town stays in festival dress, with every friend on the square.
	if festival == null and SaveSystem.has_encountered(CHAPTER5_DONE):
		_start_festival(false)


func _on_step_started(index: int, step: QuestStep) -> void:
	super._on_step_started(index, step)
	if festival == null and quest.chapter != null and quest.chapter.id == FESTIVAL_ID:
		_start_festival(true)


## Dresses the square for the festival and gathers every friend there (walking in, or
## already standing there when walk is false).
func _start_festival(walk: bool) -> void:
	festival = FestivalDecor.new()
	add_child(festival)
	festival_postman = _add_npc("postman", FESTIVAL_SPOTS["postman"] + Vector3(-8, 0, 4))
	var npcs: Dictionary[String, StoryNpc] = _npcs()
	for who: String in FESTIVAL_SPOTS:
		var npc: StoryNpc = npcs[who]
		var spot: Vector3 = FESTIVAL_SPOTS[who]
		if not walk:
			npc.global_position = spot
			npc.face(FESTIVAL_HERO)
			continue
		# Each friend walks in from just off the square (or from close by, like the clock maker).
		var from: Vector3 = spot + (spot - Vector3(0, 0, 4)).normalized() * 7.0
		if npc.global_position.distance_to(spot) > 8.0:
			npc.global_position = from
		npc.walk_to(spot, 3.0, FESTIVAL_HERO)


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
		add_child(Blocks.prop("oak", t, t.x * 37.0, Vector3.ONE * 0.75, [Color(0.24, 0.48, 0.26)]))
	for spot: Vector3 in TERRACES:
		Blocks.hidden_solid(_nav, spot + Vector3(0, 2.5, 0), Vector3(12.4, 5, 4.6))
		add_child(Blocks.prop("terrace", spot, 180.0))
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


## Grey streets with pale pavements on both sides.
func _build_road() -> void:
	super._build_road()
	for z: float in [-22.0, 22.0]:
		for side: float in [-1.0, 1.0]:
			add_child(Blocks.box_mesh(Vector3(52, 0.1, 0.8), PAVEMENT, Vector3(0, 0.05, z + side * 2.9)))
	for x: float in [-24.0, 24.0]:
		for side: float in [-1.0, 1.0]:
			add_child(Blocks.box_mesh(Vector3(0.8, 0.1, 44), PAVEMENT, Vector3(x + side * 2.9, 0.05, 0)))


## The town's own things: a red phone box and post box, park benches, a pond with ducks, a red
## double-decker by the harbour, hedges and iron railings, and green fields beyond.
func _build_scenery() -> void:
	Scenery.backdrop(self, look["hills"], look["fields"], 5)
	Scenery.solid(_nav, self, "phone_box", Vector3(12.5, 0, -7.5), 180.0, Vector3(1.1, 2.6, 1.1))
	Scenery.solid(_nav, self, "post_box", Vector3(-12.5, 0, -8), 180.0, Vector3(0.7, 1.4, 0.7))
	for spot: Vector3 in [Vector3(-12, 0, 9), Vector3(11, 0, 14.5)]:
		Scenery.solid(_nav, self, "bench", spot, 180.0, Vector3(1.8, 0.8, 0.6))
	Scenery.solid(_nav, self, "double_decker", Vector3(-29, 0, -26.4), 90.0, Vector3(7.8, 4, 2.6))
	Scenery.solid(_nav, self, "tractor", BARN_POS + Vector3(-5.5, 0, 3.5), 200.0, Vector3(2.2, 2, 3.2))
	_build_pond(Vector3(12, 0, -2))
	var hedges: Array[Transform3D] = []
	var x: float = -21.0
	while x <= 21.0:
		if absf(x + 9.0) > 2.0 and absf(x - 6.5) > 2.0:
			hedges.append(Scenery.at(Vector3(x, 0, 26.2)))
			Blocks.hidden_solid(_nav, Vector3(x, 0.55, 26.2), Vector3(2.0, 1.1, 0.8))
		x += 2.0
	add_child(Scenery.scatter("hedge", hedges))
	var rails: Array[Transform3D] = []
	x = -15.0
	while x <= 12.5:
		rails.append(Scenery.at(Vector3(x, 0, 34.2)))
		x += 2.0
	add_child(Scenery.scatter("iron_fence", rails))
	# Tidy flower beds in front of the houses and shops, and round bushes in the park.
	var beds: Array[Transform3D] = []
	for spot: Vector3 in HOUSES:
		beds.append(Scenery.at(spot + Vector3(-1.6, 0, 3.0)))
		beds.append(Scenery.at(spot + Vector3(1.6, 0, 3.0)))
	for spot: Vector3 in [BAKERY_POS, CAFE_POS]:
		beds.append(Scenery.at(spot + Vector3(-2.2, 0, 3.4)))
	for bx: float in [-11.0, -3.0, 4.0, 10.0]:
		beds.append(Scenery.at(Vector3(bx, 0, 35.8)))
	add_child(Scenery.scatter("flower_bed", beds, [], 0.0))
	add_child(Scenery.scatter("bush", Scenery.loose(Rect2(-37, -29, 74, 66), 34, _clear_of_things, 51)))


## A round pond with a stone edge and two ducks.
func _build_pond(center: Vector3) -> void:
	var water: CylinderMesh = CylinderMesh.new()
	water.top_radius = 2.4
	water.bottom_radius = 2.4
	water.height = 0.1
	add_child(Blocks.mesh(water, Color(0.30, 0.55, 0.80), center + Vector3(0, 0.05, 0)))
	var rim: TorusMesh = TorusMesh.new()
	rim.inner_radius = 2.3
	rim.outer_radius = 2.75
	add_child(Blocks.mesh(rim, Color(0.70, 0.68, 0.64), center + Vector3(0, 0.05, 0)))
	Blocks.hidden_solid(_nav, center + Vector3(0, 0.3, 0), Vector3(4.2, 0.6, 4.2))
	for d: Vector3 in [Vector3(-0.8, 0.05, 0.4), Vector3(0.9, 0.05, -0.5)]:
		var duck: Node3D = ModelPainter.load_model("duck")
		duck.position = center + d
		duck.rotation.y = d.x * 2.0
		add_child(duck)


func _grass_blocked(p: Vector2) -> bool:
	if p.y < SEA_Z + 1.5:
		return true
	var road: bool = (absf(p.y + 22) < 3.2 or absf(p.y - 22) < 3.2) and absf(p.x) < 27.0
	road = road or ((absf(p.x + 24) < 3.2 or absf(p.x - 24) < 3.2) and absf(p.y) < 25.0)
	for spot: Vector3 in TERRACES:
		if absf(p.x - spot.x) < 6.4 and absf(p.y - spot.z) < 3.0:
			return true
	var buildings: Array[Vector3] = HOUSES.duplicate()
	buildings.append_array([BAKERY_POS, CAFE_POS, TOY_SHOP_POS, BARN_POS, CLOCK_POS])
	for spot: Vector3 in buildings:
		if absf(p.x - spot.x) < 3.8 and absf(p.y - spot.z) < 3.5:
			return true
	return road


## Town life: the red bus and a taxi drive round, a dog strolls in the park.
func _populate(life: TownLife) -> void:
	life.add_vehicle("double_decker", &"bus", TownLife.ROAD_LOOP, 3.0, 0)
	life.add_vehicle("taxi", &"taxi", TownLife.ROAD_LOOP, 4.0, 2)
	life.add_wanderer("dog", &"dog", Vector3(-8, 0, 12), 5.0)
	life.add_wanderer("man", &"man", Vector3(-14, 0, 2), 6.0)
	life.add_wanderer("woman", &"woman", Vector3(12, 0, 6), 5.0)
	var lamp_lights: Array[Vector3] = []
	for lamp: Vector3 in LAMPS:
		lamp_lights.append(lamp + Vector3(0, 3.3, 0))
	life.add_day_night(lamp_lights)
	life.add_dress_up(Vector3(-17, 0, -27.2), Vector3(4, 0, -27.2))
	var weather: Weather = Weather.new()
	add_child(weather)
	weather.setup(self)


func _clickable_things() -> Array[Dictionary]:
	return [
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(-20, 0, 2)},
		{"id": &"ball", "uk": "м'яч", "en": "ball", "pos": Vector3(14, 0, 18)},
		{"id": &"dog", "uk": "собака", "en": "dog", "pos": Vector3(10, 0, 16)},
		{"id": &"house", "uk": "будинок", "en": "house", "pos": HOUSES[2]},
		{"id": &"flower", "uk": "квітка", "en": "flower", "pos": Vector3(-6, 0, 18)},
	]


## No postman here; the ferry is moored in the harbour; the baker waits by her bakery.
func _build_story_cast() -> void:
	baker = _add_npc("baker", BAKER_POS)
	toy_maker = _add_npc("toy_maker", TOY_MAKER_POS)
	farmer = _add_npc("farmer", FARMER_POS)
	clock_maker = _add_npc("clock_maker", CLOCK_MAKER_POS)
	# His turn to speak during a talk: the microphone sign at the bottom of the screen.
	say_hud = CanvasLayer.new()
	say_hud.layer = 4
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	center.position.y -= 160
	say_hud.add_child(center)
	_say_mic = MicBubble.new()
	_say_mic.shown = false
	center.add_child(_say_mic)
	add_child(say_hud)


func _add_npc(model_name: String, pos: Vector3) -> StoryNpc:
	var npc: StoryNpc = StoryNpc.new()
	npc.setup(model_name)
	add_child(npc)
	npc.global_position = pos
	npc.rotation.y = PI
	# No collision: a character added after the navigation bake would block paths he walks.
	return npc

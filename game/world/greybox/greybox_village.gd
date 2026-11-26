class_name GreyboxVillage
extends Node3D
## Phase 1 greybox: a village blocked out in plain shapes (road loop, houses, river with a
## bridge, one house with a password door), the hero, the car, Tygrytsa and the follow camera.
## The quest (walk to the car → drive to the marker → walk to the door → open it) is data:
## content/chapters/greybox_loop.tres, run by QuestRunner. This scene is its host.

const CHAPTER_PATH: String = "res://content/chapters/greybox_loop.tres"

const ENTER_DISTANCE: float = 3.5
const IDLE_LOG_SECONDS: float = 5.0
const WALK_OFFSET: Vector3 = Vector3(0, 11, 9)
const DRIVE_OFFSET: Vector3 = Vector3(0, 15, 12.5)
const DOOR_POS: Vector3 = Vector3(-14, 0, -28)
const WELL_POS: Vector3 = Vector3(-19, 0, 5)
const LEAF_COLOR: Color = Color(0.32, 0.60, 0.34)
const PETAL_COLOR: Color = Color(1.0, 0.80, 0.18)
## The sunflower field west of the start, and the village edge for the wicker fence.
const SUNFLOWER_FIELD: Rect2 = Rect2(-37, 8, 9, 12)
const EDGE: float = 40.0
const CAR_START: Vector3 = Vector3(-6, 0, 16)
const HERO_START: Vector3 = Vector3(-14, 0, 8)
## Places that teach a word when he walks or drives past: [word, position, radius, camera offset].
## Words the door may ask: all are things in this village, so each can be taught on the spot.
const DOOR_WORDS: Array[StringName] = [
	&"tree", &"flower", &"duck", &"dog", &"ball", &"house", &"bridge", &"car", &"river", &"road"
]
const DOOR_OPTIONS: int = 3
const LEARNING_SPOTS: Array[Array] = [
	[&"bridge", Vector3(12, 0, -22), 3.5, Vector3(7, 4, 6)],
	[&"bridge", Vector3(12, 0, 22), 3.5, Vector3(7, 4, -6)],
	[&"river", Vector3(9, 0, 5), 2.5, Vector3(-4, 5, 5)],
	[&"river", Vector3(9, 0, -10), 2.5, Vector3(-4, 5, 5)],
	[&"river", Vector3(15, 0, 8), 2.5, Vector3(4, 5, 5)],
	[&"road", Vector3(-24, 0, 8), 3.0, Vector3(6, 5, 6)],
	[&"road", Vector3(0, 0, 22), 3.0, Vector3(5, 5, 7)],
	[&"fence", Vector3(-37, 0, 0), 3.0, Vector3(6, 3, 4)],
	[&"fence", Vector3(37, 0, 0), 3.0, Vector3(-6, 3, 4)],
	[&"fence", Vector3(0, 0, -37), 3.0, Vector3(4, 3, 6)],
	[&"fence", Vector3(0, 0, 37), 3.0, Vector3(4, 3, -6)],
]

var hero: Hero
var car: Car
var companion: Companion
var door: PasswordDoor
var marker: GoalMarker
var pointer: PointerInput
var pause_overlay: PauseOverlay
var learning: LearningDirector
var session: SessionTimer
var parent_screen: ParentScreen
var quest: QuestRunner

var _walk_cam: PhantomCamera3D
var _drive_cam: PhantomCamera3D
var _nav: NavigationRegion3D
var _pending_enter: bool = false
var _last_input_ms: int = 0
var _taught_car: bool = false
var _word_places: Dictionary[StringName, Array] = {}
var _pending_door_word: StringName = &""
var _last_door_word: StringName = &""
var _find_target: Clickable
var _find_wrong: int = 0
var _pending_find_word: StringName = &""


func _ready() -> void:
	_build_environment()
	_nav = NavigationRegion3D.new()
	add_child(_nav)
	_build_ground()
	_build_road()
	_build_river()
	_build_houses()
	_bake_navigation()
	_build_grass()
	_build_actors()
	_build_clickables()
	_build_camera()
	_build_learning()
	pointer = PointerInput.new()
	add_child(pointer)
	pointer.ground_clicked.connect(_on_ground_clicked)
	pointer.ground_held.connect(_on_ground_held)
	pointer.pickable_clicked.connect(_on_pickable_clicked)
	pointer.card_hovered.connect(func(card: PasswordCard) -> void: door.hover(card))
	pointer.any_input.connect(_on_any_input)
	pause_overlay = PauseOverlay.new()
	add_child(pause_overlay)
	_build_parent_area()
	_last_input_ms = Time.get_ticks_msec()
	EventLog.log_event(&"session_start", {"scene": "greybox_village"})
	Speech.line("line:intro")
	quest = QuestRunner.new()
	add_child(quest)
	quest.start(load(CHAPTER_PATH), self)


func _unhandled_input(event: InputEvent) -> void:
	if door.is_active():
		if event.is_action_pressed(&"move_left"):
			door.focus_step(-1)
		elif event.is_action_pressed(&"move_right"):
			door.focus_step(1)
		elif event.is_action_pressed(&"use"):
			door.pick_focused()
		return
	if event.is_action_pressed(&"use"):
		if car.driving:
			_exit_car()
		elif hero.global_position.distance_to(car.global_position) <= ENTER_DISTANCE:
			_enter_car()
	elif event.is_action_pressed(&"horn") and car.driving:
		car.honk()


# --- Input from the pointer -------------------------------------------------------------


func _on_ground_clicked(point: Vector3) -> void:
	_pending_enter = false
	if car.driving:
		car.drive_to(point)
	else:
		hero.go_to(point)


func _on_ground_held(point: Vector3) -> void:
	_on_ground_clicked(point)


func _on_pickable_clicked(area: Area3D) -> void:
	if area is PasswordCard:
		door.pick(area)
	elif area is Clickable and _find_target != null:
		_on_find_click(area)
	elif area is Clickable:
		var thing: Clickable = area
		thing.activate(false)
		if not learning.request(thing.word_id, thing.global_position, thing.picture_view()):
			thing.say_name()
	elif area.has_meta(&"car"):
		if car.driving:
			car.honk()
		elif hero.global_position.distance_to(car.global_position) <= ENTER_DISTANCE:
			_enter_car()
		else:
			_pending_enter = true
			hero.go_to(car.global_position + Vector3(-1.8, 0, 0))


func _on_any_input() -> void:
	var now: int = Time.get_ticks_msec()
	var gap: float = (now - _last_input_ms) / 1000.0
	if gap >= IDLE_LOG_SECONDS:
		EventLog.log_event(&"idle", {"seconds": snappedf(gap, 0.1)})
	_last_input_ms = now


# --- Car ----------------------------------------------------------------------------------


func _enter_car() -> void:
	_pending_enter = false
	hero.stop()
	hero.visible = false
	hero.process_mode = Node.PROCESS_MODE_DISABLED
	car.driving = true
	companion.follow = car
	_drive_cam.priority = 20
	Sfx.play(&"pop")
	EventLog.log_event(&"car_enter")
	if not _taught_car:
		_taught_car = learning.offer(&"car", car.global_position, car.global_position + Vector3(4, 3, 5))
	quest.notify_car_entered()  # the next instruction waits for the card


func _exit_car() -> void:
	car.driving = false
	car.stop()
	var side: Vector3 = car.global_transform.basis.x.normalized() * -2.2
	hero.global_position = car.global_position + side
	hero.visible = true
	hero.process_mode = Node.PROCESS_MODE_INHERIT
	companion.follow = hero
	_drive_cam.priority = 0
	Sfx.play(&"pop")
	EventLog.log_event(&"car_exit")


func _physics_process(_delta: float) -> void:
	if _pending_enter and not car.driving:
		if hero.global_position.distance_to(car.global_position) <= ENTER_DISTANCE:
			_enter_car()


# --- Quest host (called by QuestRunner) --------------------------------------------


func place_marker(pos: Vector3) -> void:
	clear_marker()
	marker = GoalMarker.new()
	add_child(marker)
	marker.global_position = Vector3(pos.x, 0.0, pos.z)
	marker.reached.connect(_on_marker_reached)


func clear_marker() -> void:
	if marker != null:
		marker.queue_free()
		marker = null


func set_hint(goal: Node3D, line_key: String) -> void:
	companion.set_goal(goal, line_key)


## Says an instruction, after any open learning card has finished.
func say_when_free(key: String) -> void:
	if learning.is_open():
		await learning.moment_closed
	Speech.line(key)


func car_position() -> Vector3:
	return car.global_position


func exit_car() -> void:
	_exit_car()


## Find the object (teach before test): asks for a thing he has already learned; if none, teaches
## one first. Wrong clicks say the clicked thing's name and repeat the ask; after 2 the target
## glows under a marker.
func start_find() -> void:
	var things: Array[Clickable] = _clickables()
	var ids: Array[StringName] = []
	for thing: Clickable in things:
		if not ids.has(thing.word_id):
			ids.append(thing.word_id)
	var taught: Array[StringName] = learning.taught_words().filter(
		func(w: StringName) -> bool: return ids.has(w)
	)
	if taught.is_empty():
		_pending_find_word = ids.pick_random()
		Speech.line("line:teach", null, true)
		var place: Array = _picture_of(_pending_find_word)
		if learning.request(_pending_find_word, place[0], place[1]):
			return
		taught = [_pending_find_word]
	_begin_find(LearningTracker.most_needed(taught)[0])


func _begin_find(word_id: StringName) -> void:
	_pending_find_word = &""
	var candidates: Array[Clickable] = _clickables().filter(
		func(c: Clickable) -> bool: return c.word_id == word_id
	)
	_find_target = candidates.pick_random()
	_find_target.set_highlight(true)
	_find_wrong = 0
	var word: WordEntry = WordDB.get_word(word_id)
	say_when_free_word("find:ask", word)
	companion.set_goal(_find_target, "find:hint", word)
	EventLog.log_event(&"find_ask", {"word": String(word_id)})


func _on_find_click(thing: Clickable) -> void:
	var word: WordEntry = WordDB.get_word(_find_target.word_id)
	EventLog.log_event(&"find_pick", {"word": String(thing.word_id), "correct": thing.word_id == word.id})
	if thing.word_id == word.id:
		thing.activate()
		Sfx.play(&"chime")
		if _find_wrong == 0:
			LearningTracker.record_answer(word.id, true)
		Speech.line("find:yes", word, true)
		_find_target.set_highlight(false)
		_find_target = null
		clear_marker()
		quest.notify_found()
		return
	_find_wrong += 1
	if _find_wrong == 1:
		LearningTracker.record_answer(word.id, false)
	thing.activate()
	thing.say_name()
	if _find_wrong >= 2:
		place_marker(_find_target.global_position)
		Speech.line("find:glow", word)
	else:
		Speech.line("find:retry", word)


func _clickables() -> Array[Clickable]:
	var out: Array[Clickable] = []
	for child: Node in get_children():
		if child is Clickable:
			out.append(child)
	return out


## Like say_when_free, for a line that names a word.
func say_when_free_word(key: String, word: WordEntry) -> void:
	if learning.is_open():
		await learning.moment_closed
	Speech.line(key, word)


func _on_marker_reached(body: Node3D) -> void:
	if _find_target != null:
		return
	quest.notify_marker_reached(&"car" if body == car else &"hero")


func _on_cards_shown() -> void:
	hero.stop()
	hero.keyboard_enabled = false
	quest.notify_door_question()


func _on_cards_hidden() -> void:
	hero.keyboard_enabled = true


func _on_door_opened(_word: StringName, _wrong: int) -> void:
	quest.notify_door_opened()


# --- Building the world ---------------------------------------------------------------


func _build_parent_area() -> void:
	session = SessionTimer.new()
	add_child(session)
	parent_screen = ParentScreen.new()
	add_child(parent_screen)
	var gate: ParentGate = ParentGate.new()
	add_child(gate)
	var was_paused: Array[bool] = [false]
	gate.unlocked.connect(
		func() -> void:
			# Over a learning card the parent gate is the parent's override: close the card only.
			if learning.is_open():
				learning.card.parent_close()
				return
			was_paused[0] = get_tree().paused
			get_tree().paused = true
			parent_screen.open()
	)
	parent_screen.closed.connect(
		func() -> void:
			session.refresh_limit()
			get_tree().paused = was_paused[0] or session.visible
	)
	parent_screen.extend_requested.connect(
		func() -> void:
			was_paused[0] = false
			session.extend()
			parent_screen.close()
	)


func _build_learning() -> void:
	learning = LearningDirector.new()
	add_child(learning)
	learning.is_busy = func() -> bool: return door.is_active() or pause_overlay.visible
	for spot_data: Array in LEARNING_SPOTS:
		var spot: LearningSpot = LearningSpot.new()
		spot.setup(spot_data[0], spot_data[2], spot_data[3])
		add_child(spot)
		spot.global_position = spot_data[1]
		spot.passed.connect(_on_learning_spot)
		_remember_place(spot.word_id, spot.global_position, spot.global_position + spot.view_offset)
	for child: Node in get_children():
		if child is Clickable:
			var thing: Clickable = child
			_remember_place(thing.word_id, thing.global_position, thing.picture_view())
	_remember_place(&"car", car.global_position, car.global_position + Vector3(4, 3, 5))
	learning.moment_closed.connect(_on_moment_closed)


func _remember_place(word_id: StringName, focus: Vector3, view_from: Vector3) -> void:
	if not _word_places.has(word_id):
		_word_places[word_id] = [focus, view_from]


func _picture_of(word_id: StringName) -> Array:
	if word_id == &"car":
		return [car.global_position, car.global_position + Vector3(4, 3, 5)]
	return _word_places.get(word_id, [door.global_position, door.global_position + Vector3(4, 3, 6)])


# --- Teach before test: the door only asks words he has already met ------------------


func _on_door_wants_question() -> void:
	var taught: Array[StringName] = learning.taught_words().filter(
		func(w: StringName) -> bool: return DOOR_WORDS.has(w) and w != _last_door_word
	)
	if not taught.is_empty():
		# Smart repetition: the word he most needs (lowest box, longest ago) comes first.
		_ask_door(LearningTracker.most_needed(taught)[0])
		return
	# Nothing taught yet: teach a word right here, then ask it.
	var fresh: Array[StringName] = DOOR_WORDS.filter(func(w: StringName) -> bool: return w != _last_door_word)
	_pending_door_word = fresh.pick_random()
	Speech.line("line:teach", null, true)
	var place: Array = _picture_of(_pending_door_word)
	if not learning.request(_pending_door_word, place[0], place[1]):
		_ask_door(_pending_door_word)


func _on_moment_closed(word_id: StringName) -> void:
	if word_id == _pending_find_word:
		_begin_find(word_id)
	if word_id == _pending_door_word:
		_pending_door_word = &""
		if door.is_hero_inside():
			_ask_door(word_id)


func _ask_door(answer_id: StringName) -> void:
	var answer: WordEntry = WordDB.get_word(answer_id)
	if answer == null:
		return
	_last_door_word = answer_id
	var pool: Array[StringName] = learning.taught_words().filter(
		func(w: StringName) -> bool: return w != answer_id
	)
	pool.shuffle()
	var rest: Array[StringName] = DOOR_WORDS.filter(
		func(w: StringName) -> bool: return w != answer_id and not pool.has(w)
	)
	rest.shuffle()
	pool.append_array(rest)
	var others: Array[WordEntry] = []
	for w: StringName in pool:
		if others.size() >= DOOR_OPTIONS - 1:
			break
		var entry: WordEntry = WordDB.get_word(w)
		if entry != null:
			others.append(entry)
	var place: Array = _picture_of(answer_id)
	door.ask(answer, others, place[0], place[1])


func _on_learning_spot(spot: LearningSpot) -> void:
	learning.offer(spot.word_id, spot.global_position, spot.global_position + spot.view_offset)


func _build_environment() -> void:
	var env: Environment = Environment.new()
	env.background_mode = Environment.BG_SKY
	# Painted sky with drifting clouds; its radiance isn't used for light, so it is computed
	# rarely (ambient light comes from a colour), which keeps it cheap.
	var sky: Sky = Sky.new()
	var sky_mat: ShaderMaterial = ShaderMaterial.new()
	sky_mat.shader = preload("res://game/art/painted_sky.gdshader")
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	# Golden morning (time-of-day preset): warm key light, cool blue-violet fill.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.56, 0.62, 0.82)
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.04
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.86, 0.66)
	sun.light_energy = 0.95
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _build_ground() -> void:
	var ground: StaticBody3D = Blocks.solid_box(
		_nav, Vector3(0, -0.5, 0), Vector3(90, 1, 90), Color(0.5, 0.72, 0.38)
	)
	# A soft painted colour wash across the meadow.
	(ground.get_child(1) as MeshInstance3D).material_override = PaintedMaterials.make(
		Color(0.5, 0.72, 0.38), 0.0, 0.35
	)
	# Low fences at the edge so nobody leaves the village.
	for side: Vector3 in [Vector3(0, 0.4, -40), Vector3(0, 0.4, 40)]:
		Blocks.solid_box(_nav, side, Vector3(80, 0.8, 0.4), Color(0.85, 0.75, 0.55))
	for side: Vector3 in [Vector3(-40, 0.4, 0), Vector3(40, 0.4, 0)]:
		Blocks.solid_box(_nav, side, Vector3(0.4, 0.8, 80), Color(0.85, 0.75, 0.55))


func _build_grass() -> void:
	var grass: WindGrass = WindGrass.new()
	add_child(grass)
	grass.scatter(Rect2(-38, -38, 76, 76), 2500, _grass_blocked)
	_build_sunflower_field()
	_build_fence_ring()
	add_child(PerfMonitor.new())


## A field of sunflowers swaying in the wind: one MultiMesh (a few draw calls for all of them).
func _build_sunflower_field() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 11
	var spots: Array[Transform3D] = []
	var step: float = 1.4
	var x: float = SUNFLOWER_FIELD.position.x
	while x < SUNFLOWER_FIELD.end.x:
		var z: float = SUNFLOWER_FIELD.position.y
		while z < SUNFLOWER_FIELD.end.y:
			var jitter: Vector3 = Vector3(rng.randf_range(-0.4, 0.4), 0, rng.randf_range(-0.4, 0.4))
			var basis: Basis = Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)).scaled(
				Vector3.ONE * rng.randf_range(0.85, 1.15)
			)
			spots.append(Transform3D(basis, Vector3(x, 0, z) + jitter))
			z += step
		x += step
	add_child(_multimesh("sunflower", spots, [PETAL_COLOR, Color(0.38, 0.62, 0.30)]))


## The wicker fence (tyn) all around the village edge, one MultiMesh.
func _build_fence_ring() -> void:
	var spots: Array[Transform3D] = []
	var x: float = -EDGE + 1.0
	while x < EDGE:
		spots.append(Transform3D(Basis(), Vector3(x, 0, -EDGE)))
		spots.append(Transform3D(Basis(), Vector3(x, 0, EDGE)))
		spots.append(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(-EDGE, 0, x)))
		spots.append(Transform3D(Basis(Vector3.UP, PI / 2.0), Vector3(EDGE, 0, x)))
		x += 2.0
	add_child(_multimesh("fence", spots))
	for child: Node in _nav.get_children():
		# The old plain edge boards are now only collision.
		if child is StaticBody3D and absf((child as StaticBody3D).position.y - 0.4) < 0.01:
			(child.get_child(1) as MeshInstance3D).visible = false


func _multimesh(
	model_name: String, spots: Array[Transform3D], sway_colors: Array[Color] = []
) -> MultiMeshInstance3D:
	var mm: MultiMesh = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = ModelPainter.merged_mesh(model_name, sway_colors)
	mm.instance_count = spots.size()
	for i: int in spots.size():
		mm.set_instance_transform(i, spots[i])
	var inst: MultiMeshInstance3D = MultiMeshInstance3D.new()
	inst.multimesh = mm
	return inst


## Where no grass grows: roads, the river and bridges, houses, the door house.
func _grass_blocked(p: Vector2) -> bool:
	var road: bool = (absf(p.y + 22) < 3.2 or absf(p.y - 22) < 3.2) and absf(p.x) < 27.0
	road = road or ((absf(p.x + 24) < 3.2 or absf(p.x - 24) < 3.2) and absf(p.y) < 25.0)
	var river: bool = absf(p.x - 12) < 2.6
	if SUNFLOWER_FIELD.grow(0.5).has_point(p) or p.distance_to(Vector2(WELL_POS.x, WELL_POS.z)) < 1.4:
		return true
	var door_house: bool = absf(p.x - DOOR_POS.x) < 4.5 and p.y < DOOR_POS.z + 1.0 and p.y > DOOR_POS.z - 8.0
	for h: Vector2 in [Vector2(2, -4), Vector2(4, 8), Vector2(-30, -8), Vector2(30, 6), Vector2(-4, 30)]:
		if absf(p.x - h.x) < 3.3 and absf(p.y - h.y) < 3.0:
			return true
	return road or river or door_house


func _build_road() -> void:
	var road: Color = Color(0.6, 0.58, 0.55)
	add_child(Blocks.box_mesh(Vector3(52, 0.04, 5), road, Vector3(0, 0.02, -22)))
	add_child(Blocks.box_mesh(Vector3(52, 0.04, 5), road, Vector3(0, 0.02, 22)))
	add_child(Blocks.box_mesh(Vector3(5, 0.04, 44), road, Vector3(-24, 0.02, 0)))
	add_child(Blocks.box_mesh(Vector3(5, 0.04, 44), road, Vector3(24, 0.02, 0)))


func _build_river() -> void:
	# The river runs north–south at x = 12, crossed by the road on two bridges.
	var water: Color = Color(0.35, 0.6, 0.85)
	for segment: Vector2 in [Vector2(-37, -25.5), Vector2(-18.5, 18.5), Vector2(25.5, 37)]:
		var length: float = segment.y - segment.x
		var center: float = (segment.x + segment.y) / 2.0
		Blocks.solid_box(_nav, Vector3(12, 0.1, center), Vector3(4, 0.4, length), water)
	for z: float in [-22.0, 22.0]:
		add_child(Blocks.box_mesh(Vector3(5, 0.25, 7), Color(0.65, 0.5, 0.35), Vector3(12, 0.12, z)))


func _build_houses() -> void:
	var walls: Array[Color] = [Color(0.95, 0.9, 0.8), Color(0.9, 0.85, 0.95), Color(1.0, 0.92, 0.75)]
	var roofs: Array[Color] = [Color(0.75, 0.35, 0.3), Color(0.45, 0.4, 0.65), Color(0.85, 0.55, 0.25)]
	var spots: Array[Vector3] = [
		Vector3(2, 0, -4), Vector3(4, 0, 8), Vector3(-30, 0, -8), Vector3(30, 0, 6), Vector3(-4, 0, 30)
	]
	# White hatas with thatched roofs, fronts facing south (toward the camera).
	for spot: Vector3 in spots:
		Blocks.hidden_solid(_nav, spot + Vector3(0, 1.75, 0), Vector3(5, 3.5, 4.5))
		add_child(Blocks.prop("hata", spot, 180.0))
	# The house with the password door: a bigger hata; its own model door is left out, the
	# PasswordDoor panel takes its place.
	Blocks.hidden_solid(_nav, DOOR_POS + Vector3(0, 2.25, -3.5), Vector3(7, 4.5, 7))
	var door_house: MeshInstance3D = MeshInstance3D.new()
	door_house.mesh = ModelPainter.merged_mesh("hata", [], 0.0, ["Door"])
	door_house.position = DOOR_POS + Vector3(0, 0, -3.5)
	door_house.rotation_degrees.y = 180.0
	door_house.scale = Vector3(1.4, 1.3, 1.58)
	add_child(door_house)
	# A well by the path.
	Blocks.hidden_solid(_nav, WELL_POS + Vector3(0, 0.6, 0), Vector3(1.5, 1.2, 1.5))
	add_child(Blocks.prop("well", WELL_POS, 30.0))
	door = PasswordDoor.new()
	add_child(door)
	door.position = DOOR_POS + Vector3(0, 0, 0.1)
	door.cards_shown.connect(_on_cards_shown)
	door.cards_hidden.connect(_on_cards_hidden)
	door.opened.connect(_on_door_opened)
	door.wants_question.connect(_on_door_wants_question)
	# Tree trunks block the way; the clickable trees draw their own tree, the rest are props.
	var clickable_trees: Array[Vector3] = [Vector3(-10, 0, 2), Vector3(16, 0, -6)]
	for t: Vector3 in [
		Vector3(-10, 0, 2), Vector3(-18, 0, -2), Vector3(16, 0, -6), Vector3(18, 0, 12), Vector3(-30, 0, 30)
	]:
		Blocks.hidden_solid(_nav, t + Vector3(0, 1, 0), Vector3(0.5, 2, 0.5))
		if not clickable_trees.has(t):
			add_child(Blocks.prop("tree", t, t.x * 37.0, Vector3.ONE, [LEAF_COLOR]))


func _bake_navigation() -> void:
	var nav_mesh: NavigationMesh = NavigationMesh.new()
	nav_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nav_mesh.agent_radius = 0.5
	nav_mesh.agent_height = 1.5
	nav_mesh.agent_max_climb = 0.3
	_nav.navigation_mesh = nav_mesh
	_nav.bake_navigation_mesh(false)


func _build_actors() -> void:
	hero = Hero.new()
	add_child(hero)
	hero.global_position = HERO_START
	car = Car.new()
	add_child(car)
	car.global_position = CAR_START
	car.rotation.y = PI / 2.0
	companion = Companion.new()
	add_child(companion)
	companion.global_position = HERO_START + Companion.FOLLOW_OFFSET
	companion.follow = hero


func _build_clickables() -> void:
	var things: Array[Dictionary] = [
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(-10, 0, 2)},
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(16, 0, -6)},
		{"id": &"flower", "uk": "квітка", "en": "flower", "pos": Vector3(-8, 0, 10)},
		{"id": &"sunflower", "uk": "соняшник", "en": "sunflower", "pos": Vector3(-17, 0, 12)},
		{"id": &"ball", "uk": "м'яч", "en": "ball", "pos": Vector3(-12, 0, 13)},
		{"id": &"duck", "uk": "качка", "en": "duck", "pos": Vector3(12, 0, 4)},
		{"id": &"dog", "uk": "собака", "en": "dog", "pos": Vector3(0, 0, 14)},
		{"id": &"house", "uk": "будинок", "en": "house", "pos": Vector3(4, 0, 8)},
	]
	for thing: Dictionary in things:
		var art: Node3D = _art_for(thing["id"])
		var size: Vector3 = Vector3(2.0, 2.5, 2.0)
		if thing["id"] == &"house":
			art = Node3D.new()
			size = Vector3(5.6, 4.5, 5.2)
		var c: Clickable = Clickable.new()
		c.name = String(thing["id"]).capitalize()
		c.setup(thing["id"], thing["uk"], thing["en"], art, size)
		add_child(c)
		c.global_position = thing["pos"]


func _art_for(id: StringName) -> Node3D:
	var root: Node3D = Node3D.new()
	match id:
		&"tree":
			root.add_child(Blocks.prop("tree", Vector3.ZERO, 40.0, Vector3.ONE, [LEAF_COLOR]))
		&"sunflower":
			root.add_child(Blocks.prop("sunflower", Vector3.ZERO, 0.0, Vector3.ONE, [PETAL_COLOR]))
		&"flower":
			var head: SphereMesh = SphereMesh.new()
			head.radius = 0.35
			head.height = 0.3
			root.add_child(Blocks.box_mesh(Vector3(0.1, 1.2, 0.1), Color(0.3, 0.6, 0.3), Vector3(0, 0.6, 0)))
			root.add_child(Blocks.mesh(head, Color(1.0, 0.85, 0.2), Vector3(0, 1.3, 0), 0.06))
		&"ball":
			var ball: SphereMesh = SphereMesh.new()
			ball.radius = 0.4
			ball.height = 0.8
			root.add_child(Blocks.mesh(ball, Color(0.9, 0.3, 0.35), Vector3(0, 0.4, 0)))
		&"duck":
			var duck: SphereMesh = SphereMesh.new()
			duck.radius = 0.4
			duck.height = 0.6
			root.add_child(Blocks.mesh(duck, Color(1.0, 0.95, 0.5), Vector3(0, 0.35, 0)))
			var head: SphereMesh = SphereMesh.new()
			head.radius = 0.22
			head.height = 0.44
			root.add_child(Blocks.mesh(head, Color(1.0, 0.95, 0.5), Vector3(0, 0.75, -0.3)))
		&"dog":
			root.add_child(
				Blocks.box_mesh(Vector3(0.6, 0.5, 1.1), Color(0.75, 0.55, 0.35), Vector3(0, 0.55, 0))
			)
			root.add_child(
				Blocks.box_mesh(Vector3(0.45, 0.45, 0.45), Color(0.75, 0.55, 0.35), Vector3(0, 0.95, -0.6))
			)
	return root


func _build_camera() -> void:
	var camera: Camera3D = Camera3D.new()
	camera.fov = 50.0
	add_child(camera)
	camera.add_child(PhantomCameraHost.new())
	_walk_cam = _make_pcam(hero, WALK_OFFSET, 10)
	_drive_cam = _make_pcam(car, DRIVE_OFFSET, 0)
	camera.global_position = hero.global_position + WALK_OFFSET
	camera.look_at(hero.global_position)


func _make_pcam(target: Node3D, offset: Vector3, prio: int) -> PhantomCamera3D:
	var pcam: PhantomCamera3D = PhantomCamera3D.new()
	add_child(pcam)
	pcam.follow_mode = PhantomCamera3D.FollowMode.SIMPLE
	pcam.follow_target = target
	pcam.follow_offset = offset
	pcam.follow_damping = true
	pcam.follow_damping_value = Vector3(0.3, 0.3, 0.3)
	pcam.rotation = Vector3(-atan2(offset.y, offset.z), 0, 0)
	var tween: PhantomCameraTween = PhantomCameraTween.new()
	tween.duration = 0.9
	tween.transition = PhantomCameraTween.TransitionType.SINE
	tween.ease = PhantomCameraTween.EaseType.EASE_IN_OUT
	pcam.tween_resource = tween
	pcam.priority = prio
	return pcam

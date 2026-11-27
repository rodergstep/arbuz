class_name GreyboxVillage
extends Node3D
## Phase 1 greybox: a village blocked out in plain shapes (road loop, houses, river with a
## bridge, one house with a password door), the hero, the car, Tygrytsa and the follow camera.
## The quest (walk to the car → drive to the marker → walk to the door → open it) is data:
## content/chapters/greybox_loop.tres, run by QuestRunner. This scene is its host.

const CHAPTER_PATH: String = "res://content/chapters/greybox_loop.tres"
## The story start, played once (until finished; then the practice loop).
const PROLOGUE_PATH: String = "res://content/chapters/prologue.tres"
const PROLOGUE_DONE: String = "chapter:prologue"
const ENGLAND_SCENE: String = "res://game/world/england/england_town.tscn"
const POSTMAN_POS: Vector3 = Vector3(-15, 0, 14.5)
const FERRY_DOCK: Vector3 = Vector3(12, 0, 14)
const FERRY_TRIP: Vector3 = Vector3(0, 0, -18)

const ENTER_DISTANCE: float = 3.5
const IDLE_LOG_SECONDS: float = 5.0
const WALK_OFFSET: Vector3 = Vector3(0, 11, 9)
const DRIVE_OFFSET: Vector3 = Vector3(0, 15, 12.5)
const WELL_POS: Vector3 = Vector3(-19, 0, 5)
const LEAF_COLOR: Color = Color(0.32, 0.60, 0.34)
const PETAL_COLOR: Color = Color(1.0, 0.80, 0.18)
## The sunflower field west of the start, and the village edge for the wicker fence.
const SUNFLOWER_FIELD: Rect2 = Rect2(-37, 8, 9, 12)
const EDGE: float = 40.0
const DOOR_OPTIONS: int = 3
## How the country looks: its light, sky, ground, grass and roads. Ukraine: a warm golden summer,
## a deep blue sky, yellow-green meadows and earth roads. England sets its own in _configure().
const UKRAINE_LOOK: Dictionary = {
	"sky_top": Color(0.30, 0.55, 0.92),
	"sky_horizon": Color(1.0, 0.88, 0.66),
	"cloud_cover": 0.42,
	"sun": Color(1.0, 0.84, 0.6),
	"sun_energy": 1.0,
	"ambient": Color(0.56, 0.62, 0.82),
	"saturation": 1.06,
	"ground": Color(0.52, 0.71, 0.33),
	"grass": Color(0.48, 0.71, 0.31),
	"road": Color(0.60, 0.47, 0.34),
	"hills": [Color(0.44, 0.64, 0.32), Color(0.54, 0.66, 0.30), Color(0.40, 0.58, 0.32)],
	"fields":
	[Color(0.80, 0.68, 0.34), Color(0.50, 0.68, 0.32), Color(0.86, 0.74, 0.32), Color(0.44, 0.62, 0.30)],
}

## Town layout (a town subclass sets these in _configure()).
var door_pos: Vector3 = Vector3(-14, 0, -28)
var look: Dictionary = UKRAINE_LOOK
## Hidden treasures to find freely: [word id, position], tucked behind houses and fields.
var treasures: Array[Array] = [
	[&"teddy", Vector3(5.2, 0, -4.8)], [&"kite", Vector3(-36, 0, 23)], [&"star", Vector3(17, 0, -27)]
]
var car_start: Vector3 = Vector3(-6, 0, 16)
var hero_start: Vector3 = Vector3(-14, 0, 8)
## Words the door may ask: all are things in this village, so each can be taught on the spot.
var door_words: Array[StringName] = [
	&"tree", &"flower", &"duck", &"dog", &"ball", &"house", &"bridge", &"car", &"river", &"road"
]
## Places that teach a word when he walks or drives past: [word, position, radius, camera offset].
var learning_spots: Array[Array] = [
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
var postman: PostmanNpc
var ferry: Node3D
var say_hud: CanvasLayer
var _say_mic: MicBubble
var _treasure_hunt: TreasureHunt
var _cutscene: bool = false
var _fade_layer: CanvasLayer

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


## A town scene: the hero, car, Tygrytsa, learning moments, doors, find tasks and quests are
## shared; a town subclass overrides _configure() and the _build_* layout methods.
func _configure() -> void:
	pass


## The chapter this town starts with.
func _first_chapter_path() -> String:
	return CHAPTER_PATH if SaveSystem.has_encountered(PROLOGUE_DONE) else PROLOGUE_PATH


func _ready() -> void:
	_configure()
	_build_environment()
	_nav = NavigationRegion3D.new()
	add_child(_nav)
	_build_ground()
	_build_road()
	_build_river()
	_build_houses()
	_build_scenery()
	_bake_navigation()
	_build_grass()
	_build_actors()
	_build_clickables()
	var life: TownLife = TownLife.new()
	add_child(life)
	life.setup(self)
	_populate(life)
	_build_story_cast()
	_build_camera()
	_build_learning()
	_treasure_hunt = TreasureHunt.new()
	add_child(_treasure_hunt)
	_treasure_hunt.setup(self, treasures)
	var car_words: CarWords = CarWords.new()
	add_child(car_words)
	car_words.setup(car, learning)
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
	EventLog.log_event(&"session_start", {"scene": String(name)})
	Speech.line("line:intro")
	quest = QuestRunner.new()
	add_child(quest)
	quest.step_started.connect(_on_step_started)
	quest.start(load(_first_chapter_path()), self)


func _unhandled_input(event: InputEvent) -> void:
	# No gameplay keys during a cutscene or a character's talk (pause has its own handler).
	if _cutscene or _talking():
		return
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
	if _cutscene or _talking():
		return
	_pending_enter = false
	if car.driving:
		car.drive_to(point)
	else:
		hero.go_to(point)


func _on_ground_held(point: Vector3) -> void:
	_on_ground_clicked(point)


func _on_pickable_clicked(area: Area3D) -> void:
	# Story sequences own the input (the postman's talk, the ferry).
	if _cutscene or _talking():
		return
	if area is PasswordCard:
		door.pick(area)
	elif area is CollectItem:
		_on_collect_click(area)
	elif area is Treasure:
		_treasure_hunt.on_click(area)
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


## A town with collect tasks handles the click (Chapter 1).
func _on_collect_click(_item: CollectItem) -> void:
	pass


## True while a character is talking with him.
func _talking() -> bool:
	return postman != null and postman.is_talking()


## Prologue: the postman says hello, gives a letter from England, says bye (talks to the child).
func start_talk(_talk_id: StringName = &"") -> void:
	hero.stop()
	hero.keyboard_enabled = false
	set_hint(null, "")
	await postman.talk(learning, _say_mic, hero.global_position)
	hero.keyboard_enabled = true
	quest.notify_talk_done()


## Prologue end: the car rolls onto the ferry, which sails away up the river ("Bye bye, village!
## Hello, England!"); a soft fade, and the village is ready to play again.
func play_ferry() -> void:
	_cutscene = true
	car.driving = true
	car.stop()
	car.process_mode = Node.PROCESS_MODE_DISABLED
	companion.visible = false
	Speech.line("ferry:board", null, true)
	var deck: Vector3 = ferry.global_position + Vector3(0, 0.6, 0.4)
	var board: Tween = create_tween()
	board.tween_property(car, "global_position", deck, 2.2).set_trans(Tween.TRANS_SINE)
	board.parallel().tween_property(car, "rotation:y", 0.0, 1.0)
	await board.finished
	car.reparent(ferry)
	Speech.line("ferry:bye")
	Sfx.play(&"horn")
	var sail: Tween = create_tween()
	sail.tween_property(ferry, "global_position", FERRY_DOCK + FERRY_TRIP, 8.0).set_trans(Tween.TRANS_SINE)
	await sail.finished
	await _fade(true)
	# The prologue's ferry goes to England: switch to the English town while the screen is dark.
	if quest.chapter != null and quest.chapter.id == &"prologue":
		quest.notify_ferry_done()
		get_tree().change_scene_to_file(ENGLAND_SCENE)
		return
	car.reparent(self)
	ferry.global_position = FERRY_DOCK
	car.global_position = car_start
	car.rotation.y = PI / 2.0
	car.process_mode = Node.PROCESS_MODE_INHERIT
	_exit_car()
	hero.global_position = hero_start
	companion.global_position = hero_start + Companion.FOLLOW_OFFSET
	companion.visible = true
	_cutscene = false
	await _fade(false)
	quest.notify_ferry_done()


func _fade(to_dark: bool) -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	layer.layer = 8
	var rect: ColorRect = ColorRect.new()
	rect.color = Color(UiTokens.BG_SKY, 0.0 if to_dark else 1.0)
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(rect)
	add_child(layer)
	var tween: Tween = create_tween()
	tween.tween_property(rect, "color:a", 1.0 if to_dark else 0.0, 1.2)
	await tween.finished
	if to_dark:
		_fade_layer = layer
	else:
		if _fade_layer != null:
			_fade_layer.queue_free()
			_fade_layer = null
		layer.queue_free()


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
	# His album of friends and treasures (the book button in the corner).
	add_child(Album.new())
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


func _build_story_cast() -> void:
	postman = PostmanNpc.new()
	add_child(postman)
	postman.global_position = POSTMAN_POS
	Blocks.hidden_solid(_nav, POSTMAN_POS + Vector3(0, 0.9, 0), Vector3(0.6, 1.8, 0.6))
	ferry = Node3D.new()
	ferry.add_child(Blocks.prop("ferry", Vector3.ZERO))
	add_child(ferry)
	ferry.global_position = FERRY_DOCK
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


func _build_learning() -> void:
	learning = LearningDirector.new()
	add_child(learning)
	learning.is_busy = func() -> bool:
		return door.is_active() or pause_overlay.visible or _cutscene or _talking()
	for spot_data: Array in learning_spots:
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


## If he is already standing at the door when the quest gets there, ask now.
func _on_step_started(_index: int, _step: QuestStep) -> void:
	if door != null and door.is_hero_inside() and not door.is_active():
		_on_door_wants_question.call_deferred()


## The door only asks when the quest is at it (walking to the door, or the door step), so
## passing by during another task never pops the cards up.
func _door_step_near() -> bool:
	var step: QuestStep = quest.current() if quest != null else null
	if step == null:
		return false
	return step.kind == QuestStep.Kind.OPEN_DOOR or quest.next_is(QuestStep.Kind.OPEN_DOOR)


func _on_door_wants_question() -> void:
	if not _door_step_near():
		return
	var taught: Array[StringName] = learning.taught_words().filter(
		func(w: StringName) -> bool: return door_words.has(w) and w != _last_door_word
	)
	if not taught.is_empty():
		# Smart repetition: the word he most needs (lowest box, longest ago) comes first.
		_ask_door(LearningTracker.most_needed(taught)[0])
		return
	# Nothing taught yet: teach a word right here, then ask it.
	var fresh: Array[StringName] = door_words.filter(func(w: StringName) -> bool: return w != _last_door_word)
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
	var rest: Array[StringName] = door_words.filter(
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
	sky_mat.set_shader_parameter(&"top_color", look["sky_top"])
	sky_mat.set_shader_parameter(&"horizon_color", look["sky_horizon"])
	sky_mat.set_shader_parameter(&"cloud_cover", look["cloud_cover"])
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_QUALITY
	sky.radiance_size = Sky.RADIANCE_SIZE_32
	env.sky = sky
	# Golden morning (time-of-day preset): warm key light, cool blue-violet fill.
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = look["ambient"]
	env.ambient_light_energy = 0.42
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.92
	env.adjustment_enabled = true
	env.adjustment_saturation = look["saturation"]
	env.adjustment_contrast = 1.04
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = look["sun"]
	sun.light_energy = look["sun_energy"]
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
		look["ground"], 0.0, 0.35
	)
	# Low fences at the edge so nobody leaves the village.
	for side: Vector3 in [Vector3(0, 0.4, -40), Vector3(0, 0.4, 40)]:
		Blocks.solid_box(_nav, side, Vector3(80, 0.8, 0.4), Color(0.85, 0.75, 0.55))
	for side: Vector3 in [Vector3(-40, 0.4, 0), Vector3(40, 0.4, 0)]:
		Blocks.solid_box(_nav, side, Vector3(0.4, 0.8, 80), Color(0.85, 0.75, 0.55))


func _build_grass() -> void:
	var grass: WindGrass = WindGrass.new()
	grass.color = look["grass"]
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
	add_child(Scenery.scatter("sunflower", spots, [PETAL_COLOR, Color(0.38, 0.62, 0.30)]))


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
	add_child(Scenery.scatter("fence", spots))
	for child: Node in _nav.get_children():
		# The old plain edge boards are now only collision.
		if child is StaticBody3D and absf((child as StaticBody3D).position.y - 0.4) < 0.01:
			(child.get_child(1) as MeshInstance3D).visible = false


## Where a bush may not go: where no grass grows, and near anything he clicks or walks to.
func _clear_of_things(p: Vector2) -> bool:
	if _grass_blocked(p):
		return true
	var keep_clear: Array[Vector3] = [POSTMAN_POS, hero_start, car_start, door_pos]
	for thing: Dictionary in _clickable_things():
		keep_clear.append(thing["pos"])
	for spot: Array in learning_spots:
		keep_clear.append(spot[1])
	for q: Vector3 in keep_clear:
		if p.distance_to(Vector2(q.x, q.z)) < 3.5:
			return true
	return false


## Where no grass grows: roads, the river and bridges, houses, the door house.
func _grass_blocked(p: Vector2) -> bool:
	var road: bool = (absf(p.y + 22) < 3.2 or absf(p.y - 22) < 3.2) and absf(p.x) < 27.0
	road = road or ((absf(p.x + 24) < 3.2 or absf(p.x - 24) < 3.2) and absf(p.y) < 25.0)
	var river: bool = absf(p.x - 12) < 2.6
	if SUNFLOWER_FIELD.grow(0.5).has_point(p) or p.distance_to(Vector2(WELL_POS.x, WELL_POS.z)) < 1.4:
		return true
	var door_house: bool = absf(p.x - door_pos.x) < 4.5 and p.y < door_pos.z + 1.0 and p.y > door_pos.z - 8.0
	for h: Vector2 in [Vector2(2, -4), Vector2(4, 8), Vector2(-30, -8), Vector2(30, 6), Vector2(-4, 30)]:
		if absf(p.x - h.x) < 3.3 and absf(p.y - h.y) < 3.0:
			return true
	return road or river or door_house


func _build_road() -> void:
	var road: Color = look["road"]
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
	Blocks.hidden_solid(_nav, door_pos + Vector3(0, 2.25, -3.5), Vector3(7, 4.5, 7))
	var door_house: MeshInstance3D = MeshInstance3D.new()
	door_house.mesh = ModelPainter.merged_mesh("hata", [], 0.0, ["Door"])
	door_house.position = door_pos + Vector3(0, 0, -3.5)
	door_house.rotation_degrees.y = 180.0
	door_house.scale = Vector3(1.4, 1.3, 1.58)
	add_child(door_house)
	# A well by the path.
	Blocks.hidden_solid(_nav, WELL_POS + Vector3(0, 0.6, 0), Vector3(1.5, 1.2, 1.5))
	add_child(Blocks.prop("well", WELL_POS, 30.0))
	_make_door()
	# Tree trunks block the way; the clickable trees draw their own tree, the rest are props.
	var clickable_trees: Array[Vector3] = [Vector3(-10, 0, 2), Vector3(16, 0, -6)]
	for t: Vector3 in [
		Vector3(-10, 0, 2), Vector3(-18, 0, -2), Vector3(16, 0, -6), Vector3(18, 0, 12), Vector3(-30, 0, 30)
	]:
		Blocks.hidden_solid(_nav, t + Vector3(0, 1, 0), Vector3(0.5, 2, 0.5))
		if not clickable_trees.has(t):
			add_child(Blocks.prop("tree", t, t.x * 37.0, Vector3.ONE, [LEAF_COLOR]))


## The village's own things: wheat fields, a cherry orchard, poplars along the road, willows by
## the river, haystacks, a stork on its nest, a well sweep, pumpkins, yard fences with clay pots
## and painted gates, and the golden fields and hills beyond the edge.
func _build_scenery() -> void:
	Scenery.backdrop(self, look["hills"], look["fields"], 3)
	var wheat: Array[Transform3D] = Scenery.field(Rect2(27, -37, 10, 10), 0.75, 21, 0.25)
	wheat.append_array(Scenery.field(Rect2(-37, -37, 9, 6), 0.75, 22, 0.25))
	add_child(Scenery.scatter("wheat", wheat, [Color(0.93, 0.76, 0.36)], 0.1))
	for x: float in [-16.0, -12.0, -8.0]:
		for z: float in [-15.0, -11.0]:
			Scenery.solid(_nav, self, "cherry_tree", Vector3(x, 0, z), x * 13.0, Vector3(0.4, 2, 0.4))
	var poplars: Array[Transform3D] = []
	for x: float in [-20.0, -14.0, -8.0, -2.0, 4.0, 20.0]:
		poplars.append(Scenery.at(Vector3(x, 0, -27.5), x * 7.0))
	for z: float in [-12.0, -4.0, 14.0]:
		poplars.append(Scenery.at(Vector3(36.5, 0, z), z * 5.0))
	add_child(Scenery.scatter("poplar", poplars, [Color(0.30, 0.55, 0.28)], 0.04))
	for spot: Vector3 in [Vector3(8.6, 0, -9), Vector3(15.6, 0, 13), Vector3(8.6, 0, 31)]:
		Scenery.solid(
			_nav, self, "willow", spot, spot.z * 9.0, Vector3(0.6, 2, 0.6), 0.9, [Color(0.50, 0.70, 0.36)]
		)
	for spot: Vector3 in [Vector3(-33, 0, -24), Vector3(-29, 0, -27), Vector3(32, 0, 30), Vector3(28, 0, 34)]:
		Scenery.solid(_nav, self, "haystack", spot, spot.x * 11.0, Vector3(2, 2, 2))
	Scenery.solid(_nav, self, "stork_nest", Vector3(-2, 0, -11), 160.0, Vector3(0.4, 5, 0.4))
	Scenery.solid(_nav, self, "zhuravel", Vector3(20, 0, 15), 200.0, Vector3(1.4, 1, 1.4))
	Scenery.solid(_nav, self, "tractor", Vector3(-24, 0, -31), 70.0, Vector3(2.2, 2, 3.2))
	var pumpkins: Array[Transform3D] = Scenery.field(Rect2(-9, 34, 8, 2.5), 1.3, 31, 0.3)
	pumpkins.append_array(Scenery.field(Rect2(33, 9, 3, 4), 1.3, 32, 0.3))
	add_child(Scenery.scatter("pumpkin", pumpkins))
	# Each hata's front yard: a wicker fence with clay pots and a painted gate in the middle.
	var yard: Array[Transform3D] = []
	for spot: Vector3 in [Vector3(4, 0, 8), Vector3(-30, 0, -8), Vector3(30, 0, 6), Vector3(-4, 0, 30)]:
		yard.append(Scenery.at(spot + Vector3(-2.3, 0, 3.6)))
		yard.append(Scenery.at(spot + Vector3(2.3, 0, 3.6)))
		add_child(Blocks.prop("gate", spot + Vector3(0, 0, 3.6)))
	add_child(Scenery.scatter("pot_fence", yard))
	# Wild poppies and cornflowers in the meadows, and soft bushes.
	var meadow: Rect2 = Rect2(-37, -37, 74, 74)
	add_child(Scenery.scatter("poppies", Scenery.loose(meadow, 170, _grass_blocked, 41), [], 0.0))
	add_child(Scenery.scatter("bush", Scenery.loose(meadow, 26, _clear_of_things, 42)))


## The password door at door_pos (its house is built by the town).
func _make_door() -> void:
	door = PasswordDoor.new()
	add_child(door)
	door.position = door_pos + Vector3(0, 0, 0.1)
	door.cards_shown.connect(_on_cards_shown)
	door.cards_hidden.connect(_on_cards_hidden)
	door.opened.connect(_on_door_opened)
	door.wants_question.connect(_on_door_wants_question)


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
	hero.global_position = hero_start
	car = Car.new()
	add_child(car)
	car.global_position = car_start
	car.rotation.y = PI / 2.0
	companion = Companion.new()
	add_child(companion)
	companion.global_position = hero_start + Companion.FOLLOW_OFFSET
	companion.follow = hero


## Town life: a tractor on the road; a hen, a pig, a sheep, grandma and a girl about.
func _populate(life: TownLife) -> void:
	life.add_vehicle("tractor", &"tractor", TownLife.ROAD_LOOP, 2.5, 1)
	life.add_wanderer("hen", &"hen", Vector3(-26, 0, -3), 4.0)
	life.add_wanderer("pig", &"pig", Vector3(-6, 0, 33.5), 3.0)
	life.add_wanderer("sheep", &"sheep", Vector3(30, 0, 31), 4.0)
	life.add_wanderer("grandma", &"grandma", Vector3(-24, 0, 10), 5.0)
	life.add_wanderer("girl", &"girl", Vector3(14, 0, 2), 5.0)
	life.add_dress_up(Vector3(-12, 0, 18), Vector3(-20.5, 0, 18))
	life.add_butterflies(
		[
			Vector3(-32, 0, 14),
			Vector3(-10, 0, 10),
			Vector3(6, 0, 18),
			Vector3(-20, 0, -10),
			Vector3(28, 0, -30)
		]
	)


## Things he can click in this town: {id, uk, en, pos}.
func _clickable_things() -> Array[Dictionary]:
	return [
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(-10, 0, 2)},
		{"id": &"tree", "uk": "дерево", "en": "tree", "pos": Vector3(16, 0, -6)},
		{"id": &"flower", "uk": "квітка", "en": "flower", "pos": Vector3(-8, 0, 10)},
		{"id": &"sunflower", "uk": "соняшник", "en": "sunflower", "pos": Vector3(-17, 0, 12)},
		{"id": &"ball", "uk": "м'яч", "en": "ball", "pos": Vector3(-12, 0, 13)},
		{"id": &"duck", "uk": "качка", "en": "duck", "pos": Vector3(12, 0, 4)},
		{"id": &"dog", "uk": "собака", "en": "dog", "pos": Vector3(0, 0, 14)},
		{"id": &"house", "uk": "будинок", "en": "house", "pos": Vector3(4, 0, 8)},
	]


func _build_clickables() -> void:
	for thing: Dictionary in _clickable_things():
		var art: Node3D = _art_for(thing["id"])
		var size: Vector3 = Vector3(2.0, 2.5, 2.0)
		if art.get_child_count() == 0:
			# The thing's look is drawn by the town (a house); the clickable is only its area.
			size = _pick_size_for(thing["id"])
		var c: Clickable = Clickable.new()
		c.name = String(thing["id"]).capitalize()
		c.setup(thing["id"], thing["uk"], thing["en"], art, size)
		add_child(c)
		c.global_position = thing["pos"]


func _pick_size_for(id: StringName) -> Vector3:
	return Vector3(5.6, 4.5, 5.2) if id == &"house" else Vector3(2.0, 2.5, 2.0)


func _art_for(id: StringName) -> Node3D:
	match id:
		&"tree":
			var root: Node3D = Node3D.new()
			root.add_child(Blocks.prop("tree", Vector3.ZERO, 40.0, Vector3.ONE, [LEAF_COLOR]))
			return root
		&"sunflower":
			var root: Node3D = Node3D.new()
			root.add_child(Blocks.prop("sunflower", Vector3.ZERO, 0.0, Vector3.ONE, [PETAL_COLOR]))
			return root
	return Props.make(id)


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

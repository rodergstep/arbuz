class_name GreyboxVillage
extends Node3D
## Phase 1 greybox: a village blocked out in plain shapes (road loop, houses, river with a
## bridge, one house with a password door), the hero, the car, Тигриця and the follow camera.
## The little quest loop (walk to the car → drive to the marker → walk to the door → open it)
## is hard-coded here for the prototype; Phase 2 moves it into chapter data.

enum Step { TO_CAR, DRIVE, TO_DOOR, DOOR, FREE }

const ENTER_DISTANCE: float = 3.5
const IDLE_LOG_SECONDS: float = 5.0
const WALK_OFFSET: Vector3 = Vector3(0, 11, 9)
const DRIVE_OFFSET: Vector3 = Vector3(0, 15, 12.5)
const DOOR_POS: Vector3 = Vector3(-14, 0, -28)
## Drive targets on the car's side of the river with a clear straight line from the previous
## spot, so driving straight at the marker never hits the water, a house or a tree.
const DRIVE_SPOTS: Array[Vector3] = [Vector3(-24, 0, -6), Vector3(0, 0, -22), Vector3(-30, 0, 20)]
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
var step: Step = Step.TO_CAR

var _walk_cam: PhantomCamera3D
var _drive_cam: PhantomCamera3D
var _nav: NavigationRegion3D
var _drive_spot: int = 0
var _pending_enter: bool = false
var _last_input_ms: int = 0
var _taught_car: bool = false
var _word_places: Dictionary[StringName, Array] = {}
var _pending_door_word: StringName = &""
var _last_door_word: StringName = &""


func _ready() -> void:
	_build_environment()
	_nav = NavigationRegion3D.new()
	add_child(_nav)
	_build_ground()
	_build_road()
	_build_river()
	_build_houses()
	_bake_navigation()
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
	_last_input_ms = Time.get_ticks_msec()
	EventLog.log_event(&"session_start", {"scene": "greybox_village"})
	Speech.say_first(
		"line:intro",
		"Привіт! Я Тигриця. Поїхали в пригоду! Ходімо до машини.",
		"Hello! I am Tigrytsia. Let's go! Let's go to the car!"
	)
	_go_to_step(Step.TO_CAR)


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
	if step == Step.TO_CAR:
		_go_to_step(Step.DRIVE)  # its instruction waits for the card


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


# --- The little quest loop ------------------------------------------------------------


func _go_to_step(next: Step) -> void:
	step = next
	EventLog.log_event(&"step", {"step": Step.keys()[next]})
	match next:
		Step.TO_CAR:
			_place_marker(car.global_position + Vector3(-2.2, 0, 0))
			companion.set_goal(
				marker,
				[
					"hint:to_car",
					"Я тут! Ходи до машини, натисни на неї!",
					"I'm here! Go to the car! Click the car!"
				]
			)
		Step.DRIVE:
			_say_when_free("line:drive", "Поїхали! Їдь до вогника!", "Let's go! Drive to the light!")
			_place_marker(DRIVE_SPOTS[_drive_spot])
			_drive_spot = (_drive_spot + 1) % DRIVE_SPOTS.size()
			companion.set_goal(
				marker,
				["hint:drive", "Їдь до вогника! Натисни на вогник!", "Drive to the light! Click the light!"]
			)
		Step.TO_DOOR:
			_say_when_free(
				"line:to_door",
				"Приїхали! Ходімо до дверей.",
				"We are here! Out of the car. Let's go to the door!"
			)
			_place_marker(DOOR_POS + Vector3(0, 0, 6.5))
			companion.set_goal(
				marker, ["hint:to_door", "Ходімо до дверей! Вони тут.", "Go to the door! The door is here!"]
			)
		Step.DOOR:
			_remove_marker()
			companion.set_goal(null)
		Step.FREE:
			_remove_marker()
			companion.set_goal(null)


## Says an instruction, after any open learning card has finished.
func _say_when_free(key: String, uk: String, en: String) -> void:
	if learning.is_open():
		await learning.moment_closed
	Speech.say_first(key, uk, en)


func _place_marker(pos: Vector3) -> void:
	_remove_marker()
	marker = GoalMarker.new()
	add_child(marker)
	marker.global_position = Vector3(pos.x, 0.0, pos.z)
	marker.reached.connect(_on_marker_reached)


func _remove_marker() -> void:
	if marker != null:
		marker.queue_free()
		marker = null


func _on_marker_reached(body: Node3D) -> void:
	EventLog.log_event(&"marker_reached", {"step": Step.keys()[step]})
	match step:
		Step.TO_CAR:
			if body == hero:
				Speech.say_first(
					"line:here_car",
					"Ось наша машина! Натисни на неї.",
					"Here is our car! Click the car!",
					true
				)
		Step.DRIVE:
			if body == car:
				Sfx.play(&"chime")
				_exit_car()
				_go_to_step(Step.TO_DOOR)
		Step.TO_DOOR:
			if body == hero:
				_go_to_step(Step.DOOR)


func _on_cards_shown() -> void:
	hero.stop()
	hero.keyboard_enabled = false
	if step == Step.TO_DOOR:
		_go_to_step(Step.DOOR)


func _on_cards_hidden() -> void:
	hero.keyboard_enabled = true


func _on_door_opened(_word: StringName, _wrong: int) -> void:
	companion.set_goal(null)
	var tween: Tween = create_tween()
	tween.tween_interval(6.0)
	tween.tween_callback(_restart_loop)


func _restart_loop() -> void:
	_say_when_free("line:again", "Ще раз? Ходімо до машини!", "Again? Let's go to the car!")
	_go_to_step(Step.TO_CAR)


# --- Building the world ---------------------------------------------------------------


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
		_ask_door(taught.pick_random())
		return
	# Nothing taught yet: teach a word right here, then ask it.
	var fresh: Array[StringName] = DOOR_WORDS.filter(func(w: StringName) -> bool: return w != _last_door_word)
	_pending_door_word = fresh.pick_random()
	Speech.say_first("line:teach", "Спершу вивчимо слово!", "Let's learn a new word!", true)
	var place: Array = _picture_of(_pending_door_word)
	if not learning.request(_pending_door_word, place[0], place[1]):
		_ask_door(_pending_door_word)


func _on_moment_closed(word_id: StringName) -> void:
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
	var sky: Sky = Sky.new()
	var sky_mat: ProceduralSkyMaterial = ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.45, 0.65, 0.9)
	sky_mat.sky_horizon_color = Color(0.95, 0.85, 0.75)
	sky_mat.ground_horizon_color = Color(0.85, 0.8, 0.7)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.66, 0.8)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var world_env: WorldEnvironment = WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)
	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.93, 0.8)
	sun.light_energy = 0.85
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 60.0
	add_child(sun)


func _build_ground() -> void:
	Blocks.solid_box(_nav, Vector3(0, -0.5, 0), Vector3(90, 1, 90), Color(0.55, 0.75, 0.4))
	# Low fences at the edge so nobody leaves the village.
	for side: Vector3 in [Vector3(0, 0.4, -40), Vector3(0, 0.4, 40)]:
		Blocks.solid_box(_nav, side, Vector3(80, 0.8, 0.4), Color(0.85, 0.75, 0.55))
	for side: Vector3 in [Vector3(-40, 0.4, 0), Vector3(40, 0.4, 0)]:
		Blocks.solid_box(_nav, side, Vector3(0.4, 0.8, 80), Color(0.85, 0.75, 0.55))


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
	for i: int in spots.size():
		Blocks.house(_nav, spots[i], Vector3(5, 3.5, 4.5), walls[i % walls.size()], roofs[i % roofs.size()])
	# The house with the password door; its front faces south (+z) toward DOOR_POS.
	Blocks.house(
		_nav,
		DOOR_POS + Vector3(0, 0, -3.5),
		Vector3(7, 4.5, 7),
		Color(0.98, 0.95, 0.85),
		Color(0.3, 0.55, 0.4)
	)
	door = PasswordDoor.new()
	add_child(door)
	door.position = DOOR_POS + Vector3(0, 0, 0.1)
	door.cards_shown.connect(_on_cards_shown)
	door.cards_hidden.connect(_on_cards_hidden)
	door.opened.connect(_on_door_opened)
	door.wants_question.connect(_on_door_wants_question)
	for t: Vector3 in [
		Vector3(-10, 0, 2), Vector3(-18, 0, -2), Vector3(16, 0, -6), Vector3(18, 0, 12), Vector3(-30, 0, 30)
	]:
		Blocks.solid_box(_nav, t + Vector3(0, 1, 0), Vector3(0.5, 2, 0.5), Color(0.5, 0.35, 0.2))


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
		var art: Node3D = _art_for(&"flower" if thing["id"] == &"sunflower" else thing["id"])
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
			var crown: SphereMesh = SphereMesh.new()
			crown.radius = 1.4
			crown.height = 2.4
			root.add_child(Blocks.mesh(crown, Color(0.3, 0.6, 0.35), Vector3(0, 2.8, 0)))
		&"flower":
			var head: SphereMesh = SphereMesh.new()
			head.radius = 0.35
			head.height = 0.3
			root.add_child(Blocks.box_mesh(Vector3(0.1, 1.2, 0.1), Color(0.3, 0.6, 0.3), Vector3(0, 0.6, 0)))
			root.add_child(Blocks.mesh(head, Color(1.0, 0.85, 0.2), Vector3(0, 1.3, 0)))
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

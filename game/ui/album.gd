class_name Album
extends CanvasLayer
## His album (roadmap step 20, rewards): a big book button in the corner opens a page with every
## friend he has helped, every treasure he has found, and a gold star sticker for each word he has
## said himself, each as a little live 3D picture.
## Tapping one says it again ("This is a teddy."): the souvenirs replay their words. Ones not
## found yet show a soft question mark. Anyone can open and close it; the game waits behind it.

signal opened
signal closed

## [model, word id, save key that unlocks it]
const FRIENDS: Array[Array] = [
	["postman", &"postman", "chapter:prologue"],
	["baker", &"baker", "chapter:bakery"],
	["toy_maker", &"toymaker", "chapter:balloons"],
	["farmer", &"farmer", "chapter:animals"],
	["clock_maker", &"clockmaker", "chapter:clock"],
]
const TREASURES: Array[StringName] = [&"teddy", &"kite", &"star", &"umbrella", &"teapot", &"crown"]
const TILE: Vector2i = Vector2i(170, 170)

var is_open: bool = false

var _book_button: Button
var _page: Control
var _grid: GridContainer
var _viewports: Array[SubViewport] = []
var _stickers: HFlowContainer
var _map: HBoxContainer


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_book_button = _big_button(AlbumIcon.Kind.BOOK, Vector2(110, 110))
	_book_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_book_button.position = Vector2(-140, 24)
	_book_button.pressed.connect(open)
	add_child(_book_button)
	_page = Control.new()
	_page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.visible = false
	add_child(_page)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(UiTokens.INK, 0.4)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_page.add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.BG_PAPER
	style.set_corner_radius_all(40)
	style.set_content_margin_all(30)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column: VBoxContainer = VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	_grid = GridContainer.new()
	_grid.columns = 6
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	column.add_child(_grid)
	# His map: the countries he has been to (Ukraine, then England after the ferry); tapping one
	# says its name. Later arcs add Spain and France as "?".
	_map = HBoxContainer.new()
	_map.add_theme_constant_override("separation", 24)
	column.add_child(_map)
	# A gold star sticker for every word he has said himself; tapping one says the word.
	_stickers = HFlowContainer.new()
	_stickers.custom_minimum_size = Vector2(1060, 0)
	_stickers.add_theme_constant_override("h_separation", 8)
	column.add_child(_stickers)
	var close_button: Button = _big_button(AlbumIcon.Kind.CLOSE, Vector2(100, 100))
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(close)
	column.add_child(close_button)


func open() -> void:
	if is_open or get_tree().paused:
		return
	is_open = true
	get_tree().paused = true
	_book_button.visible = false
	_fill()
	_page.visible = true
	Sfx.play(&"chime")
	Speech.line("album:open", null, true)
	EventLog.log_event(&"album_open")
	opened.emit()


func close() -> void:
	if not is_open:
		return
	is_open = false
	_page.visible = false
	_book_button.visible = true
	for child: Node in _grid.get_children() + _stickers.get_children() + _map.get_children():
		child.queue_free()
	_viewports.clear()
	get_tree().paused = false
	closed.emit()


func _fill() -> void:
	for friend: Array in FRIENDS:
		_add_tile(friend[0], friend[1], SaveSystem.has_encountered(friend[2]), true)
	for treasure: StringName in TREASURES:
		_add_tile(String(treasure), treasure, SaveSystem.has_encountered("treasure:%s" % treasure), false)
	_add_place(AlbumIcon.Kind.UKRAINE, &"ukraine", true)
	_add_place(AlbumIcon.Kind.ENGLAND, &"england", SaveSystem.has_encountered("chapter:prologue"))
	for key: String in SaveSystem.words:
		if int(LearningTracker.stats(StringName(key))["said"]) > 0:
			_add_sticker(StringName(key))


func _add_place(kind: AlbumIcon.Kind, word_id: StringName, visited: bool) -> void:
	var place: Button = _big_button(kind, Vector2(110, 110))
	if not visited:
		place.modulate = Color(1, 1, 1, 0.25)
	var word: WordEntry = WordDB.get_word(word_id)
	place.pressed.connect(
		func() -> void:
			Sfx.play(&"pop" if visited else &"soft")
			if visited and word != null:
				Speech.line("card:this_is", word, true)
	)
	_map.add_child(place)


func _add_sticker(word_id: StringName) -> void:
	var word: WordEntry = WordDB.get_word(word_id)
	if word == null:
		return
	var sticker: Button = _big_button(AlbumIcon.Kind.STAR, Vector2(64, 64))
	sticker.tooltip_text = word.en
	sticker.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	sticker.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	sticker.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	sticker.pressed.connect(
		func() -> void:
			Sfx.play(&"pop")
			Speech.line("card:word", word, true)
	)
	_stickers.add_child(sticker)


## One picture: the thing turning slowly in its own little world (or "?" until it is found).
func _add_tile(model: String, word_id: StringName, unlocked: bool, person: bool) -> void:
	var tile: Button = Button.new()
	tile.custom_minimum_size = Vector2(TILE)
	tile.focus_mode = Control.FOCUS_ALL
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(UiTokens.BG_SKY, 1.0) if unlocked else Color(0.85, 0.84, 0.82)
	style.set_corner_radius_all(24)
	for state: String in ["normal", "hover", "pressed", "focus"]:
		tile.add_theme_stylebox_override(state, style)
	_grid.add_child(tile)
	if not unlocked:
		tile.text = "?"
		tile.add_theme_font_size_override("font_size", 90)
		tile.add_theme_color_override("font_color", Color(0.6, 0.58, 0.55))
		tile.pressed.connect(func() -> void: Sfx.play(&"soft"))
		return
	var frame: SubViewportContainer = SubViewportContainer.new()
	frame.stretch = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	tile.add_child(frame)
	var vp: SubViewport = SubViewport.new()
	vp.own_world_3d = true
	vp.transparent_bg = true
	vp.size = TILE
	frame.add_child(vp)
	_viewports.append(vp)
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -30, 0)
	vp.add_child(light)
	var spinner: Node3D = Node3D.new()
	vp.add_child(spinner)
	var art: Node3D = Props.make(StringName(model))
	art.rotation.y = PI if Props.is_model(StringName(model)) else 0.0
	spinner.add_child(art)
	var turn: Tween = spinner.create_tween().set_loops()
	turn.tween_property(spinner, "rotation:y", TAU, 8.0).from(0.0)
	var cam: Camera3D = Camera3D.new()
	cam.fov = 35.0
	var height: float = 1.0 if person else 0.45
	var dist: float = 4.2 if person else 2.6
	cam.look_at_from_position(Vector3(0, height + 0.4, dist), Vector3(0, height, 0))
	vp.add_child(cam)
	var word: WordEntry = WordDB.get_word(word_id)
	tile.pressed.connect(
		func() -> void:
			Sfx.play(&"pop")
			Speech.line("card:this_is", word, true)
			LearningTracker.record_heard(word_id)
	)


func _big_button(kind: AlbumIcon.Kind, min_size: Vector2) -> Button:
	var button: Button = Button.new()
	button.custom_minimum_size = min_size
	var icon: AlbumIcon = AlbumIcon.new()
	icon.kind = kind
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	button.add_child(icon)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.ACCENT_SUN
	style.set_corner_radius_all(int(min_size.x / 2.0))
	for state: String in ["normal", "hover", "pressed", "focus"]:
		button.add_theme_stylebox_override(state, style)
	return button

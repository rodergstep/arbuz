class_name LearningCard
extends CanvasLayer
## A learning moment, in English (Ukrainian only the first time he meets the word): a big card
## with a live picture of the real thing in the world and the English word, then asks him to say it, then
## short English sentences that use the word, each shown while it is spoken. Tap, click or
## Space skips. The game waits behind it.

signal closed(word_id: StringName, skipped: bool)

const PICTURE_SIZE: Vector2i = Vector2i(440, 440)
const CARD_SIZE: Vector2 = Vector2(1040, 540)
const MAX_SENTENCES: int = 2
const LINE_PAUSE: float = 0.5
const SILENT_LINE_SECONDS: float = 2.2
const MIN_OPEN_SECONDS: float = 1.0
## How long to wait for him to say the word back before praising anyway.
const SAY_IT_LISTEN: float = 4.0

var is_open: bool = false

var _panel: PanelContainer
var _viewport: SubViewport
var _camera: Camera3D
var _word_en: Label
var _word_uk: Label
var _first_time: bool = false
var _mic: MicBubble
var _sentence: Label
var _entry: WordEntry
var _opened_ms: int = 0
var _skipped: bool = false
var _run: int = 0


func _ready() -> void:
	layer = 5
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root: Control = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(UiTokens.INK, 0.35)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(dim)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = CARD_SIZE
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = UiTokens.BG_PAPER
	style.set_corner_radius_all(40)
	style.set_content_margin_all(36)
	style.shadow_color = Color(0, 0, 0, 0.25)
	style.shadow_size = 16
	_panel.add_theme_stylebox_override("panel", style)
	center.add_child(_panel)
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 40)
	_panel.add_child(row)
	var frame: SubViewportContainer = SubViewportContainer.new()
	frame.custom_minimum_size = Vector2(PICTURE_SIZE)
	frame.stretch = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(frame)
	_viewport = SubViewport.new()
	_viewport.size = PICTURE_SIZE
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	frame.add_child(_viewport)
	_camera = Camera3D.new()
	_camera.fov = 45.0
	_viewport.add_child(_camera)
	var words: VBoxContainer = VBoxContainer.new()
	words.alignment = BoxContainer.ALIGNMENT_CENTER
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 18)
	row.add_child(words)
	_word_en = _label(UiTokens.SIZE_TITLE, UiTokens.ACCENT_SKY)
	words.add_child(_word_en)
	_word_uk = _label(UiTokens.SIZE_SUBTITLE, UiTokens.INK)
	words.add_child(_word_uk)
	_mic = MicBubble.new()
	_mic.visible = false
	words.add_child(_mic)
	_sentence = _label(UiTokens.SIZE_BODY, UiTokens.INK)
	_sentence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sentence.custom_minimum_size = Vector2(480, 120)
	words.add_child(_sentence)
	visible = false


## Opens the card for a word; focus is the point to picture, view_from where the picture's
## camera stands.
func open(entry: WordEntry, focus: Vector3, view_from: Vector3) -> void:
	_entry = entry
	_run += 1
	is_open = true
	_skipped = false
	_opened_ms = Time.get_ticks_msec()
	_viewport.world_3d = get_viewport().world_3d
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_camera.global_position = view_from
	_camera.look_at(focus + Vector3(0, 0.8, 0))
	_camera.current = true
	_word_en.text = entry.en
	var key: String = "word:%s" % entry.id
	_first_time = not SaveSystem.has_encountered(key)
	SaveSystem.mark_encountered(key)
	_word_uk.text = entry.uk
	_word_uk.visible = _first_time
	_sentence.text = ""
	visible = true
	_panel.scale = Vector2(0.8, 0.8)
	_panel.pivot_offset = CARD_SIZE / 2.0
	var tween: Tween = create_tween()
	(
		tween
		. tween_property(_panel, "scale", Vector2.ONE, UiTokens.MOTION_TRANSITION)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	Sfx.play(&"chime")
	EventLog.log_event(&"learning_moment", {"word_id": String(entry.id)})
	LearningTracker.record_heard(entry.id)
	_play(_run)


func close() -> void:
	if not is_open:
		return
	is_open = false
	_run += 1
	Speech.stop()
	visible = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	EventLog.log_event(&"learning_moment_closed", {"word_id": String(_entry.id), "skipped": _skipped})
	closed.emit(_entry.id, _skipped)


func _input(event: InputEvent) -> void:
	if not is_open or PauseOverlay.active:
		return
	var skip: bool = event.is_action_pressed(&"use")
	skip = skip or (event is InputEventMouseButton and event.pressed)
	if skip and Time.get_ticks_msec() - _opened_ms > MIN_OPEN_SECONDS * 1000.0:
		get_viewport().set_input_as_handled()
		_skipped = true
		close()


func _play(run: int) -> void:
	# The first time he meets a word: Ukrainian first (and the Ukrainian word on the card).
	if _first_time:
		await _line(Speech.text("card:first", Speech.LANG_UK, _entry), Speech.LANG_UK, run)
	await _line(Speech.text("card:this_is", Speech.LANG_EN, _entry), Speech.LANG_EN, run)
	await _line(_entry.en, Speech.LANG_EN, run)
	# Say it back: he is asked to repeat the word; any sound he makes counts (never judged).
	# Praise comes either way, a bit warmer when he joined in.
	await _line(Speech.text("card:say_it", Speech.LANG_EN, _entry), Speech.LANG_EN, run)
	var heard: bool = false
	if run == _run:
		_mic.visible = true
		heard = await VoiceListener.listen(SAY_IT_LISTEN)
		_mic.visible = false
	if heard and run == _run:
		Sfx.play(&"chime")
		_celebrate()
	var praise: String = "card:great_heard" if heard else "card:great"
	await _line(Speech.text(praise, Speech.LANG_EN, _entry), Speech.LANG_EN, run)
	var sentences: PackedStringArray = _entry.examples_en.duplicate()
	if sentences.size() > MAX_SENTENCES:
		sentences = sentences.slice(0, MAX_SENTENCES)
	for sentence: String in sentences:
		if run != _run:
			return
		_sentence.text = sentence
		await _line(sentence, Speech.LANG_EN, run)
	if run == _run:
		await get_tree().create_timer(1.2, true).timeout
	if run == _run:
		close()


## Speaks one line and waits until it is done (or for a fixed time when there is no voice).
func _line(text: String, lang: StringName, run: int) -> void:
	if run != _run:
		return
	Speech.say(text, lang)
	if not Speech.can_speak(lang):
		await get_tree().create_timer(SILENT_LINE_SECONDS, true).timeout
	else:
		# The voice starts a moment after the request; then wait until it finishes.
		await get_tree().create_timer(0.3, true).timeout
		while run == _run and Speech.is_speaking():
			await get_tree().create_timer(0.1, true).timeout
	while run == _run and PauseOverlay.active:
		await get_tree().create_timer(0.2, true).timeout
	if run == _run:
		await get_tree().create_timer(LINE_PAUSE, true).timeout


func _celebrate() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(_word_en, "scale", Vector2(1.25, 1.25), 0.15)
	tween.tween_property(_word_en, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC)


func _label(font_size: int, color: Color) -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return label

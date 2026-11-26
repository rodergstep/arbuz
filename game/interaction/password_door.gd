class_name PasswordDoor
extends Node3D
## Greybox password door, all in English. When the hero walks up, a picture of a thing he has
## already learned appears over the door and Тигриця asks "What is this?". Three blank cards
## rise; each says its English word when pointed at or clicked. The first wrong pick gives a
## hint (the retry names the word: "Where is the car?").
## A wrong pick gets a gentle wiggle, the card says its word and the question repeats. After 2
## wrong picks the right card glows and the door opens with praise. No fail state.
## Re-arms with a new word after the hero walks away, so it can be played again.
## Teach before test: the door never picks its own word. When the hero arrives it emits
## wants_question; the scene chooses a word he has already been taught (or teaches it first)
## and then calls ask().

signal wants_question
signal opened(word_id: StringName, wrong_picks: int)
signal cards_shown
signal cards_hidden

const MAX_WRONG: int = 2
const CARD_SPACING: float = 2.6

var cards: Array[PasswordCard] = []
var focused_index: int = 1

var _answer: WordEntry
var _others: Array[WordEntry] = []
var _hero_inside: bool = false
var _wrong: int = 0
var _active: bool = false
var _open: bool = false
var _panel: Node3D
var _cards_root: Node3D
var _picture_view: SubViewport
var _picture_cam: Camera3D
var _picture: Sprite3D


func _ready() -> void:
	_panel = Node3D.new()
	add_child(_panel)
	# Hinge on the left edge: the door swings open around it.
	_panel.position = Vector3(-0.8, 0.0, 0.0)
	_panel.add_child(Blocks.box_mesh(Vector3(1.6, 2.4, 0.15), Color(0.55, 0.35, 0.2), Vector3(0.8, 1.2, 0)))
	var knob: SphereMesh = SphereMesh.new()
	knob.radius = 0.08
	knob.height = 0.16
	_panel.add_child(Blocks.mesh(knob, Color(1.0, 0.85, 0.3), Vector3(1.35, 1.1, 0.12)))
	_build_picture()
	_cards_root = Node3D.new()
	_cards_root.position = Vector3(0, 0, 3.2)
	_cards_root.visible = false
	add_child(_cards_root)
	var trigger: Area3D = Area3D.new()
	trigger.collision_layer = 0
	trigger.collision_mask = Blocks.LAYER_HERO
	var shape: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(9.0, 3.0, 6.0)
	shape.shape = box
	shape.position = Vector3(0, 1.5, 4.5)
	trigger.add_child(shape)
	trigger.body_entered.connect(_on_hero_entered)
	trigger.body_exited.connect(_on_hero_exited)
	add_child(trigger)


func is_active() -> bool:
	return _active


func question_line() -> String:
	return "What is this? Listen to the cards!"


func is_hero_inside() -> bool:
	return _hero_inside


## Shows the picture and the cards and asks. answer must be a word he has already been taught;
## focus and view_from frame the real thing in the world for the picture.
func ask(answer: WordEntry, others: Array[WordEntry], focus: Vector3, view_from: Vector3) -> void:
	if _open or _active or not _hero_inside:
		return
	_answer = answer
	_others = others
	_active = true
	_wrong = 0
	_build_cards()
	_cards_root.visible = true
	_cards_root.position.y = -1.5
	var rise: Tween = create_tween()
	rise.tween_property(_cards_root, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	_show_picture(focus, view_from)
	Speech.say_first("door:question", "Що це? Послухай картки!", question_line(), true)
	EventLog.log_event(&"door_question", {"word": String(answer.id)})
	cards_shown.emit()


func focus_step(step: int) -> void:
	if not _active or cards.is_empty():
		return
	focused_index = clampi(focused_index + step, 0, cards.size() - 1)
	_update_focus()
	cards[focused_index].say()


func pick_focused() -> void:
	if _active and not cards.is_empty():
		pick(cards[focused_index])


func hover(card: PasswordCard) -> void:
	if not _active:
		return
	focused_index = cards.find(card)
	_update_focus()
	card.say()


func pick(card: PasswordCard) -> void:
	if not _active:
		return
	var correct: bool = card.is_answer
	EventLog.log_event(&"card_pick", {"word": card.word_en, "correct": correct, "wrong_before": _wrong})
	if correct:
		Sfx.play(&"chime")
		card.celebrate()
		Speech.say("Yes! %s! Well done!" % _cap(card.word_en), Speech.LANG_EN, true)
		Speech.say_first("door:opening", "Двері відчиняються!", "The door is opening!")
		_open_door()
		return
	_wrong += 1
	Sfx.play(&"soft")
	card.wiggle()
	Speech.say(card.word_en, Speech.LANG_EN, true)
	if _wrong >= MAX_WRONG:
		var answer: PasswordCard = _answer_card()
		answer.glow()
		Speech.say_first("door:glow", "Дивись! Ця картка світиться!", "Look! This card is glowing!")
		Speech.say("%s!" % _cap(answer.word_en), Speech.LANG_EN)
		Speech.say("This is a %s. Well done! The door is opening!" % answer.word_en, Speech.LANG_EN)
		_open_door()
	else:
		Speech.say_first("door:retry", "Спробуймо ще!", "Try again! Where is the %s?" % _answer.en)


func _on_hero_entered(_body: Node3D) -> void:
	_hero_inside = true
	if not _open and not _active:
		wants_question.emit()


func _on_hero_exited(_body: Node3D) -> void:
	_hero_inside = false
	if _active:
		_active = false
		_hide_question()
		cards_hidden.emit()
	elif _open:
		_close_and_rearm()


func _open_door() -> void:
	_active = false
	_open = true
	var tween: Tween = create_tween()
	tween.tween_interval(0.6)
	tween.tween_callback(Sfx.play.bind(&"door"))
	tween.tween_property(_panel, "rotation:y", deg_to_rad(-100.0), 0.9).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.tween_interval(1.5)
	tween.tween_callback(_hide_question)
	opened.emit(_answer.id, _wrong)
	cards_hidden.emit()


func _close_and_rearm() -> void:
	_open = false
	create_tween().tween_property(_panel, "rotation:y", 0.0, 0.8)


func _build_picture() -> void:
	_picture_view = SubViewport.new()
	_picture_view.size = Vector2i(512, 384)
	_picture_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_picture_view)
	_picture_cam = Camera3D.new()
	_picture_cam.fov = 45.0
	_picture_view.add_child(_picture_cam)
	var frame: MeshInstance3D = Blocks.box_mesh(
		Vector3(2.9, 2.2, 0.1), UiTokens.BG_PAPER, Vector3(0, 0, -0.06)
	)
	_picture = Sprite3D.new()
	_picture.pixel_size = 2.6 / 512.0
	_picture.position = Vector3(0, 3.6, 3.9)
	_picture.texture = _picture_view.get_texture()
	_picture.add_child(frame)
	_picture.visible = false
	add_child(_picture)


func _show_picture(focus: Vector3, view_from: Vector3) -> void:
	_picture_view.world_3d = get_viewport().world_3d
	_picture_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_picture_cam.global_position = view_from
	_picture_cam.look_at(focus + Vector3(0, 0.8, 0))
	_picture.visible = true


func _hide_question() -> void:
	_cards_root.visible = false
	_picture.visible = false
	_picture_view.render_target_update_mode = SubViewport.UPDATE_DISABLED


func _cap(word: String) -> String:
	return word.substr(0, 1).to_upper() + word.substr(1)


func _answer_card() -> PasswordCard:
	for card: PasswordCard in cards:
		if card.is_answer:
			return card
	return cards[0]


func _build_cards() -> void:
	for card: PasswordCard in cards:
		card.queue_free()
	cards.clear()
	var words: Array[WordEntry] = [_answer]
	words.append_array(_others)
	words.shuffle()
	for i: int in words.size():
		var card: PasswordCard = PasswordCard.new()
		card.word_en = words[i].en
		card.is_answer = words[i] == _answer
		card.position = Vector3((i - 1) * CARD_SPACING, 1.6, 0.0)
		card.door = self
		_cards_root.add_child(card)
		cards.append(card)
	focused_index = 1
	_update_focus()


func _update_focus() -> void:
	for i: int in cards.size():
		cards[i].set_focused(i == focused_index)

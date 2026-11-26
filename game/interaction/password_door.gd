class_name PasswordDoor
extends Node3D
## Greybox password door. When the hero walks up, Тигриця asks (in Ukrainian) how to say a word
## in English. Three blank cards rise; each says its English word when pointed at or clicked.
## A wrong pick gets a gentle wiggle, the card says its word and the question repeats. After 2
## wrong picks the right card glows and the door opens with praise. No fail state.
## Re-arms with a new word after the hero walks away, so it can be played again.

signal opened(word_id: StringName, wrong_picks: int)
signal cards_shown
signal cards_hidden

const MAX_WRONG: int = 2
const CARD_SPACING: float = 2.6
const ROUNDS: Array[Dictionary] = [
	{"uk": "лев", "answer": "lion", "others": ["dog", "ox"]},
	{"uk": "кіт", "answer": "cat", "others": ["cow", "duck"]},
	{"uk": "яблуко", "answer": "apple", "others": ["milk", "ball"]},
	{"uk": "собака", "answer": "dog", "others": ["sun", "fish"]},
]

var cards: Array[PasswordCard] = []
var focused_index: int = 1

var _round: int = 0
var _wrong: int = 0
var _active: bool = false
var _open: bool = false
var _panel: Node3D
var _cards_root: Node3D


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
	return "Як англійською буде «%s»? Послухай картки і вибери!" % ROUNDS[_round]["uk"]


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
		Speech.say(card.word_en, Speech.LANG_EN, true)
		Speech.say("Ура! Правильно! Двері відчиняються!", Speech.LANG_UK)
		_open_door()
		return
	_wrong += 1
	Sfx.play(&"soft")
	card.wiggle()
	Speech.say(card.word_en, Speech.LANG_EN, true)
	if _wrong >= MAX_WRONG:
		var answer: PasswordCard = _answer_card()
		answer.glow()
		Speech.say("Дивись, ось ця картка світиться!", Speech.LANG_UK)
		Speech.say(answer.word_en, Speech.LANG_EN)
		Speech.say("Молодець! Двері відчиняються!", Speech.LANG_UK)
		_open_door()
	else:
		Speech.say("Спробуймо ще! Як буде «%s»?" % ROUNDS[_round]["uk"], Speech.LANG_UK)


func _on_hero_entered(_body: Node3D) -> void:
	if _open or _active:
		return
	_active = true
	_wrong = 0
	_build_cards()
	_cards_root.visible = true
	_cards_root.position.y = -1.5
	create_tween().tween_property(_cards_root, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	Speech.say(question_line(), Speech.LANG_UK, true)
	EventLog.log_event(&"door_question", {"word": ROUNDS[_round]["answer"]})
	cards_shown.emit()


func _on_hero_exited(_body: Node3D) -> void:
	if _active:
		_active = false
		_cards_root.visible = false
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
	tween.tween_callback(func() -> void: _cards_root.visible = false)
	opened.emit(StringName(ROUNDS[_round]["answer"]), _wrong)
	cards_hidden.emit()


func _close_and_rearm() -> void:
	_open = false
	_round = (_round + 1) % ROUNDS.size()
	create_tween().tween_property(_panel, "rotation:y", 0.0, 0.8)


func _answer_card() -> PasswordCard:
	for card: PasswordCard in cards:
		if card.is_answer:
			return card
	return cards[0]


func _build_cards() -> void:
	for card: PasswordCard in cards:
		card.queue_free()
	cards.clear()
	var words: Array[String] = [ROUNDS[_round]["answer"]]
	for other: String in ROUNDS[_round]["others"]:
		words.append(other)
	words.shuffle()
	for i: int in words.size():
		var card: PasswordCard = PasswordCard.new()
		card.word_en = words[i]
		card.is_answer = words[i] == ROUNDS[_round]["answer"]
		card.position = Vector3((i - 1) * CARD_SPACING, 1.6, 0.0)
		card.door = self
		_cards_root.add_child(card)
		cards.append(card)
	focused_index = 1
	_update_focus()


func _update_focus() -> void:
	for i: int in cards.size():
		cards[i].set_focused(i == focused_index)

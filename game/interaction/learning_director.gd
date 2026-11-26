class_name LearningDirector
extends Node
## Decides when a learning moment opens. Education first, but toddler-sized: a passing moment
## (bridge, river, road…) opens at most every COOLDOWN seconds, each word at most
## MAX_AUTO_PER_WORD times a session and not again within WORD_REPEAT seconds. A moment he asks
## for (clicking a thing) always opens. Nothing opens over another card or a door question.

signal moment_closed(word_id: StringName)

const COOLDOWN: float = 20.0
const WORD_REPEAT: float = 120.0
const MAX_AUTO_PER_WORD: int = 2
const START_GRACE: float = 3.0
## Pacing: at most this many brand-new words open on their own per session (3–5 at a time).
const MAX_NEW_PER_SESSION: int = 5

## Returns true when something else owns the screen (for example a door question).
var is_busy: Callable = func() -> bool: return false

var card: LearningCard

var _last_closed_ms: int = -1000000
var _auto_counts: Dictionary[StringName, int] = {}
var _last_shown_ms: Dictionary[StringName, int] = {}
var _start_ms: int = 0
var _taught: Array[StringName] = []
var _new_this_session: int = 0


func _ready() -> void:
	_start_ms = Time.get_ticks_msec()
	card = LearningCard.new()
	add_child(card)
	card.closed.connect(_on_closed)


func is_open() -> bool:
	return card.is_open


## Words shown on a learning card this session, oldest first.
func taught_words() -> Array[StringName]:
	return _taught.duplicate()


func was_taught(word_id: StringName) -> bool:
	return _taught.has(word_id)


## A passing moment: may be declined. Returns true when the card opened.
func offer(word_id: StringName, focus: Vector3, view_from: Vector3) -> bool:
	if not _may_offer(word_id) or not _open(word_id, focus, view_from):
		return false
	_auto_counts[word_id] = _auto_counts.get(word_id, 0) + 1
	return true


func _may_offer(word_id: StringName) -> bool:
	var now: int = Time.get_ticks_msec()
	var screen_free: bool = not card.is_open and not is_busy.call()
	var paced: bool = now - _start_ms >= START_GRACE * 1000.0 and now - _last_closed_ms >= COOLDOWN * 1000.0
	var word_ok: bool = (
		_auto_counts.get(word_id, 0) < MAX_AUTO_PER_WORD
		and now - _last_shown_ms.get(word_id, -1000000) >= WORD_REPEAT * 1000.0
	)
	var new_ok: bool = not _is_new(word_id) or _new_this_session < MAX_NEW_PER_SESSION
	return screen_free and paced and word_ok and new_ok


## A moment he asked for (a click): opens unless a card or a door question is on screen.
func request(word_id: StringName, focus: Vector3, view_from: Vector3) -> bool:
	if card.is_open or is_busy.call():
		return false
	return _open(word_id, focus, view_from)


func _open(word_id: StringName, focus: Vector3, view_from: Vector3) -> bool:
	var entry: WordEntry = WordDB.get_word(word_id)
	if entry == null:
		return false
	if _is_new(word_id):
		_new_this_session += 1
	_last_shown_ms[word_id] = Time.get_ticks_msec()
	if not _taught.has(word_id):
		_taught.append(word_id)
	get_tree().paused = true
	card.open(entry, focus, view_from)
	return true


func _is_new(word_id: StringName) -> bool:
	return not SaveSystem.has_encountered("word:%s" % word_id)


func _on_closed(word_id: StringName, _skipped: bool) -> void:
	_last_closed_ms = Time.get_ticks_msec()
	get_tree().paused = false
	moment_closed.emit(word_id)

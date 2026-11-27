class_name CarWords
extends Node
## The car's words while he drives (roadmap step 28): Tygrytsa says what the car does as it
## happens: "Go!" when it starts, "Stop!" when it stops, "Left!" / "Right!" on a turn,
## "Beep beep!" for the horn. The first time each word comes up, its learning card opens (when
## the director allows); after that just the short line. Never chatty: one word at most every
## GAP seconds, the same word not again for WORD_GAP seconds, and nothing over other speech.

const GAP: float = 6.0
const WORD_GAP: float = 25.0
const LINES: Dictionary[StringName, String] = {
	&"go": "car:go", &"stop": "car:stop", &"left": "car:left", &"right": "car:right", &"horn": "car:horn"
}

var car: Car
var learning: LearningDirector

var _last_ms: int = -100000
var _word_ms: Dictionary[StringName, int] = {}


func setup(the_car: Car, the_learning: LearningDirector) -> void:
	car = the_car
	learning = the_learning
	car.started.connect(_say.bind(&"go"))
	car.stopped.connect(_say.bind(&"stop"))
	car.turned.connect(func(left: bool) -> void: _say(&"left" if left else &"right"))
	car.honked.connect(_say.bind(&"horn"))


func _say(word: StringName) -> void:
	var now: int = Time.get_ticks_msec()
	if now - _last_ms < GAP * 1000.0 or now - _word_ms.get(word, -100000) < WORD_GAP * 1000.0:
		return
	if Speech.is_speaking() or learning.is_open():
		return
	_last_ms = now
	_word_ms[word] = now
	EventLog.log_event(&"car_word", {"word": String(word)})
	# Teach before use: the first time, the card shows the word in a little scene.
	if not learning.was_taught(word) and not SaveSystem.has_encountered("word:%s" % word):
		var pos: Vector3 = car.global_position
		if learning.offer(word, pos, pos + Vector3(4, 3, 5)):
			return
	Speech.line(LINES[word], WordDB.get_word(word))

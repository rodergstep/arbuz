class_name SayItBack
extends RefCounted
## "Say it back": waits until he says a word (any sound counts, never judged), asking again
## gently ("Your turn! Say: hello!", every third time saying the word first), then praises.
## Used by learning cards and by characters who teach a word (the postman).

const LISTEN_SECONDS: float = 5.0
## Short praise, picked at random and never one of the last two (playtest: the same long
## "Yes, car, great job, you said it" every time was tiring). The word itself comes up in only
## one of them; the card already says it many times.
const PRAISE_HEARD: Array[String] = [
	"praise:yes",
	"praise:super",
	"praise:well_done",
	"praise:wow",
	"praise:brilliant",
	"praise:hooray",
	"praise:right",
	"praise:clever",
]
## Without a microphone he isn't heard, so the praise stays calm.
const PRAISE_QUIET: Array[String] = ["praise:lovely", "praise:good", "praise:well_done"]

static var _recent: Array[String] = []


## Listens until he makes a sound. `alive` returns false to stop (the card closed, the scene
## moved on). Returns true when he said something; false without a usable microphone.
static func wait_for_word(caller: Node, word: WordEntry, mic: Control, alive: Callable) -> bool:
	var tries: int = 0
	while alive.call():
		await wait_while_paused(caller, alive)
		if mic != null:
			mic.shown = true
		var heard: bool = await VoiceListener.listen(LISTEN_SECONDS)
		if mic != null:
			mic.shown = false
		if heard or not VoiceListener.available() or VoiceListener.seems_blocked():
			return heard
		tries += 1
		EventLog.log_event(&"say_it_reprompt", {"word_id": String(word.id), "tries": tries})
		if tries % 3 == 0:
			await say_and_wait(caller, word.en, alive)
		await say_and_wait(caller, Speech.text("card:your_turn", Speech.LANG_EN, word), alive)
	return false


## Praise after his turn: warmer when he joined in.
static func praise(caller: Node, word: WordEntry, heard: bool, alive: Callable) -> void:
	if heard:
		Sfx.play(&"chime")
	await say_and_wait(caller, Speech.text(praise_key(heard), Speech.LANG_EN, word), alive)


## A praise line key: random, never one of the last two used.
static func praise_key(heard: bool) -> String:
	var pool: Array[String] = PRAISE_HEARD if heard else PRAISE_QUIET
	var fresh: Array[String] = pool.filter(func(k: String) -> bool: return not _recent.has(k))
	var key: String = (fresh if not fresh.is_empty() else pool).pick_random()
	_recent.append(key)
	if _recent.size() > 2:
		_recent.pop_front()
	return key


## Says one English text and waits until it has been spoken.
static func say_and_wait(caller: Node, text: String, alive: Callable, speaker: String = "") -> void:
	if not alive.call():
		return
	Speech.say(text, Speech.LANG_EN, false, speaker)
	await wait_until_quiet(caller, alive)


static func wait_until_quiet(caller: Node, alive: Callable) -> void:
	await caller.get_tree().create_timer(0.3, true).timeout
	while alive.call() and Speech.is_speaking():
		await caller.get_tree().create_timer(0.1, true).timeout
	await wait_while_paused(caller, alive)


## The pause screen stops the voice; the story waits here until it is closed.
static func wait_while_paused(caller: Node, alive: Callable) -> void:
	while alive.call() and PauseOverlay.active:
		await caller.get_tree().create_timer(0.2, true).timeout

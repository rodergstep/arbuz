class_name SayItBack
extends RefCounted
## "Say it back": waits until he says a word (any sound counts, never judged), asking again
## gently ("Your turn! Say: hello!", every third time saying the word first), then praises.
## Used by learning cards and by characters who teach a word (the postman).

const LISTEN_SECONDS: float = 5.0


## Listens until he makes a sound. `alive` returns false to stop (the card closed, the scene
## moved on). Returns true when he said something; false without a usable microphone.
static func wait_for_word(caller: Node, word: WordEntry, mic: Control, alive: Callable) -> bool:
	var tries: int = 0
	while alive.call():
		if mic != null:
			mic.visible = true
		var heard: bool = await VoiceListener.listen(LISTEN_SECONDS)
		if mic != null:
			mic.visible = false
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
	var key: String = "card:great_heard" if heard else "card:great"
	await say_and_wait(caller, Speech.text(key, Speech.LANG_EN, word), alive)


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

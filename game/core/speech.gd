extends Node
## Everything the game says. Lines come from content/voice/lines.csv by key (with {word},
## {Word}, {a_word} and {uk_word} filled from the word database). Each spoken text plays its
## generated voice file (audio/voice/<lang>/<hash>.ogg, made by audio_gen/generate_voices.py);
## a text with no file falls back to the operating system's text-to-speech.
## English immersion: a line with Ukrainian is said in Ukrainian + English the first time
## (remembered in the save), English only after that.

signal queue_finished

const LANG_UK: StringName = &"uk"
const LANG_EN: StringName = &"en"
const LINES_PATH: String = "res://content/voice/lines.csv"
const VOICE_DIR: String = "res://audio/voice"
const TTS_VOLUME: int = 85
const TTS_RATE: float = 0.75

var _voices: Dictionary[StringName, String] = {}
var _tts: bool = false
var _volume: int = TTS_VOLUME
var _lines: Dictionary[String, PackedStringArray] = {}
var _queue: Array[PackedStringArray] = []
var _player: AudioStreamPlayer
var _tts_busy: bool = false
var _tts_wait: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	add_child(_player)
	_load_lines()
	apply_volume()
	_tts = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if _tts:
		for lang: StringName in [LANG_UK, LANG_EN]:
			var ids: PackedStringArray = DisplayServer.tts_get_voices_for_language(String(lang))
			if not ids.is_empty():
				_voices[lang] = ids[0]


## Says a catalogue line. word fills the placeholders. first_key names what "the first time"
## means (defaults to the line key; e.g. "word:duck" so the first meeting of a word counts).
func line(key: String, word: WordEntry = null, interrupt: bool = false, first_key: String = "") -> void:
	var uk: String = text(key, LANG_UK, word)
	var en: String = text(key, LANG_EN, word)
	if uk.is_empty():
		say(en, LANG_EN, interrupt)
		return
	say_first(first_key if not first_key.is_empty() else key, uk, en, interrupt)


## The filled-in text of a catalogue line in one language ("" when the line has none).
func text(key: String, lang: StringName, word: WordEntry = null) -> String:
	if not _lines.has(key):
		push_warning("Speech: unknown line '%s'" % key)
		return ""
	var raw: String = _lines[key][0 if lang == LANG_UK else 1]
	if word == null or raw.is_empty():
		return raw
	return (
		raw
		. replace("{Word}", word.en.capitalize())
		. replace("{word}", word.en)
		. replace("{a_word}", with_article(word.en))
		. replace("{uk_word}", word.uk)
	)


## Ukrainian + English the first time this key is met, English only after (kept in the save).
func say_first(key: String, uk: String, en: String, interrupt: bool = false) -> bool:
	if SaveSystem.has_encountered(key):
		say(en, LANG_EN, interrupt)
		return false
	say(uk, LANG_UK, interrupt)
	if not en.is_empty():
		say(en, LANG_EN)
	SaveSystem.mark_encountered(key)
	return true


## Queues one text. interrupt clears whatever is playing or waiting.
func say(spoken: String, lang: StringName = LANG_EN, interrupt: bool = false) -> void:
	if spoken.is_empty():
		return
	EventLog.log_event(&"voice", {"text": spoken, "lang": String(lang)})
	if interrupt:
		stop()
	_queue.append(PackedStringArray([spoken, String(lang)]))


func stop() -> void:
	_queue.clear()
	_player.stop()
	if _tts and _tts_busy:
		DisplayServer.tts_stop()
	_tts_busy = false


func is_speaking() -> bool:
	return not _queue.is_empty() or _player.playing or _tts_busy


## True when this language can be heard at all (a file or a system voice).
func can_speak(lang: StringName) -> bool:
	return _tts and _voices.has(lang) or DirAccess.dir_exists_absolute("%s/%s" % [VOICE_DIR, lang])


## Applies the parent's volume to the voice and the master bus.
func apply_volume() -> void:
	var v: float = clampf(float(SaveSystem.settings.get("volume", 0.85)), 0.0, 1.0)
	_volume = roundi(v * 100.0)
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.001)))


## The generated voice file for a text; the generator uses the same naming.
static func voice_path(spoken: String, lang: StringName) -> String:
	return "%s/%s/%s.ogg" % [VOICE_DIR, lang, ("%s|%s" % [lang, spoken]).sha1_text().substr(0, 16)]


static func with_article(word: String) -> String:
	return ("an " if "aeiou".contains(word.substr(0, 1).to_lower()) else "a ") + word


func _process(delta: float) -> void:
	if _tts_busy:
		_tts_wait += delta
		# The system voice reports speaking a moment after the request.
		if _tts_wait > 0.3 and not DisplayServer.tts_is_speaking():
			_tts_busy = false
		return
	if _player.playing or _queue.is_empty():
		return
	var item: PackedStringArray = _queue.pop_front()
	var lang: StringName = StringName(item[1])
	var path: String = voice_path(item[0], lang)
	if ResourceLoader.exists(path):
		_player.stream = load(path)
		_player.play()
	elif _tts and _voices.has(lang):
		DisplayServer.tts_speak(item[0], _voices[lang], _volume, 1.0, TTS_RATE, 0, false)
		_tts_busy = true
		_tts_wait = 0.0
	if _queue.is_empty() and not _player.playing and not _tts_busy:
		queue_finished.emit()


func _load_lines() -> void:
	var file: FileAccess = FileAccess.open(LINES_PATH, FileAccess.READ)
	if file == null:
		push_warning("Speech: cannot open %s" % LINES_PATH)
		return
	file.get_csv_line()
	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() >= 3 and not row[0].is_empty():
			_lines[row[0]] = PackedStringArray([row[1], row[2]])

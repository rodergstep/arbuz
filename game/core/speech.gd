extends Node
## Placeholder voices through the operating system's text-to-speech (Phase 1).
## AudioManager with generated voice files replaces this in Phase 2; callers keep using say().
## Ukrainian needs a Ukrainian system voice (macOS: Spoken Content → System voice → Manage
## voices → Ukrainian, e.g. "Lesya"). Without one, Ukrainian lines are logged and skipped.

const LANG_UK: StringName = &"uk"
const LANG_EN: StringName = &"en"
const VOLUME: int = 85
const RATE: float = 0.85

var _voices: Dictionary[StringName, String] = {}
var _enabled: bool = false


func _ready() -> void:
	_enabled = DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)
	if not _enabled:
		return
	for lang: StringName in [LANG_UK, LANG_EN]:
		var ids: PackedStringArray = DisplayServer.tts_get_voices_for_language(String(lang))
		if not ids.is_empty():
			_voices[lang] = ids[0]
	if not _voices.has(LANG_UK):
		push_warning("Speech: no Ukrainian system voice installed; Ukrainian lines are skipped")
	EventLog.log_event(
		&"speech_ready", {"voices": _voices.keys().map(func(k: StringName) -> String: return String(k))}
	)


## Speaks a line. Lines queue unless interrupt is true.
func say(text: String, lang: StringName = LANG_UK, interrupt: bool = false) -> void:
	EventLog.log_event(&"voice", {"text": text, "lang": String(lang)})
	if not _enabled or not _voices.has(lang):
		return
	DisplayServer.tts_speak(text, _voices[lang], VOLUME, 1.0, RATE, 0, interrupt)


func can_speak(lang: StringName) -> bool:
	return _enabled and _voices.has(lang)


func stop() -> void:
	if _enabled:
		DisplayServer.tts_stop()


func is_speaking() -> bool:
	return _enabled and DisplayServer.tts_is_speaking()

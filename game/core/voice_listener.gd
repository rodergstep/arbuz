extends Node
## Listens for a moment to hear whether he said something (any sound counts; pronunciation is
## never judged). Only the loudness is looked at, live; no audio is stored, sent or kept.
## The microphone runs only during a listen() window. Parents can turn it off.

signal level_changed(level: float)

const BUS_NAME: StringName = &"Listen"
## RMS loudness (0..1) that counts as his voice, and for how long.
const VOICE_LEVEL: float = 0.04
const VOICE_SECONDS: float = 0.25
const BLOCKED_AFTER: int = 3

var _player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _listening: bool = false
var _heard_for: float = 0.0
var _heard: bool = false
## Each listen() gets a new id; cancel() or a newer listen() ends the older one.
var _session: int = 0
## Listen windows in a row that got only exact digital silence. A blocked microphone (for
## example macOS permission denied) gives that every time; a quiet child on a noise-gated mic
## can too, so one window proves nothing. Any real signal resets the count.
var _silent_windows: int = 0
var _any_signal: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var bus: int = AudioServer.bus_count
	AudioServer.add_bus(bus)
	AudioServer.set_bus_name(bus, BUS_NAME)
	# Never play the microphone back: the bus is silent; the capture effect still reads it.
	AudioServer.set_bus_volume_db(bus, -80.0)
	_capture = AudioEffectCapture.new()
	AudioServer.add_bus_effect(bus, _capture)
	_player = AudioStreamPlayer.new()
	_player.bus = BUS_NAME
	add_child(_player)


func available() -> bool:
	return (
		bool(SaveSystem.settings.get("microphone", true))
		and bool(ProjectSettings.get_setting("audio/driver/enable_input", false))
		and DisplayServer.get_name() != "headless"
	)


## Listens for up to `seconds`; returns true as soon as he makes a sound, false on timeout or
## when there is no microphone.
func listen(seconds: float) -> bool:
	if not available():
		await get_tree().create_timer(seconds, true).timeout
		return false
	_session += 1
	var session: int = _session
	_heard = false
	_heard_for = 0.0
	_any_signal = false
	_capture.clear_buffer()
	_player.stream = AudioStreamMicrophone.new()
	_player.play()
	_listening = true
	var waited: float = 0.0
	while waited < seconds and not _heard and session == _session:
		await get_tree().create_timer(0.05, true).timeout
		waited += 0.05
	if session != _session:
		return false
	var heard: bool = _heard
	_silent_windows = 0 if _any_signal else _silent_windows + 1
	_stop_mic()
	EventLog.log_event(&"say_it_listen", {"heard": heard, "after_s": snappedf(waited, 0.1)})
	return heard


## True after BLOCKED_AFTER windows in a row of exact digital silence: the microphone is most
## likely blocked, so a card should stop waiting for him (he must never get stuck).
func seems_blocked() -> bool:
	return _silent_windows >= BLOCKED_AFTER


## Stops listening at once (the card was closed); the pending listen() returns false.
func cancel() -> void:
	if _listening:
		_session += 1
		_stop_mic()


func _stop_mic() -> void:
	_listening = false
	_player.stop()
	_player.stream = null
	level_changed.emit(0.0)


func _process(delta: float) -> void:
	if not _listening:
		return
	var frames: int = _capture.get_frames_available()
	if frames <= 0:
		return
	var buffer: PackedVector2Array = _capture.get_buffer(frames)
	var sum: float = 0.0
	for f: Vector2 in buffer:
		sum += f.x * f.x
		if f.x != 0.0:
			_any_signal = true
	var rms: float = sqrt(sum / buffer.size())
	level_changed.emit(rms)
	if rms >= VOICE_LEVEL:
		_heard_for += delta
		if _heard_for >= VOICE_SECONDS:
			_heard = true
	else:
		_heard_for = maxf(0.0, _heard_for - delta)

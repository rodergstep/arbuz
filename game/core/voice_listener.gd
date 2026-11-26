extends Node
## Listens for a moment to hear whether he said something (any sound counts; pronunciation is
## never judged). Only the loudness is looked at, live; no audio is stored, sent or kept.
## The microphone runs only during a listen() window. Parents can turn it off.

signal level_changed(level: float)

const BUS_NAME: StringName = &"Listen"
## His voice = a burst clearly louder than the room right now. Rooms differ a lot (measured on
## the M4: 0.0005 RMS quiet, 0.025 with background noise; a word from a speaker peaks ~0.03), so
## a fixed level fails (playtest bug: 0.04 never triggered). The room level is a slow moving
## average that adapts while he is quiet.
const VOICE_RATIO: float = 2.0
const START_ROOM_LEVEL: float = 0.002
const MIN_VOICE_LEVEL: float = 0.006
## Never ask for more than this: in a noisy room a missed word (he gets stuck, asked again and
## again) is worse than a noise counted as his word (he is praised; nothing is ever judged).
const MAX_VOICE_LEVEL: float = 0.015
## How fast the room level follows the room (seconds).
const ROOM_SECONDS: float = 0.8
## The microphone pops and settles when it starts: ignore this much.
const WARMUP_SECONDS: float = 0.25
## How much loud sound counts as "he said something" (syllables have gaps, so this adds up).
const VOICE_SECONDS: float = 0.15
const BLOCKED_AFTER: int = 3

var _player: AudioStreamPlayer
var _capture: AudioEffectCapture
var _listening: bool = false
var _heard_for: float = 0.0
var _elapsed: float = 0.0
var _room: float = 0.0
var _peak: float = 0.0
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
	_elapsed = 0.0
	# Start from a quiet room; it adapts only on quiet frames, so his first word never sets it.
	_room = START_ROOM_LEVEL
	_peak = 0.0
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
	(
		EventLog
		. log_event(
			&"say_it_listen",
			{
				"heard": heard,
				"after_s": snappedf(waited, 0.1),
				"peak": snappedf(_peak, 0.0001),
				"room": snappedf(_room, 0.0001),
				"threshold": snappedf(threshold(), 0.0001),
			}
		)
	)
	return heard


## The loudness that counts as his voice in this room right now.
func threshold() -> float:
	return clampf(_room * VOICE_RATIO, MIN_VOICE_LEVEL, MAX_VOICE_LEVEL)


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


func _process(_delta: float) -> void:
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
	# Time covered by these samples (more accurate than the frame delta).
	var seconds: float = float(frames) / AudioServer.get_mix_rate()
	_elapsed += seconds
	_peak = maxf(_peak, rms)
	level_changed.emit(rms)
	if _elapsed <= WARMUP_SECONDS or rms == 0.0:
		return
	if rms >= threshold():
		_heard_for += seconds
		if _heard_for >= VOICE_SECONDS:
			_heard = true
	else:
		_heard_for = maxf(0.0, _heard_for - seconds * 0.3)
		# Follow the room only while he is quiet, so his voice never raises the bar.
		_room = lerpf(_room, rms, 1.0 - exp(-seconds / ROOM_SECONDS))

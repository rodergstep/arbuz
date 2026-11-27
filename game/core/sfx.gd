extends Node
## Placeholder sound effects synthesized in code (soft tones, no files). Replaced by real
## sounds in Phase 3; callers keep using play().

const MIX_RATE: int = 22050
const VOICES: int = 4
const VOLUME_DB: float = -10.0
const CAR_HORN: AudioStream = preload("res://audio/sfx/car_horn.ogg")

var _streams: Dictionary[StringName, AudioStreamWAV] = {}
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0


func _ready() -> void:
	for i: int in VOICES:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.volume_db = VOLUME_DB
		add_child(player)
		_players.append(player)
	_streams[&"tap"] = _tones([880.0], 0.07, 0.3)
	_streams[&"horn_toy"] = _tones([392.0, 494.0], 0.18, 0.5, true)
	# A duck's "quack" (a falling nasal buzz) and a bicycle bell (two bright rings).
	_streams[&"horn_duck"] = _quack()
	_streams[&"horn_bell"] = _tones([2093.0, 2637.0, 2093.0, 2637.0], 0.09, 0.35)
	_streams[&"boing"] = _sweep(320.0, 140.0, 0.28)
	_streams[&"chime"] = _tones([523.0, 659.0, 784.0, 1047.0], 0.11, 0.4)
	_streams[&"soft"] = _tones([494.0, 523.0], 0.09, 0.25)
	_streams[&"door"] = _tones([392.0, 523.0, 659.0, 784.0, 1047.0, 1319.0], 0.09, 0.4)
	_streams[&"pop"] = _sweep(500.0, 900.0, 0.09)
	# A short, bright party tune for the festival (an original little arpeggio).
	_streams[&"tune"] = _tones([523.0, 659.0, 784.0, 659.0, 698.0, 880.0, 784.0, 1047.0], 0.16, 0.3)


## His car's horn: the one he chose at the horn stand (save setting "horn"): a real car horn
## (CC0 recording), a duck's quack or a bicycle bell.
func play_horn() -> void:
	var horn: String = String(SaveSystem.settings.get("horn", "car"))
	if horn == "car":
		var player: AudioStreamPlayer = _players[_next]
		_next = (_next + 1) % _players.size()
		player.stream = CAR_HORN
		player.play()
		return
	play(StringName("horn_" + horn))


func _quack() -> AudioStreamWAV:
	var count: int = int(0.28 * MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for i: int in count:
		var k: float = float(i) / count
		phase += TAU * lerpf(520.0, 330.0, k) / MIX_RATE
		var buzz: float = clampf(sin(phase) * 2.5, -1.0, 1.0) * 0.7 + sin(phase * 3.0) * 0.3
		var env: float = minf(1.0, i / 300.0) * (1.0 - k)
		data.encode_s16(i * 2, int(buzz * env * 0.45 * 32767.0))
	return _wav(data)


func play(kind: StringName) -> void:
	if not _streams.has(kind):
		push_warning("Sfx: unknown sound %s" % kind)
		return
	var player: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[kind]
	player.play()


func _tones(freqs: Array[float], note_len: float, gain: float, square: bool = false) -> AudioStreamWAV:
	var data: PackedByteArray = PackedByteArray()
	var per_note: int = int(note_len * MIX_RATE)
	data.resize(freqs.size() * per_note * 2)
	var offset: int = 0
	for freq: float in freqs:
		for i: int in per_note:
			var t: float = float(i) / MIX_RATE
			var env: float = minf(1.0, i / 200.0) * (1.0 - float(i) / per_note)
			var s: float = sin(TAU * freq * t)
			if square:
				s = clampf(s * 3.0, -1.0, 1.0) * 0.6
			data.encode_s16(offset, int(s * env * gain * 32767.0))
			offset += 2
	return _wav(data)


func _sweep(from_hz: float, to_hz: float, length: float) -> AudioStreamWAV:
	var count: int = int(length * MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	for i: int in count:
		var k: float = float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, k) / MIX_RATE
		var env: float = minf(1.0, i / 150.0) * (1.0 - k)
		data.encode_s16(i * 2, int(sin(phase) * env * 0.45 * 32767.0))
	return _wav(data)


func _wav(data: PackedByteArray) -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = data
	return wav

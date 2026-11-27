extends Node
## Placeholder sound effects synthesized in code (soft tones, no files). Replaced by real
## sounds in Phase 3; callers keep using play().

const MIX_RATE: int = 22050
const VOICES: int = 4
const VOLUME_DB: float = -10.0

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
	_streams[&"horn"] = _tones([392.0, 494.0], 0.18, 0.5, true)
	_streams[&"boing"] = _sweep(320.0, 140.0, 0.28)
	_streams[&"chime"] = _tones([523.0, 659.0, 784.0, 1047.0], 0.11, 0.4)
	_streams[&"soft"] = _tones([494.0, 523.0], 0.09, 0.25)
	_streams[&"door"] = _tones([392.0, 523.0, 659.0, 784.0, 1047.0, 1319.0], 0.09, 0.4)
	_streams[&"pop"] = _sweep(500.0, 900.0, 0.09)
	# A short, bright party tune for the festival (an original little arpeggio).
	_streams[&"tune"] = _tones([523.0, 659.0, 784.0, 659.0, 698.0, 880.0, 784.0, 1047.0], 0.16, 0.3)


## A soft, looping toy-car engine hum (synthesized: a low tone with a few harmonics and a gentle
## putter), for an AudioStreamPlayer that changes its pitch with the car's speed.
func engine_stream() -> AudioStreamWAV:
	var seconds: float = 1.0
	var count: int = int(seconds * MIX_RATE)
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	var base: float = 60.0
	for i: int in count:
		var t: float = float(i) / MIX_RATE
		var putter: float = 0.75 + 0.25 * sin(TAU * 12.0 * t)
		var s: float = (
			sin(TAU * base * t) * 0.6 + sin(TAU * base * 2.0 * t) * 0.25 + sin(TAU * base * 3.0 * t) * 0.12
		)
		data.encode_s16(i * 2, int(s * putter * 0.35 * 32767.0))
	var wav: AudioStreamWAV = _wav(data)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	return wav


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

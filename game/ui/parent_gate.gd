class_name ParentGate
extends Node
## The parent lock: hold Ctrl + Shift + P for 3 seconds. A three-year-old is very unlikely to
## do that by accident. Emits unlocked; the parent screen opens on it.

signal unlocked

const HOLD_SECONDS: float = 3.0

var _held: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	var holding: bool = (
		Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_SHIFT) and Input.is_key_pressed(KEY_P)
	)
	if not holding:
		_held = 0.0
		return
	_held += delta
	if _held >= HOLD_SECONDS:
		_held = -INF
		EventLog.log_event(&"parent_gate_open")
		unlocked.emit()

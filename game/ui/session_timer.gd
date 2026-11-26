class_name SessionTimer
extends CanvasLayer
## Gentle sessions: counts play time (not while paused). Two minutes before the end Тигриця
## warns; at the end she yawns, says goodbye, and a calm night screen stays until a parent
## unlocks it (ParentGate → "play 15 more minutes").

signal warned
signal ended

const WARN_BEFORE: float = 120.0
const EXTEND_SECONDS: float = 15.0 * 60.0

var played: float = 0.0
var limit: float = 15.0 * 60.0

var _warned: bool = false
var _ended: bool = false
var _tree_was_paused: bool = false


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	limit = float(SaveSystem.settings.get("session_minutes", 15)) * 60.0
	var night: ColorRect = ColorRect.new()
	night.color = Color(0.12, 0.15, 0.3, 0.92)
	night.set_anchors_preset(Control.PRESET_FULL_RECT)
	night.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(night)
	var moon: Polygon2D = Polygon2D.new()
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 32:
		points.append(Vector2.from_angle(TAU * i / 32.0) * 90.0)
	moon.polygon = points
	moon.color = Color(1.0, 0.95, 0.75)
	night.add_child(moon)
	night.resized.connect(func() -> void: moon.position = Vector2(night.size.x / 2.0, night.size.y / 2.5))
	visible = false


func _process(delta: float) -> void:
	if _ended or get_tree().paused:
		return
	played += delta
	if not _warned and played >= limit - WARN_BEFORE:
		_warned = true
		Speech.line("session:warn")
		EventLog.log_event(&"session_warning")
		warned.emit()
	if played >= limit:
		_end()


func extend() -> void:
	limit = played + EXTEND_SECONDS
	_warned = false
	if _ended:
		_ended = false
		visible = false
		get_tree().paused = _tree_was_paused
	EventLog.log_event(&"session_extended")


## Re-reads the parent's session length (after the parent screen).
func refresh_limit() -> void:
	limit = maxf(played + 60.0, float(SaveSystem.settings.get("session_minutes", 15)) * 60.0)


func _end() -> void:
	_ended = true
	_tree_was_paused = false
	get_tree().paused = true
	visible = true
	Speech.line("session:bye", null, true)
	EventLog.log_event(&"session_end", {"played_s": roundi(played)})
	ended.emit()

class_name PerfMonitor
extends CanvasLayer
## Frame-rate check for the Intel MacBook budget (≥30 fps): writes average and lowest fps to the
## playtest log every 30 s; F3 shows a small counter for parents and developers.

const REPORT_SECONDS: float = 30.0

var _label: Label
var _frames: int = 0
var _elapsed: float = 0.0
var _min_fps: float = 1000.0


func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_label = Label.new()
	_label.position = Vector2(12, 8)
	_label.add_theme_font_size_override("font_size", 18)
	_label.visible = false
	add_child(_label)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		_label.visible = not _label.visible


func _process(delta: float) -> void:
	_frames += 1
	_elapsed += delta
	if delta > 0.0:
		_min_fps = minf(_min_fps, 1.0 / delta)
	if _label.visible:
		_label.text = "%d fps" % Engine.get_frames_per_second()
	if _elapsed >= REPORT_SECONDS:
		EventLog.log_event(
			&"perf", {"fps_avg": snappedf(_frames / _elapsed, 0.1), "fps_min": snappedf(_min_fps, 0.1)}
		)
		_frames = 0
		_elapsed = 0.0
		_min_fps = 1000.0

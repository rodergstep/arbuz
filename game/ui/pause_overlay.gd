class_name PauseOverlay
extends CanvasLayer
## Pause is always available (Esc / P / Start). A soft dim and one big play button; any click,
## Space or the pause key resumes. No text.

var _root: Control


func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.1, 0.12, 0.2, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)
	var play: Polygon2D = Polygon2D.new()
	play.color = Color(1.0, 0.96, 0.88)
	play.polygon = PackedVector2Array([Vector2(-60, -80), Vector2(90, 0), Vector2(-60, 80)])
	_root.add_child(play)
	_root.resized.connect(func() -> void: play.position = _root.size / 2.0)
	visible = false


func toggle() -> void:
	set_paused(not get_tree().paused)


func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		Speech.stop()
	EventLog.log_event(&"pause" if paused else &"resume")


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var resume: bool = event.is_action_pressed(&"use") or event.is_action_pressed(&"pause")
	resume = resume or (event is InputEventMouseButton and event.pressed)
	if resume:
		get_viewport().set_input_as_handled()
		set_paused(false)

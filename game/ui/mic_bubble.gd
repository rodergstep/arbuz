class_name MicBubble
extends Control
## "Your turn!" sign on the learning card while it listens: a pulsing circle with a microphone
## that grows with his voice, so he sees that the game hears him. No text.

const SIZE: float = 120.0

var _level: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	VoiceListener.level_changed.connect(func(level: float) -> void: _level = level)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	var grow: float = clampf(_level * 12.0, 0.0, 1.0)
	draw_circle(c, SIZE * (0.36 + 0.05 * pulse + 0.12 * grow), Color(UiTokens.ACCENT_SUN, 0.35))
	draw_circle(c, SIZE * 0.32, UiTokens.ACCENT_SUN)
	_draw_microphone(c, 1.0 + 0.15 * grow)


## A simple microphone: rounded head, a U-shaped holder, a stem and a foot.
func _draw_microphone(c: Vector2, scale_by: float) -> void:
	var ink: Color = UiTokens.INK
	var w: float = 14.0 * scale_by
	var h: float = 22.0 * scale_by
	var top: Vector2 = c + Vector2(0, -h * 0.75)
	var bottom: Vector2 = c + Vector2(0, h * 0.1)
	draw_circle(top, w, ink)
	draw_circle(bottom, w, ink)
	draw_rect(Rect2(Vector2(c.x - w, top.y), Vector2(w * 2.0, bottom.y - top.y)), ink)
	var holder_r: float = w + 8.0 * scale_by
	draw_arc(bottom, holder_r, 0.0, PI, 24, ink, 4.0 * scale_by, true)
	var stem_top: Vector2 = bottom + Vector2(0, holder_r)
	var stem_end: Vector2 = stem_top + Vector2(0, 10.0 * scale_by)
	draw_line(stem_top, stem_end, ink, 4.0 * scale_by, true)
	draw_line(
		stem_end - Vector2(12, 0) * scale_by, stem_end + Vector2(12, 0) * scale_by, ink, 4.0 * scale_by, true
	)

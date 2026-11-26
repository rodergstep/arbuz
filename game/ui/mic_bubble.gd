class_name MicBubble
extends Control
## "Your turn!" sign on the learning card while it listens: a soft mouth-shaped bubble that
## grows with his voice, so he sees that the game hears him. No text.

const SIZE: float = 120.0

var _level: float = 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	VoiceListener.level_changed.connect(func(level: float) -> void: _level = level)


func _process(_delta: float) -> void:
	if visible:
		queue_redraw()


func _draw() -> void:
	var center: Vector2 = size / 2.0
	var pulse: float = 0.5 + 0.5 * sin(Time.get_ticks_msec() / 250.0)
	var grow: float = clampf(_level * 12.0, 0.0, 1.0)
	draw_circle(center, SIZE * (0.32 + 0.06 * pulse + 0.15 * grow), Color(UiTokens.ACCENT_SUN, 0.35))
	draw_circle(center, SIZE * 0.28, UiTokens.ACCENT_SUN)
	# an open mouth that opens wider with his voice
	var mouth: Rect2 = Rect2(center - Vector2(22, 8 + 14 * grow), Vector2(44, 16 + 28 * grow))
	draw_rect(mouth, UiTokens.INK)

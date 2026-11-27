class_name AlbumIcon
extends Control
## Drawn icons for the album's buttons (no font glyphs needed): an open book, a cross.

enum Kind { BOOK, CLOSE }

var kind: Kind = Kind.BOOK


func _draw() -> void:
	var c: Vector2 = size / 2.0
	var s: float = minf(size.x, size.y) * 0.32
	match kind:
		Kind.BOOK:
			var page: Color = Color(1, 1, 1)
			var cover: Color = UiTokens.ACCENT_SKY
			draw_rect(Rect2(c + Vector2(-s * 1.1, -s * 0.8), Vector2(s * 2.2, s * 1.7)), cover)
			draw_rect(Rect2(c + Vector2(-s, -s * 0.7), Vector2(s * 0.95, s * 1.45)), page)
			draw_rect(Rect2(c + Vector2(s * 0.05, -s * 0.7), Vector2(s * 0.95, s * 1.45)), page)
			for i: int in 3:
				var y: float = -s * 0.35 + i * s * 0.35
				draw_line(c + Vector2(-s * 0.8, y), c + Vector2(-s * 0.2, y), UiTokens.INK, 3.0)
			draw_circle(c + Vector2(s * 0.5, 0), s * 0.28, UiTokens.ACCENT_SUN)
		Kind.CLOSE:
			draw_line(c + Vector2(-s, -s), c + Vector2(s, s), UiTokens.INK, 10.0, true)
			draw_line(c + Vector2(-s, s), c + Vector2(s, -s), UiTokens.INK, 10.0, true)

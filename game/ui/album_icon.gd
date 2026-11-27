class_name AlbumIcon
extends Control
## Drawn icons for the album (no font glyphs needed): an open book, a cross, a star sticker.

enum Kind { BOOK, CLOSE, STAR, UKRAINE, ENGLAND }

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
		Kind.STAR:
			var points: PackedVector2Array = PackedVector2Array()
			for i: int in 10:
				var r: float = s * (1.35 if i % 2 == 0 else 0.6)
				var a: float = -PI / 2.0 + TAU * i / 10.0
				points.append(c + Vector2(cos(a), sin(a)) * r)
			draw_colored_polygon(points, UiTokens.ACCENT_SUN)
			draw_polyline(points + PackedVector2Array([points[0]]), Color(0.85, 0.55, 0.15), 3.0, true)
		Kind.UKRAINE:
			# A round map pin in the colours of the flag: blue sky over a golden wheat field.
			draw_circle(c, s * 1.3, Color(0.25, 0.5, 0.85))
			var half: PackedVector2Array = PackedVector2Array()
			for i: int in 25:
				half.append(c + Vector2(cos(PI * i / 24.0), sin(PI * i / 24.0)) * s * 1.3)
			draw_colored_polygon(half, Color(0.98, 0.8, 0.2))
			draw_arc(c, s * 1.3, 0, TAU, 48, UiTokens.INK, 4.0, true)
		Kind.ENGLAND:
			# White with a red cross.
			draw_circle(c, s * 1.3, Color(0.98, 0.98, 0.96))
			draw_rect(
				Rect2(c + Vector2(-s * 1.25, -s * 0.22), Vector2(s * 2.5, s * 0.44)), Color(0.85, 0.15, 0.2)
			)
			draw_rect(
				Rect2(c + Vector2(-s * 0.22, -s * 1.25), Vector2(s * 0.44, s * 2.5)), Color(0.85, 0.15, 0.2)
			)
			draw_arc(c, s * 1.3, 0, TAU, 48, UiTokens.INK, 4.0, true)
		Kind.CLOSE:
			draw_line(c + Vector2(-s, -s), c + Vector2(s, s), UiTokens.INK, 10.0, true)
			draw_line(c + Vector2(-s, s), c + Vector2(s, -s), UiTokens.INK, 10.0, true)

class_name Ink
extends RefCounted
## 아트 가이드 색상표와 요괴 칸 그리기 도우미.

const NIGHT := Color(0.11, 0.13, 0.24)
const NIGHT_DEEP := Color(0.07, 0.08, 0.16)
const CREAM := Color(0.96, 0.93, 0.86)
const CREAM_DIM := Color(0.85, 0.81, 0.73)
const INK := Color(0.13, 0.11, 0.10)
const VERMILION := Color(0.82, 0.27, 0.20)
const JADE := Color(0.36, 0.62, 0.52)
const GOLD := Color(0.88, 0.70, 0.32)
const SLATE := Color(0.55, 0.58, 0.70)

const TRAIT_COLORS := {
	&"coin": GOLD, &"charm": Color(0.45, 0.65, 0.95), &"bind": Color(0.35, 0.5, 0.85),
	&"guard": JADE, &"rage": VERMILION, &"devour": Color(0.5, 0.5, 0.55),
}


static func speed_key(interval: float) -> String:
	if interval <= 1.1:
		return "SPEED_FAST"
	if interval <= 1.6:
		return "SPEED_NORMAL"
	return "SPEED_SLOW"


static func name_of(kind: StringName) -> String:
	var prefix := "YOKAI_" if YokaiDb.ALLIES.has(kind) else "ENEMY_"
	return TranslationServer.translate(prefix + String(kind).to_upper())


static func centroid(cells: Array[Vector2i]) -> Vector2:
	var sum := Vector2.ZERO
	for c in cells:
		sum += Vector2(c) + Vector2(0.5, 0.5)
	return sum / maxf(cells.size(), 1)


## cells(상대 또는 절대 좌표)를 origin 기준으로 그린다.
static func draw_shape(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, fill: Color, line: Color, width := 3.0) -> void:
	for c in cells:
		ci.draw_rect(Rect2(origin + Vector2(c) * cs, Vector2(cs, cs)).grow(-1), fill)
	for c in cells:
		var o := origin + Vector2(c) * cs
		if c + Vector2i.UP not in cells:
			ci.draw_line(o, o + Vector2(cs, 0), line, width)
		if c + Vector2i.DOWN not in cells:
			ci.draw_line(o + Vector2(0, cs), o + Vector2(cs, cs), line, width)
		if c + Vector2i.LEFT not in cells:
			ci.draw_line(o, o + Vector2(0, cs), line, width)
		if c + Vector2i.RIGHT not in cells:
			ci.draw_line(o + Vector2(cs, 0), o + Vector2(cs, cs), line, width)


static func draw_portrait(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, kind: StringName, modulate := Color.WHITE) -> void:
	var lo := Vector2i(1 << 20, 1 << 20)
	var hi := Vector2i(-1, -1)
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
		hi = Vector2i(maxi(hi.x, c.x), maxi(hi.y, c.y))
	var side := clampf(mini(hi.x - lo.x, hi.y - lo.y) + 1, 1, 3) * cs * 0.95
	var center := origin + centroid(cells) * cs
	ci.draw_texture_rect(YokaiDb.texture(kind), Rect2(center - Vector2(side, side) / 2, Vector2(side, side)), false, modulate)


static func draw_badge(ci: CanvasItem, center: Vector2, value: int, color: Color, font: Font, size := 20, text_color := CREAM) -> void:
	ci.draw_circle(center, size * 0.75, color)
	ci.draw_circle(center, size * 0.75, INK, false, 2.0)
	ci.draw_string(font, center + Vector2(-size, size * 0.35), str(value), HORIZONTAL_ALIGNMENT_CENTER, size * 2, size, text_color)


static func draw_piece(ci: CanvasItem, origin: Vector2, p: Piece, cs: float, font: Font, tint := Color.WHITE) -> void:
	draw_shape(ci, origin, p.cells, cs, CREAM * tint, INK)
	draw_portrait(ci, origin, p.cells, cs, p.kind, tint)
	var first: Vector2 = origin + Vector2(p.cells[0]) * cs
	var badge := maxf(cs * 0.18, 12)
	draw_badge(ci, first + Vector2(badge, badge), p.atk, VERMILION, font, int(badge))
	draw_badge(ci, first + Vector2(badge * 2.8, badge), p.hp, JADE, font, int(badge))
	for i in p.traits.size():
		var dot := first + Vector2(cs - badge * 0.8, badge * 0.8 + i * badge * 1.1)
		ci.draw_rect(Rect2(dot - Vector2(badge, badge) * 0.4, Vector2(badge, badge) * 0.8), TRAIT_COLORS.get(p.traits[i], SLATE))

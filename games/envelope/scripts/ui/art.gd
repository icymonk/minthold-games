class_name Art
extends RefCounted
## 외부 그림 없이 도형으로 그리는 인물·봉투(기획서 7장).

const SKIN := Color("#F1C9A5")
const HAIR := [Color("#2B2B33"), Color("#5A3E2B"), Color("#8A5A3C"), Color("#3B3F58"), Color("#6E6259"), Color("#1F2A2E")]
const SHIRT := [Color("#8FB9A8"), Color("#7C93C3"), Color("#C9A26B"), Color("#B784A7"), Color("#6FA3B8"), Color("#9CA36B")]

const C := Cards.Id
const LOOK := {
	C.NEWBIE: Color("#F2C14E"),
	C.THIEF: Color("#3A3A44"),
	C.BUDDY: Color("#E58F9E"),
	C.MISER: Color("#9C7A4B"),
	C.CHAIR: Color("#5E9C8A"),
	C.ACCOUNTANT: Color("#F4F4F0"),
	C.HR: Color("#41507A"),
	C.SNIFFER: Color("#7FA36B"),
	C.BUSYBODY: Color("#E39A5B"),
	C.BROADCAST: Color("#5B8DD6"),
	C.SUPPLIES: Color("#A0A6AE"),
	C.BOSS: Color("#55555F"),
	C.QUITTER: Color("#B9B2A3"),
}


## 카드 머리띠 색: 진영(우선순위)별.
static func band(kind: int) -> Color:
	if kind < 0:
		return Style.KRAFT
	match Cards.priority(kind):
		1:
			return Color("#E0A93B")
		2:
			return Style.STAMP
		3:
			return Color("#9C7A4B")
		5:
			return Color("#7D8597")
	return Color("#55555F") if kind == C.BOSS else Style.PARTITION.darkened(0.2)


## 상반신 인물. kind < 0이면 seat 번호로 머리·옷 색만 바꾼 동료.
static func portrait(ci: CanvasItem, rect: Rect2, kind: int, seat := 0) -> void:
	var u := minf(rect.size.x, rect.size.y)
	var c := rect.get_center()
	var head := c + Vector2(0, -u * 0.12)
	var r := u * 0.2
	var shirt: Color = LOOK.get(kind, SHIRT[seat % SHIRT.size()])
	var hair: Color = HAIR[(seat if kind < 0 else kind) % HAIR.size()]
	var body := Rect2(c.x - u * 0.34, head.y + r * 0.9, u * 0.68, rect.end.y - head.y - r * 0.9)
	ci.draw_style_box(_round(shirt, int(u * 0.18), Color(Style.INK, 0.6), 2), body)
	ci.draw_circle(head, r, SKIN)
	ci.draw_circle(head, r, Color(Style.INK, 0.6), false, 2.0, true)
	if kind != C.BOSS:
		ci.draw_colored_polygon(_arc(head, r * 1.04, PI, TAU), hair)
	else:
		ci.draw_line(head + Vector2(-r * 0.95, -r * 0.2), head + Vector2(-r * 0.7, -r * 0.6), hair, 4.0)
		ci.draw_line(head + Vector2(r * 0.95, -r * 0.2), head + Vector2(r * 0.7, -r * 0.6), hair, 4.0)
	var eye := r * 0.38
	ci.draw_circle(head + Vector2(-eye, r * 0.1), maxf(2.0, r * 0.09), Style.INK)
	ci.draw_circle(head + Vector2(eye, r * 0.1), maxf(2.0, r * 0.09), Style.INK)
	var sad := kind == C.MISER or kind == C.QUITTER
	var mouth := _arc(head + Vector2(0, r * (0.75 if sad else 0.35)), r * 0.3, PI * 1.2 if sad else PI * 0.2, PI * 1.8 if sad else PI * 0.8)
	ci.draw_polyline(mouth, Style.INK, 2.0, true)
	if kind not in [C.SUPPLIES, C.QUITTER, C.NEWBIE, C.BUDDY]:
		var badge := Rect2(c.x + u * 0.08, body.position.y + u * 0.14, u * 0.14, u * 0.1)
		ci.draw_line(head + Vector2(-r * 0.5, r * 0.9), badge.position + Vector2(badge.size.x * 0.5, 0), Style.STAMP, 2.0)
		ci.draw_line(head + Vector2(r * 0.5, r * 0.9), badge.position + Vector2(badge.size.x * 0.5, 0), Style.STAMP, 2.0)
		ci.draw_rect(badge, Color.WHITE)
		ci.draw_rect(badge, Style.INK, false, 1.5)
	_accessory(ci, kind, head, r, body, u)


static func _accessory(ci: CanvasItem, kind: int, head: Vector2, r: float, body: Rect2, u: float) -> void:
	var chest := Vector2(body.get_center().x, body.position.y + u * 0.2)
	match kind:
		C.NEWBIE:
			ci.draw_colored_polygon(_star(chest, u * 0.1), Color("#FFF3B0"))
			ci.draw_line(head + Vector2(r * 1.1, r * 0.6), head + Vector2(r * 1.7, -r * 1.2), SKIN, u * 0.07)
		C.THIEF:
			ci.draw_rect(Rect2(head.x - r, head.y - r * 0.15, r * 2, r * 0.5), Style.INK)
			ci.draw_circle(head + Vector2(-r * 0.38, r * 0.1), r * 0.1, Color.WHITE)
			ci.draw_circle(head + Vector2(r * 0.38, r * 0.1), r * 0.1, Color.WHITE)
		C.BUDDY:
			ci.draw_colored_polygon(_heart(chest, u * 0.09), Style.STAMP)
		C.MISER:
			var coin := chest + Vector2(-u * 0.12, u * 0.05)
			ci.draw_circle(coin, u * 0.08, Color("#E8C44A"))
			ci.draw_circle(coin, u * 0.08, Style.INK, false, 1.5, true)
			ci.draw_line(coin + Vector2(0, -u * 0.04), coin + Vector2(0, u * 0.04), Style.INK, 2.0)
		C.CHAIR:
			var board := Rect2(chest + Vector2(-u * 0.24, -u * 0.04), Vector2(u * 0.16, u * 0.2))
			ci.draw_rect(board, Color("#C9A26B"))
			ci.draw_rect(board.grow(-u * 0.025), Color.WHITE)
			for i in 3:
				var y := board.position.y + u * (0.06 + 0.045 * i)
				ci.draw_line(Vector2(board.position.x + u * 0.04, y), Vector2(board.end.x - u * 0.04, y), Style.INK, 1.0)
		C.ACCOUNTANT:
			for x in [-1.0, 1.0]:
				ci.draw_circle(head + Vector2(x * r * 0.4, r * 0.1), r * 0.26, Style.INK, false, 2.0, true)
			ci.draw_line(head + Vector2(-r * 0.14, r * 0.1), head + Vector2(r * 0.14, r * 0.1), Style.INK, 2.0)
			ci.draw_colored_polygon(_tie(chest + Vector2(0, -u * 0.12), u), Color("#41507A"))
		C.HR:
			for x in [-1.0, 1.0]:
				ci.draw_rect(Rect2(head + Vector2(x * r * 0.4 - r * 0.24, r * 0.0), Vector2(r * 0.48, r * 0.26)), Style.INK, false, 2.0)
			ci.draw_colored_polygon(PackedVector2Array([chest + Vector2(-u * 0.08, -u * 0.12), chest + Vector2(0, u * 0.02), chest + Vector2(u * 0.08, -u * 0.12)]), Color.WHITE)
		C.SNIFFER:
			var lens := head + Vector2(r * 1.5, r * 0.3)
			ci.draw_line(lens + Vector2(r * 0.3, r * 0.3), lens + Vector2(r * 0.85, r * 0.85), Style.INK, u * 0.04)
			ci.draw_circle(lens, r * 0.42, Color(Color.WHITE, 0.6))
			ci.draw_circle(lens, r * 0.42, Style.INK, false, 3.0, true)
		C.BUSYBODY:
			var bubble := head + Vector2(r * 1.55, -r * 0.9)
			ci.draw_circle(bubble, r * 0.5, Color.WHITE)
			ci.draw_circle(bubble, r * 0.5, Style.INK, false, 2.0, true)
			ci.draw_line(bubble + Vector2(0, -r * 0.28), bubble + Vector2(0, r * 0.08), Style.STAMP, 3.0)
			ci.draw_circle(bubble + Vector2(0, r * 0.25), 2.0, Style.STAMP)
		C.BROADCAST:
			var m := head + Vector2(r * 1.1, r * 0.45)
			ci.draw_colored_polygon(PackedVector2Array([m + Vector2(0, -r * 0.18), m + Vector2(r * 0.9, -r * 0.5), m + Vector2(r * 0.9, r * 0.5), m + Vector2(0, r * 0.18)]), Style.STAMP)
			for i in 2:
				ci.draw_arc(m + Vector2(r * 0.9, 0), r * (0.35 + 0.25 * i), -0.8, 0.8, 8, Style.INK, 2.0)
		C.SUPPLIES:
			var box := Rect2(chest + Vector2(-u * 0.14, -u * 0.04), Vector2(u * 0.28, u * 0.18))
			ci.draw_rect(box, Color("#C9A26B"))
			ci.draw_rect(box, Style.INK, false, 1.5)
			ci.draw_line(box.position + Vector2(box.size.x * 0.5, 0), box.position + Vector2(box.size.x * 0.5, box.size.y * 0.4), Style.INK, 1.5)
			ci.draw_line(box.position + Vector2(u * 0.04, -u * 0.06), box.position + Vector2(u * 0.12, -u * 0.12), Color("#E8C44A"), u * 0.035)
		C.BOSS:
			ci.draw_colored_polygon(_tie(chest + Vector2(0, -u * 0.12), u), Style.STAMP)
			ci.draw_line(head + Vector2(-r * 0.35, r * 0.55), head + Vector2(r * 0.35, r * 0.55), Style.INK, 3.0)
		C.QUITTER:
			var box := Rect2(chest + Vector2(-u * 0.16, -u * 0.02), Vector2(u * 0.32, u * 0.18))
			ci.draw_rect(box, Color("#C9A26B"))
			ci.draw_rect(box, Style.INK, false, 1.5)
			var stem := box.position + Vector2(box.size.x * 0.7, 0)
			ci.draw_line(stem, stem + Vector2(0, -u * 0.1), Color("#4E8A3E"), 2.5)
			ci.draw_circle(stem + Vector2(-u * 0.03, -u * 0.09), u * 0.03, Color("#6BAA4F"))
			ci.draw_circle(stem + Vector2(u * 0.03, -u * 0.11), u * 0.03, Color("#6BAA4F"))


## 크라프트 봉투: 몸통 + 뚜껑 V선.
static func envelope(ci: CanvasItem, rect: Rect2) -> void:
	ci.draw_style_box(_round(Style.KRAFT.lightened(0.25), 14, Style.KRAFT.darkened(0.3), 3), rect)
	var a := rect.position + Vector2(10, 10)
	var b := Vector2(rect.end.x - 10, rect.position.y + 10)
	var tip := Vector2(rect.get_center().x, rect.position.y + rect.size.y * 0.42)
	ci.draw_polyline(PackedVector2Array([a, tip, b]), Style.KRAFT.darkened(0.3), 3.0, true)
	ci.draw_circle(tip, 9.0, Style.STAMP)


static func _round(color: Color, radius: int, border: Color, w: int) -> StyleBoxFlat:
	return Style.box(color, radius, border, w)


static func _arc(c: Vector2, r: float, from: float, to: float, n := 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n + 1:
		var a := lerpf(from, to, float(i) / n)
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	return pts


static func _star(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		pts.append(c + Vector2(cos(a), sin(a)) * (r if i % 2 == 0 else r * 0.45))
	return pts


static func _heart(c: Vector2, r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		pts.append(c + Vector2(16 * pow(sin(t), 3), -(13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t))) * r / 16.0)
	return pts


static func _tie(top: Vector2, u: float) -> PackedVector2Array:
	return PackedVector2Array([top + Vector2(-u * 0.03, 0), top + Vector2(u * 0.03, 0), top + Vector2(u * 0.05, u * 0.2), top + Vector2(0, u * 0.26), top + Vector2(-u * 0.05, u * 0.2)])

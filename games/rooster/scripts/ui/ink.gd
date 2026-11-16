class_name Ink
extends RefCounted
## 아트 가이드 색상표와 종이·먹선 그리기 도우미.

const NIGHT := Color(0.11, 0.13, 0.24)
const NIGHT_DEEP := Color(0.07, 0.08, 0.16)
const CREAM := Color(0.96, 0.93, 0.86)
const CREAM_DIM := Color(0.85, 0.81, 0.73)
const INK := Color(0.13, 0.11, 0.10)
const VERMILION := Color(0.82, 0.27, 0.20)
const JADE := Color(0.36, 0.62, 0.52)
const GOLD := Color(0.88, 0.70, 0.32)
const SLATE := Color(0.55, 0.58, 0.70)
const WOOD := Color(0.55, 0.36, 0.20)

const FAMILY_COLORS := {
	&"fire": Color(0.90, 0.42, 0.20), &"water": Color(0.32, 0.55, 0.88), &"grudge": Color(0.66, 0.56, 0.80),
	&"metal": GOLD, &"divine": JADE, &"mountain": Color(0.50, 0.42, 0.34),
}

static var _ui := {}
static var _bold: Font


## 능력 색은 그 능력을 원래 가진 요괴의 계열 색.
static func trait_color(t: StringName) -> Color:
	for kind in YokaiDb.ALLIES:
		if YokaiDb.ALLIES[kind]["trait"] == t:
			return FAMILY_COLORS[YokaiDb.ALLIES[kind]["family"]]
	return SLATE


static func family_color(kind: StringName) -> Color:
	return FAMILY_COLORS[YokaiDb.family(kind)]


static func ui(file: String) -> Texture2D:
	if not _ui.has(file):
		_ui[file] = load("res://assets/ui/" + file)
	return _ui[file]


static func bold() -> Font:
	if _bold == null:
		_bold = load("res://assets/fonts/Pretendard-Bold.otf")
	return _bold


static func speed_key(interval: float) -> String:
	if interval <= 1.1:
		return "SPEED_FAST"
	if interval <= 1.6:
		return "SPEED_NORMAL"
	return "SPEED_SLOW"


static func name_of(kind: StringName) -> String:
	var prefix := "YOKAI_" if YokaiDb.is_ally(kind) else "ENEMY_"
	return TranslationServer.translate(prefix + String(kind).to_upper())


## 한국어일 때 받침에 맞는 조사를 붙인다. pair는 "이가", "을를"처럼 받침 있음/없음 순서.
static func with_josa(word: String, pair: String) -> String:
	if not TranslationServer.get_locale().begins_with("ko") or word.is_empty():
		return word
	var code := word.unicode_at(word.length() - 1)
	var final := (code - 0xAC00) % 28 if code >= 0xAC00 and code <= 0xD7A3 else 0
	if pair == "으로":
		return word + ("으로" if final != 0 and final != 8 else "로")
	return word + (pair[0] if final != 0 else pair[1])


static func centroid(cells: Array[Vector2i]) -> Vector2:
	var sum := Vector2.ZERO
	for c in cells:
		sum += Vector2(c) + Vector2(0.5, 0.5)
	return sum / maxf(cells.size(), 1)


# --- 판과 종이 ---

static func box(color: Color, radius := 10, border := Color(0, 0, 0, 0), border_w := 0, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	if shadow > 0:
		sb.shadow_color = Color(0, 0, 0, 0.35)
		sb.shadow_size = shadow
		sb.shadow_offset = Vector2(0, shadow * 0.5)
	return sb


## 밤하늘 위에 놓는 반투명 판.
static func draw_panel(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_style_box(box(Color(NIGHT_DEEP, 0.72), 14, Color(CREAM, 0.22), 2), r)


## 한지 카드: 그림자 + 한지 결 + 먹선 테두리.
static func draw_paper(ci: CanvasItem, r: Rect2, tint := Color.WHITE, border := INK) -> void:
	ci.draw_style_box(box(CREAM * tint, 8, Color(0, 0, 0, 0), 0, 6), r)
	ci.draw_texture_rect(ui("paper.jpg"), r.grow(-4), false, tint)
	ci.draw_style_box(box(Color(0, 0, 0, 0), 8, border, 3), r)


## 보따리(보자기) 판: 짙은 남색 천에 크림색 바느질선.
static func draw_bundle(ci: CanvasItem, origin: Vector2, w: int, h: int, cs: float) -> void:
	var r := Rect2(origin, Vector2(w, h) * cs)
	ci.draw_style_box(box(Color(NIGHT_DEEP, 0.9), 16, Color(CREAM, 0.5), 2, 10), r.grow(18))
	_dashed_rect(ci, r.grow(9), Color(CREAM, 0.35), 2.0)
	for y in h:
		for x in w:
			var cell := Rect2(origin + Vector2(x, y) * cs, Vector2(cs, cs)).grow(-4)
			ci.draw_style_box(box(Color(CREAM, 0.06), 6, Color(CREAM, 0.12), 1), cell)


static func _dashed_rect(ci: CanvasItem, r: Rect2, color: Color, width: float) -> void:
	var pts := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position]
	for i in 4:
		ci.draw_dashed_line(pts[i], pts[i + 1], color, width, 10.0)


# --- 아이콘 ---

static func draw_coin(ci: CanvasItem, c: Vector2, radius: float) -> void:
	ci.draw_circle(c, radius, GOLD)
	ci.draw_circle(c, radius, INK, false, maxf(radius * 0.12, 1.5))
	ci.draw_circle(c, radius * 0.72, Color(INK, 0.35), false, 1.0)
	var s := radius * 0.38
	ci.draw_rect(Rect2(c - Vector2(s, s), Vector2(s, s) * 2), NIGHT_DEEP)


static func draw_heart(ci: CanvasItem, c: Vector2, s: float, color := VERMILION) -> void:
	var pts := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		var x := 16 * pow(sin(t), 3)
		var y := 13 * cos(t) - 5 * cos(2 * t) - 2 * cos(3 * t) - cos(4 * t)
		pts.append(c + Vector2(x, -y) * s / 34.0)
	ci.draw_colored_polygon(pts, color)


static func draw_sword(ci: CanvasItem, c: Vector2, s: float, color := INK) -> void:
	var d := Vector2(1, -1).normalized()
	var n := Vector2(d.y, -d.x)
	var tip := c + d * s * 0.5
	var guard := c - d * s * 0.18
	ci.draw_colored_polygon(PackedVector2Array([tip, guard + n * s * 0.09, guard - n * s * 0.09]), color)
	ci.draw_line(guard + n * s * 0.2, guard - n * s * 0.2, color, s * 0.09)
	ci.draw_line(guard, c - d * s * 0.46, color, s * 0.1)


## 칼·하트 아이콘 + 숫자.
static func draw_stats(ci: CanvasItem, pos: Vector2, atk: int, hp: int, size: int, color := INK) -> void:
	var f := bold()
	draw_sword(ci, pos + Vector2(size * 0.5, -size * 0.35), size * 1.1, color)
	ci.draw_string(f, pos + Vector2(size * 1.15, 0), str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)
	var x := size * 1.25 + f.get_string_size(str(atk), HORIZONTAL_ALIGNMENT_LEFT, -1, size).x + size * 0.8
	draw_heart(ci, pos + Vector2(x + size * 0.45, -size * 0.35), size * 0.95)
	ci.draw_string(f, pos + Vector2(x + size * 1.1, 0), str(hp), HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


static func draw_badge(ci: CanvasItem, center: Vector2, value: int, color: Color, _font: Font = null, size := 20, text_color := CREAM) -> void:
	ci.draw_circle(center, size * 0.78, color)
	ci.draw_circle(center, size * 0.78, INK, false, 2.0)
	ci.draw_string(bold(), center + Vector2(-size, size * 0.36), str(value), HORIZONTAL_ALIGNMENT_CENTER, size * 2, size, text_color)


static func draw_label(ci: CanvasItem, pos: Vector2, text: String, size: int, color := CREAM, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT, outline := 0) -> void:
	if outline > 0:
		ci.draw_string_outline(bold(), pos, text, align, width, size, outline, Color(NIGHT_DEEP, 0.9))
	ci.draw_string(bold(), pos, text, align, width, size, color)


# --- 요괴 칸 ---

## cells(상대 또는 절대 좌표)를 origin 기준으로 그린다.
static func draw_shape(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, fill: Color, line: Color, width := 3.0) -> void:
	for c in cells:
		ci.draw_rect(Rect2(origin + Vector2(c) * cs, Vector2(cs, cs)), fill)
	_outline(ci, origin, cells, cs, line, width)


## 한지 결을 깐 요괴 칸.
static func draw_paper_shape(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, tint := Color.WHITE, line := INK) -> void:
	var paper := ui("paper.jpg")
	var tex_size := paper.get_size()
	for c in cells:
		var r := Rect2(origin + Vector2(c) * cs, Vector2(cs, cs))
		ci.draw_rect(r.grow(1), CREAM * tint)
		var src := Rect2(Vector2(fposmod(c.x * 131.0, tex_size.x - cs), fposmod(c.y * 97.0, tex_size.y - cs)), Vector2(cs, cs))
		ci.draw_texture_rect_region(paper, r, src, tint)
	_outline(ci, origin, cells, cs, Color(line, line.a * tint.a), 3.0)


static func _outline(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, line: Color, width: float) -> void:
	if width <= 0:
		return
	var h := width / 2
	for c in cells:
		var o := origin + Vector2(c) * cs
		if c + Vector2i.UP not in cells:
			ci.draw_line(o + Vector2(-h, 0), o + Vector2(cs + h, 0), line, width)
		if c + Vector2i.DOWN not in cells:
			ci.draw_line(o + Vector2(-h, cs), o + Vector2(cs + h, cs), line, width)
		if c + Vector2i.LEFT not in cells:
			ci.draw_line(o, o + Vector2(0, cs), line, width)
		if c + Vector2i.RIGHT not in cells:
			ci.draw_line(o + Vector2(cs, 0), o + Vector2(cs, cs), line, width)


## 칸 모양에 맞춰 그린 그림을 현재 회전에 맞게 돌려서 그린다. 그림은 빈 칸을 침범하지 않는다.
static func draw_portrait(ci: CanvasItem, origin: Vector2, cells: Array[Vector2i], cs: float, kind: StringName, modulate := Color.WHITE) -> void:
	var base := YokaiDb.base_cells(kind)
	var turns := rotation_of(base, cells)
	var size := Vector2.ZERO
	for c in base:
		size = Vector2(maxf(size.x, c.x + 1), maxf(size.y, c.y + 1))
	size *= cs
	var lo := Vector2i(1 << 20, 1 << 20)
	for c in cells:
		lo = Vector2i(mini(lo.x, c.x), mini(lo.y, c.y))
	var offset: Vector2 = [Vector2.ZERO, Vector2(size.y, 0), size, Vector2(0, size.x)][turns]
	ci.draw_set_transform(origin + Vector2(lo) * cs + offset, turns * PI / 2)
	ci.draw_texture_rect(YokaiDb.texture(kind), Rect2(Vector2.ZERO, size), false, modulate)
	ci.draw_set_transform(Vector2.ZERO)


## base를 시계 방향으로 몇 번 돌리면 cells가 되는지. 대칭이면 가장 적게 돈 횟수.
static func rotation_of(base: Array[Vector2i], cells: Array[Vector2i]) -> int:
	var target := Piece.normalized(cells)
	var cur := Piece.normalized(base)
	for turns in 4:
		if cur == target:
			return turns
		var rotated: Array[Vector2i] = []
		for c in cur:
			rotated.append(Vector2i(-c.y, c.x))
		cur = Piece.normalized(rotated)
	return 0


## 비율을 유지한 채 rect 안에 맞춰 그린다.
static func draw_fit(ci: CanvasItem, tex: Texture2D, rect: Rect2, modulate := Color.WHITE) -> void:
	var k := minf(rect.size.x / tex.get_width(), rect.size.y / tex.get_height())
	var s := tex.get_size() * k
	ci.draw_texture_rect(tex, Rect2(rect.get_center() - s / 2, s), false, modulate)


static func draw_piece(ci: CanvasItem, origin: Vector2, p: Piece, cs: float, _font: Font = null, tint := Color.WHITE) -> void:
	draw_paper_shape(ci, origin, p.cells, cs, tint)
	draw_portrait(ci, origin, p.cells, cs, p.kind, tint)
	_outline(ci, origin, p.cells, cs, Color(INK, tint.a), 3.0)
	var first: Vector2 = origin + Vector2(p.cells[0]) * cs
	var badge := maxf(cs * 0.17, 11)
	draw_badge(ci, first + Vector2(badge * 1.1, badge * 1.1), p.atk, Color(VERMILION, tint.a), null, int(badge))
	draw_badge(ci, first + Vector2(badge * 2.9, badge * 1.1), p.hp, Color(JADE, tint.a), null, int(badge))
	if p.evolved:
		draw_shape(ci, origin, p.cells, cs, Color(0, 0, 0, 0), Color(GOLD, tint.a), maxf(cs * 0.05, 3))
	elif p.belly > 0:
		var last: Vector2 = origin + Vector2(p.cells[-1]) * cs
		for i in p.belly:
			var c := last + Vector2(cs - badge * (0.9 + i * 1.1), cs - badge * 0.9)
			ci.draw_circle(c, badge * 0.42, Color(INK, tint.a * 0.5))
			if i < p.eaten:
				ci.draw_circle(c, badge * 0.32, Color(GOLD, tint.a))
	for i in p.traits.size():
		var dot := first + Vector2(cs - badge * 0.9, badge * 0.9 + i * badge * 1.1)
		ci.draw_rect(Rect2(dot - Vector2(badge, badge) * 0.4, Vector2(badge, badge) * 0.8), trait_color(p.traits[i]))
		ci.draw_rect(Rect2(dot - Vector2(badge, badge) * 0.4, Vector2(badge, badge) * 0.8), INK, false, 1.5)


# --- 테마 ---

static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font = load("res://assets/fonts/Pretendard-Regular.otf")
	t.default_font_size = 24
	var pad := func(sb: StyleBoxFlat) -> StyleBoxFlat:
		sb.content_margin_left = 18
		sb.content_margin_right = 18
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		return sb
	t.set_stylebox(&"normal", &"Button", pad.call(box(CREAM, 10, INK, 3, 4)))
	t.set_stylebox(&"hover", &"Button", pad.call(box(Color(1, 0.98, 0.92), 10, INK, 3, 6)))
	t.set_stylebox(&"pressed", &"Button", pad.call(box(CREAM_DIM, 10, INK, 3, 1)))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 10, GOLD, 3))
	t.set_stylebox(&"disabled", &"Button", pad.call(box(Color(CREAM, 0.4), 10, Color(INK, 0.4), 3)))
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(state, &"Button", INK)
	t.set_font(&"font", &"Button", bold())
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", pad.call(box(VERMILION, 12, INK, 3, 6)))
	t.set_stylebox(&"hover", &"AccentButton", pad.call(box(VERMILION.lightened(0.12), 12, INK, 3, 8)))
	t.set_stylebox(&"pressed", &"AccentButton", pad.call(box(VERMILION.darkened(0.15), 12, INK, 3, 2)))
	for state in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(state, &"AccentButton", CREAM)
	var panel := box(CREAM, 14, INK, 3, 14)
	panel.content_margin_left = 40
	panel.content_margin_right = 40
	panel.content_margin_top = 32
	panel.content_margin_bottom = 32
	t.set_stylebox(&"panel", &"PanelContainer", panel)
	t.set_color(&"font_color", &"Label", CREAM)
	t.set_type_variation(&"PaperLabel", &"Label")
	t.set_color(&"font_color", &"PaperLabel", INK)
	t.set_font(&"font", &"PaperLabel", bold())
	var edit := box(Color(NIGHT_DEEP, 0.8), 10, Color(CREAM, 0.5), 2)
	edit.content_margin_left = 14
	edit.content_margin_right = 14
	t.set_stylebox(&"normal", &"LineEdit", edit)
	t.set_stylebox(&"focus", &"LineEdit", box(Color(0, 0, 0, 0), 10, GOLD, 2))
	t.set_color(&"font_color", &"LineEdit", CREAM)
	t.set_color(&"font_placeholder_color", &"LineEdit", Color(CREAM, 0.45))
	return t

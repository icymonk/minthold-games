class_name Art
extends RefCounted
## 그림 그리기 공용: SVG 텍스처와 골판지 상자.

const BG := preload("res://assets/art/depot_bg.svg")
const CAB := preload("res://assets/art/cab.svg")
const WHEEL := preload("res://assets/art/wheel.svg")
const HOUSE := preload("res://assets/art/house.svg")
const POINTER := preload("res://assets/art/pointer.svg")
## 손가락 끝(텍스처 안 좌표).
const POINTER_TIP := Vector2(30, 4)

const CARD_LIGHT := Color("#D9A86E")
const CARD_DARK := Color("#9E6F3E")
const INK := Color("#0F1520")
const LABEL := Color("#F7F2E6")
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## 화면을 덮도록 배경을 늘려 그린다(가운데 기준으로 잘림).
static func draw_cover(ci: CanvasItem, tex: Texture2D, area: Vector2) -> void:
	var s := maxf(area.x / tex.get_width(), area.y / tex.get_height())
	var sz := tex.get_size() * s
	ci.draw_texture_rect(tex, Rect2((area - sz) / 2.0, sz), false)


## at = 상자 원점 칸(왼쪽 아래)의 왼쪽 위 화면 좌표. 화면은 y가 아래로 커진다.
static func draw_box(ci: CanvasItem, font: Font, box: Box, at: Vector2, cell: float,
		alpha := 1.0, alert := false, squash := 0.0) -> void:
	var cells := box.cells
	var sz := box.size()
	# 찌그러짐: 바닥 기준으로 납작해지고 옆으로 퍼진다.
	var sy := 1.0 - squash
	var sx := 1.0 + squash * 0.6
	var base := at + Vector2(0, cell)
	var pivot := base + Vector2(sz.x * cell / 2.0, 0)
	var rect_of := func(c: Vector2i) -> Rect2:
		var p := at + Vector2(c.x, -c.y) * cell
		var a := pivot + (p - pivot) * Vector2(sx, sy)
		return Rect2(a, Vector2(cell * sx, cell * sy))
	var line := maxf(2.0, cell * 0.035)
	var ink := Color(INK, alpha)
	# 그림자
	if alpha >= 1.0 and cell > 60:
		for c in cells:
			var r: Rect2 = rect_of.call(c)
			ci.draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.25))
	for c in cells:
		var r: Rect2 = rect_of.call(c)
		ci.draw_rect(r, Color(Style.CARDBOARD, alpha))
		if not (c + Vector2i(0, 1)) in cells:
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.14)), Color(CARD_LIGHT, alpha))
			# 덮개 접힌 선
			ci.draw_line(r.position + Vector2(0, r.size.y * 0.14), r.position + Vector2(r.size.x, r.size.y * 0.14),
				Color(CARD_DARK, alpha * 0.8), line * 0.7)
		if not (c + Vector2i(0, -1)) in cells:
			ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.9), Vector2(r.size.x, r.size.y * 0.1)), Color(CARD_DARK, alpha * 0.6))
		if not (c + Vector2i(1, 0)) in cells:
			ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.9, 0), Vector2(r.size.x * 0.1, r.size.y)), Color(CARD_DARK, alpha * 0.45))
	# 테이프: 원점 칸이 있는 세로줄 가운데
	var tape_col: int = cells[0].x
	for c in cells:
		if c.x == tape_col:
			var r: Rect2 = rect_of.call(c)
			var w := r.size.x * 0.2
			ci.draw_rect(Rect2(r.position + Vector2((r.size.x - w) / 2.0, 0), Vector2(w, r.size.y)), Color(Style.TAPE, alpha * 0.85))
	# 바깥 테두리
	for c in cells:
		var r: Rect2 = rect_of.call(c)
		for n in DIRS:
			if not (c + n) in cells:
				_edge(ci, r, n, Style.ALERT if alert else ink, line * (2.6 if alert else 1.0))
	# 송장
	var lr: Rect2 = rect_of.call(cells[0])
	var color := Color(Style.stop_color(box.stop), alpha)
	if cell < 60:
		var tag := lr.size * 0.6
		var tr := Rect2(lr.get_center() - tag / 2.0, tag)
		ci.draw_rect(tr, color)
		ci.draw_rect(tr, ink, false, 2)
		_text(ci, font, str(box.stop), tr, int(cell * 0.45), ink)
		return
	var lab := Rect2(lr.position + lr.size * Vector2(0.14, 0.28), lr.size * Vector2(0.72, 0.6))
	ci.draw_rect(lab, Color(LABEL, alpha))
	ci.draw_rect(Rect2(lab.position, Vector2(lab.size.x, lab.size.y * 0.3)), color)
	ci.draw_rect(lab, ink, false, line * 0.8)
	var num := Rect2(lab.position + Vector2(0, lab.size.y * 0.3), lab.size * Vector2(1, 0.7))
	_text(ci, font, str(box.stop), num, int(cell * 0.34), ink)
	if alert:
		var badge := lr.position + Vector2(lr.size.x * 0.84, lr.size.y * 0.16)
		ci.draw_circle(badge, cell * 0.16, Style.ALERT)
		_text(ci, font, "!", Rect2(badge - Vector2(cell, cell) * 0.16, Vector2(cell, cell) * 0.32), int(cell * 0.24), Color.WHITE)


## 배송 집 아이콘(집 + 번호).
static func draw_house(ci: CanvasItem, font: Font, stop: int, center: Vector2, sz: float, alpha := 1.0) -> void:
	var r := Rect2(center - Vector2(sz, sz) / 2.0, Vector2(sz, sz))
	ci.draw_texture_rect(HOUSE, r, false, Color(Style.stop_color(stop), alpha))
	_text(ci, font, str(stop), Rect2(r.position + Vector2(0, sz * 0.38), Vector2(sz, sz * 0.55)), int(sz * 0.42), Color(INK, alpha))


static func _edge(ci: CanvasItem, r: Rect2, n: Vector2i, color: Color, w: float) -> void:
	match n:
		Vector2i(1, 0): ci.draw_line(Vector2(r.end.x, r.position.y), r.end, color, w)
		Vector2i(-1, 0): ci.draw_line(r.position, Vector2(r.position.x, r.end.y), color, w)
		Vector2i(0, 1): ci.draw_line(r.position, Vector2(r.end.x, r.position.y), color, w)
		Vector2i(0, -1): ci.draw_line(Vector2(r.position.x, r.end.y), r.end, color, w)


## 사각형 가운데에 글자를 맞춰 쓴다.
static func _text(ci: CanvasItem, font: Font, text: String, r: Rect2, fs: int, color: Color) -> void:
	var asc := font.get_ascent(fs)
	var desc := font.get_descent(fs)
	var y := r.position.y + (r.size.y + asc - desc) / 2.0
	ci.draw_string(font, Vector2(r.position.x, y), text, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, fs, color)


static func text_center(ci: CanvasItem, font: Font, text: String, r: Rect2, fs: int, color: Color) -> void:
	_text(ci, font, text, r, fs, color)


## 옆에서 본 트럭: bay = 짐칸 안쪽 사각형. 운전석은 왼쪽, 열린 뒷문은 오른쪽.
static func draw_truck(ci: CanvasItem, bay: Rect2, cell: float, frame := 16.0) -> void:
	var f := bay.grow(frame)
	ci.draw_rect(Rect2(f.position.x - 200, f.end.y - 4, f.size.x + 200, 24), INK)
	ci.draw_texture(CAB, Vector2(f.position.x - 312, f.end.y - 360))
	for x in [f.position.x - 150, f.position.x + 150, f.end.x - 130]:
		ci.draw_texture_rect(WHEEL, Rect2(Vector2(x - 56, f.end.y - 12), Vector2(112, 112)), false)
	ci.draw_rect(f, Style.TAPE)
	ci.draw_rect(Rect2(f.position.x, f.end.y - frame - 30, f.size.x, 30), Color(Style.LAMP, 0.0))
	ci.draw_rect(bay, Color("#141B29"))
	var cols := int(round(bay.size.x / cell))
	var rows := int(round(bay.size.y / cell))
	for x in range(1, cols):
		ci.draw_line(bay.position + Vector2(x * cell, 0), bay.position + Vector2(x * cell, bay.size.y), Color(1, 1, 1, 0.05), 2)
	for y in range(1, rows):
		for x in range(1, cols):
			ci.draw_circle(bay.position + Vector2(x * cell, y * cell), 3, Color(1, 1, 1, 0.12))
	ci.draw_rect(Rect2(bay.position.x, bay.end.y - 8, bay.size.x, 8), Color(CARD_DARK, 0.6))
	ci.draw_rect(f, INK, false, 6)
	# 문틀(밝게) + 열린 문짝
	ci.draw_rect(Rect2(f.end.x - frame, f.position.y, frame, f.size.y), Style.LAMP)
	var door := PackedVector2Array([
		Vector2(f.end.x, f.position.y), Vector2(f.end.x + 64, f.position.y + 34),
		Vector2(f.end.x + 64, f.end.y - 34), Vector2(f.end.x, f.end.y)])
	ci.draw_colored_polygon(door, Color("#C9BC98"))
	door.append(door[0])
	ci.draw_polyline(door, INK, 5)
	ci.draw_line(Vector2(f.end.x + 32, f.position.y + 40), Vector2(f.end.x + 32, f.end.y - 40), Color(INK, 0.3), 4)

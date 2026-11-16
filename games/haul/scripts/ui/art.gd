class_name Art
extends RefCounted
## 그림 그리기 공용. 트럭·도시·창고 소품은 Kenney CC0 그림(tools/art_bake로 굽는다), 상자는 코드로 그린다.

const CITY := preload("res://assets/art/city.jpg")
const CAB := preload("res://assets/art/cab.png")
const WHEEL := preload("res://assets/art/wheel.png")
const HAZARD := preload("res://assets/art/kenney/hazard.png")
const BELT := preload("res://assets/art/kenney/belt.png")
const GEAR := preload("res://assets/art/kenney/gear.png")
const BEACON := preload("res://assets/art/kenney/beacon.png")
const CRATE := preload("res://assets/art/kenney/crate.png")
const BARRELS: Array[Texture2D] = [
	preload("res://assets/art/kenney/barrel_blue.png"),
	preload("res://assets/art/kenney/barrel_yellow.png"),
]
const MOON := preload("res://assets/art/kenney/moon.png")
const CLOUDS: Array[Texture2D] = [
	preload("res://assets/art/kenney/cloud1.png"),
	preload("res://assets/art/kenney/cloud3.png"),
]
const HOUSES: Array[Texture2D] = [
	preload("res://assets/art/kenney/house1.png"),
	preload("res://assets/art/kenney/houseAlt1.png"),
	preload("res://assets/art/kenney/house2.png"),
	preload("res://assets/art/kenney/houseAlt2.png"),
]
const POINTER := preload("res://assets/art/kenney/hand.svg")
## 손가락 끝(텍스처 안 좌표, 32px 원본 기준).
const POINTER_TIP := Vector2(14.4, 2)
const POINTER_SCALE := 3.0

## 굽기 배율: 그림은 1m=690px로 구웠고, 칸 104px일 때 절반 크기로 그린다.
const BAKE_SCALE := 0.5
## 운전석 그림에서 바닥(바퀴 아래)부터 짐칸 바닥선까지 높이(구운 픽셀).
const CAB_CHASSIS := 206.0

const CARD_LIGHT := Color("#E9B97A")
const CARD := Color("#D49A5A")
const CARD_DARK := Color("#A86F3A")
const CARD_EDGE := Color("#7A4C26")
const INK := Color("#1E2433")
const LABEL := Color("#FBF7EE")
const BODY_TOP := Color("#6FE0A8")
const BODY_BOTTOM := Color("#2F9C80")
const BODY_EDGE := Color("#23705E")
const STEEL := Color("#6F7290")
const STEEL_DARK := Color("#4C4E66")
const INSIDE := Color("#2B3245")
const FLOOR := Color("#8A6646")
const DOCK := Color("#3A3F55")
const DOCK_LIGHT := Color("#4C526B")
const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


## 새벽 도시 + 물류창고 도크. floor_y = 도크 바닥 윗선.
static func draw_scene(ci: CanvasItem, area: Vector2, floor_y: float, time := 0.0) -> void:
	var s := maxf(area.x / CITY.get_width(), area.y / CITY.get_height())
	var sz := CITY.get_size() * s
	ci.draw_texture_rect(CITY, Rect2(Vector2((area.x - sz.x) / 2.0, floor_y - sz.y * 0.78), sz), false, Color(0.62, 0.62, 0.78))
	ci.draw_texture_rect(MOON, Rect2(area.x * 0.16, 40, 96, 98), false, Color(1, 1, 1, 0.9))
	for i in 3:
		var c := CLOUDS[i % 2]
		var x := fmod(area.x * (0.2 + i * 0.33) + time * (8 + i * 3), area.x + 400) - 200
		ci.draw_texture_rect(c, Rect2(x, 70 + i * 60, 260, 130), false, Color(0.75, 0.72, 0.95, 0.25))
	# 도크 바닥
	ci.draw_rect(Rect2(0, floor_y, area.x, area.y - floor_y), DOCK)
	ci.draw_rect(Rect2(0, floor_y, area.x, 14), DOCK_LIGHT)
	var x0 := 0.0
	while x0 < area.x:
		ci.draw_texture_rect(HAZARD, Rect2(x0, floor_y + 14, 70, 10), false)
		x0 += 70
	for i in range(1, 12):
		ci.draw_line(Vector2(i * area.x / 12.0, floor_y + 24), Vector2(i * area.x / 12.0 - 60, area.y), Color(1, 1, 1, 0.04), 2)


## 도크 양옆 소품: 상자 더미, 드럼통, 경광등.
static func draw_props(ci: CanvasItem, area: Vector2, floor_y: float, time: float) -> void:
	var c := 84.0
	ci.draw_texture_rect(CRATE, Rect2(30, floor_y - c, c, c), false)
	ci.draw_texture_rect(CRATE, Rect2(30 + c, floor_y - c, c, c), false)
	ci.draw_texture_rect(CRATE, Rect2(30 + c * 0.5, floor_y - c * 2, c, c), false)
	ci.draw_texture_rect(BARRELS[0], Rect2(area.x - 130, floor_y - 96, 74, 96), false)
	ci.draw_texture_rect(BARRELS[1], Rect2(area.x - 210, floor_y - 96, 74, 96), false)
	var on := 0.6 + 0.4 * sin(time * 6.0)
	for bx in [14.0, area.x - 76]:
		ci.draw_circle(Vector2(bx + 31, floor_y - 210), 46, Color(1, 0.55, 0.15, 0.12 * on))
		ci.draw_rect(Rect2(bx + 26, floor_y - 186, 10, 186), STEEL_DARK)
		ci.draw_texture_rect(BEACON, Rect2(bx, floor_y - 236, 62, 50), false, Color(1, 1, 1, 0.75 + 0.25 * on))


## 컨베이어 벨트(Kenney 금속 벨트 타일 + 톱니 롤러).
static func draw_conveyor(ci: CanvasItem, r: Rect2, time: float) -> void:
	var belt_y := r.end.y - 34
	ci.draw_rect(Rect2(r.position.x + 30, belt_y + 20, 18, r.end.y + 60 - belt_y), STEEL_DARK)
	ci.draw_rect(Rect2(r.end.x - 48, belt_y + 20, 18, r.end.y + 60 - belt_y), STEEL_DARK)
	var tile := 70.0 * 34.0 / 30.0
	var phase := fmod(time * 60.0, tile)
	var x := r.position.x - tile + phase
	ci.draw_rect(Rect2(r.position.x, belt_y, r.size.x, 34), Color("#3D4351"))
	while x < r.end.x:
		var left := maxf(x, r.position.x)
		var right := minf(x + tile, r.end.x)
		if right > left:
			var u0 := (left - x) / tile * 70.0
			var u1 := (right - x) / tile * 70.0
			ci.draw_texture_rect_region(BELT, Rect2(left, belt_y, right - left, 34), Rect2(u0, 0, u1 - u0, 30))
		x += tile
	var g := 40.0
	var roller := r.position.x + 60
	while roller < r.end.x - 40:
		ci.draw_set_transform(Vector2(roller, belt_y + 46), time * 3.0)
		ci.draw_texture_rect(GEAR, Rect2(-g / 2.0, -g / 2.0, g, g), false, Color(0.8, 0.82, 0.9))
		ci.draw_set_transform(Vector2.ZERO)
		roller += 110


## at = 상자 원점 칸(왼쪽 아래)의 왼쪽 위 화면 좌표. 화면은 y가 아래로 커진다.
static func draw_box(ci: CanvasItem, font: Font, box: Box, at: Vector2, cell: float,
		alpha := 1.0, alert := false, squash := 0.0) -> void:
	var cells := box.cells
	var sz := box.size()
	var sy := 1.0 - squash
	var sx := 1.0 + squash * 0.6
	var base := at + Vector2(0, cell)
	var pivot := base + Vector2(sz.x * cell / 2.0, 0)
	var rect_of := func(c: Vector2i) -> Rect2:
		var p := at + Vector2(c.x, -c.y) * cell
		var a := pivot + (p - pivot) * Vector2(sx, sy)
		return Rect2(a, Vector2(cell * sx, cell * sy))
	var line := maxf(2.0, cell * 0.03)
	var edge := Color(CARD_EDGE, alpha)
	# 바닥 그림자
	if alpha >= 1.0:
		for c in cells:
			if not (c + Vector2i(0, -1)) in cells:
				var r: Rect2 = rect_of.call(c)
				ci.draw_rect(Rect2(r.position.x + cell * 0.04, r.end.y - cell * 0.02, r.size.x, cell * 0.06), Color(0, 0, 0, 0.28))
	for c in cells:
		var r: Rect2 = rect_of.call(c)
		_gradient(ci, r, Color(CARD_LIGHT, alpha), Color(CARD, alpha))
		if not (c + Vector2i(0, 1)) in cells:
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * 0.1)), Color(CARD_LIGHT.lightened(0.15), alpha))
			ci.draw_line(r.position + Vector2(0, r.size.y * 0.1), r.position + Vector2(r.size.x, r.size.y * 0.1), Color(CARD_DARK, alpha * 0.6), line * 0.6)
		if not (c + Vector2i(0, -1)) in cells:
			ci.draw_rect(Rect2(r.position + Vector2(0, r.size.y * 0.88), Vector2(r.size.x, r.size.y * 0.12)), Color(CARD_DARK, alpha * 0.55))
		if not (c + Vector2i(1, 0)) in cells:
			ci.draw_rect(Rect2(r.position + Vector2(r.size.x * 0.9, 0), Vector2(r.size.x * 0.1, r.size.y)), Color(CARD_DARK, alpha * 0.4))
		if not (c + Vector2i(-1, 0)) in cells:
			ci.draw_rect(Rect2(r.position, Vector2(r.size.x * 0.05, r.size.y)), Color(1, 1, 1, alpha * 0.12))
	# 테이프: 원점 칸 세로줄
	var tape_col: int = cells[0].x
	for c in cells:
		if c.x == tape_col:
			var r: Rect2 = rect_of.call(c)
			var w := r.size.x * 0.18
			var tr := Rect2(r.position + Vector2((r.size.x - w) / 2.0, 0), Vector2(w, r.size.y))
			ci.draw_rect(tr, Color("#C98F55", alpha * 0.9))
			ci.draw_rect(Rect2(tr.position, Vector2(w * 0.3, tr.size.y)), Color(1, 1, 1, alpha * 0.18))
	if box.has(Box.Trait.FRAGILE) or box.has(Box.Trait.FROZEN) or box.has(Box.Trait.HEAVY) or box.has(Box.Trait.UPRIGHT):
		_trait_marks(ci, box, rect_of.call(cells[cells.size() - 1]), cell, alpha)
	for c in cells:
		var r: Rect2 = rect_of.call(c)
		for n in DIRS:
			if not (c + n) in cells:
				_edge(ci, r, n, Style.ALERT if alert else edge, line * (3.0 if alert else 1.0))
	# 송장: 원점 칸
	var lr: Rect2 = rect_of.call(cells[0])
	var color := Color(Style.stop_color(box.stop), alpha)
	if cell < 60:
		var tag := lr.size * 0.62
		var t := Rect2(lr.get_center() - tag / 2.0 + Vector2(0, lr.size.y * 0.06), tag)
		ci.draw_rect(t, Color(LABEL, alpha))
		ci.draw_rect(Rect2(t.position, Vector2(t.size.x, t.size.y * 0.28)), color)
		_text(ci, font, str(box.stop), Rect2(t.position + Vector2(0, t.size.y * 0.22), t.size * Vector2(1, 0.78)), int(cell * 0.4), Color(INK, alpha))
		return
	var lab := Rect2(lr.position + lr.size * Vector2(0.14, 0.26), lr.size * Vector2(0.72, 0.58))
	ci.draw_rect(Rect2(lab.position + Vector2(3, 4), lab.size), Color(0, 0, 0, alpha * 0.18))
	ci.draw_rect(lab, Color(LABEL, alpha))
	ci.draw_rect(Rect2(lab.position, Vector2(lab.size.x, lab.size.y * 0.28)), color)
	var num := Rect2(lab.position + Vector2(0, lab.size.y * 0.26), lab.size * Vector2(1, 0.56))
	_text(ci, font, str(box.stop), num, int(cell * 0.32), Color(INK, alpha))
	# 바코드
	var bx := lab.position.x + lab.size.x * 0.14
	var by := lab.position.y + lab.size.y * 0.84
	var k := 0
	while bx < lab.end.x - lab.size.x * 0.14:
		var bw := 2.0 if (k * 7 + box.id) % 3 else 4.0
		ci.draw_rect(Rect2(bx, by, bw, lab.size.y * 0.1), Color(INK, alpha * 0.7))
		bx += bw + 2.5
		k += 1
	if alert:
		var badge := lr.position + Vector2(lr.size.x * 0.86, lr.size.y * 0.14)
		ci.draw_circle(badge, cell * 0.16, Style.ALERT)
		ci.draw_arc(badge, cell * 0.16, 0, TAU, 24, Color.WHITE, 2)
		_text(ci, font, "!", Rect2(badge - Vector2(cell, cell) * 0.16, Vector2(cell, cell) * 0.32), int(cell * 0.24), Color.WHITE)


static func _trait_marks(ci: CanvasItem, box: Box, r: Rect2, cell: float, alpha: float) -> void:
	if cell < 60:
		return
	var p := r.position + Vector2(r.size.x * 0.12, r.size.y * 0.16)
	var s := cell * 0.16
	if box.has(Box.Trait.FRAGILE):
		ci.draw_rect(Rect2(p, Vector2(s, s * 1.2)), Color(Style.ALERT, alpha * 0.85), false, 2)
		ci.draw_line(p + Vector2(s * 0.5, 0), p + Vector2(s * 0.3, s * 1.2), Color(Style.ALERT, alpha * 0.85), 2)
	elif box.has(Box.Trait.FROZEN):
		ci.draw_circle(p + Vector2(s, s) * 0.5, s * 0.5, Color(Style.FROZEN, alpha * 0.9))
	elif box.has(Box.Trait.HEAVY):
		ci.draw_rect(Rect2(p, Vector2(s, s)), Color(INK, alpha * 0.7))
	elif box.has(Box.Trait.UPRIGHT):
		ci.draw_line(p + Vector2(s * 0.5, s * 1.2), p + Vector2(s * 0.5, 0), Color(INK, alpha * 0.8), 3)
		ci.draw_line(p + Vector2(s * 0.5, 0), p + Vector2(0, s * 0.5), Color(INK, alpha * 0.8), 3)
		ci.draw_line(p + Vector2(s * 0.5, 0), p + Vector2(s, s * 0.5), Color(INK, alpha * 0.8), 3)


## 배송 집(Kenney 집 그림 + 번호 배지).
static func draw_house(ci: CanvasItem, font: Font, stop: int, center: Vector2, sz: float, alpha := 1.0) -> void:
	var tex := HOUSES[(stop - 1) % HOUSES.size()]
	var h := sz
	var w := h * tex.get_width() / tex.get_height()
	ci.draw_texture_rect(tex, Rect2(center - Vector2(w, h) / 2.0, Vector2(w, h)), false, Color(1, 1, 1, alpha))
	var badge := center + Vector2(w * 0.42, h * 0.22)
	var rad := sz * 0.26
	ci.draw_circle(badge + Vector2(0, 2), rad, Color(0, 0, 0, 0.3 * alpha))
	ci.draw_circle(badge, rad, Color(Style.stop_color(stop), alpha))
	ci.draw_arc(badge, rad, 0, TAU, 32, Color(LABEL, alpha), 3)
	_text(ci, font, str(stop), Rect2(badge - Vector2(rad, rad), Vector2(rad, rad) * 2), int(rad * 1.25), Color(INK, alpha))


## 튜토리얼 손가락. flip이면 위에서 아래로 가리킨다.
static func draw_pointer(ci: CanvasItem, tip: Vector2, flip: bool) -> void:
	var sz := Vector2(32, 32) * POINTER_SCALE
	var off := POINTER_TIP * POINTER_SCALE
	if flip:
		ci.draw_set_transform(tip, PI)
	else:
		ci.draw_set_transform(tip)
	ci.draw_texture_rect(POINTER, Rect2(-off + Vector2(3, 4), sz), false, Color(0, 0, 0, 0.3))
	ci.draw_texture_rect(POINTER, Rect2(-off, sz), false)
	ci.draw_set_transform(Vector2.ZERO)


static func _gradient(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]),
		PackedColorArray([top, top, bottom, bottom]))


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


## 옆에서 본 배송 트럭: bay = 짐칸 안쪽 사각형. 운전석(Kenney 3D 렌더)은 왼쪽, 열린 뒷문은 오른쪽.
## 반환값: 바퀴 아래 땅의 y.
static func draw_truck(ci: CanvasItem, bay: Rect2, cell: float, frame := 16.0) -> float:
	var k := cell / 104.0 * BAKE_SCALE
	var f := bay.grow(frame)
	var ground := f.end.y + CAB_CHASSIS * k
	var cab_sz := CAB.get_size() * k
	var wheel_d := WHEEL.get_width() * k
	# 땅 그림자
	ci.draw_rect(Rect2(f.position.x - cab_sz.x, ground - 10 * k * 2, f.size.x + cab_sz.x + 40 * k, 20 * k * 2), Color(0, 0, 0, 0.3))
	# 섀시
	var chassis := Rect2(f.position.x - 20 * k, f.end.y - 4, f.size.x + 60 * k, 64 * k)
	ci.draw_rect(chassis, STEEL)
	ci.draw_rect(Rect2(chassis.position.x, chassis.end.y - 16 * k, chassis.size.x, 16 * k), STEEL_DARK)
	# 뒷바퀴 펜더와 바퀴
	var wc := Vector2(f.end.x - wheel_d * 0.9, ground - wheel_d / 2.0)
	ci.draw_circle(wc, wheel_d * 0.6, STEEL_DARK)
	ci.draw_texture_rect(WHEEL, Rect2(wc - Vector2(wheel_d, wheel_d) / 2.0, Vector2(wheel_d, wheel_d)), false)
	ci.draw_texture_rect(CAB, Rect2(Vector2(f.position.x - cab_sz.x + 2, ground - cab_sz.y), cab_sz), false)
	# 짐칸 몸체
	_gradient(ci, f, BODY_TOP, BODY_BOTTOM)
	ci.draw_rect(Rect2(f.position, Vector2(f.size.x, frame * 0.5)), Color(1, 1, 1, 0.25))
	ci.draw_rect(f, BODY_EDGE, false, 4)
	# 잘라 본 안쪽
	_gradient(ci, bay, INSIDE.darkened(0.25), INSIDE)
	var cols := int(round(bay.size.x / cell))
	var rows := int(round(bay.size.y / cell))
	for x in range(1, cols):
		ci.draw_line(bay.position + Vector2(x * cell, 0), bay.position + Vector2(x * cell, bay.size.y), Color(1, 1, 1, 0.06), 2)
	for y in range(1, rows):
		ci.draw_line(bay.position + Vector2(0, y * cell), bay.position + Vector2(bay.size.x, y * cell), Color(1, 1, 1, 0.035), 2)
	ci.draw_rect(Rect2(bay.position.x, bay.end.y - 10 * k * 2, bay.size.x, 10 * k * 2), FLOOR)
	ci.draw_rect(Rect2(bay.position, Vector2(bay.size.x, 14 * k * 2)), Color(0, 0, 0, 0.25))
	# 문틀 + 열린 문짝 + 후미등
	ci.draw_rect(Rect2(f.end.x - frame, f.position.y, frame, f.size.y), Style.LAMP)
	var dw := 70.0 * k * 2
	var door := PackedVector2Array([
		Vector2(f.end.x, f.position.y), Vector2(f.end.x + dw, f.position.y + dw * 0.45),
		Vector2(f.end.x + dw, f.end.y - dw * 0.45), Vector2(f.end.x, f.end.y)])
	ci.draw_polygon(door, PackedColorArray([BODY_TOP.darkened(0.1), BODY_TOP.darkened(0.25), BODY_BOTTOM.darkened(0.25), BODY_BOTTOM.darkened(0.1)]))
	door.append(door[0])
	ci.draw_polyline(door, BODY_EDGE, 4)
	ci.draw_rect(Rect2(f.end.x + dw * 0.55, f.get_center().y - 20 * k * 2, 8 * k * 2, 40 * k * 2), STEEL_DARK)
	ci.draw_rect(Rect2(f.end.x - 4, chassis.position.y + 6, 20 * k * 2, 18 * k * 2), Color("#E0523F"))
	return ground

extends Control
## 장터·보따리 화면. 고용 → 대기 줄 → 보따리에 끌어다 놓기, 맞닿은 요괴 위에 놓으면 먹이기.

const SHELF_POS := Vector2(60, 120)
const CARD := Vector2(200, 300)
const CARD_GAP := 18.0
const BAG_POS := Vector2(60, 480)
const CELL := 100.0
const BENCH_RECT := Rect2(740, 480, 540, 380)
const BENCH_CELL := 60.0
const SELL_RECT := Rect2(740, 880, 540, 90)
const PREVIEW_RECT := Rect2(1330, 120, 550, 340)
const INFO_RECT := Rect2(1330, 480, 550, 380)

var run: RunState
var _font: Font
var _selected: Piece
var _drag: Piece
var _drag_from_bag := false
var _drag_cells_backup: Array[Vector2i] = []
var _grab := Vector2i.ZERO
var _press_pos := Vector2.ZERO
var _moved := false
var _mouse := Vector2.ZERO
var _toast := ""
var _toast_until := 0.0


func _ready() -> void:
	run = Game.run
	_font = get_theme_default_font()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_button(tr("MARKET_REFRESH") % RunState.REFRESH_COST, Rect2(SHELF_POS.x + 5 * (CARD.x + CARD_GAP), SHELF_POS.y + 220, 170, 80), _on_refresh)
	_add_button(tr("NIGHT_FIGHT"), Rect2(1330, 880, 550, 90), _on_fight).add_theme_font_size_override(&"font_size", 36)


func _add_button(text: String, rect: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override(&"font_size", 24)
	b.pressed.connect(cb)
	add_child(b)
	return b


func _process(_delta: float) -> void:
	queue_redraw()


func _toast_msg(key: String) -> void:
	_toast = tr(key)
	_toast_until = Time.get_ticks_msec() / 1000.0 + 2.5


func _on_refresh() -> void:
	if not run.refresh_shelf():
		_toast_msg("TOAST_NO_COINS")


func _on_fight() -> void:
	if run.bag.pieces.is_empty():
		_toast_msg("TOAST_EMPTY_BAG")
		return
	Game.battle = run.fight()
	Game.goto(&"battle")


# --- 좌표 ---

func _card_rect(i: int) -> Rect2:
	return Rect2(SHELF_POS + Vector2(i * (CARD.x + CARD_GAP), 0), CARD)


func _cell_at(pos: Vector2) -> Vector2i:
	var rel := (pos - BAG_POS) / CELL
	return Vector2i(floori(rel.x), floori(rel.y))


func _bag_rect() -> Rect2:
	return Rect2(BAG_POS, Vector2(run.bag.width, run.bag.height) * CELL)


func _bench_layout() -> Dictionary:
	var out := {}
	var cursor := BENCH_RECT.position + Vector2(16, 56)
	var row_h := 0.0
	for p in run.bench:
		var s := Vector2(p.size()) * BENCH_CELL
		if cursor.x + s.x > BENCH_RECT.end.x - 16:
			cursor = Vector2(BENCH_RECT.position.x + 16, cursor.y + row_h + 16)
			row_h = 0.0
		out[p] = Rect2(cursor, s)
		cursor.x += s.x + 20
		row_h = maxf(row_h, s.y)
	return out


func _bench_piece_at(pos: Vector2) -> Piece:
	var layout := _bench_layout()
	for p in layout:
		var r: Rect2 = layout[p]
		if r.has_point(pos):
			var c := Vector2i(((pos - r.position) / BENCH_CELL).floor())
			if c in p.cells:
				return p
	return null


# --- 입력 ---

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse = event.position
		if _drag == null and _selected != null and event.button_mask & MOUSE_BUTTON_MASK_LEFT and _press_pos.distance_to(_mouse) > 8:
			_begin_drag(_selected, _press_pos)
		if _drag:
			_moved = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		_rotate()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_mouse = event.position
		if event.pressed:
			_press(event.position)
		elif _drag:
			_drop(event.position)


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate()


func _press(pos: Vector2) -> void:
	_press_pos = pos
	for i in run.shelf.size():
		if _card_rect(i).has_point(pos) and run.shelf[i] != &"":
			var p := run.hire(i)
			if p == null:
				_toast_msg("TOAST_NO_COINS" if run.bench.size() < RunState.BENCH_MAX else "TOAST_BENCH_FULL")
			else:
				_selected = p
			return
	var hit := run.bag.piece_at(_cell_at(pos)) if _bag_rect().has_point(pos) else _bench_piece_at(pos)
	_selected = hit


func _begin_drag(p: Piece, pos: Vector2) -> void:
	_drag = p
	_drag_from_bag = p in run.bag.pieces
	_drag_cells_backup = p.cells.duplicate()
	if _drag_from_bag:
		_grab = _cell_at(pos) - p.pos
	else:
		var r: Rect2 = _bench_layout()[p]
		_grab = Vector2i(((pos - r.position) / BENCH_CELL).floor())
	_moved = false


func _rotate() -> void:
	var p := _drag if _drag else _selected
	if p == null:
		return
	if _drag:
		var g := _grab
		p.rotate_cw()
		_grab = Vector2i(clampi(-g.y + p.size().x - 1, 0, p.size().x - 1), clampi(g.x, 0, p.size().y - 1))
		return
	var backup := p.cells.duplicate()
	p.rotate_cw()
	if p in run.bag.pieces and not run.bag.can_place(p, p.pos):
		p.cells = backup
		_toast_msg("TOAST_NO_ROOM")


func _drop(pos: Vector2) -> void:
	var p := _drag
	_drag = null
	if not _moved:
		return
	if SELL_RECT.has_point(pos):
		run.sell(p)
		_selected = null
		return
	if _bag_rect().has_point(pos):
		var target := run.bag.piece_at(_cell_at(pos))
		if target != null and target != p:
			_try_eat(target, p)
			return
		var at := _cell_at(pos) - _grab
		if run.bag.can_place(p, at):
			run.bench.erase(p)
			run.bag.place(p, at)
			return
		_toast_msg("TOAST_NO_ROOM")
	elif BENCH_RECT.has_point(pos) and _drag_from_bag:
		if run.bench.size() < RunState.BENCH_MAX:
			run.bag.remove(p)
			run.bench.append(p)
			return
		_toast_msg("TOAST_BENCH_FULL")
	p.cells = _drag_cells_backup


func _try_eat(eater: Piece, food: Piece) -> void:
	food.cells = _drag_cells_backup
	if not _drag_from_bag or not run.bag.merge(eater, food):
		_toast_msg("TOAST_EAT_TOUCH")
		return
	_selected = eater
	_toast = tr("TOAST_ATE") % [Ink.name_of(eater.kind), Ink.name_of(food.kind)]
	_toast_until = Time.get_ticks_msec() / 1000.0 + 2.5


# --- 그리기 ---

func _draw() -> void:
	_draw_top_bar()
	_draw_shelf()
	_draw_bag()
	_draw_bench()
	_draw_preview()
	_draw_info()
	_draw_drag()
	if Time.get_ticks_msec() / 1000.0 < _toast_until:
		var r := Rect2(560, 400, 800, 64)
		draw_rect(r, Color(Ink.INK, 0.9))
		draw_string(_font, r.position + Vector2(0, 42), _toast, HORIZONTAL_ALIGNMENT_CENTER, r.size.x, 26, Ink.CREAM)


func _text(pos: Vector2, s: String, size := 24, color := Ink.CREAM, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(_font, pos, s, align, width, size, color)


func _draw_top_bar() -> void:
	var title := tr("NIGHT_LABEL") % [run.night, RunState.NIGHTS]
	if run.is_boss_night():
		title += "  ·  " + tr("NIGHT_BOSS")
	_text(Vector2(60, 70), title, 40, Ink.VERMILION if run.is_boss_night() else Ink.CREAM)
	for i in RunState.START_LANTERNS:
		var c := Vector2(560 + i * 50, 58)
		draw_circle(c, 18, Ink.VERMILION if i < run.lanterns else Color(Ink.SLATE, 0.3))
		draw_circle(c, 18, Ink.INK, false, 2)
	draw_circle(Vector2(760, 58), 18, Ink.GOLD)
	draw_rect(Rect2(753, 51, 14, 14), Ink.NIGHT)
	_text(Vector2(790, 70), tr("COINS") % run.coins, 32, Ink.GOLD)
	_text(Vector2(1000, 70), tr("NIGHT_HINT"), 20, Color(Ink.CREAM, 0.6))


func _draw_shelf() -> void:
	for i in run.shelf.size():
		var r := _card_rect(i)
		var kind := run.shelf[i]
		if kind == &"":
			draw_rect(r, Color(Ink.CREAM, 0.08))
			continue
		var affordable := run.coins >= YokaiDb.cost(kind)
		draw_rect(r, Ink.CREAM if affordable else Ink.CREAM_DIM)
		draw_rect(r, Ink.INK, false, 3)
		var def: Dictionary = YokaiDb.ALLIES[kind]
		draw_texture_rect(YokaiDb.texture(kind), Rect2(r.position + Vector2(30, 8), Vector2(140, 140)), false)
		_text(r.position + Vector2(0, 176), Ink.name_of(kind), 26, Ink.INK, CARD.x, HORIZONTAL_ALIGNMENT_CENTER)
		var cells: Array[Vector2i] = []
		cells.assign(def["cells"])
		Ink.draw_shape(self, r.position + Vector2(20, 200), cells, 22, Ink.CREAM_DIM, Ink.INK, 2)
		_text(r.position + Vector2(90, 220), "%d / %d" % [def["atk"], def["hp"]], 22, Ink.INK)
		_text(r.position + Vector2(90, 248), tr(Ink.speed_key(def["interval"])), 18, Color(Ink.INK, 0.7))
		Ink.draw_badge(self, r.position + Vector2(CARD.x - 30, 30), YokaiDb.cost(kind), Ink.GOLD, _font, 24, Ink.INK)
		draw_rect(Rect2(r.position + Vector2(10, 270), Vector2(16, 16)), Ink.TRAIT_COLORS[def["trait"]])
		_text(r.position + Vector2(32, 286), tr("TRAIT_" + String(def["trait"]).to_upper()), 18, Ink.INK)
	_text(Vector2(SHELF_POS.x + 5 * (CARD.x + CARD_GAP), SHELF_POS.y + 30), tr("MARKET_TITLE"), 28)
	_text(Vector2(SHELF_POS.x + 5 * (CARD.x + CARD_GAP), SHELF_POS.y + 64), tr("MARKET_CLICK"), 18, Color(Ink.CREAM, 0.6))


func _draw_bag() -> void:
	var bag := run.bag
	_text(BAG_POS + Vector2(0, -14), tr("BAG_TITLE"), 26)
	draw_rect(_bag_rect().grow(8), Ink.NIGHT_DEEP)
	for y in bag.height:
		for x in bag.width:
			draw_rect(Rect2(BAG_POS + Vector2(x, y) * CELL, Vector2(CELL, CELL)).grow(-3), Color(Ink.CREAM, 0.07))
		_text(BAG_POS + Vector2(bag.width * CELL + 14, y * CELL + CELL / 2 + 8), "◀", 22, Color(Ink.VERMILION, 0.7))
	_text(BAG_POS + Vector2(0, bag.height * CELL + 44), tr("BAG_FRONT"), 18, Color(Ink.CREAM, 0.6))
	for p in bag.pieces:
		var tint := Color(1, 1, 1, 0.35) if p == _drag else Color.WHITE
		Ink.draw_piece(self, BAG_POS + Vector2(p.pos) * CELL, p, CELL, _font, tint)
		if p == _selected:
			Ink.draw_shape(self, BAG_POS + Vector2(p.pos) * CELL, p.cells, CELL, Color(0, 0, 0, 0), Ink.GOLD, 5)


func _draw_bench() -> void:
	draw_rect(BENCH_RECT, Color(Ink.CREAM, 0.06))
	_text(BENCH_RECT.position + Vector2(16, 36), tr("BENCH_TITLE") % [run.bench.size(), RunState.BENCH_MAX], 22)
	var layout := _bench_layout()
	for p in layout:
		var r: Rect2 = layout[p]
		Ink.draw_piece(self, r.position, p, BENCH_CELL, _font, Color(1, 1, 1, 0.35) if p == _drag else Color.WHITE)
		if p == _selected:
			Ink.draw_shape(self, r.position, p.cells, BENCH_CELL, Color(0, 0, 0, 0), Ink.GOLD, 4)
	draw_rect(SELL_RECT, Color(Ink.VERMILION, 0.18))
	draw_rect(SELL_RECT, Color(Ink.VERMILION, 0.6), false, 2)
	_text(SELL_RECT.position + Vector2(0, 56), tr("SELL_ZONE") % RunState.SELL_REFUND, 22, Ink.CREAM, SELL_RECT.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _draw_preview() -> void:
	var r := PREVIEW_RECT
	draw_rect(r, Color(Ink.NIGHT_DEEP, 0.9))
	var pr := run.procession
	_text(r.position + Vector2(20, 40), tr("PREVIEW_TITLE"), 26)
	_text(r.position + Vector2(20, 76), tr("RULE_" + String(pr.rule).to_upper()), 20, Ink.GOLD, r.size.x - 40)
	if pr.time_limit != 60.0:
		_text(r.position + Vector2(20, 104), tr("PREVIEW_TIME") % int(pr.time_limit), 18, Ink.VERMILION)
	for lane in pr.lanes.size():
		var y := r.position.y + 130 + lane * 52
		_text(Vector2(r.position.x + 20, y + 32), "%d" % (lane + 1), 20, Color(Ink.CREAM, 0.5))
		var x := r.position.x + 56
		for kind in pr.lanes[lane]:
			draw_texture_rect(YokaiDb.texture(kind), Rect2(x, y, 48, 48), false)
			x += 50


func _draw_info() -> void:
	var r := INFO_RECT
	draw_rect(r, Color(Ink.NIGHT_DEEP, 0.9))
	var p := _selected
	if p == null or (p not in run.bag.pieces and p not in run.bench):
		_text(r.position + Vector2(24, 50), tr("INFO_EMPTY"), 22, Color(Ink.CREAM, 0.7), r.size.x - 48)
		for i in 4:
			draw_multiline_string(_font, r.position + Vector2(24, 110 + i * 64), tr("HELP_%d" % (i + 1)), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 48, 20, 2, Color(Ink.CREAM, 0.85))
		return
	draw_texture_rect(YokaiDb.texture(p.kind), Rect2(r.position + Vector2(16, 16), Vector2(120, 120)), false)
	_text(r.position + Vector2(150, 56), Ink.name_of(p.kind), 32)
	_text(r.position + Vector2(150, 96), tr("INFO_STATS") % [p.atk, p.hp, tr(Ink.speed_key(p.interval))], 22)
	if p.eaten > 0:
		_text(r.position + Vector2(150, 128), tr("INFO_EATEN") % p.eaten, 20, Ink.GOLD)
	for i in p.traits.size():
		var t := p.traits[i]
		var y := r.position.y + 170 + i * 66
		draw_rect(Rect2(r.position.x + 24, y, 20, 20), Ink.TRAIT_COLORS.get(t, Ink.SLATE))
		_text(Vector2(r.position.x + 54, y + 18), tr("TRAIT_" + String(t).to_upper()), 22)
		draw_multiline_string(_font, Vector2(r.position.x + 54, y + 44), tr("TRAIT_" + String(t).to_upper() + "_DESC"), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 80, 18, 2, Color(Ink.CREAM, 0.7))
	_text(r.position + Vector2(24, r.size.y - 20), tr("INFO_TRAIT_SLOTS") % [p.traits.size(), Piece.MAX_TRAITS], 18, Color(Ink.CREAM, 0.5))


func _draw_drag() -> void:
	if _drag == null or not _moved:
		return
	var p := _drag
	var origin := _mouse - (Vector2(_grab) + Vector2(0.5, 0.5)) * CELL
	var tint := Color(1, 1, 1, 0.85)
	if _bag_rect().has_point(_mouse):
		var target := run.bag.piece_at(_cell_at(_mouse))
		if target != null and target != p:
			var ok := _drag_from_bag and run.bag.touching(target, p)
			Ink.draw_shape(self, BAG_POS + Vector2(target.pos) * CELL, target.cells, CELL, Color(Ink.VERMILION, 0.25), Ink.VERMILION if ok else Ink.SLATE, 6)
			_text(BAG_POS + Vector2(target.pos) * CELL + Vector2(0, -10), tr("DRAG_EAT") if ok else tr("TOAST_EAT_TOUCH"), 22, Ink.VERMILION if ok else Ink.SLATE)
		else:
			var at := _cell_at(_mouse) - _grab
			var ok := run.bag.can_place(p, at)
			Ink.draw_shape(self, BAG_POS + Vector2(at) * CELL, p.cells, CELL, Color(Ink.JADE if ok else Ink.VERMILION, 0.3), Color(0, 0, 0, 0), 0)
	Ink.draw_piece(self, origin, p, CELL, _font, tint)

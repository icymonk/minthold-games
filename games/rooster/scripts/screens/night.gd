extends Control
## 장터·보따리 화면. 고용 → 대기 줄 → 보따리에 끌어다 놓기, 맞닿은 요괴 위에 놓으면 먹이기.

const SHELF_POS := Vector2(70, 112)
const CARD := Vector2(200, 286)
const CARD_GAP := 18.0
const SHELF_Y := 392.0
const BAG_POS := Vector2(80, 560)
const CELL := 80.0
const PLOT_CELL := 54.0
const BENCH_RECT := Rect2(760, 540, 580, 290)
const BENCH_CELL := 52.0
const SELL_RECT := Rect2(760, 850, 580, 96)
const SYNERGY_RECT := Rect2(1400, 262, 480, 166)
const PREVIEW_RECT := Rect2(1400, 440, 480, 240)
const INFO_RECT := Rect2(1400, 696, 480, 250)
const FIGHT_RECT := Rect2(1400, 964, 480, 92)

var run: RunState
var _font: Font
var _selected: Piece
var _drag: Piece
var _drag_from_bag := false
var _drag_shop := -1
var _card := -1
var _drag_cells_backup: Array[Vector2i] = []
var _grab := Vector2i.ZERO
var _press_pos := Vector2.ZERO
var _moved := false
var _mouse := Vector2.ZERO
var _toast := ""
var _toast_until := 0.0
var _overlay: Control
var _ci: CanvasItem
var _plot_i := -1
var _plot: Plot
var _plot_grab := Vector2i.ZERO
var _refresh_btn: Button
var _skip_btn: Button


func _ready() -> void:
	_ci = self
	run = Game.run
	_font = get_theme_default_font()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_btn = _add_button(tr("MARKET_REFRESH") % RunState.REFRESH_COST, Rect2(1170, 210, 180, 72), _on_refresh)
	_skip_btn = _add_button(tr("PLOT_SKIP") % RunState.SKIP_PLOT_COINS, Rect2(_plot_rect(3).position + Vector2(0, 100), Vector2(CARD.x * 2 + CARD_GAP, 72)), _on_skip_plots)
	var fight := _add_button(tr("NIGHT_FIGHT"), FIGHT_RECT, _on_fight)
	fight.theme_type_variation = &"AccentButton"
	fight.add_theme_font_size_override(&"font_size", 36)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)


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
	_skip_btn.visible = not run.plots.is_empty()
	_refresh_btn.visible = run.plots.is_empty()
	queue_redraw()
	_overlay.queue_redraw()


func _toast_msg(key: String) -> void:
	_toast = tr(key)
	_toast_until = Time.get_ticks_msec() / 1000.0 + 2.5


func _on_refresh() -> void:
	if not run.refresh_shelf():
		_toast_msg("TOAST_NO_COINS")


func _on_skip_plots() -> void:
	run.skip_plots()


func _on_fight() -> void:
	if run.bag.pieces.is_empty():
		_toast_msg("TOAST_EMPTY_BAG")
		return
	Game.battle = run.fight()
	Game.goto(&"battle")


# --- 좌표 ---

func _card_rect(i: int) -> Rect2:
	return Rect2(SHELF_POS + Vector2(i * (CARD.x + CARD_GAP), 0), CARD)


func _plot_rect(i: int) -> Rect2:
	return _card_rect(i)


func _cell_at(pos: Vector2) -> Vector2i:
	var rel := (pos - BAG_POS) / CELL
	return Vector2i(floori(rel.x), floori(rel.y))


func _bag_rect() -> Rect2:
	return Rect2(BAG_POS, Vector2(run.bag.width, run.bag.height) * CELL)


func _bench_layout() -> Dictionary:
	var out := {}
	var cursor := BENCH_RECT.position + Vector2(20, 60)
	var row_h := 0.0
	for p in run.bench:
		var s := Vector2(p.size()) * BENCH_CELL
		if cursor.x + s.x > BENCH_RECT.end.x - 20:
			cursor = Vector2(BENCH_RECT.position.x + 20, cursor.y + row_h + 16)
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
		if _drag == null and _plot == null and event.button_mask & MOUSE_BUTTON_MASK_LEFT and _press_pos.distance_to(_mouse) > 8:
			if _plot_i >= 0:
				_plot = run.plots[_plot_i].copy()
				_plot_grab = _plot.cells[0]
			elif _card >= 0:
				_begin_shop_drag(_card)
			elif _selected != null:
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
		elif _plot:
			_drop_plot(event.position)
		else:
			_plot_i = -1


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate()


func _press(pos: Vector2) -> void:
	_press_pos = pos
	_card = -1
	_plot_i = -1
	if not run.plots.is_empty():
		for i in run.plots.size():
			if _plot_rect(i).has_point(pos):
				_plot_i = i
				_selected = null
				return
	for i in run.shelf.size():
		if not run.plots.is_empty():
			break
		if _card_rect(i).has_point(pos) and run.shelf[i] != &"":
			_card = i
			_selected = null
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


func _begin_shop_drag(slot: int) -> void:
	if run.coins < YokaiDb.cost(run.shelf[slot]):
		_toast_msg("TOAST_NO_COINS")
		_card = -1
		return
	_drag = Piece.create(run.shelf[slot])
	_drag_shop = slot
	_drag_from_bag = false
	_drag_cells_backup = _drag.cells.duplicate()
	_grab = _drag.cells[0]
	_moved = false


func _drop_from_shop(pos: Vector2, p: Piece) -> void:
	var slot := _drag_shop
	_drag_shop = -1
	_card = -1
	if not _moved:
		return
	var target := _piece_under(pos)
	if target != null:
		_report_feed(target, p, run.hire_feed(slot, target))
		return
	if _bag_rect().has_point(pos):
		var hired := run.hire_to_bag(slot, p.cells, _cell_at(pos) - _grab)
		if hired == null:
			_toast_msg("TOAST_NO_ROOM")
		else:
			_selected = hired
	elif BENCH_RECT.has_point(pos):
		var hired := run.hire(slot)
		if hired == null:
			_toast_msg("TOAST_BENCH_FULL")
		else:
			hired.cells.assign(p.cells)
			_selected = hired


func _drop_plot(pos: Vector2) -> void:
	var plot := _plot
	var i := _plot_i
	_plot = null
	_plot_i = -1
	if not _bag_rect().grow(CELL).has_point(pos):
		return
	if not run.expand_bag(i, plot, _cell_at(pos) - _plot_grab):
		_toast_msg("TOAST_PLOT_EDGE")


func _rotate() -> void:
	if _plot:
		_plot.rotate_cw()
		_plot_grab = _plot.cells[0]
		return
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
	if _drag_shop >= 0:
		_drop_from_shop(pos, p)
		return
	if not _moved:
		return
	if SELL_RECT.has_point(pos):
		run.sell(p)
		_selected = null
		return
	var target := _piece_under(pos)
	if target != null and target != p:
		p.cells = _drag_cells_backup
		_report_feed(target, p, run.feed(target, p))
		return
	if _bag_rect().has_point(pos):
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


## 보따리 칸이나 대기 줄에서 pos 아래 있는 요괴.
func _piece_under(pos: Vector2) -> Piece:
	if _bag_rect().has_point(pos):
		return run.bag.piece_at(_cell_at(pos))
	if BENCH_RECT.has_point(pos):
		return _bench_piece_at(pos)
	return null


func _report_feed(eater: Piece, food: Piece, result: Bag.Feed) -> void:
	var before := Ink.name_of(food.kind)
	match result:
		Bag.Feed.SELF:
			_toast_msg("TOAST_NO_COINS")
			return
		Bag.Feed.FULL:
			_toast_msg("TOAST_EAT_FULL")
			return
		Bag.Feed.FOOD_EVOLVED:
			_toast_msg("TOAST_EAT_EVOLVED")
			return
		Bag.Feed.NO_ROOM:
			_toast_msg("TOAST_EAT_NO_ROOM")
			return
		Bag.Feed.EVOLVED:
			_toast = tr("TOAST_EVOLVED") % [Ink.with_josa(Ink.name_of(YokaiDb.base_of(eater.kind)), "이가"), Ink.with_josa(Ink.name_of(eater.kind), "으로")]
		_:
			_toast = tr("TOAST_ATE") % [Ink.with_josa(Ink.name_of(eater.kind), "이가"), Ink.with_josa(before, "을를")]
	_selected = eater
	_toast_until = Time.get_ticks_msec() / 1000.0 + 2.5


# --- 그리기 ---

func _draw() -> void:
	draw_texture_rect(Ink.ui("bg_market.jpg"), Rect2(Vector2.ZERO, size), false)
	_draw_top_bar()
	_draw_shelf()
	_draw_bag()
	_draw_bench()
	_draw_synergies()
	_draw_preview()
	_draw_info()


## 버튼보다 위에 그려야 하는 것: 툴팁, 끌고 있는 요괴, 알림.
func _draw_overlay() -> void:
	_ci = _overlay
	_draw_tooltip()
	_draw_synergy_tip()
	_draw_drag()
	if Time.get_ticks_msec() / 1000.0 < _toast_until:
		var r := Rect2(560, 470, 800, 70)
		_ci.draw_style_box(Ink.box(Color(Ink.INK, 0.92), 12, Ink.GOLD, 2, 8), r)
		Ink.draw_label(_ci, r.position + Vector2(0, 46), _toast, 26, Ink.CREAM, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_ci = self


func _text(pos: Vector2, s: String, size := 24, color := Ink.CREAM, width := -1.0, align := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	_ci.draw_string(_font, pos, s, align, width, size, color)


func _draw_top_bar() -> void:
	var title := tr("NIGHT_LABEL") % [run.night, RunState.NIGHTS]
	if run.is_boss_night():
		title += "  ·  " + tr("NIGHT_BOSS")
	Ink.draw_label(self, Vector2(70, 72), title, 44, Ink.VERMILION if run.is_boss_night() else Ink.CREAM)
	var lantern := Ink.ui("lantern.png")
	for i in RunState.START_LANTERNS:
		var lit := i < run.lanterns
		draw_texture_rect(lantern, Rect2(Vector2(470 + i * 42, 22), Vector2(26, 80)), false, Color.WHITE if lit else Color(0.35, 0.35, 0.45, 0.6))
	Ink.draw_coin(self, Vector2(650, 58), 20)
	Ink.draw_label(self, Vector2(682, 70), tr("COINS") % run.coins, 32, Ink.GOLD)


func _draw_shelf() -> void:
	var shelf := Ink.ui("shelf.png")
	var shelf_w := 5 * (CARD.x + CARD_GAP) + 70
	draw_texture_rect(shelf, Rect2(Vector2(SHELF_POS.x - 45, SHELF_Y - 14), Vector2(shelf_w, shelf_w * shelf.get_height() / shelf.get_width())), false)
	if not run.plots.is_empty():
		_draw_plots()
		return
	for i in run.shelf.size():
		var r := _card_rect(i)
		var kind := run.shelf[i]
		if kind == &"":
			draw_style_box(Ink.box(Color(Ink.CREAM, 0.05), 8, Color(Ink.CREAM, 0.25), 2), r)
			continue
		var cost := YokaiDb.cost(kind)
		var tint := Color.WHITE if run.coins >= cost else Color(0.7, 0.7, 0.75)
		Ink.draw_paper(self, r, tint)
		var def: Dictionary = YokaiDb.ALLIES[kind]
		Ink.draw_fit(self, YokaiDb.icon(kind), Rect2(r.position + Vector2(20, 10), Vector2(160, 156)), Color(tint, 0.35 if i == _drag_shop else 1.0))
		_draw_family_chip(self, r.position + Vector2(10, 10), kind, 15)
		_text(r.position + Vector2(0, 28), "★".repeat(def["tier"]), 16, Ink.GOLD, CARD.x - 12, HORIZONTAL_ALIGNMENT_RIGHT)
		Ink.draw_label(self, r.position + Vector2(0, 194), Ink.name_of(kind), 26, Ink.INK, CARD.x, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.draw_stats(self, r.position + Vector2(22, 232), def["atk"], def["hp"], 22)
		var cells: Array[Vector2i] = []
		cells.assign(def["cells"])
		Ink.draw_shape(self, r.position + Vector2(CARD.x - 20 - 3 * 15, 208), cells, 15, Color(Ink.INK, 0.18), Ink.INK, 1.5)
		var chip := Rect2(r.position + Vector2(14, 248), Vector2(CARD.x - 28, 26))
		draw_style_box(Ink.box(Color(Ink.trait_color(def["trait"]), 0.25), 6), chip)
		_text(chip.position + Vector2(10, 20), tr("TRAIT_" + String(def["trait"]).to_upper()), 17, Ink.INK)
		_text(chip.position + Vector2(0, 20), tr("CARD_BELLY") % def["belly"], 15, Color(Ink.INK, 0.7), chip.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
		var price := Vector2(r.get_center().x, SHELF_Y + 30)
		Ink.draw_coin(self, price + Vector2(-18, 0), 15)
		Ink.draw_label(self, price + Vector2(4, 11), str(cost), 28, Ink.GOLD if tint == Color.WHITE else Ink.CREAM_DIM, -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
		if i == _card and _drag == null:
			draw_style_box(Ink.box(Color(0, 0, 0, 0), 10, Ink.GOLD, 4), r.grow(4))
	Ink.draw_label(self, Vector2(1170, 150), tr("MARKET_TITLE"), 30)
	_text(Vector2(1170, 188), tr("MARKET_CLICK"), 18, Color(Ink.CREAM, 0.7))


func _draw_plots() -> void:
	for i in run.plots.size():
		var r := _plot_rect(i)
		var plot := run.plots[i]
		Ink.draw_paper(self, r, Color.WHITE if i != _plot_i or _plot == null else Color(1, 1, 1, 0.4))
		var origin := r.position + Vector2((CARD.x - plot.size().x * PLOT_CELL) / 2, 40)
		_draw_plot_cells(self, origin, plot, PLOT_CELL, Color(Ink.INK, 0.15))
		Ink.draw_label(self, r.position + Vector2(0, 230), tr("PLOT_CELLS") % plot.cells.size(), 26, Ink.INK, CARD.x, HORIZONTAL_ALIGNMENT_CENTER)
		for c in plot.special:
			var k := String(plot.special[c]).to_upper()
			draw_multiline_string(_font, r.position + Vector2(10, 258), tr("CELL_" + k + "_DESC"), HORIZONTAL_ALIGNMENT_CENTER, CARD.x - 20, 16, 2, Color(Ink.INK, 0.8))
	Ink.draw_label(self, Vector2(1170, 150), tr("PLOT_TITLE"), 30)
	draw_multiline_string(_font, Vector2(1170, 188), tr("PLOT_HINT"), HORIZONTAL_ALIGNMENT_LEFT, 360, 18, -1, Color(Ink.CREAM, 0.75))


func _draw_plot_cells(ci: CanvasItem, origin: Vector2, plot: Plot, cs: float, fill: Color) -> void:
	for c in plot.cells:
		var cell := Rect2(origin + Vector2(c) * cs, Vector2(cs, cs)).grow(-3)
		if plot.special.has(c):
			Ink.draw_special_cell(ci, cell, plot.special[c])
		else:
			ci.draw_style_box(Ink.box(fill, 6, Color(Ink.INK, 0.5), 2), cell)


func _draw_bag() -> void:
	var bag := run.bag
	Ink.draw_label(self, BAG_POS + Vector2(-10, -36), tr("BAG_TITLE"), 28)
	Ink.draw_bundle(self, BAG_POS, bag, CELL)
	for y in bag.height:
		var c := BAG_POS + Vector2(bag.width * CELL + 28, y * CELL + CELL / 2)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-8, 0), c + Vector2(8, -10), c + Vector2(8, 10)]), Color(Ink.VERMILION, 0.85))
	Ink.draw_label(self, BAG_POS + Vector2(-10, bag.height * CELL + 56), tr("BAG_FRONT"), 17, Color(Ink.CREAM, 0.8), -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
	for p in bag.pieces:
		var tint := Color(1, 1, 1, 0.35) if p == _drag else Color.WHITE
		Ink.draw_piece(self, BAG_POS + Vector2(p.pos) * CELL, p, CELL, _font, tint)
		if p == _selected:
			Ink.draw_shape(self, BAG_POS + Vector2(p.pos) * CELL, p.cells, CELL, Color(0, 0, 0, 0), Ink.GOLD, 5)


func _draw_bench() -> void:
	Ink.draw_panel(self, BENCH_RECT)
	Ink.draw_label(self, BENCH_RECT.position + Vector2(20, 40), tr("BENCH_TITLE") % [run.bench.size(), RunState.BENCH_MAX], 22)
	var layout := _bench_layout()
	for p in layout:
		var r: Rect2 = layout[p]
		Ink.draw_piece(self, r.position, p, BENCH_CELL, _font, Color(1, 1, 1, 0.35) if p == _drag else Color.WHITE)
		if p == _selected:
			Ink.draw_shape(self, r.position, p.cells, BENCH_CELL, Color(0, 0, 0, 0), Ink.GOLD, 4)
	var hot := _drag != null and _moved and SELL_RECT.has_point(_mouse)
	draw_style_box(Ink.box(Color(Ink.VERMILION, 0.35 if hot else 0.14), 12, Color(Ink.VERMILION, 0.8), 2), SELL_RECT)
	Ink.draw_coin(self, SELL_RECT.position + Vector2(48, SELL_RECT.size.y / 2), 16)
	_text(SELL_RECT.position + Vector2(0, 58), tr("SELL_ZONE") % RunState.SELL_REFUND, 22, Ink.CREAM, SELL_RECT.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _synergy_rect(i: int) -> Rect2:
	return Rect2(SYNERGY_RECT.position + Vector2(16 + (i % 3) * 152, 52 + (i / 3) * 46), Vector2(144, 40))


func _draw_synergies() -> void:
	Ink.draw_panel(self, SYNERGY_RECT)
	Ink.draw_label(self, SYNERGY_RECT.position + Vector2(20, 36), tr("SYNERGY_TITLE"), 22)
	var counts := Synergy.counts(run.bag)
	var levels := Synergy.levels(run.bag)
	for i in YokaiDb.FAMILIES.size():
		var f: StringName = YokaiDb.FAMILIES[i]
		var r := _synergy_rect(i)
		var col: Color = Ink.FAMILY_COLORS[f]
		var lv: int = levels[f]
		draw_style_box(Ink.box(Color(col, 0.18 + lv * 0.22), 8, Color(col, 0.9) if lv > 0 else Color(col, 0.35), 2), r)
		_text(r.position + Vector2(10, 27), tr("FAMILY_" + String(f).to_upper()), 18, Ink.CREAM)
		var next: int = Synergy.THRESHOLDS[mini(lv, Synergy.THRESHOLDS.size() - 1)]
		_text(r.position + Vector2(0, 27), "%d/%d" % [counts[f], next], 17, Ink.GOLD if lv > 0 else Color(Ink.CREAM, 0.6), r.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)


## 계열 칸에 마우스를 올리면 시너지 설명.
func _draw_synergy_tip() -> void:
	if _drag != null:
		return
	for i in YokaiDb.FAMILIES.size():
		var r := _synergy_rect(i)
		if not r.has_point(_mouse):
			continue
		var f: StringName = YokaiDb.FAMILIES[i]
		var desc := tr("FAMILY_" + String(f).to_upper() + "_DESC")
		var w := 460.0
		var h := _font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, w - 32, 17).y + 60
		var tip := Rect2(Vector2(SYNERGY_RECT.end.x - w, SYNERGY_RECT.end.y + 6), Vector2(w, h))
		_ci.draw_style_box(Ink.box(Ink.NIGHT_DEEP, 10, Ink.FAMILY_COLORS[f], 2, 8), tip)
		Ink.draw_label(_ci, tip.position + Vector2(16, 30), tr("FAMILY_" + String(f).to_upper()), 20)
		_ci.draw_multiline_string(_font, tip.position + Vector2(16, 58), desc, HORIZONTAL_ALIGNMENT_LEFT, w - 32, 17, -1, Color(Ink.CREAM, 0.9))
		return


## 계열 색 꼬리표를 그리고 그 너비를 돌려준다.
func _draw_family_chip(ci: CanvasItem, pos: Vector2, kind: StringName, fsize: int) -> float:
	var label := tr("FAMILY_" + String(YokaiDb.family(kind)).to_upper())
	var w := _font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize).x + 16
	ci.draw_style_box(Ink.box(Ink.family_color(kind), 6), Rect2(pos, Vector2(w, fsize + 10)))
	ci.draw_string(_font, pos + Vector2(8, fsize + 1), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Ink.CREAM)
	return w


func _draw_preview() -> void:
	var r := PREVIEW_RECT
	Ink.draw_panel(self, r)
	var pr := run.procession
	Ink.draw_label(self, r.position + Vector2(20, 38), tr("PREVIEW_TITLE"), 24)
	_text(r.position + Vector2(20, 70), tr("RULE_" + String(pr.rule).to_upper()), 18, Ink.GOLD, r.size.x - 40)
	if pr.time_limit != 60.0:
		_text(r.position + Vector2(20, 94), tr("PREVIEW_TIME") % int(pr.time_limit), 17, Ink.VERMILION)
	for lane in pr.lanes.size():
		var y := r.position.y + 100 + lane * 34
		_text(Vector2(r.position.x + 20, y + 24), "%d" % (lane + 1), 18, Color(Ink.CREAM, 0.5))
		draw_dashed_line(Vector2(r.position.x + 44, y + 17), Vector2(r.end.x - 20, y + 17), Color(Ink.CREAM, 0.12), 1.0, 6.0)
		var x := r.end.x - 56
		for kind in pr.lanes[lane]:
			draw_circle(Vector2(x + 18, y + 18), 17, Color(Ink.CREAM, 0.85))
			draw_texture_rect(YokaiDb.texture(kind), Rect2(x, y, 36, 36), false)
			x -= 40


func _draw_info() -> void:
	var r := INFO_RECT
	Ink.draw_panel(self, r)
	var p := _selected
	if p == null or (p not in run.bag.pieces and p not in run.bench):
		_text(r.position + Vector2(22, 40), tr("INFO_EMPTY"), 20, Color(Ink.CREAM, 0.7), r.size.x - 44)
		var y := r.position.y + 80
		for i in 5:
			var line := tr("HELP_%d" % (i + 1))
			draw_multiline_string(_font, Vector2(r.position.x + 22, y), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 44, 17, -1, Color(Ink.CREAM, 0.9))
			y += _font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 44, 17).y + 10
		return
	Ink.draw_paper(self, Rect2(r.position + Vector2(16, 16), Vector2(92, 92)))
	Ink.draw_fit(self, YokaiDb.icon(p.kind), Rect2(r.position + Vector2(20, 20), Vector2(84, 84)))
	Ink.draw_label(self, r.position + Vector2(124, 48), Ink.name_of(p.kind), 28)
	Ink.draw_stats(self, r.position + Vector2(124, 86), p.atk, p.hp, 22, Ink.CREAM)
	_text(r.position + Vector2(250, 86), tr(Ink.speed_key(p.interval)), 18, Color(Ink.CREAM, 0.7))
	_draw_family_chip(self, Vector2(r.end.x - 90, r.position.y + 48), p.kind, 16)
	if p in run.bag.pieces:
		var b: Dictionary = Synergy.bonuses(run.bag)[p.id]
		if b["atk"] != 0 or b["hp"] != 0 or b["interval"] != 1.0:
			var parts: Array[String] = []
			if b["atk"] != 0:
				parts.append(tr("BONUS_ATK") % (("+" if b["atk"] > 0 else "") + str(b["atk"])))
			if b["hp"] != 0:
				parts.append(tr("BONUS_HP") % b["hp"])
			if b["interval"] != 1.0:
				parts.append(tr("BONUS_FAST"))
			_text(r.position + Vector2(330, 86), tr("INFO_BONUS") % " ".join(parts), 16, Ink.GOLD, r.end.x - r.position.x - 340)
	var belly_text := tr("INFO_EVOLVED") if p.evolved else tr("INFO_BELLY") % [p.eaten, p.belly, Ink.name_of(YokaiDb.ALLIES[p.kind]["evolve"])]
	_text(r.position + Vector2(124, 116), belly_text, 17, Ink.GOLD, r.size.x - 140)
	for i in p.traits.size():
		var t := p.traits[i]
		var y := r.position.y + 132 + i * 38
		draw_rect(Rect2(r.position.x + 22, y + 2, 16, 16), Ink.trait_color(t))
		Ink.draw_label(self, Vector2(r.position.x + 48, y + 17), tr("TRAIT_" + String(t).to_upper()), 18)
		_text(Vector2(r.position.x + 48, y + 38), tr("TRAIT_" + String(t).to_upper() + "_DESC"), 15, Color(Ink.CREAM, 0.7), r.size.x - 70)
	_text(r.position + Vector2(0, 34), tr("INFO_TRAIT_SLOTS") % [p.traits.size(), Piece.MAX_TRAITS], 16, Color(Ink.CREAM, 0.5), r.size.x - 20, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_drag() -> void:
	if _plot:
		var at := _cell_at(_mouse) - _plot_grab
		if _bag_rect().grow(CELL).has_point(_mouse):
			var ok := run.bag.can_expand(_plot, at)
			_draw_plot_cells(_ci, BAG_POS + Vector2(at) * CELL, _plot, CELL, Color(Ink.JADE if ok else Ink.VERMILION, 0.45))
		else:
			_draw_plot_cells(_ci, _mouse - (Vector2(_plot_grab) + Vector2(0.5, 0.5)) * CELL, _plot, CELL, Color(Ink.CREAM, 0.4))
		return
	if _drag == null or not _moved:
		return
	var p := _drag
	var origin := _mouse - (Vector2(_grab) + Vector2(0.5, 0.5)) * CELL
	var tint := Color(1, 1, 1, 0.88)
	var target := _piece_under(_mouse)
	if target != null and target != p:
		var why := ""
		if not target.hungry():
			why = "TOAST_EAT_FULL"
		elif p.evolved:
			why = "TOAST_EAT_EVOLVED"
		var ok := why == ""
		var fill := (Bag.SAME_KIND_FILL if target.base_kind() == p.base_kind() else 1) + p.eaten
		var hint := tr(why) if not ok else (tr("DRAG_EVOLVE") if target.eaten + fill >= target.belly else tr("DRAG_EAT"))
		var col := Ink.VERMILION if ok else Ink.SLATE
		var label_at: Vector2
		if target in run.bag.pieces:
			Ink.draw_shape(_ci, BAG_POS + Vector2(target.pos) * CELL, target.cells, CELL, Color(Ink.VERMILION, 0.25), col, 6)
			label_at = BAG_POS + Vector2(target.pos) * CELL
		else:
			var r: Rect2 = _bench_layout()[target]
			_ci.draw_style_box(Ink.box(Color(Ink.VERMILION, 0.25), 8, col, 4), r.grow(4))
			label_at = Vector2(r.position.x, r.end.y + 34)
		Ink.draw_label(_ci, label_at + Vector2(0, -12), hint, 22, col, -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
	elif _bag_rect().has_point(_mouse):
		var at := _cell_at(_mouse) - _grab
		var ok := run.bag.can_place(p, at)
		Ink.draw_shape(_ci, BAG_POS + Vector2(at) * CELL, p.cells, CELL, Color(Ink.JADE if ok else Ink.VERMILION, 0.35), Color(0, 0, 0, 0), 0)
	elif BENCH_RECT.has_point(_mouse) and (_drag_from_bag or _drag_shop >= 0):
		_ci.draw_style_box(Ink.box(Color(Ink.JADE, 0.18), 12, Ink.JADE, 3), BENCH_RECT)
	Ink.draw_piece(_ci, origin, p, CELL, _font, tint)


func _draw_tooltip() -> void:
	if _card < 0 or _drag != null or run.shelf[_card] == &"":
		return
	var kind := run.shelf[_card]
	var def: Dictionary = YokaiDb.ALLIES[kind]
	var card := _card_rect(_card)
	var w := 420.0
	var x := card.end.x + 14 if card.end.x + 14 + w < size.x - 20 else card.position.x - 14 - w
	var r := Rect2(x, card.position.y - 6, w, 400)
	var tip := PackedVector2Array([Vector2(x, card.position.y + 60), Vector2(x - 14, card.position.y + 74), Vector2(x, card.position.y + 88)]) if x > card.position.x else PackedVector2Array([Vector2(r.end.x, card.position.y + 60), Vector2(r.end.x + 14, card.position.y + 74), Vector2(r.end.x, card.position.y + 88)])
	_ci.draw_style_box(Ink.box(Ink.NIGHT_DEEP, 12, Ink.GOLD, 2, 10), r)
	_ci.draw_colored_polygon(tip, Ink.GOLD)
	var o := r.position + Vector2(22, 0)
	var inner := w - 44
	Ink.draw_label(_ci, o + Vector2(0, 44), Ink.name_of(kind), 30)
	var chip_w := _draw_family_chip(_ci, o + Vector2(0, 98), kind, 16)
	_text(o + Vector2(chip_w + 10, 116), tr("TIER_LABEL") % def["tier"], 16, Ink.GOLD)
	Ink.draw_coin(_ci, Vector2(r.end.x - 70, o.y + 34), 14)
	Ink.draw_label(_ci, Vector2(r.end.x - 50, o.y + 45), str(YokaiDb.cost(kind)), 26, Ink.GOLD)
	Ink.draw_stats(_ci, o + Vector2(0, 84), def["atk"], def["hp"], 22, Ink.CREAM)
	_text(o + Vector2(130, 84), tr(Ink.speed_key(def["interval"])), 18, Color(Ink.CREAM, 0.7))
	var cells := YokaiDb.base_cells(kind)
	var shape_cs := 30.0
	Ink.draw_paper_shape(_ci, Vector2(r.end.x - 22 - 3 * shape_cs, o.y + 64), cells, shape_cs)
	Ink.draw_portrait(_ci, Vector2(r.end.x - 22 - 3 * shape_cs, o.y + 64), cells, shape_cs, kind)
	var t: StringName = def["trait"]
	var y := o.y + 150
	_ci.draw_rect(Rect2(o.x, y - 15, 16, 16), Ink.trait_color(t))
	Ink.draw_label(_ci, Vector2(o.x + 26, y), tr("TRAIT_" + String(t).to_upper()), 20)
	y += 12
	var desc := tr("TRAIT_" + String(t).to_upper() + "_DESC")
	_ci.draw_multiline_string(_font, Vector2(o.x, y + 18), desc, HORIZONTAL_ALIGNMENT_LEFT, inner, 17, -1, Color(Ink.CREAM, 0.85))
	y += _font.get_multiline_string_size(desc, HORIZONTAL_ALIGNMENT_LEFT, inner, 17).y + 22
	var form: StringName = def["evolve"]
	_text(Vector2(o.x, y + 18), tr("TIP_EVOLVE") % [def["belly"], Ink.with_josa(Ink.name_of(form), "으로")], 18, Ink.GOLD, inner)
	var fcells := YokaiDb.base_cells(form)
	var fcs := 26.0
	Ink.draw_paper_shape(_ci, Vector2(o.x, y + 32), fcells, fcs)
	Ink.draw_portrait(_ci, Vector2(o.x, y + 32), fcells, fcs, form)
	var hint := tr("TIP_DRAG")
	_ci.draw_multiline_string(_font, Vector2(o.x, r.end.y - 34), hint, HORIZONTAL_ALIGNMENT_LEFT, inner, 16, -1, Color(Ink.CREAM, 0.6))

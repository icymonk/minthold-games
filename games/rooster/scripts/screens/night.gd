extends Control
## 장터·보따리 화면. 고용 → 대기 줄 → 보따리에 끌어다 놓기, 맞닿은 요괴 위에 놓으면 먹이기.

const SHELF_POS := Vector2(70, 112)
const CARD := Vector2(200, 286)
const CARD_GAP := 18.0
const SHELF_Y := 392.0
const BAG_POS := Vector2(80, 560)
const CELL := 96.0
const BENCH_RECT := Rect2(760, 540, 580, 290)
const BENCH_CELL := 52.0
const SELL_RECT := Rect2(760, 850, 580, 96)
const TALISMAN_POS := Vector2(1400, 268)
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


func _ready() -> void:
	_ci = self
	run = Game.run
	_font = get_theme_default_font()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_add_button(tr("MARKET_REFRESH") % RunState.REFRESH_COST, Rect2(1170, 210, 180, 72), _on_refresh)
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
	queue_redraw()
	_overlay.queue_redraw()


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
		if _drag == null and event.button_mask & MOUSE_BUTTON_MASK_LEFT and _press_pos.distance_to(_mouse) > 8:
			if _card >= 0:
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


func _unhandled_key_input(event: InputEvent) -> void:
	if event.pressed and not event.echo and event.keycode == KEY_R:
		_rotate()


func _press(pos: Vector2) -> void:
	_press_pos = pos
	_card = -1
	for i in run.shelf.size():
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
	if _drag_shop >= 0:
		_drop_from_shop(pos, p)
		return
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
	if not _drag_from_bag:
		_toast_msg("TOAST_EAT_TOUCH")
		return
	var before := Ink.name_of(eater.kind)
	match run.bag.feed(eater, food):
		Bag.Feed.NOT_TOUCHING:
			_toast_msg("TOAST_EAT_TOUCH")
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
			_toast = tr("TOAST_EVOLVED") % [Ink.with_josa(before, "이가"), Ink.with_josa(Ink.name_of(eater.kind), "으로")]
		_:
			_toast = tr("TOAST_ATE") % [Ink.with_josa(before, "이가"), Ink.with_josa(Ink.name_of(food.kind), "을를")]
	_selected = eater
	_toast_until = Time.get_ticks_msec() / 1000.0 + 2.5


# --- 그리기 ---

func _draw() -> void:
	draw_texture_rect(Ink.ui("bg_market.jpg"), Rect2(Vector2.ZERO, size), false)
	_draw_top_bar()
	_draw_shelf()
	_draw_bag()
	_draw_bench()
	_draw_talismans()
	_draw_preview()
	_draw_info()


## 버튼보다 위에 그려야 하는 것: 툴팁, 끌고 있는 요괴, 알림.
func _draw_overlay() -> void:
	_ci = _overlay
	_draw_tooltip()
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
		draw_texture_rect(YokaiDb.icon(kind), Rect2(r.position + Vector2(20, 6), Vector2(160, 160)), false, Color(tint, 0.35 if i == _drag_shop else 1.0))
		Ink.draw_label(self, r.position + Vector2(0, 194), Ink.name_of(kind), 26, Ink.INK, CARD.x, HORIZONTAL_ALIGNMENT_CENTER)
		Ink.draw_stats(self, r.position + Vector2(22, 232), def["atk"], def["hp"], 22)
		var cells: Array[Vector2i] = []
		cells.assign(def["cells"])
		Ink.draw_shape(self, r.position + Vector2(CARD.x - 20 - 3 * 15, 208), cells, 15, Color(Ink.INK, 0.18), Ink.INK, 1.5)
		var chip := Rect2(r.position + Vector2(14, 248), Vector2(CARD.x - 28, 26))
		draw_style_box(Ink.box(Color(Ink.TRAIT_COLORS[def["trait"]], 0.25), 6), chip)
		_text(chip.position + Vector2(10, 20), tr("TRAIT_" + String(def["trait"]).to_upper()), 17, Ink.INK)
		_text(chip.position + Vector2(0, 20), tr("CARD_BELLY") % def["belly"], 15, Color(Ink.INK, 0.7), chip.size.x - 10, HORIZONTAL_ALIGNMENT_RIGHT)
		var price := Vector2(r.get_center().x, SHELF_Y + 30)
		Ink.draw_coin(self, price + Vector2(-18, 0), 15)
		Ink.draw_label(self, price + Vector2(4, 11), str(cost), 28, Ink.GOLD if tint == Color.WHITE else Ink.CREAM_DIM, -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
		if i == _card and _drag == null:
			draw_style_box(Ink.box(Color(0, 0, 0, 0), 10, Ink.GOLD, 4), r.grow(4))
	Ink.draw_label(self, Vector2(1170, 150), tr("MARKET_TITLE"), 30)
	_text(Vector2(1170, 188), tr("MARKET_CLICK"), 18, Color(Ink.CREAM, 0.7))


func _draw_bag() -> void:
	var bag := run.bag
	Ink.draw_label(self, BAG_POS + Vector2(-10, -36), tr("BAG_TITLE"), 28)
	Ink.draw_bundle(self, BAG_POS, bag.width, bag.height, CELL)
	for y in bag.height:
		var c := BAG_POS + Vector2(bag.width * CELL + 34, y * CELL + CELL / 2)
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


func _draw_talismans() -> void:
	var tex := Ink.ui("talisman.png")
	for i in 3:
		draw_texture_rect(tex, Rect2(TALISMAN_POS + Vector2(i * 78, 0), Vector2(64, 142)), false, Color(1, 1, 1, 0.45))
	Ink.draw_label(self, TALISMAN_POS + Vector2(250, 60), tr("TALISMAN_TITLE"), 24)
	_text(TALISMAN_POS + Vector2(250, 94), tr("TALISMAN_SOON"), 17, Color(Ink.CREAM, 0.6))


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
		for i in 4:
			var line := tr("HELP_%d" % (i + 1))
			draw_multiline_string(_font, Vector2(r.position.x + 22, y), line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 44, 17, -1, Color(Ink.CREAM, 0.9))
			y += _font.get_multiline_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 44, 17).y + 10
		return
	Ink.draw_paper(self, Rect2(r.position + Vector2(16, 16), Vector2(92, 92)))
	Ink.draw_fit(self, YokaiDb.icon(p.kind), Rect2(r.position + Vector2(20, 20), Vector2(84, 84)))
	Ink.draw_label(self, r.position + Vector2(124, 48), Ink.name_of(p.kind), 28)
	Ink.draw_stats(self, r.position + Vector2(124, 86), p.atk, p.hp, 22, Ink.CREAM)
	_text(r.position + Vector2(250, 86), tr(Ink.speed_key(p.interval)), 18, Color(Ink.CREAM, 0.7))
	var belly_text := tr("INFO_EVOLVED") if p.evolved else tr("INFO_BELLY") % [p.eaten, p.belly, Ink.name_of(YokaiDb.ALLIES[p.kind]["evolve"])]
	_text(r.position + Vector2(124, 116), belly_text, 17, Ink.GOLD, r.size.x - 140)
	for i in p.traits.size():
		var t := p.traits[i]
		var y := r.position.y + 132 + i * 38
		draw_rect(Rect2(r.position.x + 22, y + 2, 16, 16), Ink.TRAIT_COLORS.get(t, Ink.SLATE))
		Ink.draw_label(self, Vector2(r.position.x + 48, y + 17), tr("TRAIT_" + String(t).to_upper()), 18)
		_text(Vector2(r.position.x + 48, y + 38), tr("TRAIT_" + String(t).to_upper() + "_DESC"), 15, Color(Ink.CREAM, 0.7), r.size.x - 70)
	_text(r.position + Vector2(0, 34), tr("INFO_TRAIT_SLOTS") % [p.traits.size(), Piece.MAX_TRAITS], 16, Color(Ink.CREAM, 0.5), r.size.x - 20, HORIZONTAL_ALIGNMENT_RIGHT)


func _draw_drag() -> void:
	if _drag == null or not _moved:
		return
	var p := _drag
	var origin := _mouse - (Vector2(_grab) + Vector2(0.5, 0.5)) * CELL
	var tint := Color(1, 1, 1, 0.88)
	if _bag_rect().has_point(_mouse):
		var target := run.bag.piece_at(_cell_at(_mouse))
		if target != null and target != p and _drag_shop < 0:
			var why := ""
			if not _drag_from_bag or not run.bag.touching(target, p):
				why = "TOAST_EAT_TOUCH"
			elif not target.hungry():
				why = "TOAST_EAT_FULL"
			elif p.evolved:
				why = "TOAST_EAT_EVOLVED"
			var ok := why == ""
			var hint := tr(why) if not ok else (tr("DRAG_EVOLVE") if target.eaten + 1 >= target.belly else tr("DRAG_EAT"))
			Ink.draw_shape(_ci, BAG_POS + Vector2(target.pos) * CELL, target.cells, CELL, Color(Ink.VERMILION, 0.25), Ink.VERMILION if ok else Ink.SLATE, 6)
			Ink.draw_label(_ci, BAG_POS + Vector2(target.pos) * CELL + Vector2(0, -12), hint, 22, Ink.VERMILION if ok else Ink.SLATE, -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
		else:
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
	var r := Rect2(x, card.position.y - 6, w, 380)
	var tip := PackedVector2Array([Vector2(x, card.position.y + 60), Vector2(x - 14, card.position.y + 74), Vector2(x, card.position.y + 88)]) if x > card.position.x else PackedVector2Array([Vector2(r.end.x, card.position.y + 60), Vector2(r.end.x + 14, card.position.y + 74), Vector2(r.end.x, card.position.y + 88)])
	_ci.draw_style_box(Ink.box(Ink.NIGHT_DEEP, 12, Ink.GOLD, 2, 10), r)
	_ci.draw_colored_polygon(tip, Ink.GOLD)
	var o := r.position + Vector2(22, 0)
	var inner := w - 44
	Ink.draw_label(_ci, o + Vector2(0, 44), Ink.name_of(kind), 30)
	Ink.draw_coin(_ci, Vector2(r.end.x - 70, o.y + 34), 14)
	Ink.draw_label(_ci, Vector2(r.end.x - 50, o.y + 45), str(YokaiDb.cost(kind)), 26, Ink.GOLD)
	Ink.draw_stats(_ci, o + Vector2(0, 84), def["atk"], def["hp"], 22, Ink.CREAM)
	_text(o + Vector2(130, 84), tr(Ink.speed_key(def["interval"])), 18, Color(Ink.CREAM, 0.7))
	var cells := YokaiDb.base_cells(kind)
	var shape_cs := 30.0
	Ink.draw_paper_shape(_ci, Vector2(r.end.x - 22 - 3 * shape_cs, o.y + 64), cells, shape_cs)
	Ink.draw_portrait(_ci, Vector2(r.end.x - 22 - 3 * shape_cs, o.y + 64), cells, shape_cs, kind)
	var t: StringName = def["trait"]
	var y := o.y + 128
	_ci.draw_rect(Rect2(o.x, y - 15, 16, 16), Ink.TRAIT_COLORS.get(t, Ink.SLATE))
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

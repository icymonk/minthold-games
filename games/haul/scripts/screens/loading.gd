extends Control
## 상차 화면: 컨베이어에서 상자를 집어 문(오른쪽)으로 밀어 넣는다.

const CELL := 112
const MINI := 36
const SLOT_W := 170

var _shift: ShiftState
var _held: Box
var _hover_cell := Vector2i(-99, -99)
var _over_bay := false
var _undo: Array[Dictionary] = []
var _bay_pos: Vector2
var _conveyor_rect: Rect2
var _undo_button: Button
var _bar: HBoxContainer
var _font: Font


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = Style.bold()
	_shift = Game.shift
	_build_buttons()
	resized.connect(_layout)
	_layout()


func _build_buttons() -> void:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", 16)
	add_child(bar)
	_bar = bar
	_add_button(bar, tr("LOADING_ROTATE"), _rotate_held)
	_undo_button = _add_button(bar, tr("LOADING_UNDO"), _undo_last)
	_add_button(bar, tr("LOADING_DEPART"), _depart).theme_type_variation = &"AccentButton"
	_refresh_buttons()


func _add_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(230, 68)
	b.add_theme_font_size_override(&"font_size", 26)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _layout() -> void:
	var w := float(_shift.bay.width * CELL)
	_bay_pos = Vector2((size.x - w) / 2.0, 260)
	_conveyor_rect = Rect2(60, size.y - 290, size.x - 120, 150)
	if _bar:
		_bar.reset_size()
		_bar.position = Vector2(size.x - _bar.size.x - 60, size.y - 120)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_update_hover(event.position)
	elif event is InputEventMouseButton and event.pressed:
		_update_hover(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			_click(event.position)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_rotate_held()
		accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not event.pressed:
		return
	match event.keycode:
		KEY_R:
			_rotate_held()
		KEY_Z:
			_undo_last()
		KEY_ESCAPE:
			_return_held()


func _update_hover(pos: Vector2) -> void:
	var local := (pos - _bay_pos) / CELL
	var h := _shift.bay.height
	_over_bay = local.x >= 0 and local.x < _shift.bay.width and local.y >= 0 and local.y < h
	_hover_cell = Vector2i(floori(local.x), h - 1 - floori(local.y))
	queue_redraw()


func _click(pos: Vector2) -> void:
	if _held != null:
		if _over_bay:
			_try_place()
		elif _conveyor_rect.has_point(pos):
			_return_held()
		return
	var slot := _slot_at(pos)
	if slot >= 0:
		_push_undo()
		_held = _shift.queue.pop_at(slot)
	elif _over_bay:
		var box := _shift.bay.box_at(_hover_cell)
		if box != null and _shift.bay.can_unload(box.id) == Bay.Fail.OK:
			_push_undo()
			_held = _shift.bay.unload(box.id).box
	_refresh_buttons()
	queue_redraw()


func _try_place() -> void:
	var origin := _held_origin()
	if _shift.bay.preview(_held, origin).error != Bay.Fail.OK:
		return
	_shift.bay.place(_held, origin)
	_held = null
	_refresh_buttons()
	queue_redraw()


## 마우스 칸을 상자 왼쪽 아래 칸으로 쓰되, 짐칸 밖으로 삐져나가지 않게 당긴다.
func _held_origin() -> Vector2i:
	var s := _held.size()
	return Vector2i(
		clampi(_hover_cell.x, 0, _shift.bay.width - s.x),
		clampi(_hover_cell.y, 0, _shift.bay.height - s.y))


func _rotate_held() -> void:
	if _held != null:
		_held.rotate()
		queue_redraw()


func _return_held() -> void:
	if _held == null:
		return
	_shift.queue.append(_held)
	_held = null
	_refresh_buttons()
	queue_redraw()


func _push_undo() -> void:
	var snap := _shift.snapshot()
	if _held != null:
		snap.queue.append(_held.copy())
	_undo.append(snap)


func _undo_last() -> void:
	if _undo.is_empty():
		return
	_held = null
	_shift.restore(_undo.pop_back())
	_refresh_buttons()
	queue_redraw()


func _refresh_buttons() -> void:
	if _undo_button:
		_undo_button.disabled = _undo.is_empty()


func _depart() -> void:
	_return_held()
	Game.goto(&"shift")


func _slot_at(pos: Vector2) -> int:
	if not _conveyor_rect.has_point(pos):
		return -1
	var i := int((pos.x - _conveyor_rect.position.x - 20) / SLOT_W)
	return i if i >= 0 and i < _shift.queue.size() else -1


# ── 그리기 ─────────────────────────────────────────────

func _draw() -> void:
	_draw_text(tr("LOADING_TITLE"), Vector2(60, 70), 40, Style.TAPE)
	_draw_route()
	_draw_bay()
	_draw_conveyor()
	_draw_text(tr("LOADING_HELP"), Vector2(60, size.y - 75), 22, Color(Style.TAPE, 0.6))
	if _held != null:
		_draw_held()


func _draw_route() -> void:
	_draw_text(tr("LOADING_ROUTE"), Vector2(60, 150), 24, Color(Style.TAPE, 0.7))
	for stop in range(1, _shift.stops + 1):
		var c := Vector2(260 + (stop - 1) * 110, 140)
		draw_circle(c, 32, Style.stop_color(stop))
		_draw_text(str(stop), c + Vector2(-9, 11), 30, Style.DAWN_DEEP)
		if stop < _shift.stops:
			draw_line(c + Vector2(40, 0), c + Vector2(70, 0), Color(Style.TAPE, 0.5), 4)


func _draw_bay() -> void:
	var bay := _shift.bay
	var full := Rect2(_bay_pos, Vector2(bay.width, bay.height) * CELL)
	draw_rect(full.grow(14), Color(Style.TAPE, 0.15))
	draw_rect(full, Style.DAWN_DEEP)
	for x in range(1, bay.width):
		draw_line(_bay_pos + Vector2(x * CELL, 0), _bay_pos + Vector2(x * CELL, full.size.y), Color(1, 1, 1, 0.05), 2)
	for y in range(1, bay.height):
		draw_line(_bay_pos + Vector2(0, y * CELL), _bay_pos + Vector2(full.size.x, y * CELL), Color(1, 1, 1, 0.05), 2)
	draw_rect(Rect2(full.end.x + 14, full.position.y - 14, 10, full.size.y + 28), Style.LAMP)
	_draw_text(tr("LOADING_DOOR"), Vector2(full.end.x + 40, full.get_center().y + 10), 28, Style.LAMP)
	_draw_text(tr("LOADING_CAB"), Vector2(full.position.x - 130, full.get_center().y + 10), 28, Color(Style.TAPE, 0.5))
	var bad := bay.out_of_order()
	for id in bay.boxes:
		var box: Box = bay.boxes[id]
		_draw_box(box, _cell_rect(bay.origins[id]).position, CELL, 1.0, id in bad)
	if not bad.is_empty():
		_draw_text(tr("LOADING_OUT_OF_ORDER"), Vector2(full.position.x, full.end.y + 60), 22, Style.ALERT)


func _draw_conveyor() -> void:
	draw_rect(_conveyor_rect, Color(Style.TAPE, 0.08))
	for i in _shift.queue.size():
		var box := _shift.queue[i]
		var s := box.size()
		var top := Vector2(_conveyor_rect.position.x + 20 + i * SLOT_W, _conveyor_rect.get_center().y - s.y * MINI / 2.0)
		_draw_box(box, top + Vector2(0, (s.y - 1) * MINI), MINI, 1.0, false)


func _draw_held() -> void:
	if _over_bay:
		var origin := _held_origin()
		var p := _shift.bay.preview(_held, origin)
		var ok: bool = p.error == Bay.Fail.OK
		for c in _held.cells:
			draw_rect(_cell_rect(origin + c), Color(Style.ALERT if not ok else Style.TAPE, 0.25))
		if ok:
			_draw_box(_held, _cell_rect(p.origin).position, CELL, 0.55, false)
	else:
		var m := get_local_mouse_position()
		_draw_box(_held, m - Vector2(CELL, CELL) * 0.5, CELL, 0.85, false)


## at = 상자 원점 칸(왼쪽 아래)의 왼쪽 위 화면 좌표.
func _draw_box(box: Box, at: Vector2, cell: float, alpha: float, alert: bool) -> void:
	var color := Color(Style.CARDBOARD, alpha)
	var edge := Style.ALERT if alert else Color(Style.DAWN_DEEP, alpha)
	for c in box.cells:
		var r := Rect2(at + Vector2(c.x, -c.y) * cell, Vector2(cell, cell))
		draw_rect(r.grow(-2), color)
		for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if not (c + n) in box.cells:
				_draw_edge(r, n, edge, 6 if alert else 3)
	var label_cell: Vector2i = box.cells[0]
	var lr := Rect2(at + Vector2(label_cell.x, -label_cell.y) * cell, Vector2(cell, cell))
	var tag := lr.size * 0.42
	draw_rect(Rect2(lr.get_center() - tag / 2.0, tag), Color(Style.stop_color(box.stop), alpha))
	var fs := int(cell * 0.32)
	_draw_text(str(box.stop), lr.get_center() + Vector2(-fs * 0.28, fs * 0.36), fs, Color(Style.DAWN_DEEP, alpha))


func _draw_edge(r: Rect2, n: Vector2i, color: Color, w: float) -> void:
	match n:
		Vector2i(1, 0): draw_line(Vector2(r.end.x, r.position.y), r.end, color, w)
		Vector2i(-1, 0): draw_line(r.position, Vector2(r.position.x, r.end.y), color, w)
		Vector2i(0, 1): draw_line(r.position, Vector2(r.end.x, r.position.y), color, w)
		Vector2i(0, -1): draw_line(Vector2(r.position.x, r.end.y), r.end, color, w)


func _cell_rect(cell: Vector2i) -> Rect2:
	var y := _shift.bay.height - 1 - cell.y
	return Rect2(_bay_pos + Vector2(cell.x, y) * CELL, Vector2(CELL, CELL))


func _draw_text(text: String, pos: Vector2, fs: int, color: Color) -> void:
	draw_string(_font, pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, color)

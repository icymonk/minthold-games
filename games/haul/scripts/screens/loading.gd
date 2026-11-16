extends Control
## 상차 화면: 컨베이어에서 상자를 집어 문(오른쪽)으로 밀어 넣는다.

const CELL := 104
const MINI := 44
const SLOT_W := 190
const SLOT_PAD := 40

var _shift: ShiftState
var _guide: LoadingGuide
var _held: Box
var _hover_cell := Vector2i(-99, -99)
var _over_bay := false
var _undo: Array[Dictionary] = []
var _bay_pos: Vector2
var _conveyor_rect: Rect2
var _font: Font
var _time := 0.0
## 상자 id -> {off: 칸 단위 그림 위치 차이(오른쪽·위가 +), squash}
var _anim := {}
var _flash: Array[int] = []
var _flash_until := 0.0

var _bar: HBoxContainer
var _rotate_button: Button
var _undo_button: Button
var _depart_button: Button
var _card: PanelContainer
var _card_label: Label
var _next_button: Button
var _skip_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = Style.bold()
	_shift = Game.shift
	if Game.tutorial:
		_guide = LoadingGuide.new()
	_build_buttons()
	_build_card()
	resized.connect(_layout)
	_layout()
	_refresh()


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _build_buttons() -> void:
	_bar = HBoxContainer.new()
	_bar.add_theme_constant_override(&"separation", 16)
	add_child(_bar)
	_rotate_button = _add_button(_bar, tr("LOADING_ROTATE"), _rotate_held)
	_undo_button = _add_button(_bar, tr("LOADING_UNDO"), _undo_last)
	_depart_button = _add_button(_bar, tr("LOADING_DEPART"), _depart)
	_depart_button.theme_type_variation = &"AccentButton"
	if _guide:
		_skip_button = _add_button(self, tr("TUT_SKIP"), _skip_tutorial)
		_skip_button.custom_minimum_size = Vector2(220, 52)
		_skip_button.add_theme_font_size_override(&"font_size", 20)


func _add_button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(230, 68)
	b.add_theme_font_size_override(&"font_size", 26)
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _build_card() -> void:
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override(&"panel", Style.box(Color(Style.DAWN_DEEP, 0.92), 16, Style.LAMP, 3))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var margin := MarginContainer.new()
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 22)
	_card.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 24)
	margin.add_child(row)
	_card_label = Label.new()
	_card_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_card_label.custom_minimum_size = Vector2(820, 0)
	_card_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_card_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_card_label.add_theme_font_size_override(&"font_size", 28)
	_card_label.add_theme_font_override(&"font", _font)
	row.add_child(_card_label)
	_next_button = Button.new()
	_next_button.text = tr("TUT_NEXT")
	_next_button.theme_type_variation = &"AccentButton"
	_next_button.custom_minimum_size = Vector2(150, 60)
	_next_button.add_theme_font_size_override(&"font_size", 26)
	_next_button.focus_mode = Control.FOCUS_NONE
	_next_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_next_button.pressed.connect(_on_next)
	row.add_child(_next_button)


func _layout() -> void:
	var w := float(_shift.bay.width * CELL)
	_bay_pos = Vector2(roundf((size.x - w) / 2.0 + 130), 290)
	_conveyor_rect = Rect2(60, size.y - 250, size.x - 120, 140)
	_bar.reset_size()
	_bar.position = Vector2(size.x - _bar.size.x - 60, size.y - 96)
	_card.custom_minimum_size = Vector2(1060, 0)
	_card.reset_size()
	_card.position = Vector2(roundf((size.x - 1060) / 2.0), 118)
	if _skip_button:
		_skip_button.position = Vector2(60, size.y - 88)


# ── 입력 ───────────────────────────────────────────────

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
		KEY_ENTER, KEY_SPACE:
			if _guide and _guide.is_manual():
				_on_next()


func _update_hover(pos: Vector2) -> void:
	var local := (pos - _bay_pos) / CELL
	var h := _shift.bay.height
	_over_bay = local.x >= 0 and local.x < _shift.bay.width and local.y >= 0 and local.y < h
	_hover_cell = Vector2i(floori(local.x), h - 1 - floori(local.y))


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
		Game.sfx(&"pick")
	elif _over_bay:
		var box := _shift.bay.box_at(_hover_cell)
		if box == null:
			return
		if _shift.bay.can_unload(box.id) == Bay.Fail.OK:
			_push_undo()
			var before := _shift.bay.origins.duplicate()
			var r := _shift.bay.unload(box.id)
			_held = r.box
			Game.sfx(&"pick")
			_animate_settle(r.moved, before)
		else:
			_flash_blockers(_shift.bay.blockers(box.id))
	_refresh()


func _try_place() -> void:
	var origin := _held_origin()
	var p := _shift.bay.preview(_held, origin)
	if p.error != Bay.Fail.OK:
		Game.sfx(&"error")
		return
	var id := _held.id
	_shift.bay.place(_held, origin)
	_held = null
	Game.sfx(&"slide")
	_animate_place(id, origin, p.origin)
	_refresh()


## 마우스 칸을 상자 왼쪽 아래 칸으로 쓰되, 짐칸 밖으로 삐져나가지 않게 당긴다.
func _held_origin() -> Vector2i:
	var s := _held.size()
	return Vector2i(
		clampi(_hover_cell.x, 0, _shift.bay.width - s.x),
		clampi(_hover_cell.y, 0, _shift.bay.height - s.y))


func _rotate_held() -> void:
	if _held == null:
		return
	if _held.rotate():
		Game.sfx(&"rotate")
		if _guide:
			_guide.on_rotated()
	else:
		Game.sfx(&"error")
	_refresh()


func _return_held() -> void:
	if _held == null:
		return
	_shift.queue.append(_held)
	_held = null
	_refresh()


func _push_undo() -> void:
	_undo.append(_shift.snapshot())


func _undo_last() -> void:
	if _undo.is_empty():
		return
	_held = null
	_anim.clear()
	_shift.restore(_undo.pop_back())
	Game.sfx(&"pick", 0.8)
	_refresh()


func _depart() -> void:
	_return_held()
	Game.sfx(&"engine")
	if _guide:
		_guide.on_departed()
		Game.finish_tutorial()
	Game.goto(&"shift")


func _skip_tutorial() -> void:
	Game.finish_tutorial()
	Game.start_run()


func _on_next() -> void:
	_guide.next()
	Game.sfx(&"chime")
	_refresh()


func _slot_at(pos: Vector2) -> int:
	if not _conveyor_rect.has_point(pos):
		return -1
	var i := int((pos.x - _conveyor_rect.position.x - SLOT_PAD + 20) / SLOT_W)
	return i if i >= 0 and i < _shift.queue.size() else -1


func _refresh() -> void:
	if _guide and _guide.update(_shift, _held):
		Game.sfx(&"chime")
	_undo_button.disabled = _undo.is_empty()
	_rotate_button.disabled = _held == null
	if _guide and _guide.step != LoadingGuide.Step.DONE:
		_card_label.text = tr(_guide.text_key(_shift))
		_next_button.visible = _guide.is_manual()
	else:
		var h := LoadingGuide.hint(_shift, _held)
		_card_label.text = tr(h.key) % h.arg if h.arg != null else tr(h.key)
		_next_button.visible = false
	_layout()


# ── 움직임 ─────────────────────────────────────────────

func _animate_place(id: int, entry: Vector2i, rest: Vector2i) -> void:
	var dx := float(_shift.bay.width - entry.x)
	var dy := float(entry.y - rest.y)
	var st := {off = Vector2(dx, dy), squash = 0.0}
	_anim[id] = st
	var tw := create_tween()
	tw.tween_method(func(v: Vector2) -> void: st.off = v, Vector2(dx, dy), Vector2(0, dy), 0.06 + 0.035 * dx) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if dy > 0:
		tw.tween_method(func(v: Vector2) -> void: st.off = v, Vector2(0, dy), Vector2.ZERO, 0.08 + 0.05 * dy) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_land(tw, id, st)


func _animate_settle(moved: Array, before: Dictionary) -> void:
	for id in moved:
		var dy := float(before[id].y - _shift.bay.origins[id].y)
		var st := {off = Vector2(0, dy), squash = 0.0}
		_anim[id] = st
		var tw := create_tween()
		tw.tween_method(func(v: Vector2) -> void: st.off = v, Vector2(0, dy), Vector2.ZERO, 0.1 + 0.05 * dy) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_land(tw, id, st)


func _land(tw: Tween, id: int, st: Dictionary) -> void:
	tw.tween_callback(func() -> void: Game.sfx(&"thud", randf_range(0.9, 1.1)))
	tw.tween_method(func(v: float) -> void: st.squash = v, 0.14, 0.0, 0.22) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if _anim.get(id) == st:
			_anim.erase(id))


func _flash_blockers(ids: Array[int]) -> void:
	_flash = ids
	_flash_until = _time + 0.8
	Game.sfx(&"error")


# ── 그리기 ─────────────────────────────────────────────

func _draw() -> void:
	Art.draw_cover(self, Art.BG, size)
	_draw_header()
	_draw_bay()
	_draw_conveyor()
	if _held != null:
		_draw_held()
	_draw_pointer()


func _draw_header() -> void:
	draw_string(_font, Vector2(60, 76), tr("LOADING_STEP"), HORIZONTAL_ALIGNMENT_LEFT, -1, 44, Style.TAPE)
	if _guide:
		var tag := Rect2(190, 40, 170, 46)
		draw_rect(tag, Style.LAMP)
		Art.text_center(self, _font, tr("TUT_LABEL"), tag, 24, Art.INK)
	var r := _route_rect()
	draw_string(_font, Vector2(r.position.x - 180, r.get_center().y + 10), tr("LOADING_ROUTE"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(Style.TAPE, 0.8))
	for stop in range(1, _shift.stops + 1):
		var c := _house_center(stop)
		if stop < _shift.stops:
			for k in 3:
				draw_circle(c + Vector2(48 + k * 16, 6), 4, Color(Style.TAPE, 0.6))
		Art.draw_house(self, _font, stop, c, 72)


func _route_rect() -> Rect2:
	var w := _shift.stops * 110 - 38
	return Rect2(size.x - 60 - w, 22, w, 80)


func _house_center(stop: int) -> Vector2:
	var r := _route_rect()
	return Vector2(r.position.x + 36 + (stop - 1) * 110, r.get_center().y)


func _draw_bay() -> void:
	var bay := _shift.bay
	var inner := Rect2(_bay_pos, Vector2(bay.width, bay.height) * CELL)
	Art.draw_truck(self, inner, CELL)
	var bad := bay.out_of_order()
	var flash := _time < _flash_until and int(_time * 8) % 2 == 0
	for id in bay.boxes:
		var st: Dictionary = _anim.get(id, {})
		var off: Vector2 = st.get("off", Vector2.ZERO)
		var at := _cell_rect(bay.origins[id]).position + Vector2(off.x, -off.y) * CELL
		var alert: bool = id in bad or (flash and id in _flash)
		Art.draw_box(self, _font, bay.boxes[id], at, CELL, 1.0, alert, st.get("squash", 0.0))
	var door := Vector2(inner.end.x + 30, inner.position.y - 30)
	draw_string(_font, door + Vector2(-26, -4), tr("LOADING_DOOR"), HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Style.LAMP)
	draw_colored_polygon(PackedVector2Array([door + Vector2(40, -26), door + Vector2(40, -2), door + Vector2(22, -14)]), Style.LAMP)


func _draw_conveyor() -> void:
	var r := _conveyor_rect
	var belt_y := r.end.y - 34
	draw_rect(Rect2(r.position.x, belt_y, r.size.x, 22), Color("#2B3142"))
	var phase := fmod(_time * 80.0, 40.0)
	var x := r.position.x - 40 + phase
	while x < r.end.x:
		if x > r.position.x:
			draw_line(Vector2(x, belt_y + 3), Vector2(minf(x + 14, r.end.x), belt_y + 19), Color(1, 1, 1, 0.08), 3)
		x += 40
	draw_rect(Rect2(r.position.x, belt_y, r.size.x, 22), Art.INK, false, 3)
	var roller := r.position.x + 30
	while roller < r.end.x:
		draw_circle(Vector2(roller, belt_y + 34), 10, Color("#3A4560"))
		draw_circle(Vector2(roller, belt_y + 34), 4, Art.INK)
		roller += 80
	var suggest: int = LoadingGuide.hint(_shift, _held).suggest if _guide == null else -1
	for i in _shift.queue.size():
		var box := _shift.queue[i]
		var s := box.size()
		var left := r.position.x + SLOT_PAD + i * SLOT_W
		if box.id == suggest:
			var glow := Rect2(left - 16, belt_y - s.y * MINI - 16, s.x * MINI + 32, s.y * MINI + 24)
			draw_rect(glow, Color(Style.LAMP, 0.18 + 0.14 * sin(_time * 5.0)))
			draw_rect(glow, Style.LAMP, false, 3)
		Art.draw_box(self, _font, box, Vector2(left, belt_y - MINI), MINI)


func _draw_held() -> void:
	if _over_bay:
		var origin := _held_origin()
		var p := _shift.bay.preview(_held, origin)
		var ok: bool = p.error == Bay.Fail.OK
		var tint := Style.TAPE if ok else Style.ALERT
		var right := 0
		for c in _held.cells:
			right = maxi(right, c.x)
		# 문에서 들어오는 길
		for c in _held.cells:
			if c.x == right:
				var row := _cell_rect(origin + c)
				var lane := Rect2(row.end.x, row.position.y + row.size.y * 0.42, _bay_pos.x + _shift.bay.width * CELL - row.end.x, row.size.y * 0.16)
				if lane.size.x > 0:
					draw_rect(lane, Color(tint, 0.18))
		for c in _held.cells:
			draw_rect(_cell_rect(origin + c), Color(tint, 0.22))
			draw_rect(_cell_rect(origin + c), Color(tint, 0.6), false, 2)
		if ok:
			Art.draw_box(self, _font, _held, _cell_rect(p.origin).position, CELL, 0.55)
	else:
		var m := get_local_mouse_position()
		Art.draw_box(self, _font, _held, m - Vector2(CELL, CELL) * 0.5 + Vector2(0, sin(_time * 6.0) * 3), CELL, 0.9)


func _draw_pointer() -> void:
	if _guide == null:
		return
	var t := _guide.target(_shift, _held)
	if t.is_empty():
		return
	var at := Vector2.ZERO
	match t.kind:
		&"slot":
			var i := _shift.queue.find(_queue_box(t.box_id))
			if i < 0:
				return
			var b := _shift.queue[i]
			at = Vector2(_conveyor_rect.position.x + SLOT_PAD + i * SLOT_W + b.size().x * MINI / 2.0, _conveyor_rect.end.y - 34 - MINI / 2.0)
		&"cell":
			at = _cell_rect(t.cell).get_center()
		&"button":
			var btn: Button = _rotate_button if t.name == &"rotate" else _depart_button
			at = btn.get_global_rect().get_center() - global_position
		&"route":
			at = _house_center(1) + Vector2(0, 30)
	var pulse := fmod(_time, 1.0)
	draw_arc(at, 24 + pulse * 30, 0, TAU, 40, Color(Style.LAMP, 1.0 - pulse), 4)
	var bob := 10 + sin(_time * 5.0) * 8
	if t.kind == &"button":
		# 화면 아래쪽 버튼은 손을 뒤집어 위에서 가리킨다.
		draw_set_transform(at - Vector2(0, 34 + bob), PI)
		draw_texture(Art.POINTER, -Art.POINTER_TIP)
		draw_set_transform(Vector2.ZERO)
	else:
		draw_texture(Art.POINTER, at + Vector2(0, bob) - Art.POINTER_TIP)


func _queue_box(id: int) -> Box:
	for b in _shift.queue:
		if b.id == id:
			return b
	return null


func _cell_rect(cell: Vector2i) -> Rect2:
	var y := _shift.bay.height - 1 - cell.y
	return Rect2(_bay_pos + Vector2(cell.x, y) * CELL, Vector2(CELL, CELL))

extends Control
## 테이블 화면(기획서 5장). `Session`으로 진행하고, 자리 0의 `Knowledge`만 그린다.

const C := Cards.Id
const A := Match.Action
const AI_DELAY := 0.7
const CARD_SIZE := Vector2(150, 200)
const LOG_LINES := 8

var session: Session
var _k: Knowledge
var _selected := -1
var _picking_desk := false
var _dragging := false

var _seat_row: HBoxContainer
var _seat_panels := {}
var _envelope: PanelContainer
var _envelope_label: Label
var _target_label: Label
var _desk: PanelContainer
var _desk_box: VBoxContainer
var _hand: HBoxContainer
var _actions: HBoxContainer
var _hint: Label
var _log: Label
var _overlay: Control
var _timer: Timer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var streams: RngStreams = Game.rng if Game.rng != null else RngStreams.new(Game.run_seed)
	session = Session.new(Game.players, streams)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = AI_DELAY
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_build()
	refresh()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_DRAG_BEGIN:
			_dragging = true
			_paint_zones()
		NOTIFICATION_DRAG_END:
			_dragging = false
			_paint_zones()


func _on_tick() -> void:
	session.ai_step()
	refresh()


## 상태가 바뀔 때마다 전부 다시 그린다.
func refresh() -> void:
	_k = session.view()
	if not session.waiting_for_human() or not _k.request.is_empty():
		_selected = -1
		_picking_desk = false
	_draw_seats()
	_draw_middle()
	_draw_desk()
	_draw_hand()
	_draw_actions()
	_draw_log()
	_draw_overlay()
	_paint_zones()
	if not session.is_over() and not session.waiting_for_human() and _timer.is_stopped():
		_timer.start()


# ── 배치 ──────────────────────────────────────────────

func _build() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 18)
	margin.add_child(col)

	_seat_row = HBoxContainer.new()
	_seat_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_seat_row.add_theme_constant_override(&"separation", 16)
	col.add_child(_seat_row)
	for s in range(1, _k_players()):
		var p := _zone(Vector2(320, 230))
		p.gui_input.connect(_on_zone_input.bind(A.NOTE, s))
		_forward_drop(p, A.NOTE, s)
		_seat_row.add_child(p)
		_seat_panels[s] = p

	var mid := HBoxContainer.new()
	mid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mid.add_theme_constant_override(&"separation", 40)
	col.add_child(mid)
	_target_label = _text(36, true)
	_target_label.custom_minimum_size = Vector2(380, 0)
	_target_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_target_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mid.add_child(_target_label)
	_envelope = _zone(Vector2(420, 260))
	_envelope.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_envelope.gui_input.connect(_on_zone_input.bind(A.ENVELOPE, -1))
	_forward_drop(_envelope, A.ENVELOPE, -1)
	_envelope_label = _text(34, true)
	_envelope_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_envelope_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_envelope.add_child(_envelope_label)
	mid.add_child(_envelope)
	_log = _text(22)
	_log.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mid.add_child(_log)

	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 24)
	col.add_child(bottom)
	_desk = _zone(Vector2(360, CARD_SIZE.y))
	_desk.gui_input.connect(_on_zone_input.bind(A.PLAY, -1))
	_forward_drop(_desk, A.PLAY, -1)
	_desk_box = VBoxContainer.new()
	_desk.add_child(_desk_box)
	bottom.add_child(_desk)
	_hand = HBoxContainer.new()
	_hand.add_theme_constant_override(&"separation", 12)
	_hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(_hand)

	var bar := HBoxContainer.new()
	bar.add_theme_constant_override(&"separation", 16)
	col.add_child(bar)
	_hint = _text(24)
	_hint.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.add_child(_hint)
	_actions = HBoxContainer.new()
	_actions.add_theme_constant_override(&"separation", 12)
	bar.add_child(_actions)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


func _k_players() -> int:
	return session.m.players


# ── 그리기 ────────────────────────────────────────────

func _draw_seats() -> void:
	for s in _seat_panels:
		var p: PanelContainer = _seat_panels[s]
		_clear(p)
		var box := VBoxContainer.new()
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		p.add_child(box)
		box.add_child(_text(28, true, _seat_name(s)))
		var info := tr("TABLE_SEAT_INFO") % [_k.hand_counts[s], _k.notes[s].size()]
		if _k.out[s]:
			info += " · " + tr("TABLE_OUT")
		box.add_child(_text(20, false, info))
		for uid in _k.face_up[s]:
			box.add_child(_chip(_k.kind_of(uid)))
		p.modulate.a = 0.55 if _k.out[s] else 1.0


func _draw_middle() -> void:
	_target_label.text = tr("TABLE_TARGET") % _k.target
	_envelope_label.text = "✉\n" + tr("TABLE_ENVELOPE") % _k.envelope.size()


func _draw_desk() -> void:
	_clear(_desk_box)
	_desk_box.add_child(_text(24, true, tr("TABLE_MY_DESK")))
	_desk_box.add_child(_text(20, false, tr("TABLE_MY_NOTES") % _k.notes[Session.HUMAN].size()))
	for uid in _k.face_up[Session.HUMAN]:
		_desk_box.add_child(_chip(_k.kind_of(uid)))


func _draw_hand() -> void:
	_clear(_hand)
	var my_turn := _my_turn()
	for uid in _k.hand:
		var kind := _k.kind_of(uid)
		var b := Button.new()
		b.custom_minimum_size = CARD_SIZE
		b.toggle_mode = true
		b.button_pressed = uid == _selected
		b.add_theme_font_size_override(&"font_size", 22)
		var sub := tr("CARD_AMOUNT") % Cards.amount(kind) if Cards.playable(kind) else tr("CARD_LOCKED")
		b.text = "%s\n\n%s" % [tr(Cards.name_key(kind)), sub]
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.disabled = not my_turn or not Cards.playable(kind)
		if kind == C.THIEF:
			b.add_theme_color_override(&"font_disabled_color", Style.STAMP)
		b.pressed.connect(_on_card_pressed.bind(uid))
		b.set_drag_forwarding(_card_drag.bind(uid, b), Callable(), Callable())
		_hand.add_child(b)


func _draw_actions() -> void:
	_clear(_actions)
	if session.is_over():
		_hint.text = ""
		return
	if not session.waiting_for_human():
		_hint.text = tr("TABLE_WAIT") % _seat_name(session.m.turn) if session.m.pending.is_empty() else tr("TABLE_WAIT") % _seat_name(session.m.pending[0].seat)
		return
	if not _k.request.is_empty():
		_hint.text = tr("TABLE_ANSWER")
		return
	if _selected < 0:
		_hint.text = tr("TABLE_YOUR_TURN")
		return
	_hint.text = tr("TABLE_PICK_DESK") if _picking_desk else tr("TABLE_SELECTED") % tr(Cards.name_key(_k.kind_of(_selected)))
	_action_button(tr("ACT_PLAY"), func() -> void: _do(A.PLAY, -1))
	_action_button(tr("ACT_ENVELOPE"), func() -> void: _do(A.ENVELOPE, -1))
	_action_button(tr("ACT_NOTE"), func() -> void:
		_picking_desk = true
		refresh())
	_action_button(tr("ACT_CANCEL"), func() -> void:
		_selected = -1
		_picking_desk = false
		refresh())


func _draw_log() -> void:
	var lines: Array[String] = []
	for mv in session.events.slice(-LOG_LINES):
		lines.append(describe(mv))
	_log.text = "\n".join(lines)


func _draw_overlay() -> void:
	_clear(_overlay)
	if session.is_over():
		_show_result(session.result())
	elif session.waiting_for_human() and not _k.request.is_empty():
		_show_request(_k.request)


func _show_request(req: Dictionary) -> void:
	var list := _dialog()
	list.add_child(_text(22, false, tr("REQ_BY") % [_seat_name(req.by), tr(Cards.name_key(req.kind))]))
	list.add_child(_text(30, true, tr("REQ_%s" % req.ask)))
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(640, mini(560, req.options.size() * 72))
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var opts := VBoxContainer.new()
	opts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(opts)
	list.add_child(scroll)
	for o in req.options:
		var b := Button.new()
		b.text = option_text(req.ask, o)
		b.custom_minimum_size = Vector2(0, 60)
		b.add_theme_font_size_override(&"font_size", 24)
		b.pressed.connect(func() -> void:
			session.answer(o)
			refresh())
		opts.add_child(b)


func _show_result(r: Dictionary) -> void:
	var list := _dialog()
	list.add_child(_text(40, true, tr("RESULT_TITLE")))
	var fund_key := "RESULT_FUND_OK" if r.funded else "RESULT_FUND_FAIL"
	list.add_child(_text(26, false, tr(fund_key) % [r.fund, r.target]))
	for s in _k_players():
		var role: int = r.roles[s]
		var row := tr("RESULT_ROW") % [_seat_name(s), tr(Cards.name_key(role)) if role >= 0 else "-", r.suspicion[s]]
		if r.confined[s]:
			row += " · " + tr("RESULT_CONFINED")
		var l := _text(24, s in r.winners, row)
		if s in r.winners:
			l.add_theme_color_override(&"font_color", Style.STAMP)
		list.add_child(l)
	if r.winners.is_empty():
		list.add_child(_text(28, true, tr("RESULT_NOBODY")))
	else:
		var names := PackedStringArray()
		for s in r.winners:
			names.append(_seat_name(s))
		list.add_child(_text(28, true, tr("RESULT_WINNERS") % ", ".join(names)))
	if r.no_thief:
		list.add_child(_text(22, false, tr("RESULT_NO_THIEF")))
	var again := Button.new()
	again.text = tr("RESULT_AGAIN")
	again.theme_type_variation = &"AccentButton"
	again.custom_minimum_size = Vector2(0, 64)
	again.add_theme_font_size_override(&"font_size", 26)
	again.pressed.connect(func() -> void: Game.start_match())
	list.add_child(again)
	var back := Button.new()
	back.text = tr("BACK_TO_TITLE")
	back.custom_minimum_size = Vector2(0, 64)
	back.add_theme_font_size_override(&"font_size", 26)
	back.pressed.connect(func() -> void: Game.goto(&"title"))
	list.add_child(back)


## 놓을 수 있는 곳을 빛낸다(끄는 중이거나 카드를 골랐을 때).
func _paint_zones() -> void:
	if _k == null:
		return
	var active := _my_turn() and (_dragging or _selected >= 0)
	for s in _seat_panels:
		_paint(_seat_panels[s], active, s == session.m.turn and not session.is_over())
	_paint(_envelope, active and not _picking_desk, false)
	_paint(_desk, active and not _picking_desk, session.m.turn == Session.HUMAN and not session.is_over())


func _paint(p: PanelContainer, lit: bool, turn: bool) -> void:
	var bg := Color(Style.PARTITION, 0.45) if lit else Color.WHITE
	var border := Style.STAMP if turn else Color(Style.INK, 0.3)
	p.add_theme_stylebox_override(&"panel", _pad(Style.box(bg, 14, border, 4 if turn else 2)))


# ── 문구 ──────────────────────────────────────────────

func describe(mv: Dictionary) -> String:
	var who := _seat_name(mv.seat)
	match mv.action:
		A.PLAY:
			return tr("LOG_PLAY") % [who, tr(Cards.name_key(_k.kind_of(mv.card)))]
		A.ENVELOPE:
			return tr("LOG_ENVELOPE") % who
	return tr("LOG_NOTE") % [who, _seat_name(mv.to)]


func option_text(ask: StringName, o: Variant) -> String:
	match ask:
		&"PEEK_HAND", &"SWAP_TARGET", &"DRAW_FROM":
			return _seat_name(o)
		&"MISER_TAKE":
			return tr("OPT_SLOT") % (o + 1)
		&"CLAIM":
			return tr("OPT_CLAIM_YES") if o else tr("OPT_CLAIM_NO")
		&"NOTE_MOVE":
			return tr("OPT_NOTE_MOVE") % [_seat_name(_note_owner(o.note)), _seat_name(o.to)]
		&"TAKE_FACE_UP":
			return tr("OPT_FACE_UP") % [_seat_name(_face_up_owner(o)), tr(Cards.name_key(_k.kind_of(o)))]
		&"ENVELOPE_SWAP":
			return tr("OPT_ENVELOPE_SWAP") % [o.slot + 1, tr(Cards.name_key(_k.kind_of(o.card)))]
	return tr(Cards.name_key(_k.kind_of(o)))


func _seat_name(s: int) -> String:
	return tr("SEAT_%d" % s)


func _note_owner(uid: int) -> int:
	for s in _k_players():
		if uid in _k.notes[s]:
			return s
	return -1


func _face_up_owner(uid: int) -> int:
	for s in _k_players():
		if uid in _k.face_up[s]:
			return s
	return -1


# ── 입력 ──────────────────────────────────────────────

func _my_turn() -> bool:
	return session.waiting_for_human() and _k.request.is_empty()


func _on_card_pressed(uid: int) -> void:
	_selected = -1 if _selected == uid else uid
	_picking_desk = false
	refresh()


func _card_drag(_at: Vector2, uid: int, b: Button) -> Variant:
	if b.disabled:
		return null
	var preview := Label.new()
	preview.text = tr(Cards.name_key(_k.kind_of(uid)))
	preview.add_theme_font_size_override(&"font_size", 28)
	preview.add_theme_stylebox_override(&"normal", _pad(Style.box(Style.PAPER, 10, Style.INK, 2)))
	b.set_drag_preview(preview)
	return { uid = uid }


func _forward_drop(p: Control, action: Match.Action, to: int) -> void:
	p.set_drag_forwarding(Callable(),
		func(_at: Vector2, data: Variant) -> bool:
			return data is Dictionary and data.has(&"uid") and session.can_play(_move(data.uid, action, to)),
		func(_at: Vector2, data: Variant) -> void:
			_selected = data.uid
			_do(action, to))


func _on_zone_input(event: InputEvent, action: Match.Action, to: int) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT or _selected < 0:
		return
	if _picking_desk and action != A.NOTE:
		return
	_do(action, to)


func _do(action: Match.Action, to: int) -> void:
	if _selected < 0:
		return
	if session.play(_move(_selected, action, to)):
		_selected = -1
		_picking_desk = false
	refresh()


func _move(uid: int, action: Match.Action, to: int) -> Dictionary:
	var mv := { seat = Session.HUMAN, card = uid, action = action }
	if action == A.NOTE:
		mv.to = to
	return mv


# ── 작은 부품 ─────────────────────────────────────────

func _zone(min_size: Vector2) -> PanelContainer:
	var p := PanelContainer.new()
	p.custom_minimum_size = min_size
	p.mouse_filter = Control.MOUSE_FILTER_STOP
	return p


func _text(size: int, bold := false, value := "") -> Label:
	var l := Label.new()
	l.text = value
	l.add_theme_font_size_override(&"font_size", size)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if bold:
		l.add_theme_font_override(&"font", Style.bold())
	return l


func _chip(kind: int) -> Label:
	var l := _text(20, false, tr(Cards.name_key(kind)))
	l.add_theme_stylebox_override(&"normal", _pad(Style.box(Color(Style.KRAFT, 0.35), 8), 6))
	return l


func _action_button(label: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(150, 60)
	b.add_theme_font_size_override(&"font_size", 24)
	b.pressed.connect(on_pressed)
	_actions.add_child(b)


func _dialog() -> VBoxContainer:
	var shade := ColorRect.new()
	shade.color = Color(Style.INK, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", _pad(Style.box(Style.PAPER, 16, Style.INK, 2), 28))
	center.add_child(panel)
	var list := VBoxContainer.new()
	list.add_theme_constant_override(&"separation", 14)
	panel.add_child(list)
	return list


func _pad(sb: StyleBoxFlat, px := 16) -> StyleBoxFlat:
	sb.set_content_margin_all(px)
	return sb


func _clear(n: Node) -> void:
	for c in n.get_children():
		n.remove_child(c)
		c.queue_free()

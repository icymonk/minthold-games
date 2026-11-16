extends Control
## 테이블 화면(기획서 5장). `Session`으로 진행하고, 자리 0의 `Knowledge`만 그린다.

const C := Cards.Id
const A := Match.Action
const AI_DELAY := 0.7
const CARD_SIZE := Vector2(150, 200)
const LOG_LINES := 8
const RESULT_STEPS := 3
## 화면 위에서 바로 고르는 결정 요청. 나머지는 보기 목록 창으로 받는다.
const SEAT_ASKS := [&"PEEK_HAND", &"SWAP_TARGET", &"DRAW_FROM"]
const HAND_ASKS := [&"SWAP_GIVE", &"PASS", &"GIVE_BACK"]
const BOARD_ASKS := [&"TAKE_FACE_UP", &"MISER_TAKE"]

var session: Session
var _k: Knowledge
var _selected := -1
var _picking_desk := false
var _dragging := false

var _seat_row: HBoxContainer
var _seat_panels := {}
var _envelope: PanelContainer
var _envelope_label: Label
var _slots: HFlowContainer
var _banner: Label
var _shown_events := 0
var result_step := 0
var recorded := false
var league_points := 0
var help: HelpPanel
var _target_label: Label
var _desk: PanelContainer
var _desk_box: VBoxContainer
var _hand: HBoxContainer
var _actions: HBoxContainer
var _hint: Label
var _log: Label
var _overlay: Control
var _timer: Timer
var _was_my_turn := false
var _sounded_step := -1


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
	if help.visible:
		_timer.start()
		return
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
	var mine := session.waiting_for_human() and not session.is_over()
	if mine and not _was_my_turn:
		Sfx.play(&"turn")
	_was_my_turn = mine
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
	var env_art := Control.new()
	env_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env_art.draw.connect(func() -> void: Art.envelope(env_art, Rect2(Vector2.ZERO, env_art.size)))
	env_art.resized.connect(env_art.queue_redraw)
	_envelope.add_child(env_art)
	var env_box := VBoxContainer.new()
	env_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	env_box.alignment = BoxContainer.ALIGNMENT_END
	env_box.add_child(_envelope_label)
	_slots = HFlowContainer.new()
	_slots.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_slots.alignment = FlowContainer.ALIGNMENT_CENTER
	env_box.add_child(_slots)
	_envelope.add_child(env_box)
	mid.add_child(_envelope)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	right.add_theme_constant_override(&"separation", 12)
	mid.add_child(right)
	_banner = _text(32, true)
	_banner.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_banner)
	_log = _text(22)
	_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_log.modulate = Color(1, 1, 1, 0.75)
	right.add_child(_log)

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

	var help_button := Button.new()
	help_button.text = tr("TABLE_HELP")
	help_button.custom_minimum_size = Vector2(64, 64)
	help_button.add_theme_font_size_override(&"font_size", 30)
	help_button.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	help_button.offset_left = -84
	help_button.offset_right = -20
	help_button.offset_top = 20
	help_button.offset_bottom = 84
	help_button.pressed.connect(func() -> void: help.open())
	add_child(help_button)
	help = HelpPanel.new()
	help.closed.connect(refresh)
	add_child(help)
	if not Game.seen_intro:
		help.open(&"FIRST")
		Game.mark_intro_seen()


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
		var head := HBoxContainer.new()
		head.mouse_filter = Control.MOUSE_FILTER_IGNORE
		head.add_theme_constant_override(&"separation", 10)
		head.add_child(Portrait.new(s, -1, 64))
		var who := VBoxContainer.new()
		who.mouse_filter = Control.MOUSE_FILTER_IGNORE
		who.add_child(_text(28, true, _seat_name(s)))
		var info := tr("TABLE_SEAT_INFO") % [_k.hand_counts[s], _k.notes[s].size()]
		if _k.out[s]:
			info += " · " + tr("TABLE_OUT")
		who.add_child(_text(20, false, info))
		head.add_child(who)
		box.add_child(head)
		_add_face_up(box, s)
		_add_notes(box, s)
		var seen := seen_in_hand(s)
		if not seen.is_empty():
			box.add_child(_text(20, false, tr("TABLE_SEEN") % ", ".join(seen)))
		p.modulate.a = 0.55 if _k.out[s] else 1.0
		if _asking(SEAT_ASKS) and not s in _k.request.options:
			p.modulate.a = 0.35


func _draw_middle() -> void:
	_target_label.text = tr("TABLE_TARGET") % money(_k.target)
	_envelope_label.text = tr("TABLE_ENVELOPE") % _k.envelope.size()
	_clear(_slots)
	var picking := _asking([&"MISER_TAKE"])
	for i in _k.envelope.size():
		var kind := _k.kind_of(_k.envelope[i])
		var label := "%d" % (i + 1) if kind < 0 else "%d %s" % [i + 1, tr(Cards.name_key(kind))]
		if picking:
			_slots.add_child(_pick_button(label, i))
		else:
			_slots.add_child(_chip_text(label, kind >= 0))


func _draw_desk() -> void:
	_clear(_desk_box)
	_desk_box.add_child(_text(24, true, tr("TABLE_MY_DESK")))
	_desk_box.add_child(_text(20, false, tr("TABLE_MY_NOTES") % _k.notes[Session.HUMAN].size()))
	_add_face_up(_desk_box, Session.HUMAN)
	_add_notes(_desk_box, Session.HUMAN)
	if _k.thief_hint != Match.NO_HINT:
		var who := tr("TABLE_HINT_NONE") if _k.thief_hint < 0 else _seat_name(_k.thief_hint)
		var hint := _text(20, true, tr("TABLE_HINT") % who)
		hint.add_theme_color_override(&"font_color", Style.STAMP)
		_desk_box.add_child(hint)


func _draw_hand() -> void:
	_clear(_hand)
	var my_turn := _my_turn()
	for uid in _k.hand:
		var kind := _k.kind_of(uid)
		var b := Button.new()
		b.custom_minimum_size = CARD_SIZE
		b.toggle_mode = true
		b.button_pressed = uid == _selected
		var sub := money(Cards.amount(kind)) if Cards.playable(kind) else tr("CARD_LOCKED")
		b.accessibility_name = "%s, %s" % [tr(Cards.name_key(kind)), sub]
		b.tooltip_text = HelpPanel.ability(kind)
		for st in [&"normal", &"hover", &"pressed", &"disabled", &"hover_pressed"]:
			b.add_theme_stylebox_override(st, StyleBoxEmpty.new())
		var face := CardFace.new(kind, tr(Cards.name_key(kind)), sub, Style.STAMP if kind == C.THIEF else Style.INK)
		b.disabled = not my_turn or not Cards.playable(kind)
		if _asking(HAND_ASKS):
			b.disabled = not uid in _k.request.options
		face.lit = _asking(HAND_ASKS) and not b.disabled
		b.add_child(face)
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
		var req := _k.request
		_hint.text = "%s · %s" % [tr("REQ_BY") % [_seat_name(req.by), tr(Cards.name_key(req.kind))], tr("REQ_%s" % req.ask)]
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
	if session.events.size() > _shown_events:
		_shown_events = session.events.size()
		var last: Dictionary = session.events[-1]
		_banner.text = describe(last)
		_sound_for(last)
		if last.seat != Session.HUMAN:
			_flash(_banner)
			if _seat_panels.has(last.seat):
				_flash(_seat_panels[last.seat])


func _draw_overlay() -> void:
	_clear(_overlay)
	if session.is_over():
		if not recorded:
			recorded = true
			league_points = Game.record(session.result(), Session.HUMAN)
		_show_result(session.result())
	elif session.waiting_for_human() and not _k.request.is_empty() and not _on_board(_k.request.ask):
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


## 결산 연출(기획서 2.1): 봉투 개봉 → 감사 → 정체 공개를 한 단계씩.
func _show_result(r: Dictionary) -> void:
	var list := _dialog()
	list.custom_minimum_size = Vector2(760, 0)
	if _sounded_step != result_step:
		_sounded_step = result_step
		_result_sound(r)
	list.add_child(_text(22, false, tr("RESULT_STEP") % [result_step + 1, RESULT_STEPS]))
	match result_step:
		0:
			list.add_child(_text(40, true, tr("RESULT_OPEN")))
			var total := 0
			var row := HFlowContainer.new()
			for kind in r.envelope_kinds:
				total += Cards.amount(kind)
				row.add_child(_chip_text("%s %s" % [tr(Cards.name_key(kind)), money(Cards.amount(kind))], true))
			list.add_child(row)
			list.add_child(_stamp(tr("RESULT_FUND_OK" if r.funded else "RESULT_FUND_FAIL") % [money(r.fund), money(r.target)], r.funded))
		1:
			list.add_child(_text(40, true, tr("RESULT_AUDIT")))
			for s in _k_players():
				var parts := PackedStringArray()
				for kind in r.note_kinds[s]:
					parts.append("%d" % Cards.amount(kind))
				var line := tr("RESULT_AUDIT_ROW") % [_seat_name(s), r.suspicion[s], " + ".join(parts) if not parts.is_empty() else "-"]
				if r.confined[s]:
					list.add_child(_stamp(line + " · " + tr("RESULT_CONFINED"), false))
				else:
					list.add_child(_text(24, false, line))
			if not r.confined.has(true):
				list.add_child(_text(24, true, tr("RESULT_NOBODY_CAUGHT")))
		_:
			list.add_child(_text(40, true, tr("RESULT_REVEAL")))
			for s in _k_players():
				var role: int = r.roles[s]
				var line := tr("RESULT_ROW") % [_seat_name(s), tr(Cards.name_key(role)) if role >= 0 else "-", tr("WIN_%s" % Cards.Win.keys()[Cards.win(role)]) if role >= 0 else ""]
				if s in r.winners:
					list.add_child(_stamp(line, true))
				else:
					list.add_child(_text(24, false, line))
			list.add_child(_text(30, true, ending_text(r)))
			if r.no_thief:
				list.add_child(_text(22, false, tr("RESULT_NO_THIEF")))
			if Session.HUMAN in r.winners:
				list.add_child(_stamp(tr("RESULT_YOU_WIN"), true))
			else:
				list.add_child(_text(26, true, tr("RESULT_YOU_LOSE")))
			if Game.league != null:
				list.add_child(_text(26, true, tr("LEAGUE_STATUS") % [Game.league.played(), League.GAMES, league_points, Game.league.total()]))
				if Game.league.done():
					list.add_child(_stamp(tr("LEAGUE_DONE") % [Game.league.total(), Game.records.best], true))
	if result_step < RESULT_STEPS - 1:
		_dialog_button(list, tr("RESULT_NEXT"), func() -> void:
			result_step += 1
			refresh(), true)
		return
	if Game.league != null and not Game.league.done():
		_dialog_button(list, tr("LEAGUE_NEXT"), func() -> void: Game.start_match(), true)
	elif Game.league != null:
		_dialog_button(list, tr("LEAGUE_AGAIN"), Game.start_league, true)
	else:
		_dialog_button(list, tr("RESULT_AGAIN"), func() -> void: Game.start_match(), true)
		_dialog_button(list, tr("RESULT_SAME_SEED"), func() -> void: Game.start_match(Game.run_seed))
	_dialog_button(list, tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title"))


func _sound_for(mv: Dictionary) -> void:
	match mv.action:
		A.ENVELOPE:
			Sfx.play(&"rustle")
			_bump(_envelope)
		A.NOTE:
			Sfx.play(&"peel")
		_:
			Sfx.play(&"card")


func _result_sound(r: Dictionary) -> void:
	match result_step:
		0:
			Sfx.play(&"stamp")
		1:
			if r.confined.has(true):
				Sfx.play(&"stamp")
		_:
			Sfx.play(&"win" if Session.HUMAN in r.winners else &"lose")


func ending_text(r: Dictionary) -> String:
	if r.winners.is_empty():
		return tr("RESULT_NOBODY")
	var names := PackedStringArray()
	for s in r.winners:
		names.append(_seat_name(s))
	return tr("RESULT_WINNERS") % ", ".join(names)


func _stamp(value: String, good: bool) -> Label:
	var l := _text(26, true, value)
	l.add_theme_color_override(&"font_color", Color.WHITE)
	l.add_theme_stylebox_override(&"normal", _pad(Style.box(Style.PARTITION.darkened(0.35) if good else Style.STAMP, 8), 10))
	l.resized.connect(func() -> void: l.pivot_offset = l.size / 2)
	l.scale = Vector2(1.6, 1.6)
	l.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(l, ^"scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, ^"modulate:a", 1.0, 0.12)
	return l


func _dialog_button(list: Container, label: String, on_pressed: Callable, accent := false) -> void:
	var b := Button.new()
	b.text = label
	if accent:
		b.theme_type_variation = &"AccentButton"
	b.custom_minimum_size = Vector2(0, 64)
	b.add_theme_font_size_override(&"font_size", 26)
	b.pressed.connect(on_pressed)
	list.add_child(b)


## 놓을 수 있는 곳을 빛낸다(끄는 중이거나 카드를 골랐을 때).
func _paint_zones() -> void:
	if _k == null:
		return
	var active := _my_turn() and (_dragging or _selected >= 0)
	for s in _seat_panels:
		var lit: bool = active or (_asking(SEAT_ASKS) and s in _k.request.options)
		_paint(_seat_panels[s], lit, s == session.m.turn and not session.is_over())
	_paint(_envelope, (active and not _picking_desk) or _asking([&"MISER_TAKE"]), false, Color(0, 0, 0, 0))
	_paint(_desk, active and not _picking_desk, session.m.turn == Session.HUMAN and not session.is_over())


func _paint(p: PanelContainer, lit: bool, turn: bool, base := Color.WHITE) -> void:
	var bg := Color(Style.PARTITION, 0.45) if lit else base
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
			var owner := _note_owner(o.note)
			var nth: int = _k.notes[owner].find(o.note) + 1
			return tr("OPT_NOTE_MOVE") % [_seat_name(owner), nth, _seat_name(_k.placed_by.get(o.note, owner)), _seat_name(o.to)]
		&"TAKE_FACE_UP":
			return tr("OPT_FACE_UP") % [_seat_name(_face_up_owner(o)), tr(Cards.name_key(_k.kind_of(o)))]
		&"ENVELOPE_SWAP":
			return tr("OPT_ENVELOPE_SWAP") % [o.slot + 1, tr(Cards.name_key(_k.kind_of(o.card)))]
	return tr(Cards.name_key(_k.kind_of(o)))


func money(n: int) -> String:
	return HelpPanel.money(n)


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
	if _asking(HAND_ASKS):
		_answer(uid)
		return
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
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	if action == A.NOTE and _asking(SEAT_ASKS):
		if to in _k.request.options:
			_answer(to)
		return
	if _selected < 0:
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


func _answer(choice: Variant) -> void:
	session.answer(choice)
	refresh()


## 지금 사람에게 온 요청이 asks 중 하나인가.
func _asking(asks: Array) -> bool:
	return not _k.request.is_empty() and session.waiting_for_human() and _k.request.ask in asks


func _on_board(ask: StringName) -> bool:
	return ask in SEAT_ASKS or ask in HAND_ASKS or ask in BOARD_ASKS


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
	var l := _chip_text(tr(Cards.name_key(kind)), true)
	var sb: StyleBoxFlat = l.get_theme_stylebox(&"normal")
	sb.border_color = Art.band(kind)
	sb.border_width_left = 8
	sb.content_margin_left += 6
	return l


func _chip_text(value: String, known: bool) -> Label:
	var l := _text(20, false, value)
	var bg := Color(Style.KRAFT, 0.35) if known else Color(Style.INK, 0.08)
	l.add_theme_stylebox_override(&"normal", _pad(Style.box(bg, 8), 6))
	return l


func _pick_button(value: String, choice: Variant) -> Button:
	var b := Button.new()
	b.text = value
	b.add_theme_font_size_override(&"font_size", 20)
	b.add_theme_stylebox_override(&"normal", Style.box(Color(Style.PARTITION, 0.45), 8, Style.INK, 2))
	b.pressed.connect(_answer.bind(choice))
	return b


func _add_face_up(box: Container, s: int) -> void:
	var row := HFlowContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for uid in _k.face_up[s]:
		var card_name := tr(Cards.name_key(_k.kind_of(uid)))
		if _asking([&"TAKE_FACE_UP"]) and uid in _k.request.options:
			row.add_child(_pick_button(card_name, uid))
		else:
			row.add_child(_chip(_k.kind_of(uid)))
	box.add_child(row)


## 받은 쪽지: 아는 카드는 금액, 모르는 카드는 "?".
func _add_notes(box: Container, s: int) -> void:
	if _k.notes[s].is_empty():
		return
	var row := HFlowContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"h_separation", 6)
	row.add_child(_text(20, false, tr("TABLE_NOTE_PILE") % ""))
	for uid in _k.notes[s]:
		var kind := _k.kind_of(uid)
		var note := _text(20, true, "?" if kind < 0 else "%d" % Cards.amount(kind))
		note.custom_minimum_size = Vector2(34, 34)
		note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		note.add_theme_color_override(&"font_color", Color.WHITE)
		note.add_theme_stylebox_override(&"normal", Style.box(Style.STAMP, 3))
		row.add_child(note)
	box.add_child(row)


## 그 자리 손에 있는 걸 본(엿본·건넨) 카드. 지금도 거기 있다는 보장은 없다.
func seen_in_hand(s: int) -> PackedStringArray:
	var out := PackedStringArray()
	for uid in _k.located:
		if _k.located[uid] == s and _k.kind_of(uid) >= 0 and _holding_maybe(s, uid):
			out.append(tr(Cards.name_key(_k.kind_of(uid))))
	return out


func _holding_maybe(s: int, uid: int) -> bool:
	if uid in _k.envelope or uid in _k.hand:
		return false
	for p in _k_players():
		if uid in _k.face_up[p] or uid in _k.notes[p]:
			return false
	return _k.hand_counts[s] > 0


## 봉투에 카드가 들어가면 살짝 부푼다.
func _bump(c: Control) -> void:
	c.pivot_offset = c.size / 2
	c.scale = Vector2(1.06, 1.06)
	create_tween().tween_property(c, ^"scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _flash(c: CanvasItem) -> void:
	var base := c.modulate
	c.modulate = Color(1.25, 1.1, 0.8, base.a)
	create_tween().tween_property(c, ^"modulate", base, 0.6)


func _action_button(label: String, on_pressed: Callable) -> void:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(180, 60)
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

extends Control
## 테이블 화면(기획서 6장). `Session`으로 진행하고, 사람 쪽 `Knowledge`만 그린다.

const A := Match.Action
const S := Match.Side
const AI_DELAY := 0.6
const CARD_SIZE := Vector2(104, 140)
const CELL_SIZE := Vector2(38, 34)
const LOG_LINES := 9
const FLIP_TIME := 0.35
const BANNER_TIME := 1.6

var session: Session
var _k: Knowledge
var _picked: Array[int] = []
## 팀장이 직접 지운 번호.
var marks := {}
var _mark_mode := false
var _shown_history := 0
var _flipped := {}

var _clock: HBoxContainer
var _decks: HBoxContainer
var _row: HFlowContainer
var _memo_box: VBoxContainer
var _memo: GridContainer
var _mark_btn: Button
var _warn: Label
var _banner: Label
var _hand: HFlowContainer
var _status: Label
var _log: Label
var _pass: Button
var _guess: Button
var _overlay: Control
var _timer: Timer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var streams: RngStreams = Game.rng if Game.rng != null else RngStreams.new(Game.run_seed)
	session = Session.new(Game.side(), streams)
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.wait_time = AI_DELAY
	_timer.timeout.connect(_on_tick)
	add_child(_timer)
	_build()
	refresh()


func _on_tick() -> void:
	session.ai_step()
	refresh()


## 상태가 바뀔 때마다 전부 다시 그린다.
func refresh() -> void:
	_k = session.view()
	if not session.waiting_for_human():
		_picked.clear()
	else:
		_picked.assign(_picked.filter(func(n: int) -> bool: return not _is_revealed(n)))
	_announce()
	_draw_clock()
	_draw_decks()
	_draw_row()
	_draw_memo()
	_draw_hand()
	_draw_actions()
	_draw_log()
	_draw_overlay()
	if not session.is_over() and not session.waiting_for_human() and _timer.is_stopped():
		_timer.start()


## 기록 줄 한 줄. 사람 쪽이 모르는 번호는 쓰지 않는다.
func describe(rec: Dictionary) -> String:
	var me := session.human
	match rec.action:
		A.DRAW:
			var who := _side_name(rec.side)
			var zone := tr("ZONE_%d" % rec.zone)
			if rec.side == me:
				return tr("LOG_DRAW_SEEN") % [who, zone, _time(rec.card)]
			return tr("LOG_DRAW_HIDDEN") % [who, zone]
		A.PLACE:
			if rec.card == Cards.LAST:
				return tr("LOG_ESCAPE")
			var spr: int = rec.get(&"sprints", []).size()
			if me == S.STAFF:
				return tr("LOG_PLACE_SEEN") % [_time(rec.card), spr]
			return tr("LOG_PLACE_HIDDEN") % spr
		A.PASS:
			return tr("LOG_PASS")
		A.GUESS:
			var names := PackedStringArray()
			for n in rec.numbers:
				names.append(_time(n))
			return tr("LOG_GUESS") % [", ".join(names), tr("HIT" if rec.hit else "MISS")]
	return ""


# ── 배치 ──────────────────────────────────────────────

func _build() -> void:
	var bg := Panel.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.add_theme_stylebox_override(&"panel", Style.box(Style.SUNLIGHT, 0))
	add_child(bg)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 28)
	add_child(margin)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	margin.add_child(col)

	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", 12)
	col.add_child(top)
	top.add_child(_text(tr("CLOCK_TITLE"), 22, true))
	top.add_child(_text(Cards.time_text(0), 22))
	_clock = HBoxContainer.new()
	_clock.add_theme_constant_override(&"separation", 2)
	top.add_child(_clock)
	top.add_child(_text(Cards.time_text(Cards.LAST), 22))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var back := Button.new()
	back.text = tr("BACK_TO_TITLE")
	back.add_theme_font_size_override(&"font_size", 20)
	back.pressed.connect(func() -> void: Game.goto(&"title"))
	top.add_child(back)

	var mid := HBoxContainer.new()
	mid.add_theme_constant_override(&"separation", 24)
	col.add_child(mid)
	_decks = HBoxContainer.new()
	_decks.add_theme_constant_override(&"separation", 10)
	mid.add_child(_decks)
	var row_box := VBoxContainer.new()
	row_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row_head := HBoxContainer.new()
	row_head.add_theme_constant_override(&"separation", 24)
	row_head.add_child(_text(tr("ROW_TITLE"), 22, true))
	_banner = _text("", 24, true)
	_banner.modulate.a = 0.0
	row_head.add_child(_banner)
	row_box.add_child(row_head)
	_row = HFlowContainer.new()
	_row.add_theme_constant_override(&"h_separation", 8)
	_row.add_theme_constant_override(&"v_separation", 8)
	row_box.add_child(_row)
	mid.add_child(row_box)

	var low := HBoxContainer.new()
	low.size_flags_vertical = Control.SIZE_EXPAND_FILL
	low.add_theme_constant_override(&"separation", 24)
	col.add_child(low)
	_memo_box = VBoxContainer.new()
	var memo_head := HBoxContainer.new()
	memo_head.add_theme_constant_override(&"separation", 16)
	memo_head.add_child(_text(tr("MEMO_TITLE"), 22, true))
	_mark_btn = Button.new()
	_mark_btn.toggle_mode = true
	_mark_btn.add_theme_font_size_override(&"font_size", 18)
	_mark_btn.toggled.connect(func(on: bool) -> void: set_mark_mode(on))
	memo_head.add_child(_mark_btn)
	_memo_box.add_child(memo_head)
	_memo = GridContainer.new()
	_memo.columns = 14
	_memo.add_theme_constant_override(&"h_separation", 4)
	_memo.add_theme_constant_override(&"v_separation", 4)
	_memo_box.add_child(_memo)
	_warn = _text("", 20)
	_warn.modulate = Style.ALERT
	_memo_box.add_child(_warn)
	low.add_child(_memo_box)
	var log_box := VBoxContainer.new()
	log_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_box.add_child(_text(tr("LOG_TITLE"), 22, true))
	_log = _text("", 20)
	_log.modulate = Color(Style.INK, 0.8)
	log_box.add_child(_log)
	low.add_child(log_box)

	_status = _text("", 28, true)
	col.add_child(_status)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override(&"separation", 16)
	col.add_child(bottom)
	var hand_box := VBoxContainer.new()
	hand_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_box.add_child(_text(tr("HAND_TITLE"), 22, true))
	_hand = HFlowContainer.new()
	_hand.add_theme_constant_override(&"h_separation", 8)
	_hand.add_theme_constant_override(&"v_separation", 8)
	hand_box.add_child(_hand)
	bottom.add_child(hand_box)
	_pass = _big_button(tr("BTN_PASS"), _on_pass)
	bottom.add_child(_pass)
	_guess = _big_button(tr("BTN_GUESS"), _on_guess)
	_guess.theme_type_variation = &"AccentButton"
	bottom.add_child(_guess)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)


# ── 그리기 ────────────────────────────────────────────

func _draw_clock() -> void:
	_clear(_clock)
	var known := {}
	for h in _k.hideouts:
		if h.card != Knowledge.HIDDEN:
			known[h.card] = h.revealed
	for n in Cards.LAST + 1:
		var cell := Panel.new()
		cell.custom_minimum_size = Vector2(CELL_SIZE.x * 0.6, CELL_SIZE.y)
		var color := Color(Style.INK, 0.08)
		if known.has(n):
			color = Style.ALERT if known[n] else Style.PARTITION
		cell.add_theme_stylebox_override(&"panel", Style.box(color, 3))
		cell.tooltip_text = _time(n)
		_clock.add_child(cell)


func _draw_decks() -> void:
	_clear(_decks)
	var can_draw := _moves_of(A.DRAW)
	for z in _k.deck_counts.size():
		var r: Vector2i = Cards.ZONE_RANGES[z]
		var b := Button.new()
		b.custom_minimum_size = Vector2(150, CARD_SIZE.y)
		b.add_theme_font_size_override(&"font_size", 20)
		b.text = tr("DECK_LABEL") % [tr("ZONE_%d" % z), r.x, r.y, _k.deck_counts[z]]
		var mv := _find(can_draw, &"zone", z)
		b.disabled = mv.is_empty()
		b.pressed.connect(_play.bind(mv))
		_decks.add_child(b)


func _draw_row() -> void:
	_clear(_row)
	for i in _k.hideouts.size():
		var h: Dictionary = _k.hideouts[i]
		var card := PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE
		var face: bool = h.revealed
		var bg := Color.WHITE if face else Style.PARTITION
		card.add_theme_stylebox_override(&"panel", Style.box(bg, 10, Color(Style.INK, 0.4), 2))
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		if h.card == Knowledge.HIDDEN:
			box.add_child(_text(tr("CARD_BACK"), 48, true))
		else:
			box.add_child(_text(Cards.time_text(h.card), 26, true))
			box.add_child(_text(str(h.card), 20))
			if not face:
				box.add_child(_text(tr("HIDDEN_MINE"), 16))
		if not h.sprints.is_empty():
			var nums := PackedStringArray()
			for c in h.sprints:
				nums.append(str(c))
			box.add_child(_text(tr("SPRINT_CARDS") % ", ".join(nums), 16))
		elif h.sprint_count > 0:
			box.add_child(_text(tr("SPRINT_COUNT") % h.sprint_count, 16))
		for l in box.get_children():
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(box)
		_row.add_child(card)
		if face and i > 0 and not _flipped.has(i):
			_flipped[i] = true
			card.pivot_offset = CARD_SIZE / 2
			card.scale = Vector2(0, 1)
			card.create_tween().tween_property(card, ^"scale", Vector2.ONE, FLIP_TIME)


func _draw_memo() -> void:
	_memo_box.visible = session.human == S.CHIEF
	if not _memo_box.visible:
		return
	_clear(_memo)
	_mark_btn.set_pressed_no_signal(_mark_mode)
	_mark_btn.text = tr("MEMO_MARK_ON" if _mark_mode else "MEMO_MARK_OFF")
	var can_guess := not _moves_of(A.GUESS).is_empty()
	var open := open_numbers()
	for n in range(1, Cards.LAST):
		var b := Button.new()
		b.custom_minimum_size = CELL_SIZE * Vector2(1.6, 1.4)
		b.add_theme_font_size_override(&"font_size", 18)
		b.text = str(n)
		b.tooltip_text = _time(n)
		b.toggle_mode = true
		b.button_pressed = n in _picked
		var struck := not open.has(n)
		var marked := marks.has(n)
		if struck:
			b.modulate.a = 0.25
		elif marked:
			b.modulate = Color(Style.ALERT, 0.6)
		b.disabled = struck or (not _mark_mode and (not can_guess or marked))
		b.pressed.connect(_on_memo.bind(n))
		_memo.add_child(b)
	_warn.text = tr("MULTI_WARN") % _picked.size() if _picked.size() > 1 else ""


## 뒷면 기록 중 하나라도 될 수 있는 번호(DP 기준, 자동 지우기).
func open_numbers() -> Dictionary:
	var open := {}
	var hidden: Array[int] = []
	for i in _k.hideouts.size():
		if not _k.hideouts[i].revealed:
			hidden.append(i)
	if hidden.is_empty():
		return open
	var d := Deduce.run(_k, null, 0)
	for i in hidden:
		for c in range(1, Cards.LAST):
			if d.possible(i, c):
				open[c] = true
	return open


func _draw_hand() -> void:
	_clear(_hand)
	var places := _moves_of(A.PLACE)
	for c in _sorted(_k.hand):
		var b := Button.new()
		b.custom_minimum_size = CARD_SIZE
		b.add_theme_font_size_override(&"font_size", 20)
		var spr := Cards.sprint_of(c)
		b.text = "%s\n%d" % [Cards.time_text(c), c]
		if spr > 0:
			b.text += "\n" + tr("SPRINT_VALUE") % spr
		var mv := _find(places, &"card", c)
		b.disabled = session.human == S.STAFF and mv.is_empty() and not places.is_empty()
		if not mv.is_empty():
			b.theme_type_variation = &"AccentButton"
			b.pressed.connect(_play.bind(mv))
		_hand.add_child(b)


func _draw_actions() -> void:
	_pass.visible = session.human == S.STAFF
	_pass.disabled = _moves_of(A.PASS).is_empty()
	_guess.visible = session.human == S.CHIEF
	_guess.disabled = _picked.is_empty()
	_guess.text = tr("BTN_GUESS") if _picked.size() <= 1 else tr("BTN_GUESS_N") % _picked.size()
	_status.text = _status_text()


func _status_text() -> String:
	if session.is_over():
		return ""
	if not session.waiting_for_human():
		return tr("STATUS_WAIT") % _side_name(session.m.side)
	var m := session.m
	match m.phase:
		Match.Phase.DRAW:
			return tr("STATUS_DRAW") % m.draws_left
		Match.Phase.MANHUNT:
			return tr("STATUS_MANHUNT")
	if session.human == S.CHIEF:
		return tr("STATUS_GUESS")
	var all_sprints := _k.hand.filter(func(c: int) -> bool: return Cards.sprint_of(c) > 0)
	var range_text := [_time(mini(m.last_card() + 1, Cards.LAST)), _time(mini(m.reach(all_sprints), Cards.LAST))]
	if _moves_of(A.PASS).is_empty():
		return tr("STATUS_PLACE") % range_text
	return tr("STATUS_PLACE_OR_PASS") % range_text


func _draw_log() -> void:
	var lines := PackedStringArray()
	var h := session.m.history
	for i in range(h.size() - 1, maxi(-1, h.size() - 1 - LOG_LINES), -1):
		lines.append(describe(h[i]))
	_log.text = "\n".join(lines)


func _draw_overlay() -> void:
	_clear(_overlay)
	_overlay.visible = session.is_over()
	if not _overlay.visible:
		return
	var shade := ColorRect.new()
	shade.color = Color(Style.INK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.box(Color.WHITE, 16))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 20)
	box.custom_minimum_size = Vector2(640, 0)
	panel.add_child(box)
	var won := session.m.winner == session.human
	box.add_child(_text(tr("RESULT_WIN" if won else "RESULT_LOSE"), 56, true))
	box.add_child(_text(tr("RESULT_STAFF" if session.m.winner == S.STAFF else "RESULT_CHIEF"), 26))
	for l in box.get_children():
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var again := _big_button(tr("RESULT_AGAIN"), func() -> void: Game.start_match())
	again.theme_type_variation = &"AccentButton"
	box.add_child(again)
	box.add_child(_big_button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title")))


# ── 입력 ──────────────────────────────────────────────

func _play(mv: Dictionary) -> void:
	if session.play(mv):
		_picked.clear()
		refresh()


func _on_memo(n: int) -> void:
	if _mark_mode:
		if marks.has(n):
			marks.erase(n)
		else:
			marks[n] = true
		_picked.erase(n)
	elif n in _picked:
		_picked.erase(n)
	elif session.m.phase == Match.Phase.MANHUNT:
		_picked.assign([n])
	else:
		_picked.append(n)
	refresh()


func set_mark_mode(on: bool) -> void:
	_mark_mode = on
	refresh()


## 새로 생긴 짚기 결과를 줄 위에 잠깐 띄운다.
func _announce() -> void:
	var h := session.m.history
	for i in range(_shown_history, h.size()):
		if h[i].action == A.GUESS:
			_banner.text = describe(h[i])
			_banner.modulate = Style.ALERT if h[i].hit else Style.INK
			var tw := _banner.create_tween()
			tw.tween_interval(BANNER_TIME)
			tw.tween_property(_banner, ^"modulate:a", 0.0, 0.4)
	_shown_history = h.size()


func _on_pass() -> void:
	var moves := _moves_of(A.PASS)
	if not moves.is_empty():
		_play(moves[0])


func _on_guess() -> void:
	if not _picked.is_empty():
		var numbers: Array[int] = _picked.duplicate()
		numbers.sort()
		_play({ side = session.human, action = A.GUESS, numbers = numbers })


# ── 도우미 ────────────────────────────────────────────

func _moves_of(action: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	out.assign(session.human_moves().filter(func(mv: Dictionary) -> bool: return mv.action == action))
	return out


func _find(moves: Array[Dictionary], key: StringName, value: int) -> Dictionary:
	for mv in moves:
		if mv[key] == value:
			return mv
	return {}


func _is_revealed(n: int) -> bool:
	for h in _k.hideouts:
		if h.revealed and h.card == n:
			return true
	return false


func _side_name(s: int) -> String:
	return tr("ROLE_STAFF" if s == S.STAFF else "ROLE_CHIEF")


func _time(n: int) -> String:
	return "%s(%d)" % [Cards.time_text(n), n]


func _sorted(a: Array[int]) -> Array[int]:
	var out: Array[int] = a.duplicate()
	out.sort()
	return out


func _clear(node: Node) -> void:
	for c in node.get_children():
		node.remove_child(c)
		c.queue_free()


func _text(s: String, size: int, bold := false) -> Label:
	var l := Label.new()
	l.text = s
	l.add_theme_font_size_override(&"font_size", size)
	if bold:
		l.add_theme_font_override(&"font", Style.bold())
	return l


func _big_button(s: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = s
	b.custom_minimum_size = Vector2(200, 72)
	b.add_theme_font_size_override(&"font_size", 28)
	b.pressed.connect(on_pressed)
	return b

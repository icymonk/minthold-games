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
const POP_TIME := 0.25
const PORTRAIT_SIZE := Vector2(96, 128)

var session: Session
var _k: Knowledge
var _picked: Array[int] = []
## 팀장이 직접 지운 번호.
var marks := {}
var _mark_mode := false
var _shown_history := 0
var _flipped := {}
## 사원이 이번 기록에 함께 낼 뛰기 카드.
var _slot: Array[int] = []

var _clock: HBoxContainer
var _decks: HBoxContainer
var _row: HFlowContainer
var _memo_box: VBoxContainer
var _memo: GridContainer
var _mark_btn: Button
var _warn: Label
var _banner: Label
var _hand: HFlowContainer
var _slot_panel: PanelContainer
var _slot_title: Label
var _slot_cards: HFlowContainer
var _status: Label
var _log: Label
var _pass: Button
var _guess: Button
var _overlay: Control
var _result_row: HFlowContainer
var _result_rules: Button
var _rules: Control
var _tip_panel: PanelContainer
var _tip_label: Label
var _tip_key := &""
var _manhunt_bar: Label
var _timer: Timer
var _deduce: Deduce
var _portrait: TextureRect
var _mute_btn: Button
var _stamp: Label
var _row_shown := 0
## 짚기가 맞거나 틀린 뒤 잠깐 보여 줄 자세.
var _reaction := &""


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var streams: RngStreams = Game.rng if Game.rng != null else RngStreams.new(Game.run_seed)
	session = Session.new(Game.side(), streams, Game.level, Game.events)
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
	_deduce = null
	if not session.waiting_for_human():
		_picked.clear()
	else:
		_picked.assign(_picked.filter(func(n: int) -> bool: return not _is_revealed(n)))
	if not _staff_acting():
		_slot.clear()
	else:
		_slot.assign(_slot.filter(func(c: int) -> bool: return c in _k.hand))
	_announce()
	_draw_clock()
	_draw_decks()
	_draw_row()
	_draw_memo()
	_draw_hand()
	_draw_actions()
	_draw_log()
	_draw_tip()
	_draw_overlay()
	_draw_mute()
	_portrait.texture = Art.person(pose())
	if not session.is_over() and not session.waiting_for_human() and _timer.is_stopped():
		_timer.start()


## 기록 줄 한 줄. 사람 쪽이 모르는 번호는 쓰지 않는다.
func describe(rec: Dictionary) -> String:
	var me := session.human
	match rec.action:
		A.DRAW:
			var who := _side_name(rec.side)
			var zone := tr("ZONE_%d" % rec.zone)
			if rec.has(&"event"):
				return tr("LOG_EVENT") % [who, tr("EVENT_%d" % rec.event)] + clue_text(rec)
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
			var line: String = tr("LOG_GUESS") % [", ".join(names), tr("HIT" if rec.hit else "MISS")]
			if rec.has(&"below"):
				line += tr("LOG_BELOW") % [_time(rec.below.number), rec.below.count]
			return line
	return ""


## 사건 단서 한 줄(양쪽 모두 아는 정보).
func clue_text(rec: Dictionary) -> String:
	if not rec.has(&"clue"):
		return ""
	var c: Dictionary = rec.clue
	match rec.event:
		Events.Id.BADGE:
			return tr("CLUE_ZONE") % [c.index, tr("ZONE_%d" % c.zone)]
		Events.Id.CCTV:
			return tr("CLUE_PARITY") % [c.index, tr("ODD" if c.odd else "EVEN")]
		Events.Id.TIP_OFF:
			return tr("CLUE_HAND") % _time(c.card)
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
	var rules_btn := Button.new()
	rules_btn.text = tr("RULES_BTN")
	rules_btn.add_theme_font_size_override(&"font_size", 20)
	rules_btn.pressed.connect(show_rules.bind(true))
	_mute_btn = Button.new()
	_mute_btn.add_theme_font_size_override(&"font_size", 20)
	_mute_btn.pressed.connect(func() -> void:
		Game.toggle_mute()
		_draw_mute())
	top.add_child(_mute_btn)
	top.add_child(rules_btn)
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
	_manhunt_bar = _text(tr("MANHUNT_BANNER"), 26, true)
	_manhunt_bar.modulate = Style.ALERT
	row_head.add_child(_manhunt_bar)
	row_box.add_child(row_head)
	_row = HFlowContainer.new()
	_row.add_theme_constant_override(&"h_separation", 8)
	_row.add_theme_constant_override(&"v_separation", 8)
	_row.mouse_filter = Control.MOUSE_FILTER_PASS
	row_box.add_child(_row)
	row_box.mouse_filter = Control.MOUSE_FILTER_STOP
	row_box.set_drag_forwarding(Callable(), can_drop_row, drop_row)
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

	_tip_panel = PanelContainer.new()
	_tip_panel.add_theme_stylebox_override(&"panel", Style.box(Style.POSTIT, 10))
	var tip_row := HBoxContainer.new()
	tip_row.add_theme_constant_override(&"separation", 16)
	_tip_label = _text("", 22)
	_tip_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_row.add_child(_tip_label)
	var skip := Button.new()
	skip.text = tr("TIP_SKIP")
	skip.add_theme_font_size_override(&"font_size", 18)
	skip.pressed.connect(func() -> void:
		Game.skip_tips()
		refresh())
	tip_row.add_child(skip)
	_tip_panel.add_child(tip_row)
	col.add_child(_tip_panel)
	var status_row := HBoxContainer.new()
	status_row.add_theme_constant_override(&"separation", 16)
	_portrait = Art.picture(null, PORTRAIT_SIZE)
	_portrait.pivot_offset = Vector2(PORTRAIT_SIZE.x / 2, PORTRAIT_SIZE.y)
	var bob := _portrait.create_tween().set_loops()
	bob.tween_property(_portrait, ^"scale", Vector2(1.0, 1.04), 0.6).set_trans(Tween.TRANS_SINE)
	bob.tween_property(_portrait, ^"scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE)
	status_row.add_child(_portrait)
	_status = _text("", 28, true)
	_status.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	status_row.add_child(_status)
	col.add_child(status_row)
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
	hand_box.set_drag_forwarding(Callable(), can_drop_hand, drop_hand)
	bottom.add_child(hand_box)
	_slot_panel = PanelContainer.new()
	_slot_panel.custom_minimum_size = Vector2(CARD_SIZE.x * 2 + 40, 0)
	_slot_panel.add_theme_stylebox_override(&"panel", Style.box(Color(Style.POSTIT, 0.35), 10, Style.POSTIT, 2))
	_slot_panel.set_drag_forwarding(Callable(), can_drop_slot, drop_slot)
	var slot_box := VBoxContainer.new()
	slot_box.mouse_filter = Control.MOUSE_FILTER_PASS
	_slot_title = _text("", 20, true)
	slot_box.add_child(_slot_title)
	_slot_cards = HFlowContainer.new()
	_slot_cards.mouse_filter = Control.MOUSE_FILTER_PASS
	_slot_cards.add_theme_constant_override(&"h_separation", 6)
	_slot_cards.add_theme_constant_override(&"v_separation", 6)
	slot_box.add_child(_slot_cards)
	_slot_panel.add_child(slot_box)
	bottom.add_child(_slot_panel)
	_pass = _big_button(tr("BTN_PASS"), _on_pass)
	bottom.add_child(_pass)
	_guess = _big_button(tr("BTN_GUESS"), _on_guess)
	_guess.theme_type_variation = &"AccentButton"
	bottom.add_child(_guess)

	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.visible = false
	add_child(_overlay)
	_build_rules()


func _build_rules() -> void:
	_rules = Control.new()
	_rules.set_anchors_preset(Control.PRESET_FULL_RECT)
	_rules.visible = false
	add_child(_rules)
	var shade := ColorRect.new()
	shade.color = Color(Style.INK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			show_rules(false))
	_rules.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rules.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.box(Color.WHITE, 16))
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		pad.add_theme_constant_override(side, 28)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 16)
	box.custom_minimum_size = Vector2(900, 0)
	pad.add_child(box)
	box.add_child(_text(tr("RULES_TITLE"), 32, true))
	var body := _text(tr("RULES_BODY") + ("\n" + tr("RULES_EVENTS") if session.m.events_on else ""), 20)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(body)
	box.add_child(_big_button(tr("CLOSE"), show_rules.bind(false)))


func show_rules(on: bool) -> void:
	_rules.visible = on


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
		elif _staff_acting() and n > session.m.last_card() and n <= session.m.reach(_slot):
			color = Style.POSTIT
		cell.add_theme_stylebox_override(&"panel", Style.box(color, 3))
		cell.tooltip_text = _time(n)
		_clock.add_child(cell)


func _draw_decks() -> void:
	_clear(_decks)
	var can_draw := _moves_of(A.DRAW)
	for z in _k.deck_counts.size():
		var r: Vector2i = Cards.ZONE_RANGES[z]
		var b := Button.new()
		b.custom_minimum_size = Vector2(170, CARD_SIZE.y + 60)
		b.add_theme_font_size_override(&"font_size", 18)
		b.text = tr("DECK_LABEL") % [tr("ZONE_%d" % z), r.x, r.y, _k.deck_counts[z]]
		b.icon = Art.ZONES[z]
		b.expand_icon = true
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.add_theme_constant_override(&"icon_max_width", 140)
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
		card.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var face: bool = h.revealed
		var bg := Color.WHITE if face else Style.PARTITION
		var hunted := session.m.phase == Match.Phase.MANHUNT and not face and not session.is_over()
		var edge := Style.box(bg, 10, Style.ALERT, 4) if hunted else Style.box(bg, 10, Color(Style.INK, 0.4), 2)
		card.add_theme_stylebox_override(&"panel", edge)
		var box := VBoxContainer.new()
		box.alignment = BoxContainer.ALIGNMENT_CENTER
		if h.card == Knowledge.HIDDEN:
			box.add_child(Art.picture(Art.EMPTY_CHAIR, Vector2(CARD_SIZE.x - 16, 72)))
			box.add_child(_text(tr("CARD_BACK"), 28, true))
			for cl in _k.clues:
				if cl.get(&"index", -1) == i:
					var tag := tr("ZONE_%d" % cl.zone) if cl.kind == Knowledge.Clue.ZONE else tr("ODD" if cl.odd else "EVEN")
					var clue := _text(tag, 16, true)
					clue.modulate = Style.ALERT
					box.add_child(clue)
			var span := hint_range(i)
			if span.x > 0:
				var hint := _text(tr("RANGE_HINT") % [span.x, span.y], 16)
				hint.modulate = Color(Style.INK, 0.6)
				box.add_child(hint)
		else:
			box.add_child(Art.picture(Art.zone(h.card), Vector2(CARD_SIZE.x - 16, 48)))
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
			if l is Label:
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		card.add_child(box)
		_row.add_child(card)
		if face and i > 0 and not _flipped.has(i):
			_flipped[i] = true
			card.pivot_offset = CARD_SIZE / 2
			card.scale = Vector2(0, 1)
			card.create_tween().tween_property(card, ^"scale", Vector2.ONE, FLIP_TIME)
		elif i >= _row_shown and _row_shown > 0:
			card.pivot_offset = CARD_SIZE / 2
			card.scale = Vector2(0.6, 0.6)
			card.modulate.a = 0.0
			var tw := card.create_tween().set_parallel()
			tw.tween_property(card, ^"scale", Vector2.ONE, POP_TIME).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, ^"modulate:a", 1.0, POP_TIME)
	_row_shown = _k.hideouts.size()


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
## 쉬움에서 팀장에게 보여 주는 뒷면 기록 i의 가능한 번호 범위. 안 보여 줄 때는 (0, 0).
func hint_range(i: int) -> Vector2i:
	if Game.level != Bot.Level.EASY or session.human != S.CHIEF or _k.is_known(i):
		return Vector2i.ZERO
	if _deduce == null:
		_deduce = Deduce.run(_k, null, 0)
	var lo := 0
	var hi := 0
	for c in range(1, Cards.LAST):
		if _deduce.possible(i, c):
			if lo == 0:
				lo = c
			hi = c
	return Vector2i(lo, hi)


func open_numbers() -> Dictionary:
	var open := {}
	var hidden: Array[int] = []
	for i in _k.hideouts.size():
		if not _k.hideouts[i].revealed:
			hidden.append(i)
	if hidden.is_empty():
		return open
	if _deduce == null:
		_deduce = Deduce.run(_k, null, 0)
	var d := _deduce
	for i in hidden:
		for c in range(1, Cards.LAST):
			if d.possible(i, c):
				open[c] = true
	return open


func _draw_hand() -> void:
	_clear(_hand)
	_clear(_slot_cards)
	var staff := session.human == S.STAFF
	var acting := _staff_acting()
	for c in _sorted(_k.hand):
		var b := _card_button(c)
		if c in _slot:
			b.pressed.connect(_unslot.bind(c))
			b.set_drag_forwarding(_drag_card.bind(c), can_drop_slot, drop_slot)
			_slot_cards.add_child(b)
			continue
		var mv := place_move(c) if acting else {}
		b.disabled = staff and mv.is_empty() and not (acting and Cards.sprint_of(c) > 0)
		if not mv.is_empty():
			b.theme_type_variation = &"AccentButton"
			b.pressed.connect(_play.bind(mv))
		if acting:
			b.set_drag_forwarding(_drag_card.bind(c), can_drop_hand, drop_hand)
		_hand.add_child(b)
	_slot_panel.visible = staff
	var bonus := 0
	for c in _slot:
		bonus += Cards.sprint_of(c)
	_slot_title.text = tr("SLOT_TITLE") % bonus if not _slot.is_empty() else tr("SLOT_HINT")


func _card_button(c: int) -> Button:
	var b := Button.new()
	b.custom_minimum_size = CARD_SIZE
	b.pivot_offset = CARD_SIZE / 2
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			b.create_tween().tween_property(b, ^"scale", Vector2(1.06, 1.06), 0.1))
	b.mouse_exited.connect(func() -> void: b.create_tween().tween_property(b, ^"scale", Vector2.ONE, 0.1))
	b.add_theme_font_size_override(&"font_size", 20)
	b.text = "%s\n%d" % [Cards.time_text(c), c]
	if Cards.sprint_of(c) > 0:
		b.text += "\n" + tr("SPRINT_VALUE") % Cards.sprint_of(c)
	return b


func _draw_actions() -> void:
	_pass.visible = session.human == S.STAFF
	_pass.disabled = _moves_of(A.PASS).is_empty()
	_guess.visible = session.human == S.CHIEF
	_guess.disabled = _picked.is_empty()
	_guess.text = tr("BTN_GUESS") if _picked.size() <= 1 else tr("BTN_GUESS_N") % _picked.size()
	_status.text = _status_text()


func _status_text() -> String:
	var notes := effect_notes()
	var s := _base_status()
	return s if notes.is_empty() else s + "  ·  " + "  ·  ".join(notes)


## 지금 차례인 쪽에 걸린 사건 효과.
func effect_notes() -> PackedStringArray:
	var out := PackedStringArray()
	var m := session.m
	if m.is_over():
		return out
	var l: Dictionary = m.limits[m.side]
	for key in [&"no_place", &"one_guess", &"no_draw", &"corridor"]:
		if l.get(key, false):
			out.append(tr("EFFECT_" + String(key).to_upper()))
	if m.bonus() > 0:
		out.append(tr("EFFECT_BONUS") % m.bonus())
	return out


func _base_status() -> String:
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
	var range_text := [_time(mini(m.last_card() + 1, Cards.LAST)), _time(mini(m.reach(_slot), Cards.LAST))]
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
	var pad := MarginContainer.new()
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		pad.add_theme_constant_override(side, 32)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 18)
	box.custom_minimum_size = Vector2(760, 0)
	pad.add_child(box)
	var won := session.m.winner == session.human
	var m := session.m
	var head := HBoxContainer.new()
	head.alignment = BoxContainer.ALIGNMENT_CENTER
	head.add_theme_constant_override(&"separation", 24)
	var staff_won := m.winner == S.STAFF
	head.add_child(Art.picture(Art.person(&"staff_cheer0" if staff_won else &"staff_hurt"), PORTRAIT_SIZE))
	var title := _centered(tr("RESULT_WIN" if won else "RESULT_LOSE"), 56, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	head.add_child(Art.picture(Art.person(&"chief_hurt" if staff_won else &"chief_cheer0"), PORTRAIT_SIZE))
	box.add_child(head)
	_stamp = _centered(tr("STAMP_STAFF" if staff_won else "STAMP_CHIEF"), 44, true)
	_stamp.modulate = Style.ALERT
	_stamp.rotation_degrees = -8.0
	box.add_child(_stamp)
	_stamp.resized.connect(func() -> void: _stamp.pivot_offset = _stamp.size / 2, CONNECT_ONE_SHOT)
	_stamp.scale = Vector2(2.4, 2.4)
	_stamp.create_tween().tween_property(_stamp, ^"scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	box.add_child(_centered(tr("RESULT_STAFF" if m.winner == S.STAFF else "RESULT_CHIEF"), 26))
	var hits := 0
	var misses := 0
	for rec in m.history:
		if rec.action == A.GUESS:
			if rec.hit:
				hits += 1
			else:
				misses += 1
	box.add_child(_centered(tr("RESULT_STATS") % [m.turns[S.STAFF], hits, misses], 22))
	box.add_child(_centered(tr("RESULT_ROW"), 20, true))
	_result_row = HFlowContainer.new()
	_result_row.alignment = FlowContainer.ALIGNMENT_CENTER
	_result_row.add_theme_constant_override(&"h_separation", 6)
	_result_row.add_theme_constant_override(&"v_separation", 6)
	for i in range(1, m.hideouts.size()):
		var h: Dictionary = m.hideouts[i]
		var caught: bool = h.revealed and h.card != Cards.LAST
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(64, 60)
		chip.add_theme_stylebox_override(&"panel", Style.box(Style.ALERT if caught else Style.PARTITION, 8))
		var l := _centered("%s\n%d" % [Cards.time_text(h.card), h.card], 16)
		l.modulate = Color.WHITE
		chip.add_child(l)
		_result_row.add_child(chip)
	box.add_child(_result_row)
	box.add_child(_centered(tr("RESULT_SEED") % Game.run_seed, 16))
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", 12)
	var again := _big_button(tr("RESULT_AGAIN"), func() -> void: Game.start_match())
	again.theme_type_variation = &"AccentButton"
	buttons.add_child(again)
	buttons.add_child(_big_button(tr("RESULT_SAME"), func() -> void: Game.start_match(Game.run_seed)))
	buttons.add_child(_big_button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title")))
	box.add_child(buttons)
	var rules := Button.new()
	rules.text = tr("RULES_BTN")
	rules.add_theme_font_size_override(&"font_size", 20)
	rules.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	rules.pressed.connect(show_rules.bind(true))
	box.add_child(rules)
	_result_rules = rules


func _centered(s: String, size: int, bold := false) -> Label:
	var l := _text(s, size, bold)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l


## 첫 판 안내(기획서 6장). 지금 상황에 맞는 안내 중 아직 안 본 것.
func current_tip() -> StringName:
	if Game.tips_off or not session.waiting_for_human():
		return &""
	var m := session.m
	var key := &""
	match m.phase:
		Match.Phase.DRAW:
			key = &"TIP_STAFF_DRAW" if session.human == S.STAFF else &"TIP_CHIEF_DRAW"
		Match.Phase.MANHUNT:
			key = &"TIP_CHIEF_MANHUNT"
		_:
			if session.human == S.CHIEF:
				key = &"TIP_CHIEF_MEMO"
			elif m.is_first_turn(S.STAFF):
				key = &"TIP_STAFF_FIRST"
			else:
				key = &"TIP_STAFF_SLOT"
	return &"" if Game.tips_seen.has(key) else key


func _draw_tip() -> void:
	_tip_key = current_tip()
	_tip_panel.visible = _tip_key != &""
	_tip_label.text = tr(_tip_key) if _tip_panel.visible else ""
	_manhunt_bar.visible = session.m.phase == Match.Phase.MANHUNT and not session.is_over()


# ── 입력 ──────────────────────────────────────────────

func _play(mv: Dictionary) -> void:
	if session.play(mv):
		if _tip_key != &"":
			Game.mark_tip(_tip_key)
		_picked.clear()
		refresh()


func _staff_acting() -> bool:
	return session.human == S.STAFF and session.waiting_for_human() and session.m.phase == Match.Phase.ACT


## 뛰기 칸의 카드를 함께 내는 기록. 칸이 모자라면 가장 적은 묶음을 쓴다. 못 내면 빈 사전.
func place_move(c: int) -> Dictionary:
	if not _staff_acting() or c in _slot:
		return {}
	var mv := { side = S.STAFF, action = A.PLACE, card = c, sprints = _slot.duplicate() }
	if session.m.is_legal(mv):
		return mv
	return _find(_moves_of(A.PLACE), &"card", c)


func _drag_card(_at: Vector2, c: int) -> Variant:
	if not _staff_acting():
		return null
	var preview := _card_button(c)
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	return { card = c }


func _dragged(data: Variant) -> int:
	if data is Dictionary and data.get(&"card", -1) in _k.hand:
		return data.card
	return -1


func can_drop_row(_at: Vector2, data: Variant) -> bool:
	var c := _dragged(data)
	return c >= 0 and not place_move(c).is_empty()


func drop_row(_at: Vector2, data: Variant) -> void:
	_play(place_move(_dragged(data)))


func can_drop_slot(_at: Vector2, data: Variant) -> bool:
	var c := _dragged(data)
	return _staff_acting() and c >= 0 and Cards.sprint_of(c) > 0 and not c in _slot


func drop_slot(_at: Vector2, data: Variant) -> void:
	if can_drop_slot(_at, data):
		_slot.append(_dragged(data))
		refresh()


func can_drop_hand(_at: Vector2, data: Variant) -> bool:
	return _dragged(data) in _slot


func drop_hand(_at: Vector2, data: Variant) -> void:
	_unslot(_dragged(data))


func _unslot(c: int) -> void:
	_slot.erase(c)
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
	elif session.m.phase == Match.Phase.MANHUNT or session.m.limited(S.CHIEF, &"one_guess"):
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
		_sound_of(h[i])
		_reaction = &""
		if h[i].has(&"event"):
			_banner.text = tr("EVENT_%d" % h[i].event) + " — " + tr("EVENT_%d_DESC" % h[i].event)
			_banner.modulate = Style.INK
			var te := _banner.create_tween()
			te.tween_interval(BANNER_TIME * 1.5)
			te.tween_property(_banner, ^"modulate:a", 0.0, 0.4)
		if h[i].action == A.GUESS:
			_reaction = &"chief_cheer0" if h[i].hit else &"staff_cheer0"
			_banner.text = describe(h[i])
			_banner.modulate = Style.ALERT if h[i].hit else Style.INK
			var tw := _banner.create_tween()
			tw.tween_interval(BANNER_TIME)
			tw.tween_property(_banner, ^"modulate:a", 0.0, 0.4)
	if _shown_history < h.size() and session.is_over():
		Game.sfx(&"stamp", 0.4)
	_shown_history = h.size()


func _sound_of(rec: Dictionary) -> void:
	match rec.action:
		A.DRAW:
			Game.sfx(&"draw")
		A.PASS:
			Game.sfx(&"tick")
		A.PLACE:
			Game.sfx(&"step" if not rec.get(&"sprints", []).is_empty() else &"place")
		A.GUESS:
			Game.sfx(&"ping")
			Game.sfx(&"flip" if rec.hit else &"miss", 0.25)


## 지금 차례인 쪽의 자세. 짚기 직후에는 맞힌 쪽이 기뻐한다.
func pose() -> StringName:
	var m := session.m
	if m.is_over():
		return &"staff_cheer0" if m.winner == S.STAFF else &"chief_cheer0"
	if _reaction != &"":
		return _reaction
	if m.side == S.STAFF:
		if m.phase == Match.Phase.DRAW:
			return &"staff_interact"
		return &"staff_run0" if not _slot.is_empty() else &"staff_idle"
	if m.phase == Match.Phase.MANHUNT:
		return &"chief_talk"
	return &"chief_think" if not _picked.is_empty() else &"chief_idle"


func _draw_mute() -> void:
	_mute_btn.text = tr("SOUND_OFF" if Game.muted else "SOUND_ON")


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

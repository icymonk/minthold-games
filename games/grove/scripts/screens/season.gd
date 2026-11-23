extends ScreenBase
## 계절 화면(2-1): 3D 숲 + 손패·공터·바람 칸을 규칙(Season)에 연결한다.
## 차례 = 덱/공터에서 2장 가져오기 또는 카드 1장 내기(끌어 놓기 → 비용 고르기 → 숲에 붙음).
## 마지막 바람이 뜨면 계절 끝 점수 연출(6.6) 후 오두막 또는 런 끝으로 간다.

const MINI := 0.44
const LINE_TIME := 0.09

var hand: Hand
var season: Season
var world: ForestView
var _dots: Array[Panel] = []
var _dot_row: HBoxContainer
var _turns: Array[Button] = []
var _score: Label
var _hint: Label
var _deck: Button
var _sapling: Button
var _clearing: HBoxContainer
var _more_bar: HBoxContainer
var _clearing_detail: CardDetail
var _legend: CardDetail
var _stashing := false
var _pay_bar: HBoxContainer
var _pay_ok: Button
var _gain: Label
var _bottom: HBoxContainer
var _sapling_mode := false
var _pending := {}
var _seen_log := 0
var _busy := false
var _inspected := {}
var _inspect_card: CardDetail
## 온라인 대전: 방(Online)과 그 판(Match). 혼자 할 때는 null.
var _net: Online
var _match: Match
var _players: VBoxContainer
var _turn_label: Label
var _viewing := -1
var _overview: Button
var _ranked := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world = get_tree().get_first_node_in_group(&"forest_view") as ForestView
	if Game.in_match():
		_net = Game.online
		_match = _net.game
		season = _match.season
		_viewing = _net.seat
		_net.applied.connect(_on_net_applied)
		_net.resynced.connect(_on_net_resynced)
	elif Game.run == null:
		Game.start_run.call_deferred()
		return
	else:
		season = Game.run.season
	_seen_log = season.log.size()
	var col := _frame()
	var top := _row(col)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	_button(top, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.leave_match if _net else Game.goto.bind(&"title"), 220).custom_minimum_size.y = 112
	var info := _glass(top)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(info, tr("ONLINE_ROOM") % _net.code if _net else Game.season_name(), Style.HEADLINE)
	_dot_row = _row(info, 16)
	_dot_row.tooltip_text = tr("SEASON_WIND")
	var wind_label := _label(_dot_row, tr("SEASON_WIND"), 26, Color(Style.CREAM, 0.8))
	wind_label.visible = _net == null
	for i in season.winds:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(40, 40)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_dot_row.add_child(dot)
		_dots.append(dot)
	var acorn := TextureRect.new()
	acorn.texture = Art.acorn()
	acorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	acorn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	acorn.custom_minimum_size = Vector2(52, 52)
	acorn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(acorn)
	_score = _label(info, "", 48, Style.SPROUT)
	# 화면이 좁거나 글이 길어도 윗줄이 화면 밖으로 밀리지 않게 줄어든다
	_score.clip_text = true
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score.custom_minimum_size.x = 120 if _net else 320
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for d in [-1, 1]:
		var b := _button(top, null, "←" if d < 0 else "→", Game.turn_requested.emit.bind(d), 96)
		b.tooltip_text = tr("SEASON_TURN_LEFT" if d < 0 else "SEASON_TURN_RIGHT")
		b.custom_minimum_size.y = 112
		_turns.append(b)
	var help := _button(top, Art.ICON_HELP, "", start_coach, 96)
	help.custom_minimum_size.y = 112
	help.tooltip_text = tr("COACH_HELP")
	var legend := _button(top, null, "{ }", _toggle_legend, 96)
	legend.text = ""
	legend.icon = Art.icon(&"g_tree")
	legend.expand_icon = true
	legend.custom_minimum_size.y = 112
	legend.tooltip_text = tr("LEGEND_TITLE")
	_overview = _button(top, null, "", _toggle_overview, 96)
	_overview.icon = Art.icon(&"more")
	_overview.expand_icon = true
	_overview.toggle_mode = true
	_overview.custom_minimum_size.y = 112
	_overview.tooltip_text = tr("SEASON_OVERVIEW")
	var clear_row := _row(col, 12)
	clear_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_label(clear_row, tr("SEASON_CLEARING"), Style.BODY, Color(Style.CREAM, 0.85))
	_clearing = _row(clear_row, 8)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_row.add_child(gap)
	if _net:
		_build_players(clear_row)
	elif not Game.run.event().is_empty():
		var ev := _glass(clear_row)
		ev.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		var ev_text := _label(ev, tr("EVENT_%s" % String(Game.run.events[Game.run.season_index]).to_upper()), 26, Style.SUNSET)
		ev_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		ev_text.clip_text = true
		ev_text.custom_minimum_size.x = 420
		ev_text.tooltip_text = ev_text.text
		ev_text.mouse_filter = Control.MOUSE_FILTER_PASS
	_spacer(col)
	_pay_bar = _row(col)
	_pay_ok = _button(_pay_bar, Art.ICON_NEXT, tr("SEASON_PAY_OK"), _confirm_pay, 280)
	_pay_ok.theme_type_variation = &"AccentButton"
	_button(_pay_bar, null, tr("SEASON_CANCEL"), _cancel_pay, 220)
	_pay_bar.visible = false
	_more_bar = _row(col)
	_button(_more_bar, Art.ICON_NEXT, tr("SEASON_MORE_DONE"), _done_more, 320)
	_more_bar.visible = false
	_hint = _label(col, "", 30, Color(Style.CREAM, 0.95))
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 600
	var bottom := _row(col)
	_bottom = bottom
	bottom.alignment = BoxContainer.ALIGNMENT_END
	var side := VBoxContainer.new()
	side.size_flags_vertical = Control.SIZE_SHRINK_END
	side.add_theme_constant_override(&"separation", 12)
	bottom.add_child(side)
	_deck = _button(side, Art.ICON_NEXT, "", _draw_deck, 270)
	_deck.theme_type_variation = &"AccentButton"
	_sapling = _button(side, null, tr("SEASON_SAPLING"), _toggle_sapling, 270)
	_sapling.toggle_mode = true
	hand = Hand.new()
	hand.demo = false
	hand.world = world
	hand.targets_fn = _targets
	hand.on_drop = _on_drop
	hand.on_hover = _on_hover
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand)
	_gain = Label.new()
	_gain.top_level = true
	_gain.z_index = 20
	_gain.add_theme_font_override(&"font", Style.bold())
	_gain.add_theme_font_size_override(&"font_size", Style.SCORE)
	_gain.add_theme_color_override(&"font_color", Style.SPROUT)
	_gain.add_theme_constant_override(&"outline_size", 12)
	_gain.add_theme_color_override(&"font_outline_color", Style.FOREST)
	_gain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_gain.visible = false
	add_child(_gain)
	if world == null:
		hand.queue_free()
		hand = null
		return
	hand.sync.call_deferred(_mine())
	_refresh()
	_deck.grab_focus()
	if not _net and Game.run.season_index == 0 and not Coach.seen():
		start_coach.call_deferred()


func start_coach() -> void:
	if not hand:
		return
	for c in get_children():
		if c is Coach:
			c.queue_free()
	var coach := Coach.new()
	coach.pause = func() -> bool: return hand.picking() or _pay_bar.visible or _more_bar.visible
	add_child(coach)
	coach.start([
		{text = "COACH_PLANT", hole = hand.card_rect.bind(Cards.is_tree), wait = world.placed,
			check = func(a: Array) -> bool: return a[0].side == &""},
		{text = "COACH_HALF", hole = hand.card_rect.bind(func(c: Dictionary) -> bool: return not Cards.is_tree(c)),
			wait = world.placed, check = func(a: Array) -> bool: return a[0].side != &""},
		{text = "COACH_DRAW", hole = func() -> Rect2: return _deck.get_global_rect().merge(_clearing.get_global_rect())},
		{text = "COACH_TURN", hole = func() -> Rect2: return _turns[0].get_global_rect().merge(_turns[1].get_global_rect()),
			wait = Game.turn_requested},
		{text = "COACH_WIND", hole = func() -> Rect2: return _dot_row.get_global_rect().merge(_score.get_global_rect())},
	] as Array[Dictionary])


## 화살표·십자키는 버튼 사이 이동에 쓰이니, 섬 돌리기는 Q/E·LB/RB로 한다.
func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm:
		_inspect(get_global_mouse_position() if mm.button_mask == 0 else Vector2.INF)
	var dir := _turn_dir(event)
	if dir != 0:
		Game.turn_requested.emit(dir)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel") and hand and hand.picking():
		_cancel_pay()
		get_viewport().set_input_as_handled()


static func _turn_dir(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		return {KEY_Q: -1, KEY_E: 1}.get(event.keycode, 0)
	if event is InputEventJoypadButton and event.pressed:
		return {JOY_BUTTON_LEFT_SHOULDER: -1, JOY_BUTTON_RIGHT_SHOULDER: 1}.get(event.button_index, 0)
	return 0


# --- 규칙 연결 ---

## 지금 카드를 낼 수 있는 자리: 규칙(Forest)에 묻는다
func _targets(card: Dictionary, half: int) -> Array[Dictionary]:
	if _busy or not _my_turn() or (_net and _viewing != _net.seat) or season.over or season.draws() > 0 or hand.picking() or not season.allows(card, half):
		return []
	var out: Array[Dictionary] = []
	if _sapling_mode or Cards.is_tree(card):
		if not _sapling_mode and season.cost_now(card, half) > season.hand.size() - 1:
			return out
		for p in season.forest.free_plots():
			out.append({plot = p, side = &""})
		return out
	if season.cost_now(card, half) > season.hand.size() - 1:
		return out
	return season.forest.targets(card.halves[half], Cards.side_of(card, half))


func _on_drop(v: CardView, half: int, target: Dictionary) -> void:
	var card := v.card
	if _sapling_mode:
		if _do({k = "sapling", id = card.id, plot = target.plot}):
			world.place(target, Forest.SAPLING)
			_set_sapling(false)
			_after_action()
		return
	var cost := season.cost_now(card, half)
	if cost == 0:
		_commit(card, half, target, [])
		return
	_pending = {card = card, half = half, target = target, cost = cost}
	world.preview(target, Cards.kind_of(card, half))
	_pay_bar.visible = true
	_pay_ok.disabled = true
	hand.pick(cost, card.id, Bot._cheapest(season.hand, card.id, cost, Cards.sym_of(card, half)), func(ids: Array[int]) -> void:
		_pay_ok.disabled = ids.size() != cost)
	_refresh()


func _confirm_pay() -> void:
	if _stashing:
		var picked := hand.picked().duplicate()
		_stashing = false
		_close_pay()
		_do({k = "stash", ids = picked})
		_continue_turn()
		return
	if _pending.is_empty() or hand.picked().size() != _pending.cost:
		return
	var p := _pending
	var ids := hand.picked().duplicate()
	_close_pay()
	_commit(p.card, p.half, p.target, ids)


func _cancel_pay() -> void:
	if _stashing:
		_stashing = false
		_close_pay()
		_do({k = "stash", ids = []})
		_continue_turn()
		return
	if _pending.is_empty():
		return
	world.clear_targets()
	world.preview({}, &"")
	_close_pay()
	hand.sync(_mine())
	_refresh()


func _close_pay() -> void:
	_pending = {}
	_pay_bar.visible = false
	hand.end_pick()


func _commit(card: Dictionary, half: int, target: Dictionary, pay: Array[int]) -> void:
	var before := _points_by_spot()
	if not _do({k = "play", id = card.id, half = half, plot = target.plot, pay = pay}):
		hand.sync(_mine())
		_refresh()
		return
	world.place(target, Cards.kind_of(card, half))
	_cheer(before, target)
	_continue_turn()


## 낸 뒤: 라쿤이면 굴에 넣을 손패를 고르고, 공짜·두더지 기회가 남았으면 더 내게 하고, 아니면 차례 끝
func _continue_turn() -> void:
	_play_log()
	hand.sync(_mine())
	if not _my_turn():
		_after_action()
	elif season.wants_stash():
		_stashing = true
		_pay_bar.visible = true
		_pay_ok.disabled = false
		hand.pick(season.hand.size(), -1, [] as Array[int], Callable())
		_refresh()
	elif season.can_play_more():
		_more_bar.visible = true
		_refresh()
	else:
		_more_bar.visible = false
		_after_action()


func _done_more() -> void:
	_do({k = "skip"})
	_more_bar.visible = false
	_after_action()


## 숲의 자리별 점수: "plot/side" → pts
func _points_by_spot() -> Dictionary:
	var out := {}
	for l in _log_of(_shown()).lines:
		var key := "%d/%s" % [l.plot, l.side]
		out[key] = out.get(key, 0) + l.pts
	return out


## 이웃끼리 반응: 방금 낸 카드 덕에 점수가 오른 다른 이웃·나무가 반짝인다
func _cheer(before: Dictionary, placed: Dictionary) -> void:
	var after := _points_by_spot()
	var delay := 0.6
	for key: String in after:
		var parts := key.split("/")
		var spot := {plot = int(parts[0]), side = StringName(parts[1])}
		if spot.plot == placed.plot and spot.side == placed.side:
			continue
		if after[key] > before.get(key, 0):
			get_tree().create_timer(delay).timeout.connect(func() -> void:
				if is_instance_valid(world):
					world.cheer(spot, Style.SPROUT)
					Sfx.play(&"chime", 0.4, 1.4))
			delay += 0.12


func _draw_deck() -> void:
	_take_card(-1)


func _take_card(from: int) -> void:
	if _busy or not _do({k = "draw", from = from}):
		return
	Sfx.play(&"click")
	if not _my_turn() or not season.can_draw() or season.over:
		_after_action()
	else:
		_play_log()
		hand.sync(_mine())
		_refresh()


## 차례 끝: 공터 쓸림, 바람, 계절 끝
func _after_action() -> void:
	if not _net:
		season.end_turn()
	_play_log()
	hand.sync(_mine())
	_refresh()
	if season.over:
		_end_match() if _net else _end_season()


## 새 SeasonLog 사건들 중 화면에 보일 것(바람·쓸림·굴)
func _play_log() -> void:
	while _seen_log < season.log.size():
		var e: Dictionary = season.log[_seen_log]
		_seen_log += 1
		match e.t:
			&"wind":
				Sfx.play(&"chime")
				Game.wind_seen(e.n)
				_pulse(_dots[mini(e.n, _dots.size()) - 1])
			&"sweep":
				_toast(tr("SEASON_SWEPT") % e.count)


func _on_hover(card: Dictionary, half: int, target: Dictionary) -> void:
	if target.is_empty() or _sapling_mode:
		_gain.visible = false
		return
	var f := _my_forest().clone()
	if Cards.is_tree(card):
		f.plant(target.plot, card, card.tree)
	else:
		f.attach(target.plot, target.side, card, card.halves[half])
	var gain := _total(f) - _total(_my_forest())
	_gain.text = "%+d" % gain
	_gain.add_theme_color_override(&"font_color", Style.SPROUT if gain > 0 else Color(Style.CREAM, 0.8))
	_gain.reset_size()
	_gain.global_position = world.screen_position(target) - Vector2(_gain.size.x / 2.0, 150)
	_gain.visible = true


func _total(f: Forest) -> int:
	return _log_of(f).total


func _log_of(f: Forest) -> ScoreLog:
	if _net:
		var who := _match.forests.find(f)
		return Score.count(f, 0, _match.mods_for(who if who >= 0 else _net.seat))
	var log := Score.count(f, Game.run.season_index, Game.run.score_mods())
	log.apply(Spirits.mult(f, Game.run.owned(), Game.run.season_index))
	return log


func _toggle_sapling() -> void:
	_set_sapling(_sapling.button_pressed)


func _set_sapling(on: bool) -> void:
	_sapling_mode = on
	_sapling.set_pressed_no_signal(on)
	_refresh()


# --- 화면 갱신 ---

func _refresh() -> void:
	_score.text = tr("ONLINE_SCORE") % _total(_my_forest()) if _net else tr("SEASON_SCORE") % [_total(season.forest), Game.run.target()]
	if _viewing == (_net.seat if _net else -1) and world.open_count() < _my_forest().plots:
		world.open_plots(_my_forest().plots)
	if _net:
		_show_players()
	for i in _dots.size():
		var on := i < season.winds_seen
		_dots[i].add_theme_stylebox_override(&"panel", Style.box(Style.SUNSET if on else Color(Style.CREAM, 0.15), 20, Style.CREAM if on else Color(Style.CREAM, 0.4), 3))
	var undeck := season.deck.size() - (season.winds - season.winds_seen)
	_deck.text = tr("SEASON_DECK") % maxi(undeck, 0)
	_deck.disabled = _busy or not _my_turn() or not season.can_draw() or hand.picking()
	_sapling.disabled = _busy or not _my_turn() or season.can_play_more() or season.draws() > 0 or _my_forest().free_plots().is_empty() or hand.picking()
	for c in _clearing.get_children():
		c.queue_free()
	if is_instance_valid(_clearing_detail):
		_clearing_detail.queue_free()
	for c in season.clearing:
		_clearing.add_child(_mini_card(c))
	if season.over:
		_hint.text = ""
	elif _net and not _net.my_turn():
		_hint.text = tr("ONLINE_WAIT") % _net.name_of(_match.turn)
	elif _stashing:
		_hint.text = tr("SEASON_STASH")
	elif hand.picking():
		_hint.text = tr("SEASON_PAY") % _pending.cost
	elif season.can_play_more():
		var parts: Array[String] = []
		for e in season.pending:
			parts.append(tr("SEASON_FREE") % CardText.group_of(e.tag) if e.t == &"free" else tr("SEASON_MORE"))
		_hint.text = " · ".join(parts)
	elif _sapling_mode:
		_hint.text = tr("SEASON_SAPLING_HINT")
	elif season.draws() > 0:
		_hint.text = tr("SEASON_DRAW_MORE")
	else:
		_hint.text = tr("SEASON_TURN_HINT")


func _mini_card(c: Dictionary) -> Control:
	var box := Button.new()
	box.flat = true
	box.custom_minimum_size = CardView.CARD * MINI
	box.focus_mode = Control.FOCUS_ALL
	var v := CardView.make(c, hand.portraits if hand else null)
	v.scale = Vector2.ONE * MINI
	v.pivot_offset = Vector2.ZERO
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	box.disabled = _busy or not season.can_draw() or hand.picking()
	box.pressed.connect(_take_card.bind(c.id))
	box.mouse_entered.connect(func() -> void:
		get_tree().create_timer(Hand.DETAIL_DELAY).timeout.connect(func() -> void:
			if is_instance_valid(box) and box.get_global_rect().has_point(get_global_mouse_position()):
				_show_clearing_detail(box, c)))
	return box


## 아이콘 설명 창(나무 아이콘 버튼): 다시 누르거나 창 밖을 누르면 닫힌다
func _toggle_legend() -> void:
	if is_instance_valid(_legend):
		_legend.queue_free()
		return
	_legend = CardDetail.legend()
	add_child(_legend)
	_legend.reset_size()
	_legend.global_position = (get_viewport_rect().size - _legend.get_combined_minimum_size()) / 2.0


## 공터 카드 상세: 마우스를 잠깐 올리면 아래로 크게 펼친다
func _show_clearing_detail(box: Control, c: Dictionary) -> void:
	if is_instance_valid(_clearing_detail):
		_clearing_detail.queue_free()
	_clearing_detail = CardDetail.for_card(c, hand.portraits)
	add_child(_clearing_detail)
	_clearing_detail.place_near(box.get_global_rect(), get_viewport_rect().size)
	_clearing_detail.auto_close(box.get_global_rect())


func _pulse(c: Control) -> void:
	c.pivot_offset = c.size / 2.0
	c.scale = Vector2.ONE * 1.6
	create_tween().tween_property(c, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _toast(text: String) -> void:
	var l := _label(self, text, Style.HEADLINE, Style.SUNSET)
	l.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	l.modulate.a = 0.0
	var tw := l.create_tween()
	tw.tween_property(l, ^"modulate:a", 1.0, 0.2)
	tw.tween_interval(1.0)
	tw.tween_property(l, ^"modulate:a", 0.0, 0.3)
	tw.tween_callback(l.queue_free)


# --- 계절 끝 점수 연출(6.6) ---

func _end_season() -> void:
	_busy = true
	_refresh()
	_hint.text = ""
	create_tween().tween_property(_bottom, ^"modulate:a", 0.0, 0.4)
	var log := Game.finish_season()
	await get_tree().create_timer(0.8).timeout
	var tally := _label(self, "0", Style.SCORE, Style.SPROUT)
	tally.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tally.position.y += 260
	var sum := 0
	for line in log.lines:
		if line.pts == 0:
			continue
		sum += line.pts
		_pop(world.screen_position({plot = line.plot, side = line.side}), "+%d" % line.pts)
		tally.text = str(sum)
		Sfx.play(&"click")
		await get_tree().create_timer(LINE_TIME).timeout
	if log.cave > 0:
		sum += log.cave
		tally.text = str(sum)
		await get_tree().create_timer(0.3).timeout
	if log.mult > 1.0:
		tally.text = "%d × %.1f" % [log.base, log.mult]
		_pulse(tally)
		await get_tree().create_timer(0.6).timeout
	tally.text = str(log.total)
	_pulse(tally)
	Sfx.play(&"chime")
	await get_tree().create_timer(0.4).timeout
	var passed := not Game.run.lost
	var banner := _label(self, tr("SCORE_PASS") if passed else tr("SCORE_FAIL") % (Game.run.target() - log.total),
		Style.HEADLINE, Style.SPROUT if passed else Style.BERRY)
	banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	if not passed:
		# 실패: 숲이 회색으로 바랜다
		var grey := ColorRect.new()
		grey.color = Color(0.35, 0.35, 0.38, 0.0)
		grey.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grey.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(grey)
		move_child(grey, 0)
		create_tween().tween_property(grey, ^"color:a", 0.55, 1.2)
	var go := _button(self, Art.ICON_NEXT, tr("SCORE_CONTINUE"), Game.after_season, 360)
	go.theme_type_variation = &"AccentButton"
	go.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	go.position.y -= 200
	go.grab_focus()


func _pop(at: Vector2, text: String) -> void:
	var l := Label.new()
	l.text = text
	l.top_level = true
	l.z_index = 20
	l.add_theme_font_override(&"font", Style.bold())
	l.add_theme_font_size_override(&"font_size", Style.HEADLINE)
	l.add_theme_color_override(&"font_color", Style.SPROUT)
	l.add_theme_constant_override(&"outline_size", 10)
	l.add_theme_color_override(&"font_outline_color", Style.FOREST)
	add_child(l)
	l.reset_size()
	l.global_position = at - l.size / 2.0
	var tw := l.create_tween().set_parallel()
	tw.tween_property(l, ^"global_position:y", l.global_position.y - 80, 0.9)
	tw.tween_property(l, ^"modulate:a", 0.0, 0.9).set_delay(0.4)
	tw.chain().tween_callback(l.queue_free)


## 숲에 붙은 나무·이웃에 마우스를 올리면 그 카드의 상세 창(지금 점수 포함)을 띄운다.
func _inspect(at: Vector2) -> void:
	var hit := {}
	if world and season and at != Vector2.INF and not (hand and (hand.dragging() or hand.picking())):
		hit = world.pick_at(at)
	if hit == _inspected:
		if is_instance_valid(_inspect_card):
			_inspect_card.place_near(Rect2(at - Vector2(40, 40), Vector2(80, 80)), get_viewport_rect().size)
		return
	_inspected = hit
	if is_instance_valid(_inspect_card):
		_inspect_card.queue_free()
	_inspect_card = null
	var shown := _shown()
	if hit.is_empty() or not shown.trees.has(hit.plot):
		return
	var tree_kind := shown.kind_at(hit.plot)
	var kind := tree_kind
	var card: Dictionary = shown.trees[hit.plot].get("card", {})
	var where := ""
	if hit.side != &"":
		var here := shown.occupants(hit.plot, hit.side)
		if here.is_empty():
			return
		kind = here[0].species
		card = here[0].card
		where = tr("CARD_ON_TREE") % [CardText.name_of(tree_kind), CardText.side_of(hit.side)]
		if here.size() > 1:
			where += " ×%d" % here.size()
	var pts: int = _points_by_spot().get("%d/%s" % [hit.plot, hit.side], 0)
	_inspect_card = CardDetail.for_kind(kind, pts, where, card)
	add_child(_inspect_card)
	_inspect_card.place_near(Rect2(at - Vector2(40, 40), Vector2(80, 80)), get_viewport_rect().size)


# --- 온라인 대전 ---

## 내 손패·내 숲(온라인이면 내 자리, 혼자면 계절 그대로)
func _mine() -> Array[Dictionary]:
	return _match.hand_of(_net.seat) if _net else season.hand


func _my_forest() -> Forest:
	return _match.forests[_net.seat] if _net else season.forest


## 지금 화면에 보이는 숲(온라인에서 다른 사람 숲을 보는 중일 수 있다)
func _shown() -> Forest:
	return _match.forests[_viewing] if _net and _viewing >= 0 else season.forest


func _my_turn() -> bool:
	return _net == null or _net.my_turn()


## 행동 하나: 온라인이면 방에 쓰고(판에 바로 반영), 혼자면 계절에 바로 한다.
func _do(a: Dictionary) -> bool:
	if _net:
		return _net.act(a)
	match String(a.k):
		"draw":
			return season.draw(int(a.get("from", -1)))
		"play":
			return season.play(int(a.id), int(a.half), int(a.plot), a.pay)
		"sapling":
			return season.sapling(int(a.id), int(a.plot))
		"stash":
			var ids: Array[int] = []
			ids.assign(a.ids)
			return season.stash(ids)
		"skip":
			season.skip()
			return true
	return false


## 다른 사람이 행동했다: 그 사람 숲을 보고 있으면 다시 세우고, 판이 끝났으면 순위
func _on_net_applied(who: int) -> void:
	if who == _net.seat or not is_inside_tree():
		return
	if _viewing == who:
		world.rebuild(_shown())
	_play_log()
	hand.sync(_mine())
	_refresh()
	if season.over:
		_end_match()
	elif _net.my_turn():
		Sfx.play(&"chime")
		_toast(tr("ONLINE_YOUR_TURN"))


## 쓰기가 겹쳐 판을 처음부터 다시 만들었다
func _on_net_resynced() -> void:
	if not is_inside_tree():
		return
	_match = _net.game
	season = _match.season
	_seen_log = season.log.size()
	_close_pay()
	_stashing = false
	_more_bar.visible = false
	world.rebuild(_shown())
	hand.sync(_mine())
	_refresh()


func _build_players(parent: Control) -> void:
	var box := _glass(parent)
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_players = VBoxContainer.new()
	_players.add_theme_constant_override(&"separation", 6)
	box.add_child(_players)
	_turn_label = _label(_players, "", 28, Style.SUNSET)


## 사람마다 한 줄: 차례 표시, 이름, 도토리, 손패 수. 누르면 그 사람 숲을 본다.
func _show_players() -> void:
	if not _players:
		return
	_turn_label.text = tr("ONLINE_YOUR_TURN") if _net.my_turn() else tr("ONLINE_TURN_OF") % _net.name_of(_match.turn)
	while _players.get_child_count() - 1 < _match.players:
		var b := Button.new()
		b.toggle_mode = true
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = Art.acorn()
		b.expand_icon = false
		b.add_theme_font_override(&"font", Style.bold())
		b.add_theme_font_size_override(&"font_size", 24)
		b.custom_minimum_size = Vector2(420, 56)
		b.add_theme_constant_override(&"icon_max_width", 32)
		b.pressed.connect(_view.bind(_players.get_child_count() - 1))
		b.tooltip_text = tr("ONLINE_VIEW")
		_players.add_child(b)
	for p in _match.players:
		var b: Button = _players.get_child(p + 1)
		var mark := "▶ " if p == _match.turn else "   "
		var me := " (%s)" % tr("LOBBY_ME") if p == _net.seat else ""
		b.text = "%s%s%s   %d   ✋%d" % [mark, _net.name_of(p), me, _total(_match.forests[p]), _match.hand_of(p).size()]
		b.set_pressed_no_signal(p == _viewing)


func _view(p: int) -> void:
	if p == _viewing:
		p = _net.seat
	_viewing = p
	world.rebuild(_shown())
	world.set_overview(_overview.button_pressed)
	_refresh()


func _toggle_overview() -> void:
	world.set_overview(_overview.button_pressed)


## 판 끝: 모두의 숲 점수로 순위를 보여 준다
func _end_match() -> void:
	if _ranked:
		return
	_ranked = true
	_busy = true
	_refresh()
	create_tween().tween_property(_bottom, ^"modulate:a", 0.0, 0.4)
	if _net.is_host():
		_net.db.req("PUT", "rooms/%s/status" % _net.code, "done")
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.glass())
	add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", Style.GAP)
	panel.add_child(col)
	_label(col, tr("ONLINE_RANKING"), Style.HEADLINE, Style.SUNSET)
	var rank := 0
	for r in _match.ranking():
		rank += 1
		var row := _row(col)
		var text := "%d. %s" % [rank, _net.name_of(r.who)]
		if r.who == _net.seat:
			text += " (%s)" % tr("LOBBY_ME")
		_label(row, text, Style.BODY, Style.SPROUT if rank == 1 else Style.CREAM)
		var acorn := TextureRect.new()
		acorn.texture = Art.acorn()
		acorn.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		acorn.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		acorn.custom_minimum_size = Vector2(44, 44)
		row.add_child(acorn)
		_label(row, str(r.total), Style.HEADLINE, Style.SPROUT if rank == 1 else Style.CREAM)
		_label(row, tr("ONLINE_CAVE") % r.cave, 24, Color(Style.CREAM, 0.7))
	var go := _button(col, Art.ICON_HOME, tr("ONLINE_DONE"), Game.leave_match, 360)
	go.theme_type_variation = &"AccentButton"
	panel.reset_size()
	panel.position = (get_viewport_rect().size - panel.get_combined_minimum_size()) / 2.0
	Sfx.play(&"chime")

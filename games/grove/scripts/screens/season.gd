extends ScreenBase
## 계절 화면(2-1): 3D 숲 + 손패·빈터·바람 칸을 규칙(Season)에 연결한다.
## 차례 = 덱/빈터에서 2장 가져오기 또는 카드 1장 내기(끌어 놓기 → 비용 고르기 → 숲에 붙음).
## 마지막 바람이 뜨면 계절 끝 점수 연출(6.6) 후 오두막 또는 런 끝으로 간다.

const MINI := 0.5
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
var _pay_bar: HBoxContainer
var _pay_ok: Button
var _gain: Label
var _bottom: HBoxContainer
var _sapling_mode := false
var _pending := {}
var _seen_log := 0
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	world = get_tree().get_first_node_in_group(&"forest_view") as ForestView
	if Game.run == null:
		Game.start_run.call_deferred()
		return
	season = Game.run.season
	_seen_log = season.log.size()
	var col := _frame()
	var top := _row(col)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	_button(top, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 220).custom_minimum_size.y = 112
	var info := _glass(top)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(info, Game.season_name(), Style.HEADLINE)
	_dot_row = _row(info, 16)
	_dot_row.tooltip_text = tr("SEASON_WIND")
	_label(_dot_row, tr("SEASON_WIND"), 26, Color(Style.CREAM, 0.8))
	for i in season.winds:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(40, 40)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_dot_row.add_child(dot)
		_dots.append(dot)
	_score = _label(info, "", 48, Style.SPROUT)
	# 화면이 좁거나 글이 길어도 윗줄이 화면 밖으로 밀리지 않게 줄어든다
	_score.clip_text = true
	_score.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_score.custom_minimum_size.x = 300
	_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	for d in [-1, 1]:
		var b := _button(top, null, tr("SEASON_TURN_LEFT" if d < 0 else "SEASON_TURN_RIGHT"), Game.turn_requested.emit.bind(d), 190)
		b.custom_minimum_size.y = 112
		_turns.append(b)
	var help := _button(top, Art.ICON_HELP, "", start_coach, 112)
	help.custom_minimum_size.y = 112
	help.tooltip_text = tr("COACH_HELP")
	var clear_row := _row(col, 12)
	clear_row.alignment = BoxContainer.ALIGNMENT_BEGIN
	_label(clear_row, tr("SEASON_CLEARING"), Style.BODY, Color(Style.CREAM, 0.85))
	_clearing = _row(clear_row, 8)
	var gap := Control.new()
	gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	clear_row.add_child(gap)
	if not Game.run.event().is_empty():
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
	_deck = _button(side, Art.ICON_NEXT, "", _draw_deck, 320)
	_deck.theme_type_variation = &"AccentButton"
	_sapling = _button(side, null, tr("SEASON_SAPLING"), _toggle_sapling, 320)
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
	hand.sync.call_deferred(season.hand)
	_refresh()
	_deck.grab_focus()
	if Game.run.season_index == 0 and not Coach.seen():
		start_coach.call_deferred()


func start_coach() -> void:
	if not hand:
		return
	for c in get_children():
		if c is Coach:
			c.queue_free()
	var coach := Coach.new()
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
	if _busy or season.over or season.draws() > 0 or hand.picking():
		return []
	var out: Array[Dictionary] = []
	if _sapling_mode or Cards.is_tree(card):
		if not _sapling_mode and Cards.cost_of(card, half) > season.hand.size() - 1:
			return out
		for p in season.forest.free_plots():
			if p < ForestView.MAX_PLOTS:
				out.append({plot = p, side = &""})
		return out
	if Cards.cost_of(card, half) > season.hand.size() - 1:
		return out
	return season.forest.targets(card.halves[half], Cards.side_of(card, half))


func _on_drop(v: CardView, half: int, target: Dictionary) -> void:
	var card := v.card
	if _sapling_mode:
		if season.sapling(card.id, target.plot):
			world.place(target, Forest.SAPLING)
			_set_sapling(false)
			_after_action()
		return
	var cost := Cards.cost_of(card, half)
	if cost == 0:
		_commit(card, half, target, [])
		return
	_pending = {card = card, half = half, target = target, cost = cost}
	world.preview(target, Cards.kind_of(card, half))
	_pay_bar.visible = true
	_pay_ok.disabled = true
	hand.pick(cost, card.id, Bot._cheapest(season.hand, card.id, cost, card.sym), func(ids: Array[int]) -> void:
		_pay_ok.disabled = ids.size() != cost)
	_refresh()


func _confirm_pay() -> void:
	if _pending.is_empty() or hand.picked().size() != _pending.cost:
		return
	var p := _pending
	var ids := hand.picked().duplicate()
	_close_pay()
	_commit(p.card, p.half, p.target, ids)


func _cancel_pay() -> void:
	if _pending.is_empty():
		return
	world.clear_targets()
	world.preview({}, &"")
	_close_pay()
	hand.sync(season.hand)
	_refresh()


func _close_pay() -> void:
	_pending = {}
	_pay_bar.visible = false
	hand.end_pick()


func _commit(card: Dictionary, half: int, target: Dictionary, pay: Array[int]) -> void:
	var before := _points_by_spot()
	if not season.play(card.id, half, target.plot, pay):
		hand.sync(season.hand)
		_refresh()
		return
	world.place(target, Cards.kind_of(card, half))
	_cheer(before, target)
	_after_action()


## 숲의 자리별 점수: "plot/side" → pts
func _points_by_spot() -> Dictionary:
	var out := {}
	for l in Score.count(season.forest, Game.run.season_index, Game.run.score_mods()).lines:
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
	if _busy or not season.draw(from):
		return
	Sfx.play(&"click")
	if not season.can_draw() or season.over:
		_after_action()
	else:
		_play_log()
		hand.sync(season.hand)
		_refresh()


## 차례 끝: 빈터 쓸림, 바람, 계절 끝
func _after_action() -> void:
	season.end_turn()
	_play_log()
	hand.sync(season.hand)
	_refresh()
	if season.over:
		_end_season()


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
	var f := season.forest.clone()
	if Cards.is_tree(card):
		f.plant(target.plot, card, card.tree)
	else:
		f.attach(target.plot, target.side, card, card.halves[half])
	var gain := _total(f) - _total(season.forest)
	_gain.text = "%+d" % gain
	_gain.add_theme_color_override(&"font_color", Style.SPROUT if gain > 0 else Color(Style.CREAM, 0.8))
	_gain.reset_size()
	_gain.global_position = world.screen_position(target) - Vector2(_gain.size.x / 2.0, 150)
	_gain.visible = true


func _total(f: Forest) -> int:
	var log := Score.count(f, Game.run.season_index, Game.run.score_mods())
	log.apply(Spirits.mult(f, Game.run.spirits, Game.run.season_index))
	return log.total


func _toggle_sapling() -> void:
	_set_sapling(_sapling.button_pressed)


func _set_sapling(on: bool) -> void:
	_sapling_mode = on
	_sapling.set_pressed_no_signal(on)
	_refresh()


# --- 화면 갱신 ---

func _refresh() -> void:
	_score.text = tr("SEASON_SCORE") % [_total(season.forest), Game.run.target()]
	for i in _dots.size():
		var on := i < season.winds_seen
		_dots[i].add_theme_stylebox_override(&"panel", Style.box(Style.SUNSET if on else Color(Style.CREAM, 0.15), 20, Style.CREAM if on else Color(Style.CREAM, 0.4), 3))
	var undeck := season.deck.size() - (season.winds - season.winds_seen)
	_deck.text = tr("SEASON_DECK") % maxi(undeck, 0)
	_deck.disabled = _busy or not season.can_draw() or hand.picking()
	_sapling.disabled = _busy or season.draws() > 0 or season.forest.free_plots().is_empty() or hand.picking()
	for c in _clearing.get_children():
		c.queue_free()
	for c in season.clearing:
		_clearing.add_child(_mini_card(c))
	if season.over:
		_hint.text = ""
	elif hand.picking():
		_hint.text = tr("SEASON_PAY") % _pending.cost
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
	box.tooltip_text = tr("SEASON_TAKE")
	var v := CardView.make(c, hand.portraits if hand else null)
	v.scale = Vector2.ONE * MINI
	v.pivot_offset = Vector2.ZERO
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(v)
	box.disabled = _busy or not season.can_draw() or hand.picking()
	box.pressed.connect(_take_card.bind(c.id))
	return box


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

extends ScreenBase
## 계산대: 지금 손님 한 명을 상대한다. 고르면 조합을 미리 보여 주고,
## 계산하면 영수증 기록(`Receipt.log`)을 한 줄씩 다시 보여 준 뒤 매출 × 만족을 터뜨린다.

signal checkout_done

const COACH_STEPS := [
	{"id": &"pick", "text": "COACH_PICK", "icon": Art.HAND, "wait": &"picked"},
	{"id": &"combo", "text": "COACH_COMBO", "wait": &"tap"},
	{"id": &"checkout", "text": "COACH_CHECKOUT", "icon": Art.ICON_CHECKOUT, "wait": &"checked_out"},
	{"id": &"discard", "text": "COACH_DISCARD", "icon": Art.ICON_DISCARD, "wait": &"discarded"},
]
const STEP_TIME := 0.14
const HITSTOP := 0.15
const FLYER_WIDTH := 360

## 테스트에서 연출을 빨리 돌릴 때 올린다.
var speed := 1.0
var run: Run
var _root: MarginContainer
var _hand: HBoxContainer
var _info: Label
var _money: Label
var _score: Label
var _target: Label
var _rule: Label
var _combo: Label
var _calc: Label
var _checkout: Button
var _discard: Button
var _flyer_row: HBoxContainer
var _coach: Coach
var _busy := false
var _shown_score := 0
var _shown_money := 0


func _ready() -> void:
	if Game.run == null:
		Game.run = Run.new(Game.run_seed)
	run = Game.run
	_root = MarginContainer.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right"]:
		_root.add_theme_constant_override(side, 96)
	for side in [&"margin_top", &"margin_bottom"]:
		_root.add_theme_constant_override(side, 54)
	add_child(_root)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", Style.GAP)
	_root.add_child(_list)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(top)
	_button(Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), top).custom_minimum_size = Vector2(300, 112)
	_info = _label("", Style.HEADLINE)
	_info.reparent(top)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_money = _label("", Style.HEADLINE)
	_money.reparent(top)
	_money.add_theme_color_override(&"font_color", Style.PRICE)
	var board := HBoxContainer.new()
	board.add_theme_constant_override(&"separation", Style.GAP * 2)
	board.alignment = BoxContainer.ALIGNMENT_CENTER
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(board)
	var left := _column(board)
	_score = _label("0", Style.SCORE)
	_score.reparent(left)
	_score.add_theme_color_override(&"font_color", Style.PRICE)
	_target = _label("", Style.BODY)
	_target.reparent(left)
	_rule = _label(rule_text(), Style.BODY)
	_rule.reparent(left)
	_rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rule.add_theme_color_override(&"font_color", Style.ANGRY)
	var right := _column(board)
	_combo = _label("", Style.HEADLINE)
	_combo.reparent(right)
	_calc = _label("", Style.HEADLINE)
	_calc.reparent(right)
	_hand = HBoxContainer.new()
	_hand.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand.add_theme_constant_override(&"separation", 16)
	_list.add_child(_hand)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(row)
	_checkout = _button(Art.ICON_CHECKOUT, "", _on_checkout, row)
	_checkout.theme_type_variation = &"AccentButton"
	_discard = _button(Art.ICON_DISCARD, "", _on_discard, row)
	for b in [_checkout, _discard]:
		b.custom_minimum_size.x = 440
	_flyer_row = HBoxContainer.new()
	_flyer_row.add_theme_constant_override(&"separation", Style.GAP)
	row.add_child(_flyer_row)
	_sync_flyers()
	_shown_score = run.shift.score
	_shown_money = run.money
	_sync_hand()
	_refresh()
	_coach = Coach.new()
	_coach.rect_of = _coach_rect
	add_child(_coach)
	Sfx.play(&"shuffle")
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree():
		_coach.start(&"counter", COACH_STEPS)


func hand() -> Array[ProductCard]:
	var out: Array[ProductCard] = []
	for c in _hand.get_children():
		if c is ProductCard and not c.is_queued_for_deletion():
			out.append(c)
	return out


func picked() -> Array[ProductCard]:
	return hand().filter(func(c: ProductCard) -> bool: return c.button_pressed)


func picked_cards() -> Array[Card]:
	var out: Array[Card] = []
	for node in picked():
		out.append(node.card)
	return out


## 지금 손님에게 걸린 규칙: 진상 손님, 날씨
func rule_text() -> String:
	var lines: Array[String] = []
	if run.slot == Run.BOSS:
		lines.append("%s: %s" % [Names.boss(run.boss_id()), Names.boss_desc(run.boss_id())])
	if run.weather_id() != Weather.CLEAR:
		lines.append("%s: %s" % [Names.weather(run.weather_id()), Names.weather_desc(run.weather_id())])
	return "\n".join(lines)


func combo_text() -> String:
	return _combo.text


func _column(parent: Control) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.custom_minimum_size.x = 640
	parent.add_child(col)
	return col


## 손패 노드를 `run.shift.hand` 순서에 맞춘다. 새로 들어온 카드만 만든다.
func _sync_hand() -> void:
	var have := {}
	for node in hand():
		if run.shift.hand.has(node.card):
			have[node.card] = node
		else:
			node.queue_free()
	for i in run.shift.hand.size():
		var c := run.shift.hand[i]
		var node: ProductCard = have.get(c)
		if node == null:
			node = ProductCard.new().setup_card(c, run.shift.is_hidden(c))
			node.toggled.connect(_on_card_toggled.bind(node))
			node.modulate.a = 0.0
			_hand.add_child(node)
			create_tween().tween_property(node, ^"modulate:a", 1.0, 0.2 / speed).set_ease(Tween.EASE_OUT)
		_hand.move_child(node, i)


## 전단지 버튼. 카드를 고른 뒤 누르면 그 카드에 쓴다.
func _sync_flyers() -> void:
	for b in _flyer_row.get_children():
		b.queue_free()
	for i in run.flyers.size():
		var id := run.flyers[i]
		var b := Button.new()
		b.name = "Flyer%d" % i
		b.icon = Art.ICON_FLYER
		b.add_theme_constant_override(&"icon_max_width", 56)
		b.text = Names.flyer(id)
		b.tooltip_text = Names.flyer_desc(id)
		b.custom_minimum_size = Vector2(FLYER_WIDTH, Style.BUTTON_H)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override(&"font_size", Style.BODY)
		b.add_theme_font_override(&"font", Style.bold())
		b.pressed.connect(_on_flyer.bind(i))
		_flyer_row.add_child(b)


func flyer_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for b in _flyer_row.get_children():
		if b is Button and not b.is_queued_for_deletion():
			out.append(b)
	return out


func _on_flyer(i: int) -> void:
	if _busy:
		return
	var id := run.flyers[i]
	var cards := picked_cards()
	if not run.use_flyer(i, cards):
		Sfx.play(&"error")
		_combo.text = Names.flyer_desc(id)
		return
	Sfx.play(&"chime")
	# 바뀐 카드는 다시 그린다.
	for node in hand():
		if cards.has(node.card):
			node.queue_free()
	_shown_money = run.money
	_sync_hand()
	_sync_flyers()
	_refresh()


func _on_card_toggled(on: bool, card: ProductCard) -> void:
	if on and picked().size() > run.shift.max_cards:
		card.set_pressed_no_signal(false)
		Sfx.play(&"error")
		return
	Sfx.play(&"pick" if on else &"place")
	_refresh()
	if on and picked().size() >= 2:
		_coach.notify(&"picked")


func _refresh() -> void:
	var s := run.shift
	_info.text = tr("COUNTER_NIGHT") % [run.night, tr("SLOT_%d" % run.slot)]
	_money.text = tr("COUNTER_MONEY") % Style.num(_shown_money)
	_target.text = tr("COUNTER_TARGET") % Style.num(s.target)
	_score.text = Style.num(_shown_score)
	_checkout.text = "%s %d" % [tr("COUNTER_CHECKOUT"), s.checkouts_left]
	_discard.text = "%s %d" % [tr("COUNTER_DISCARD"), s.swaps_left]
	var cards := picked_cards()
	_checkout.disabled = _busy or not s.can_play(cards)
	_discard.disabled = _busy or not s.can_discard(cards)
	if _busy:
		return
	if cards.is_empty():
		_combo.text = tr("COUNTER_HINT")
		_calc.text = ""
		return
	if cards.any(s.is_hidden):
		_combo.text = tr("COUNTER_HIDDEN")
		_calc.text = ""
		return
	var r := s.preview(cards)
	_combo.text = _combo_name(r.kind)
	_calc.text = _calc_text(r.sales, r.satisfaction)


func _combo_name(kind: Combo.Kind) -> String:
	return Names.combo(kind)


func _calc_text(sales: int, sat: float) -> String:
	return "%s × %s" % [Style.num(sales), String.num(sat, 1).trim_suffix(".0")]


func _on_checkout() -> void:
	var nodes := picked()
	var r := run.play(picked_cards())
	if r == null:
		return
	_busy = true
	_refresh()
	_coach.pause()
	await _replay(r, nodes)
	var tw := create_tween().set_parallel()
	for node in nodes:
		tw.tween_property(node, ^"modulate:a", 0.0, 0.18 / speed)
	await tw.finished
	_after_action(&"checked_out")


func _on_discard() -> void:
	var nodes := picked()
	if not run.discard(picked_cards()):
		return
	_busy = true
	_refresh()
	_coach.pause()
	var tw := create_tween().set_parallel()
	for node in nodes:
		tw.tween_property(node, ^"modulate:a", 0.0, 0.2 / speed)
	await tw.finished
	_after_action(&"discarded")


## 영수증 기록을 한 줄씩: 조합 → 상품(띵) → 꼬리표 → 꿀팁. 끝에 매출 × 만족 폭발.
func _replay(r: Receipt, nodes: Array[ProductCard]) -> void:
	var by_name := {}
	for node in nodes:
		by_name[str(node.card)] = node
	_combo.text = _combo_name(r.kind)
	var sales := 0
	var sat := 0.0
	var step := 0
	for e in r.log:
		sales += e.sales
		sat = (sat + e.sat_add) * e.sat_mul
		_calc.text = _calc_text(sales, sat)
		var node: ProductCard = by_name.get(e.source)
		if node:
			node.flash()
			Sfx.play(&"scan", 0.8, 1.0 + step * 0.06)
			step += 1
		elif e.source != "combo":
			Sfx.play(&"chime", 0.7)
		_pop(_calc, 1.12 if e.sat_mul == 1.0 else 1.3)
		await get_tree().create_timer(STEP_TIME / speed).timeout
	_calc.text = Style.num(r.total())
	_pop(_calc, 1.5)
	Sfx.play(&"cash")
	_shake()
	await get_tree().create_timer(HITSTOP / speed).timeout
	_shown_score = run.shift.score
	_score.text = Style.num(_shown_score)
	_pop(_score, 1.3)
	await get_tree().create_timer(STEP_TIME * 2 / speed).timeout


func _after_action(event: StringName) -> void:
	_sync_hand()
	Sfx.play(&"deal")
	await get_tree().process_frame
	_shown_money = run.money
	_busy = false
	_refresh()
	if run.phase != Run.Phase.SHIFT:
		_coach.pause()
		_show_end()
	elif _coach.waiting_for() == event:
		_coach.notify(event)
	else:
		_coach.resume()
	checkout_done.emit()


func _show_end() -> void:
	if run.is_over():
		await get_tree().create_timer(0.6 / speed).timeout
		Game.goto(&"run_end")
		return
	var dim := ColorRect.new()
	dim.color = Color(Style.NIGHT_DEEP, 0.85)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.add_child(center)
	var panel := PanelContainer.new()
	var sb := Style.box(Style.NIGHT, 24, Color(Style.FLUORESCENT, 0.3), 3, 32)
	sb.set_content_margin_all(64)
	panel.add_theme_stylebox_override(&"panel", sb)
	center.add_child(panel)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", Style.GAP)
	panel.add_child(_list)
	Sfx.play(&"cash")
	_label(tr("END_CLEARED"), Style.SCORE).add_theme_color_override(&"font_color", Style.NEON)
	for key in ["payout", "leftover", "overkill", "interest", "tips"]:
		if run.last_pay.get(key, 0) > 0:
			_label("%s  +%s" % [tr(StringName("END_PAY_%s" % key.to_upper())), Names.money(run.last_pay[key])])
	_label(Names.money(run.money), Style.HEADLINE).add_theme_color_override(&"font_color", Style.PRICE)
	_button(Art.ICON_NEXT, tr("END_TO_SHOP"), Game.goto.bind(&"shop")).theme_type_variation = &"AccentButton"
	panel.pivot_offset = panel.size / 2.0
	panel.modulate.a = 0.0
	var tw := create_tween().set_parallel()
	tw.tween_property(panel, ^"modulate:a", 1.0, 0.25 / speed).set_ease(Tween.EASE_OUT)


func _pop(node: Control, to: float) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, ^"scale", Vector2.ONE * to, 0.06 / speed)
	tw.tween_property(node, ^"scale", Vector2.ONE, 0.2 / speed).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake() -> void:
	var tw := create_tween()
	for i in 4:
		tw.tween_property(_root, ^"position", Vector2(randf_range(-12, 12), randf_range(-8, 8)), 0.03 / speed)
	tw.tween_property(_root, ^"position", Vector2.ZERO, 0.05 / speed)


func _coach_rect(step: StringName) -> Rect2:
	var hand_rect := _hand.get_global_rect().grow(24)
	match step:
		&"pick":
			return hand_rect
		&"combo":
			return _combo.get_global_rect().merge(_calc.get_global_rect()).grow(24)
		&"checkout":
			return _checkout.get_global_rect().grow(16)
		&"discard":
			return hand_rect.merge(_discard.get_global_rect().grow(16))
	return Rect2()

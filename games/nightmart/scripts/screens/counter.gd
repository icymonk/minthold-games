extends ScreenBase
## 0-2 계산대 맛보기: 손패 8장에서 골라 계산하거나 바꾼다. 점수는 가격 합만 센다(조합은 1-1).

const HAND_SIZE := 8
const MAX_PICK := 5
const COACH_STEPS := [
	{"id": &"pick", "text": "COACH_PICK", "icon": Art.HAND, "wait": &"picked"},
	{"id": &"checkout", "text": "COACH_CHECKOUT", "icon": Art.ICON_CHECKOUT, "wait": &"checked_out"},
	{"id": &"discard", "text": "COACH_DISCARD", "icon": Art.ICON_DISCARD, "wait": &"discarded"},
]

var _rng: RandomNumberGenerator
var _hand: HBoxContainer
var _sales: Label
var _checkout: Button
var _discard: Button
var _coach: Coach
var _total := 0
var _busy := false


func _ready() -> void:
	_rng = (Game.rng if Game.rng else RngStreams.new(Game.run_seed)).deck
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, 96)
	for side in [&"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 54)
	add_child(margin)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", Style.GAP)
	margin.add_child(_list)
	var top := HBoxContainer.new()
	_list.add_child(top)
	_button(Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), top).custom_minimum_size = Vector2(300, 112)
	_label(tr("COUNTER_HINT"), Style.HEADLINE).size_flags_vertical = Control.SIZE_EXPAND_FILL
	_sales = _label(tr("COUNTER_SALES") % 0, Style.SCORE)
	_sales.add_theme_color_override(&"font_color", Style.PRICE)
	_sales.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_hand = HBoxContainer.new()
	_hand.alignment = BoxContainer.ALIGNMENT_CENTER
	_hand.add_theme_constant_override(&"separation", 16)
	_list.add_child(_hand)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(row)
	_checkout = _button(Art.ICON_CHECKOUT, tr("COUNTER_CHECKOUT"), _on_checkout, row)
	_checkout.theme_type_variation = &"AccentButton"
	_discard = _button(Art.ICON_DISCARD, tr("COUNTER_DISCARD"), _on_discard, row)
	for i in HAND_SIZE:
		_deal()
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


func _deal() -> void:
	var card := ProductCard.new().setup(Art.CORNERS[_rng.randi_range(0, 3)], _rng.randi_range(1, 13))
	card.toggled.connect(_on_card_toggled.bind(card))
	_hand.add_child(card)


func _on_card_toggled(on: bool, card: ProductCard) -> void:
	if on and picked().size() > MAX_PICK:
		card.set_pressed_no_signal(false)
		Sfx.play(&"error")
		return
	Sfx.play(&"pick" if on else &"place")
	_refresh()
	if on:
		_coach.notify(&"picked")


func _refresh() -> void:
	var none := picked().is_empty()
	_checkout.disabled = none or _busy
	_discard.disabled = none or _busy


func _on_checkout() -> void:
	var cards := picked()
	_busy = true
	_refresh()
	_coach.pause()
	for card in cards:
		_total += card.rank * 100
		Sfx.play(&"scan", 0.8, 1.0 + card.rank * 0.02)
		_sales.text = tr("COUNTER_SALES") % _total
		_pop(_sales, 1.15)
		var tw := create_tween()
		tw.tween_property(card, ^"modulate", Color(Style.NEON, 1.0), 0.08)
		tw.tween_property(card, ^"modulate:a", 0.0, 0.18)
		await tw.finished
	Sfx.play(&"cash")
	_pop(_sales, 1.35)
	await _replace(cards)
	_coach_done(&"checked_out")


func _on_discard() -> void:
	var cards := picked()
	_busy = true
	_refresh()
	_coach.pause()
	var tw := create_tween().set_parallel()
	for card in cards:
		tw.tween_property(card, ^"modulate:a", 0.0, 0.2)
	await tw.finished
	await _replace(cards)
	_coach_done(&"discarded")


func _replace(cards: Array[ProductCard]) -> void:
	for card in cards:
		card.queue_free()
	for card in cards:
		_deal()
	Sfx.play(&"deal")
	await get_tree().process_frame
	_busy = false
	_refresh()


func _coach_done(event: StringName) -> void:
	if _coach.waiting_for() == event:
		_coach.notify(event)
	else:
		_coach.resume()


func _pop(node: Control, to: float) -> void:
	node.pivot_offset = node.size / 2.0
	var tw := create_tween()
	tw.tween_property(node, ^"scale", Vector2.ONE * to, 0.08)
	tw.tween_property(node, ^"scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _coach_rect(step: StringName) -> Rect2:
	var hand_rect := _hand.get_global_rect().grow(24)
	match step:
		&"pick":
			return hand_rect
		&"checkout":
			return _checkout.get_global_rect().grow(16)
		&"discard":
			return hand_rect.merge(_discard.get_global_rect().grow(16))
	return Rect2()

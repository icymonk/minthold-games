extends ScreenBase
## 발주: 꿀팁·택배·상품 팩·매장 확장을 사고, 가진 꿀팁을 팔거나 택배를 뜯는다.

const COACH_STEPS := [
	{"id": &"buy_tip", "text": "COACH_BUY_TIP", "icon": Art.HAND, "wait": &"bought_tip"},
]

const OWNED_WIDTH := 168

var run: Run
var _coach: Coach
var _tip_row: HBoxContainer


func _ready() -> void:
	if Game.run == null:
		Game.run = Run.new(Game.run_seed)
	run = Game.run
	_coach = Coach.new()
	_coach.rect_of = func(_step: StringName) -> Rect2: return _tip_row.get_global_rect().grow(16) if _tip_row else Rect2()
	add_child(_coach)
	_build()
	await get_tree().process_frame
	await get_tree().process_frame
	if is_inside_tree() and run.phase == Run.Phase.SHOP:
		_coach.start(&"shop", COACH_STEPS)


func offer_buttons() -> Array[Button]:
	var out: Array[Button] = []
	for b in find_children("Offer*", "Button", true, false):
		if not b.is_queued_for_deletion():
			out.append(b)
	return out


func _build() -> void:
	_clear()
	var money := _frame(tr("SHOP_TITLE"))
	money.text = Names.money(run.money)
	if run.phase == Run.Phase.PACK:
		_build_pack()
		return
	_tip_row = _row()
	var other := _row()
	for i in run.shop.offers.size():
		var o := run.shop.offers[i]
		_offer(_tip_row if o.kind in [Shop.TIP, Shop.EXPANSION] else other, i, o)
	var owned := _row()
	owned.name = "Owned"
	owned.add_theme_constant_override(&"separation", 16)
	for i in run.tips.size():
		_small(owned, "%s\n%s" % [Names.tip(run.tips[i].id), tr("SHOP_SELL") % Names.money(run.sell_price(i))], _sell.bind(i))
	for i in run.consumables.size():
		_small(owned, "%s\n%s" % [tr("PARCEL_NAME") % Names.combo(run.consumables[i]), tr("SHOP_OPEN")], _open.bind(i))
	for e in run.expansions:
		_small(owned, Names.expansion(e.id), Callable()).disabled = true
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(spacer)
	var buttons := _row()
	var reroll := _button(Art.ICON_RETRY, tr("SHOP_REROLL") % Names.money(run.reroll_price()), _reroll, buttons)
	reroll.disabled = run.money < run.reroll_price()
	_button(Art.ICON_NEXT, tr("END_NEXT"), _leave, buttons).theme_type_variation = &"AccentButton"


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(row)
	return row


func _offer(row: HBoxContainer, i: int, o: Dictionary) -> void:
	var b := Button.new()
	b.name = "Offer%d" % i
	b.custom_minimum_size = Vector2(400, 220)
	b.disabled = not run.can_buy(i)
	b.pressed.connect(_buy.bind(i))
	row.add_child(b)
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_left = 20
	col.offset_right = -20
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	var fade := 0.4 if b.disabled else 1.0
	_text(col, Names.offer_name(o), Style.BODY, Color(Style.CORNER.get(&"goods") if o.kind == Shop.TIP else Style.FLUORESCENT, fade))
	var desc := _text(col, Names.offer_desc(o), 28, Color(Style.FLUORESCENT, 0.75 * fade))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var price := tr("SHOP_SOLD") if o.sold else Names.money(run.price_of(i))
	_text(col, price, Style.BODY, Color(Style.PRICE, fade))
	for c in col.get_children():
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


## 가진 물건 칸. 꿀팁 5 + 택배 2 + 확장이 다 차도 한 줄에 들어가게 폭을 고정한다.
func _small(row: HBoxContainer, text: String, on_pressed: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(OWNED_WIDTH, 112)
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.clip_text = true
	b.add_theme_font_size_override(&"font_size", 24)
	if on_pressed.is_valid():
		b.pressed.connect(func() -> void: Sfx.play(&"click"))
		b.pressed.connect(on_pressed)
	row.add_child(b)
	return b


func _build_pack() -> void:
	_label(tr("SHOP_PACK_PICK"), Style.HEADLINE)
	var row := _row()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for i in run.pack.size():
		var card := ProductCard.new().setup_card(run.pack[i])
		card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		card.pressed.connect(_choose.bind(i))
		row.add_child(card)
	_button(Art.ICON_NEXT, tr("SHOP_PACK_SKIP"), _choose.bind(-1))


func _buy(i: int) -> void:
	var kind: StringName = run.shop.offers[i].kind
	if not run.buy(i):
		Sfx.play(&"error")
		return
	Sfx.play(&"cash")
	_build()
	if kind == Shop.TIP:
		_coach.notify(&"bought_tip")


func _choose(i: int) -> void:
	run.choose_pack(i)
	Sfx.play(&"deal" if i >= 0 else &"click")
	_build()


func _sell(i: int) -> void:
	if run.sell_tip(i):
		Sfx.play(&"cash")
		_build()


func _open(i: int) -> void:
	if run.use_consumable(i):
		Sfx.play(&"chime")
		_build()


func _reroll() -> void:
	if run.reroll():
		Sfx.play(&"shuffle")
		_build()


func _leave() -> void:
	if run.leave_shop():
		Game.goto(&"map")

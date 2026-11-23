extends ScreenBase
## 숲지기 오두막(2-2): 보상 3장 중 1장, 솔방울 가게(새 카드·정령·카드 빼기·땅 넓히기), 다음 계절.
## 숲 섬은 뒤에 그대로 보이고, 땅을 넓히면 둘레에 작은 섬이 떠오른다.

const MINI := 0.34

var _col: VBoxContainer
var _offers: HBoxContainer
var _shop: HBoxContainer
var _acorns: Label
var _spirits: Label
var _picker: Control
## 가게 진열(오두막에 들어올 때 한 번 정한다)
var _stock: Array[Dictionary] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(Style.FOREST, 0.35)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_col = _frame()
	_col.add_theme_constant_override(&"separation", 12)
	var top := _row(_col)
	_label(top, tr("CABIN_TITLE"), Style.HEADLINE, Style.SUNSET)
	_acorns = _label(top, "", Style.BODY, Style.SPROUT)
	if Game.run == null:
		return
	if Game.last_score:
		_label(top, tr("CABIN_SCORE") % Game.last_score.total, 32)
	_spirits = _label(_col, "", 28, Color(Style.CREAM, 0.9))
	if not Game.fresh.is_empty():
		var names := Game.fresh.map(func(k: StringName) -> String: return tr("KIND_%s" % String(k).to_upper()))
		var fresh := _label(_col, tr("CODEX_NEW") % ", ".join(names), 28, Style.SUNSET)
		fresh.clip_text = true
		fresh.tooltip_text = fresh.text
	_label(_col, tr("CABIN_PICK"), 30, Color(Style.CREAM, 0.85))
	_offers = _row(_col, 20)
	_spacer(_col)
	_label(_col, tr("CABIN_SHOP"), 30, Color(Style.CREAM, 0.85))
	_shop = _row(_col, 20)
	var bottom := _row(_col)
	var next := Game.run.season_index
	_label(bottom, tr("CABIN_EVENT") % tr("EVENT_%s" % String(Game.run.events[next]).to_upper()), 30, Style.SUNSET)
	var go := _button(bottom, Art.ICON_NEXT, tr("CABIN_NEXT") % Game.season_name(next), Game.next_season, 480)
	go.theme_type_variation = &"AccentButton"
	go.custom_minimum_size.y = 110
	_stock = [
		{t = &"pair", cards = [Reward.new_pair(Game.run.rng, Game.run.new_id()), Reward.new_pair(Game.run.rng, Game.run.new_id())]},
		{t = &"remove"},
		{t = &"land"},
		{t = &"deco", deco = Cards.DECOS[Game.run.rng.randi_range(0, Cards.DECOS.size() - 1)]},
	]
	var free := Spirits.ALL.keys().filter(func(k: StringName) -> bool: return not Game.run.owned().has(k))
	if not free.is_empty():
		_stock.insert(1, {t = &"spirit", id = free[Game.run.rng.randi_range(0, free.size() - 1)]})
	_refresh()
	go.grab_focus()


func _refresh() -> void:
	_acorns.text = tr("CABIN_ACORNS") % Game.run.acorns
	var names := Game.run.spirits.map(func(id: StringName) -> String: return tr("SPIRIT_%s" % String(id).to_upper()))
	_spirits.text = tr("CABIN_SPIRITS") % [Game.run.spirits.size(), Spirits.SLOTS, ", ".join(names) if not names.is_empty() else "—"]
	for c in _offers.get_children():
		c.queue_free()
	for i in Game.run.offers.size():
		var b := _item(_offers, Game.run.offers[i], "")
		b.pressed.connect(_take.bind(i))
	_offers.get_parent().get_child(_offers.get_index() - 1).visible = not Game.run.offers.is_empty()
	for c in _shop.get_children():
		c.queue_free()
	for item in _stock:
		var price: int = Reward.PRICES[item.t]
		var b := _item(_shop, item, tr("CABIN_PRICE") % price)
		b.disabled = Game.run.acorns < price or (item.t == &"land" and Game.run.forest.plots >= Forest.MAX_PLOTS) \
			or (item.t == &"spirit" and Game.run.spirits.size() >= Spirits.SLOTS)
		b.pressed.connect(_buy.bind(item))


## 보상·상품 한 칸: 새 카드면 카드 두 장 그림, 나머지는 이름과 설명
func _item(parent: Control, o: Dictionary, price: String) -> Button:
	var b := Button.new()
	b.custom_minimum_size = Vector2(320, 220)
	b.add_theme_font_override(&"font", Style.bold())
	b.add_theme_font_size_override(&"font_size", 28)
	b.pressed.connect(func() -> void: Sfx.play(&"click"))
	parent.add_child(b)
	var col := VBoxContainer.new()
	col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 14)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	b.add_child(col)
	match o.t:
		&"pair":
			var row := HBoxContainer.new()
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			col.add_child(row)
			for c in o.cards:
				var box := Control.new()
				box.custom_minimum_size = CardView.CARD * MINI
				box.mouse_filter = Control.MOUSE_FILTER_IGNORE
				var v := CardView.make(c, _portraits())
				v.scale = Vector2.ONE * MINI
				v.pivot_offset = Vector2.ZERO
				v.mouse_filter = Control.MOUSE_FILTER_IGNORE
				box.add_child(v)
				row.add_child(box)
			_small(col, tr("CABIN_PAIR"), Style.CREAM)
		&"spirit":
			_small(col, tr("SPIRIT_%s" % String(o.id).to_upper()), Style.SUNSET, 34)
			_small(col, tr("SPIRIT_%s_DESC" % String(o.id).to_upper()), Style.CREAM)
		&"remove":
			_small(col, tr("CABIN_REMOVE"), Style.SUNSET, 34)
			_small(col, tr("CABIN_REMOVE_DESC"), Style.CREAM)
		&"deco":
			_small(col, tr("CABIN_DECO_DEW") if o.deco == &"dew" else tr("CABIN_DECO_GOLD"), Style.SUNSET, 34)
			_small(col, tr("CABIN_DECO_DEW_DESC") % Cards.DEW_POINTS if o.deco == &"dew" else tr("CABIN_DECO_GOLD_DESC"), Style.CREAM)
		&"land":
			_small(col, tr("CABIN_LAND"), Style.SUNSET, 34)
			_small(col, tr("CABIN_LAND_DESC") % [Game.run.forest.plots, Forest.MAX_PLOTS], Style.CREAM)
	if price != "":
		_small(col, price, Style.SPROUT, 30)
	return b


func _small(parent: Control, text: String, color: Color, size := 26) -> void:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 290
	l.add_theme_font_override(&"font", Style.bold())
	l.add_theme_font_size_override(&"font_size", size)
	l.add_theme_color_override(&"font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)


var _portrait: Portrait


func _portraits() -> Portrait:
	if not _portrait:
		_portrait = Portrait.new()
		add_child(_portrait)
	return _portrait


func _take(i: int) -> void:
	if Game.run.offers[i].t == &"remove":
		_pick_cards(func(ids: Array[int]) -> void:
			if Game.take_reward(i, ids):
				_refresh())
		return
	if Game.take_reward(i):
		Sfx.play(&"chime")
		_refresh()


func _buy(item: Dictionary) -> void:
	if item.t in [&"remove", &"deco"]:
		_pick_cards(func(ids: Array[int]) -> void:
			if Game.buy(item, ids):
				_stock.erase(item)
				_refresh(), 1 if item.t == &"deco" else Reward.REMOVE)
		return
	if Game.buy(item):
		Sfx.play(&"chime")
		if item.t != &"land":
			_stock.erase(item)
		_refresh()


## 씨앗 주머니에서 카드 n장 고르기(빼기 2장, 꾸미기 1장)
func _pick_cards(done: Callable, n := Reward.REMOVE) -> void:
	if _picker:
		_picker.queue_free()
	_picker = PanelContainer.new()
	_picker.add_theme_stylebox_override(&"panel", Style.glass(28))
	_picker.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(_picker)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	_picker.add_child(col)
	_label(col, tr("CABIN_REMOVE_PICK") % n if n == Reward.REMOVE else tr("CABIN_DECO_PICK"), 34, Style.SUNSET)
	var grid := GridContainer.new()
	grid.columns = 13
	grid.add_theme_constant_override(&"h_separation", 6)
	grid.add_theme_constant_override(&"v_separation", 6)
	col.add_child(grid)
	var chosen: Array[int] = []
	var ok := _button(_row(col), Art.ICON_NEXT, tr("CABIN_REMOVE_OK") if n == Reward.REMOVE else tr("SEASON_PAY_OK"), func() -> void:
		_picker.queue_free()
		_picker = null
		done.call(chosen), 360)
	ok.disabled = true
	_button(ok.get_parent(), null, tr("SEASON_CANCEL"), func() -> void:
		_picker.queue_free()
		_picker = null, 240)
	for c in Game.run.bag:
		var b := Button.new()
		b.flat = true
		b.toggle_mode = true
		b.custom_minimum_size = CardView.CARD * 0.36
		var v := CardView.make(c, _portraits())
		v.scale = Vector2.ONE * 0.36
		v.pivot_offset = Vector2.ZERO
		v.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(v)
		grid.add_child(b)
		b.toggled.connect(func(on: bool) -> void:
			if on and chosen.size() >= n:
				b.set_pressed_no_signal(false)
				return
			if on:
				chosen.append(c.id)
			else:
				chosen.erase(c.id)
			v.modulate = Style.BERRY.lightened(0.4) if on else Color.WHITE
			ok.disabled = chosen.size() != n)

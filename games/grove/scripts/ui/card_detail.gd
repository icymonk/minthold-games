class_name CardDetail
extends PanelContainer
## 카드 상세 창: 손패 카드에 마우스를 올리거나 누르면, 숲에 붙은 나무·이웃에 마우스를 올리면 뜬다.
## 크게 그린 카드와 함께 반쪽마다 비용·효과·보너스·점수를 글로 보여 준다.

const TEXT_W := 500.0
const BIG := 1.45
const LINK := Color("#FFD27A")
## 마우스가 기준 칸과 창 밖에 이만큼 머물면 닫는다(auto_close)
const CLOSE_GRACE := 0.3

var _tip: PanelContainer
var _anchor := Rect2()
var _away := 0.0
var _keys: Array[String] = []


## 손패 카드: 크게 그린 카드 + 반쪽 설명(active: 지금 쓸 반쪽)
static func for_card(card: Dictionary, portraits: Portrait, active := 0) -> CardDetail:
	var d := CardDetail.new()
	var row := d._row()
	var holder := Control.new()
	holder.custom_minimum_size = CardView.CARD * BIG
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var big := CardView.make(card, portraits)
	big.mouse_filter = Control.MOUSE_FILTER_IGNORE
	big.scale = Vector2.ONE * BIG
	big.pivot_offset = Vector2.ZERO
	big.set_half(active)
	holder.add_child(big)
	row.add_child(holder)
	var col := d._col(row)
	var kinds: Array = [card.tree] if Cards.is_tree(card) else [card.halves[0], card.halves[1]]
	for k: StringName in kinds:
		for t in CardText.term_keys(k):
			if not t in d._keys:
				d._keys.append(t)
	if not Cards.is_tree(card):
		d._keys.append("TERM_HALF")
	if Cards.is_tree(card):
		d._half(col, card.tree, true, card.tree)
	else:
		for i in 2:
			d._half(col, card.halves[i], i == active, Cards.sym_of(card, i))
		d._rich(col, d._link(TranslationServer.translate("CARD_HALF_USE")), 20, Color(Style.CREAM, 0.7))
	d._deco(col, card)
	d._legend(col, kinds)
	return d


## 숲에 붙은 카드: 그 종 하나(pts >= 0이면 지금 점수, where: 붙은 곳)
static func for_kind(kind: StringName, pts := -1, where := "", card := {}) -> CardDetail:
	var d := CardDetail.new()
	var col := d._col(d._row())
	if where != "":
		d._line(col, where, 22, Color(Style.CREAM, 0.7))
	if kind == Forest.SAPLING:
		d._line(col, TranslationServer.translate("CARD_SAPLING"), 22, Style.CREAM)
	else:
		var sym := Cards.placed_sym(card, kind) if not card.is_empty() else &""
		d._keys = CardText.term_keys(kind)
		d._half(col, kind, true, kind if Cards.TREES.has(kind) else sym)
	if pts >= 0:
		d._line(col, TranslationServer.translate("CARD_NOW") % pts, 30, Style.SUNSET, true)
	d._deco(col, card)
	if kind != Forest.SAPLING:
		d._legend(col, [kind])
	return d


## 아이콘 설명 전체(? 옆 버튼)
static func legend() -> CardDetail:
	var d := CardDetail.new()
	var outer := VBoxContainer.new()
	outer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := d._row()
	row.get_parent().remove_child(row)
	var pad: MarginContainer = d.get_child(0)
	pad.add_child(outer)
	d._line(outer, TranslationServer.translate("LEGEND_TITLE"), 30, Style.SUNSET, true)
	outer.add_child(row)
	var cols := [d._col(row), d._col(row)]
	var names: Array = [&"acorn"] + Art.ICONS.keys()
	var half := ceili(names.size() / 2.0)
	for i in names.size():
		d._icon_row(cols[0 if i < half else 1], names[i])
	for k in ["ICON_STAR", "ICON_HOOK", "ICON_ARROW"]:
		d._line(cols[1], TranslationServer.translate(k), 20, Color(Style.CREAM, 0.85))
	return d


func _init() -> void:
	set_process(false)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true
	z_index = 50
	add_theme_stylebox_override(&"panel", Style.box(Color(Style.FOREST, 0.94), 22, Color(Style.CREAM, 0.5), 2, 18))


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 20)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pad := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + s, 16)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pad.add_child(row)
	add_child(pad)
	return row


func _col(row: HBoxContainer) -> VBoxContainer:
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = TEXT_W
	col.add_theme_constant_override(&"separation", 6)
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col)
	return col


func _half(col: VBoxContainer, kind: StringName, active: bool, sym: StringName = &"") -> void:
	var def := CardText.def_of(kind)
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_theme_stylebox_override(&"panel", Style.box(Color(Style.SUNSET, 0.05) if active else Color(0, 0, 0, 0), 12, Style.SUNSET if active else Color(Style.CREAM, 0.2), 3 if active else 2, 10))
	col.add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	frame.add_child(box)
	var group := CardText.group_of(&"tree") if Cards.TREES.has(kind) else CardText.group_of(def.kind)
	var gi := CardText.gicon(&"tree") if Cards.TREES.has(kind) else CardText.gicon(def.kind)
	var meta := [gi + " " + group, _link(TranslationServer.translate("CARD_COST") % def.cost)]
	if def.has("side"):
		meta.insert(1, CardText.sicon(def.side) + " " + _link(CardText.side_of(def.side)))
	if sym != &"":
		meta.append("{t_%s} " % sym + _link(TranslationServer.translate("CARD_COLOR") % CardText.name_of(sym)))
	_line(box, CardText.name_of(kind), 34, Style.SUNSET if active else Style.CREAM, true)
	_rich(box, " · ".join(meta), 22, Color(Style.CREAM, 0.8))
	_pair(box, "CARD_EFFECT", CardText.gives(def.get("effect", {})), CardText.gives(def.get("effect", {}), true))
	_pair(box, "CARD_BONUS", CardText.gives(def.get("bonus", {})), CardText.gives(def.get("bonus", {}), true))
	_pair(box, "CARD_SCORE", CardText.rule(kind), "{acorn}")
	var hook := CardText.hook(kind)
	if hook != "":
		_rich(box, "∞ %s  %s" % [CardText.hook(kind, true), _link(hook)], 22, Style.SPROUT)
	if Dweller.KINDS.get(kind, {}).get("stack", false):
		_line(box, TranslationServer.translate("CARD_STACK"), 20, Color(Style.CREAM, 0.6))
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	col.add_child(gap)


## 이 카드의 아이콘 설명 + 용어 안내(밑줄 친 말에 마우스를 올리면 풀이)
func _legend(col: VBoxContainer, kinds: Array) -> void:
	var icons: Array[StringName] = []
	for k in kinds:
		var f := CardText.face(k)
		var text: String = f.get("text", "")
		for c in CardText.chips(k):
			text += c.text
		if not f.is_empty():
			text = "{acorn}" + text
		for n in Glyph.icons_in(text):
			if not n in icons:
				icons.append(n)
	if not icons.is_empty():
		_line(col, TranslationServer.translate("LEGEND_CARD"), 22, Style.SPROUT, true)
		var grid := GridContainer.new()
		grid.columns = 2
		grid.add_theme_constant_override(&"h_separation", 16)
		grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
		col.add_child(grid)
		for n in icons:
			_icon_row(grid, n, true)
	_line(col, TranslationServer.translate("CARD_TERMS_HINT"), 18, Color(Style.CREAM, 0.6))


## 아이콘 한 줄: [그림] 짧은 이름(short) 또는 설명 전체
func _icon_row(parent: Control, n: StringName, short := false) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 8)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(row)
	var t := TextureRect.new()
	t.texture = Art.icon(n)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(30, 30)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(t)
	var key := "ICON_" + String(n).to_upper()
	var text := TranslationServer.translate(key).get_slice(":", 0) if short else tip_of(key)
	var l := _line(row, text, 18, Color(Style.CREAM, 0.85))
	l.custom_minimum_size.x = 200 if short else 420


## 풀이 글: ICON_* / TERM_*. 분류 아이콘은 속한 종도 함께
static func tip_of(meta: String) -> String:
	var text := TranslationServer.translate(meta)
	if meta.begins_with("ICON_G_") and meta != "ICON_G_TREE":
		var g := StringName(meta.trim_prefix("ICON_G_").to_lower())
		text += "\n" + CardText.members(g)
	return text


## 글 속 용어(이 카드에 나오는 것만)를 [[TERM_X|말]] 링크로. 링크 안쪽은 다시 건드리지 않는다.
func _link(text: String) -> String:
	var keys := _keys.duplicate()
	for k in ["TERM_COST", "TERM_EFFECT", "TERM_BONUS", "TERM_ACORN"]:
		if not k in keys:
			keys.append(k)
	keys.sort_custom(func(a: String, b: String) -> bool: return _word(a).length() > _word(b).length())
	for k in keys:
		var w := _word(k)
		if w == "" or w == k.replace("TERM_", "TERMW_"):
			continue
		var at := _free_find(text, w)
		if at >= 0:
			text = text.substr(0, at) + "[[%s|%s]]" % [k, w] + text.substr(at + w.length())
	return text


static func _word(key: String) -> String:
	return TranslationServer.translate(key.replace("TERM_", "TERMW_"))


## 이미 링크인 곳 밖에서 w를 찾는다
static func _free_find(text: String, w: String) -> int:
	var from := 0
	while true:
		var at := text.find(w, from)
		if at < 0:
			return -1
		var open := text.rfind("[[", at)
		var close := text.rfind("]]", at)
		if open < 0 or close > open:
			return at
		from = at + w.length()
	return -1


## 링크·아이콘이 들어간 한 줄
func _rich(parent: Control, text: String, font_size: int, color: Color, bold := false) -> RichTextLabel:
	var rt := RichTextLabel.new()
	rt.fit_content = true
	rt.scroll_active = false
	rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rt.custom_minimum_size.x = TEXT_W
	rt.mouse_filter = Control.MOUSE_FILTER_PASS
	rt.meta_underlined = false
	rt.add_theme_font_size_override(&"normal_font_size", font_size)
	rt.add_theme_color_override(&"default_color", color)
	if bold:
		rt.add_theme_font_override(&"normal_font", Style.bold())
	Glyph.fill(rt, text, font_size + 8, true, LINK)
	rt.meta_hover_started.connect(func(meta: Variant) -> void: _show_tip(String(meta)))
	rt.meta_hover_ended.connect(func(_meta: Variant) -> void: _hide_tip())
	rt.meta_clicked.connect(func(meta: Variant) -> void:
		if is_instance_valid(_tip):
			_hide_tip()
		else:
			_show_tip(String(meta)))
	parent.add_child(rt)
	return rt


func _show_tip(meta: String) -> void:
	_hide_tip()
	_tip = PanelContainer.new()
	_tip.top_level = true
	_tip.z_index = 60
	_tip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_tip.add_theme_stylebox_override(&"panel", Style.box(Color(Style.CREAM, 0.97), 12, Style.SUNSET, 2, 10))
	var l := Label.new()
	l.text = tip_of(meta)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 380
	l.add_theme_font_size_override(&"font_size", 20)
	l.add_theme_color_override(&"font_color", Style.FOREST)
	l.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 12)
	pad.add_child(l)
	_tip.add_child(pad)
	add_child(_tip)
	var view := get_viewport_rect().size
	var s := _tip.get_combined_minimum_size()
	var m := get_global_mouse_position()
	_tip.global_position = Vector2(clampf(m.x + 18, 8, view.x - s.x - 8), clampf(m.y + 22, 8, view.y - s.y - 8))


func _hide_tip() -> void:
	if is_instance_valid(_tip):
		_tip.queue_free()
	_tip = null


## 마우스가 기준 칸(anchor)과 이 창 밖에 잠깐 머물면 스스로 닫는다(창 위 용어에 마우스를 올릴 수 있게)
func auto_close(anchor: Rect2) -> void:
	_anchor = anchor
	set_process(true)


func _process(delta: float) -> void:
	var m := get_global_mouse_position()
	if _anchor.grow(8).has_point(m) or get_global_rect().grow(8).has_point(m) or _gap().has_point(m):
		_away = 0.0
		return
	_away += delta
	if _away > CLOSE_GRACE:
		queue_free()


## 기준 칸과 창을 함께 덮는 사각형(사이 틈 포함)
func _gap() -> Rect2:
	return get_global_rect().merge(_anchor)


func _deco(col: VBoxContainer, card: Dictionary) -> void:
	match card.get("deco", &""):
		&"dew":
			_line(col, TranslationServer.translate("CARD_DEW") % Cards.DEW_POINTS, 18, CardView.DEW.lightened(0.3))
		&"gold":
			_line(col, TranslationServer.translate("CARD_ANY_COLOR"), 18, CardView.GOLD)


func _pair(box: VBoxContainer, key: String, text: String, icons := "") -> void:
	if text == "":
		text = TranslationServer.translate("CARD_NONE")
		icons = ""
	var label := _link(TranslationServer.translate(key))
	_rich(box, "%s  %s  %s" % [label, icons, _link(text)], 24, Style.CREAM)


func _line(parent: Control, text: String, font_size: int, color: Color, bold := false) -> Label:
	var l := Label.new()
	l.text = text
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = TEXT_W
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_color", color)
	if bold:
		l.add_theme_font_override(&"font", Style.bold())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


## 기준 사각형(rect, 전역 좌표) 위쪽(없으면 아래)에 화면 안으로 맞춰 띄운다.
func place_near(rect: Rect2, view: Vector2) -> void:
	reset_size()
	var s := get_combined_minimum_size()
	var x := clampf(rect.get_center().x - s.x / 2.0, 16.0, view.x - s.x - 16.0)
	var y := rect.position.y - s.y - 16.0
	if y < 16.0:
		y = minf(rect.end.y + 16.0, view.y - s.y - 16.0)
	global_position = Vector2(x, maxf(y, 16.0))

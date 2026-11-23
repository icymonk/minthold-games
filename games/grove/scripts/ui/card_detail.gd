class_name CardDetail
extends PanelContainer
## 카드 상세 창: 손패 카드에 마우스를 올리거나 누르면, 숲에 붙은 나무·이웃에 마우스를 올리면 뜬다.
## 크게 그린 카드와 함께 반쪽마다 비용·효과·보너스·점수를 글로 보여 준다.

const TEXT_W := 500.0
const BIG := 1.45


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
	var terms: Array[String] = []
	if Cards.is_tree(card):
		d._half(col, card.tree, true, card.tree)
		terms = CardText.terms(card.tree)
	else:
		for i in 2:
			d._half(col, card.halves[i], i == active, Cards.sym_of(card, i))
			for t in CardText.terms(card.halves[i]):
				if not t in terms:
					terms.append(t)
		terms.append(TranslationServer.translate("TERM_HALF"))
		d._line(col, TranslationServer.translate("CARD_HALF_USE"), 20, Color(Style.CREAM, 0.6))
	d._deco(col, card)
	d._terms(col, terms)
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
		d._half(col, kind, true, kind if Cards.TREES.has(kind) else sym)
	if pts >= 0:
		d._line(col, TranslationServer.translate("CARD_NOW") % pts, 30, Style.SUNSET, true)
	d._deco(col, card)
	if kind != Forest.SAPLING:
		d._terms(col, CardText.terms(kind))
	return d


func _init() -> void:
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
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 2)
	box.modulate = Color.WHITE if active else Color(1, 1, 1, 0.55)
	col.add_child(box)
	var group := CardText.group_of(&"tree") if Cards.TREES.has(kind) else CardText.group_of(def.kind)
	var meta := [group, TranslationServer.translate("CARD_COST") % def.cost]
	if def.has("side"):
		meta.insert(1, CardText.side_of(def.side))
	if sym != &"":
		meta.append(TranslationServer.translate("CARD_COLOR") % CardText.name_of(sym))
	_line(box, CardText.name_of(kind), 34, Style.SUNSET if active else Style.CREAM, true)
	_line(box, " · ".join(meta), 22, Color(Style.CREAM, 0.75))
	_pair(box, "CARD_EFFECT", CardText.gives(def.get("effect", {})))
	_pair(box, "CARD_BONUS", CardText.gives(def.get("bonus", {})))
	_pair(box, "CARD_SCORE", CardText.rule(kind))
	var hook := CardText.hook(kind)
	if hook != "":
		_line(box, hook, 22, Style.SPROUT)
	if Dweller.KINDS.get(kind, {}).get("stack", false):
		_line(box, TranslationServer.translate("CARD_STACK"), 20, Color(Style.CREAM, 0.6))
	var gap := Control.new()
	gap.custom_minimum_size.y = 8
	col.add_child(gap)


## 용어 풀이: 카드에 나온 말을 작은 글로
func _terms(col: VBoxContainer, terms: Array[String]) -> void:
	if terms.is_empty():
		return
	_line(col, TranslationServer.translate("CARD_TERMS"), 22, Style.SPROUT, true)
	for t in terms:
		_line(col, "· " + t, 18, Color(Style.CREAM, 0.8))


func _deco(col: VBoxContainer, card: Dictionary) -> void:
	match card.get("deco", &""):
		&"dew":
			_line(col, TranslationServer.translate("CARD_DEW") % Cards.DEW_POINTS, 18, CardView.DEW.lightened(0.3))
		&"gold":
			_line(col, TranslationServer.translate("CARD_ANY_COLOR"), 18, CardView.GOLD)


func _pair(box: VBoxContainer, key: String, text: String) -> void:
	if text == "":
		text = TranslationServer.translate("CARD_NONE")
	_line(box, "%s  %s" % [TranslationServer.translate(key), text], 24, Style.CREAM)


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

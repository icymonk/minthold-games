class_name CardView
extends Control
## 손패의 카드 한 장. 나무 카드는 그림 하나, 이웃 카드는 반쪽 둘(위/아래 또는 왼/오른).

const CARD := Vector2(228, 330)
## 나무 색(카드 귀퉁이 동그라미)
const TREE_COLORS := {&"linden": Color("#A8C84A"), &"oak": Color("#8A6A2A"), &"fir": Color("#2F6A50"), &"birch": Color("#E8E2CC"),
	&"beech": Color("#C9853E"), &"maple": Color("#D85A3A"), &"pine": Color("#4F7FB0"), &"chestnut": Color("#7A3A2A")}
## 카드 꾸미기: 이슬 방울, 금빛 테두리
const DEW := Color("#5AA8E0")
const GOLD := Color("#E8C14A")

var card: Dictionary
var half := 0
var _halves: Array[Control] = []
var _frame: Panel


static func make(c: Dictionary, portraits: Portrait) -> CardView:
	var v := CardView.new()
	v.card = c
	v._build(portraits)
	return v


func _build(portraits: Portrait) -> void:
	custom_minimum_size = CARD
	size = CARD
	pivot_offset = CARD / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	var inner := Rect2(Vector2(10, 10), CARD - Vector2(20, 20))
	if DemoCards.is_tree(card):
		_halves.append(_half_box(card.tree, inner, Style.SPROUT, portraits, card.tree))
	elif card.axis == &"v":
		var h := inner.size.y / 2.0
		_halves.append(_half_box(card.halves[0], Rect2(inner.position, Vector2(inner.size.x, h - 4)), Dweller.KINDS[card.halves[0]].color, portraits, Cards.sym_of(card, 0)))
		_halves.append(_half_box(card.halves[1], Rect2(inner.position + Vector2(0, h + 4), Vector2(inner.size.x, h - 4)), Dweller.KINDS[card.halves[1]].color, portraits, Cards.sym_of(card, 1)))
	else:
		var w := inner.size.x / 2.0
		_halves.append(_half_box(card.halves[0], Rect2(inner.position, Vector2(w - 4, inner.size.y)), Dweller.KINDS[card.halves[0]].color, portraits, Cards.sym_of(card, 0)))
		_halves.append(_half_box(card.halves[1], Rect2(inner.position + Vector2(w + 4, 0), Vector2(w - 4, inner.size.y)), Dweller.KINDS[card.halves[1]].color, portraits, Cards.sym_of(card, 1)))
	if card.get("deco", &"") == &"dew":
		var dew := Panel.new()
		dew.add_theme_stylebox_override(&"panel", Style.box(DEW, 22, Style.CREAM, 3))
		dew.size = Vector2(44, 44)
		dew.position = Vector2(CARD.x - 50, 6)
		dew.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(dew)
		var plus := Label.new()
		plus.text = "+%d" % Cards.DEW_POINTS
		plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		plus.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		plus.add_theme_font_override(&"font", Style.bold())
		plus.add_theme_font_size_override(&"font_size", 20)
		plus.add_theme_color_override(&"font_color", Style.CREAM)
		plus.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		dew.add_child(plus)
	set_half(0)


func _half_box(kind: StringName, r: Rect2, color: Color, portraits: Portrait, sym: StringName) -> Control:
	var box := Panel.new()
	box.position = r.position
	box.size = r.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.clip_contents = true
	box.add_theme_stylebox_override(&"panel", Style.box(color.lightened(0.45), 12))
	add_child(box)
	var narrow := r.size.x < 150
	var w := r.size.x - 8
	# 아래 글 띠: 이름, 도토리 점수와 조건. 글이 길면 줄을 바꾸고 그림을 줄인다.
	var name_size := 15 if narrow else 21
	var rule_size := 13 if narrow else 15
	var font := Style.bold()
	var name_text := CardText.name_of(kind)
	var face := CardText.face(kind)
	var name_h := font.get_multiline_string_size(name_text, HORIZONTAL_ALIGNMENT_CENTER, w, name_size).y
	var rule_h := 0.0
	if not face.is_empty():
		rule_h = font.get_multiline_string_size("%s ●  %s" % [face.pts, face.text], HORIZONTAL_ALIGNMENT_CENTER, w, rule_size).y + 4.0
	var band := name_h + rule_h + 8.0
	var band_box := Panel.new()
	band_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band_box.add_theme_stylebox_override(&"panel", Style.box(Color(Style.CREAM, 0.92), 10))
	band_box.position = Vector2(2, r.size.y - band - 2)
	band_box.size = Vector2(r.size.x - 4, band)
	box.add_child(band_box)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var top := 36.0 if narrow else 4.0
	pic.position = Vector2(4, top)
	pic.size = Vector2(r.size.x - 8, maxf(r.size.y - band - top - 6, 24))
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	box.move_child(pic, 0)
	if portraits:
		portraits.request(kind, func(tex: Texture2D) -> void:
			if is_instance_valid(pic):
				pic.texture = tex)
	var name_label := Label.new()
	name_label.text = name_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_font_override(&"font", font)
	name_label.add_theme_font_size_override(&"font_size", name_size)
	name_label.add_theme_color_override(&"font_color", Style.FOREST)
	name_label.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	name_label.position = Vector2(2, 3)
	name_label.size = Vector2(w, name_h)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	band_box.add_child(name_label)
	if not face.is_empty():
		var rt := RichTextLabel.new()
		rt.fit_content = true
		rt.scroll_active = false
		rt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rt.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rt.add_theme_font_size_override(&"normal_font_size", rule_size)
		rt.add_theme_font_size_override(&"bold_font_size", rule_size + 3)
		rt.add_theme_font_override(&"bold_font", font)
		rt.add_theme_color_override(&"default_color", Style.FOREST.lightened(0.1))
		rt.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
		if face.pts != "":
			rt.push_bold()
			rt.add_text(face.pts)
			rt.pop()
		rt.add_image(Art.acorn(), rule_size + 5, rule_size + 5)
		if face.text != "":
			rt.add_text(" " + face.text)
		rt.pop()
		rt.position = Vector2(2, name_h + 4)
		rt.size = Vector2(w, rule_h)
		band_box.add_child(rt)
	box.add_child(_badge(str(CardText.def_of(kind).get("cost", 0)), Style.FOREST, Style.CREAM, Vector2(4, 4), 30))
	if sym != &"":
		var tone: Color = TREE_COLORS.get(sym, Style.MOSS)
		var dot := _badge(CardText.name_of(sym).left(1), tone, Style.FOREST if tone.get_luminance() > 0.6 else Style.CREAM, Vector2.ZERO, 28)
		dot.position = Vector2(r.size.x - dot.size.x - 4, 4)
		box.add_child(dot)
	var y := 36.0
	for c in CardText.chips(kind):
		var bg: Color = {effect = Style.SUNSET, bonus = GOLD, hook = Style.MOSS}[c.tone]
		var chip := _badge(c.text, bg, Style.FOREST if c.tone == &"bonus" else Style.CREAM, Vector2.ZERO, 22 if narrow else 26, w - (0.0 if narrow else 36.0))
		chip.position = Vector2(4 if narrow else r.size.x - chip.size.x - 4, y)
		box.add_child(chip)
		y += chip.size.y + 4.0
	return box


## 둥근 표시(비용 숫자·효과 칩). 크기는 글 길이에 맞춘다.
func _badge(text: String, bg: Color, fg: Color, at: Vector2, h: float, max_w := 0.0) -> Panel:
	var p := Panel.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_theme_stylebox_override(&"panel", Style.box(bg, h / 2.0, Color(Style.CREAM, 0.9), 2))
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_override(&"font", Style.bold())
	l.add_theme_font_size_override(&"font_size", int(h * 0.6))
	l.add_theme_color_override(&"font_color", fg)
	l.add_theme_color_override(&"font_shadow_color", Color.TRANSPARENT)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fs := int(h * 0.6)
	var w := maxf(h, Style.bold().get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x + 14.0)
	if max_w > 0.0 and w > max_w:
		# 좁은 반쪽: 줄을 바꿔 두 줄로
		w = max_w
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		h = Style.bold().get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, w - 10.0, fs).y + 6.0
	p.size = Vector2(w, h)
	p.position = at
	l.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	p.add_child(l)
	return p


## 쓸 반쪽을 밝히고 다른 반쪽은 어둡게
func set_half(i: int) -> void:
	half = i
	for k in _halves.size():
		_halves[k].modulate = Color.WHITE if k == i or _halves.size() == 1 else Color(0.45, 0.45, 0.5)
	var border := Style.SUNSET if _halves.size() > 1 else Style.MOSS
	if card.get("deco", &"") == &"gold":
		border = GOLD
	_frame.add_theme_stylebox_override(&"panel", Style.box(Style.CREAM, 18, border, 5, 10))


## 잡은 곳이 어느 반쪽인지(local: 카드 안 좌표)
func half_at(local: Vector2) -> int:
	if DemoCards.is_tree(card):
		return 0
	if card.axis == &"v":
		return 1 if local.y > CARD.y / 2.0 else 0
	return 1 if local.x > CARD.x / 2.0 else 0


func kind() -> StringName:
	return DemoCards.kind_of(card, half)


func side() -> StringName:
	return DemoCards.side_of(card, half)


## 붙일 곳이 없을 때: 빨갛게 떨린다
func shake() -> void:
	var x := position.x
	var tw := create_tween()
	modulate = Style.BERRY.lightened(0.3)
	for i in 4:
		tw.tween_property(self, ^"position:x", x + (12.0 if i % 2 == 0 else -12.0), 0.05)
	tw.tween_property(self, ^"position:x", x, 0.05)
	tw.tween_property(self, ^"modulate", Color.WHITE, 0.2)

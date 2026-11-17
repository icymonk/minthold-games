class_name ProductCard
extends Button
## 상품 카드 한 장: 코너 색 띠, 가격, 구운 상품 그림. 누르면 골라지고(toggle) 커진다.

const SIZE := Vector2(200, 280)

var corner: StringName
var rank: int
var card: Card
## 뒷면(진상 손님·정전): 그림·가격·꼬리표를 숨긴다.
var face_down := false


func setup(card_corner: StringName, card_rank: int) -> ProductCard:
	corner = card_corner
	rank = card_rank
	return self


func setup_card(c: Card, face_down := false) -> ProductCard:
	card = c
	self.face_down = face_down
	return setup(c.corner, c.rank)


func _ready() -> void:
	toggle_mode = true
	custom_minimum_size = SIZE
	pivot_offset = SIZE / 2.0
	for state in [&"normal", &"hover", &"focus", &"disabled"]:
		add_theme_stylebox_override(state, Style.card_box(false))
	add_theme_stylebox_override(&"hover", Style.card_box(false))
	add_theme_stylebox_override(&"pressed", Style.card_box(true))
	add_theme_stylebox_override(&"hover_pressed", Style.card_box(true))
	add_theme_stylebox_override(&"focus", Style.box(Color(0, 0, 0, 0), 18, Style.PRICE, 6))
	button_down.connect(_bump.bind(0.94))
	toggled.connect(func(on: bool) -> void: _bump(1.08 if on else 1.0))
	if face_down:
		_back()
		return
	var band := ColorRect.new()
	band.color = Style.CORNER[corner]
	band.position = Vector2(14, 14)
	band.size = Vector2(SIZE.x - 28, 12)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(band)
	var art := TextureRect.new()
	art.texture = Art.product(corner, rank)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.position = Vector2(20, 80)
	art.size = Vector2(SIZE.x - 40, SIZE.y - 100)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	var price := Label.new()
	price.text = str(rank)
	price.position = Vector2(20, 26)
	price.add_theme_font_override(&"font", Style.bold())
	price.add_theme_font_size_override(&"font_size", 48)
	price.add_theme_color_override(&"font_color", Style.CORNER[corner].darkened(0.2))
	add_child(price)
	if card and card.tag != Card.TAG_NONE:
		var tag := Label.new()
		tag.text = Names.t("TAG_%s" % String(card.tag).to_upper())
		tag.position = Vector2(SIZE.x - 120, 30)
		tag.size = Vector2(100, 40)
		tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tag.add_theme_font_override(&"font", Style.bold())
		tag.add_theme_font_size_override(&"font_size", 28)
		tag.add_theme_color_override(&"font_color", Style.ANGRY)
		tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(tag)
	if card and card.is_waste():
		art.modulate = Color(0.35, 0.35, 0.35)
		_corner_label(Names.t("CARD_WASTE"), Style.ANGRY)
	elif card and card.shelf_life > 0:
		_corner_label(Names.t("CARD_LIFE") % card.shelf_life, Style.ANGRY if card.shelf_life <= 1 else Style.CORNER[corner].darkened(0.3))


## 아래 가운데 작은 도장(유통기한·폐기)
func _corner_label(text: String, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(0, SIZE.y - 56)
	l.size = Vector2(SIZE.x, 40)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override(&"font", Style.bold())
	l.add_theme_font_size_override(&"font_size", 32)
	l.add_theme_color_override(&"font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)


func _back() -> void:
	for state in [&"normal", &"hover", &"disabled"]:
		add_theme_stylebox_override(state, Style.box(Style.NIGHT.lightened(0.15), 18, Color(Style.FLUORESCENT, 0.3), 4))
	var q := Label.new()
	q.text = "?"
	q.set_anchors_preset(Control.PRESET_FULL_RECT)
	q.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	q.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	q.add_theme_font_override(&"font", Style.bold())
	q.add_theme_font_size_override(&"font_size", 120)
	q.add_theme_color_override(&"font_color", Color(Style.FLUORESCENT, 0.5))
	q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(q)


## 계산 연출: 상품 하나 찍힐 때 튀어 오른다.
func flash() -> void:
	var tw := create_tween()
	tw.tween_property(self, ^"scale", Vector2.ONE * 1.18, 0.06)
	tw.parallel().tween_property(self, ^"modulate", Color(Style.NEON.lightened(0.5), 1.0), 0.06)
	tw.tween_property(self, ^"scale", Vector2.ONE * 1.08, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, ^"modulate", Color.WHITE, 0.16)


func _bump(to: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, ^"scale", Vector2.ONE * to, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

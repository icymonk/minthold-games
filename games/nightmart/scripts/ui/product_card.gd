class_name ProductCard
extends Button
## 상품 카드 한 장: 코너 색 띠, 가격, 구운 상품 그림. 누르면 골라지고(toggle) 커진다.

const SIZE := Vector2(200, 280)

var corner: StringName
var rank: int


func setup(card_corner: StringName, card_rank: int) -> ProductCard:
	corner = card_corner
	rank = card_rank
	return self


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
	button_down.connect(_bump.bind(0.94))
	toggled.connect(func(on: bool) -> void: _bump(1.08 if on else 1.0))


func _bump(to: float) -> void:
	var tw := create_tween()
	tw.tween_property(self, ^"scale", Vector2.ONE * to, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

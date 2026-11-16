class_name Style
extends RefCounted
## 새벽 편의점 색상표와 공용 테마. 크기는 docs/game-guide.md 2.1을 따른다.

const NIGHT := Color("#121626")
const NIGHT_DEEP := Color("#0A0D18")
const FLUORESCENT := Color("#EAF6FF")
const NEON := Color("#3DDC97")
const PRICE := Color("#FFD23F")
const ANGRY := Color("#FF4D6D")
const NEON_DARK := Color("#1E9E6A")
const CARD := Color("#F7FBFF")
## 코너 색: 식사·간식·음료·생활. 카드 위 띠와 가격 숫자에 쓴다.
const CORNER := {
	&"meal": Color("#FF8A3D"),
	&"snack": Color("#FF5FA2"),
	&"drink": Color("#3DB8FF"),
	&"goods": Color("#B48CFF"),
}

const HEADLINE := 64
const BODY := 40
const SCORE := 120
const BUTTON_H := 160
const GAP := 32

static var _bold: Font


static func bold() -> Font:
	if _bold == null:
		_bold = load("res://assets/fonts/Pretendard-Bold.otf")
	return _bold


static func box(color: Color, radius := 16, border := Color(0, 0, 0, 0), border_w := 0, shadow := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.shadow_size = shadow
	sb.shadow_offset = Vector2(0, shadow / 2.0)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox(&"normal", &"Button", box(NIGHT.lightened(0.1), 16, Color(FLUORESCENT, 0.35), 3, 12))
	t.set_stylebox(&"hover", &"Button", box(NIGHT.lightened(0.2), 16, FLUORESCENT, 3, 16))
	t.set_stylebox(&"pressed", &"Button", box(NIGHT.lightened(0.05), 16, NEON, 3, 4))
	t.set_stylebox(&"disabled", &"Button", box(Color(NIGHT.lightened(0.06), 0.6), 16, Color(FLUORESCENT, 0.12), 3))
	t.set_color(&"font_disabled_color", &"Button", Color(FLUORESCENT, 0.3))
	t.set_constant(&"icon_max_width", &"Button", 64)
	t.set_constant(&"h_separation", &"Button", 20)
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 16, PRICE, 6))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"Button", FLUORESCENT)
	t.set_font_size(&"font_size", &"Button", BODY)
	t.set_color(&"font_color", &"Label", FLUORESCENT)
	t.set_font_size(&"font_size", &"Label", BODY)
	t.set_color(&"font_color", &"LineEdit", FLUORESCENT)
	t.set_font_size(&"font_size", &"LineEdit", BODY)
	t.set_stylebox(&"normal", &"LineEdit", box(Color(FLUORESCENT, 0.08), 16, Color(FLUORESCENT, 0.35), 3))
	t.set_stylebox(&"focus", &"LineEdit", box(Color(0, 0, 0, 0), 16, PRICE, 6))
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", box(NEON, 16, NEON.lightened(0.3), 3, 12))
	t.set_stylebox(&"hover", &"AccentButton", box(NEON.lightened(0.15), 16, FLUORESCENT, 3, 16))
	t.set_stylebox(&"pressed", &"AccentButton", box(NEON.darkened(0.15), 16, NEON, 3, 4))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"AccentButton", NIGHT_DEEP)
	return t


## 상품 카드 틀: 흰 카드, 그림자, 고르면 네온 테두리.
static func card_box(picked: bool) -> StyleBoxFlat:
	return box(CARD, 18, NEON if picked else Color(NIGHT, 0.25), 8 if picked else 2, 28 if picked else 14)

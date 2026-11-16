class_name Style
extends RefCounted
## 저녁 식탁 색상표와 공용 테마.

const NIGHT := Color("#1E1418")
const NIGHT_DEEP := Color("#120B0E")
const CANDLE := Color("#F5B54A")
const LINEN := Color("#F3E9D8")
const WINE := Color("#9E2B3C")
const CRASH := Color("#E0523F")

static var _bold: Font


static func bold() -> Font:
	if _bold == null:
		_bold = load("res://assets/fonts/Pretendard-Bold.otf")
	return _bold


static func box(color: Color, radius := 10, border := Color(0, 0, 0, 0), border_w := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox(&"normal", &"Button", box(Color(LINEN, 0.12), 12, Color(LINEN, 0.4), 2))
	t.set_stylebox(&"hover", &"Button", box(Color(LINEN, 0.22), 12, LINEN, 2))
	t.set_stylebox(&"pressed", &"Button", box(Color(CANDLE, 0.35), 12, CANDLE, 2))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 12, CANDLE, 3))
	t.set_color(&"font_color", &"Button", LINEN)
	t.set_color(&"font_color", &"Label", LINEN)
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", box(WINE, 12))
	t.set_stylebox(&"hover", &"AccentButton", box(WINE.lightened(0.15), 12))
	t.set_color(&"font_color", &"AccentButton", LINEN)
	t.set_color(&"font_hover_color", &"AccentButton", LINEN)
	return t

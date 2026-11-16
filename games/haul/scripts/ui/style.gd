class_name Style
extends RefCounted
## 아트 가이드 색상표(기획서 12장)와 공용 테마.

const DAWN := Color("#1B2333")
const DAWN_DEEP := Color("#0F1520")
const LAMP := Color("#F2A541")
const CARDBOARD := Color("#C8955C")
const TAPE := Color("#E8D9B5")
const ALERT := Color("#E0523F")
const FROZEN := Color("#7CC6E8")

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
	t.set_stylebox(&"normal", &"Button", box(Color(TAPE, 0.12), 12, Color(TAPE, 0.4), 2))
	t.set_stylebox(&"hover", &"Button", box(Color(TAPE, 0.22), 12, TAPE, 2))
	t.set_stylebox(&"pressed", &"Button", box(Color(LAMP, 0.35), 12, LAMP, 2))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 12, LAMP, 3))
	t.set_color(&"font_color", &"Button", TAPE)
	t.set_color(&"font_color", &"Label", TAPE)
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", box(LAMP, 12))
	t.set_stylebox(&"hover", &"AccentButton", box(LAMP.lightened(0.15), 12))
	t.set_color(&"font_color", &"AccentButton", DAWN_DEEP)
	t.set_color(&"font_hover_color", &"AccentButton", DAWN_DEEP)
	return t

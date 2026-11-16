class_name Style
extends RefCounted
## 아트 가이드 색상표(기획서 8장)와 공용 테마.

const SUNLIGHT := Color("#F6E7C8")
const PARTITION := Color("#7FA7B5")
const POSTIT := Color("#F2C94C")
const INK := Color("#2A2A30")
const ALERT := Color("#D9534F")

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
	t.set_stylebox(&"normal", &"Button", box(Color.WHITE, 12, Color(INK, 0.35), 2))
	t.set_stylebox(&"hover", &"Button", box(Color(PARTITION, 0.25), 12, INK, 2))
	t.set_stylebox(&"pressed", &"Button", box(Color(POSTIT, 0.45), 12, INK, 2))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 12, POSTIT, 3))
	t.set_stylebox(&"disabled", &"Button", box(Color(INK, 0.06), 12, Color(INK, 0.15), 2))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"Button", INK)
	t.set_color(&"font_disabled_color", &"Button", Color(INK, 0.35))
	t.set_color(&"font_color", &"Label", INK)
	t.set_color(&"font_color", &"LineEdit", INK)
	t.set_stylebox(&"normal", &"LineEdit", box(Color.WHITE, 10, Color(INK, 0.35), 2))
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", box(ALERT, 12))
	t.set_stylebox(&"hover", &"AccentButton", box(ALERT.lightened(0.12), 12))
	t.set_stylebox(&"pressed", &"AccentButton", box(ALERT.darkened(0.15), 12))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"AccentButton", Color.WHITE)
	return t

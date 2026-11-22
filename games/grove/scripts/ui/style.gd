class_name Style
extends RefCounted
## 해 질 녘 숲 색상표(기획서 5장)와 공용 테마. 크기는 docs/game-guide.md 2.1을 따른다.

const FOREST := Color("#1F3A2E")
const MOSS := Color("#6E9A4F")
const CREAM := Color("#F6EEDC")
const SUNSET := Color("#F29E4C")
const SPROUT := Color("#A8D672")
const BERRY := Color("#D9534F")

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
	sb.shadow_color = Color(0, 0, 0, 0.4)
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.border_color = border
	sb.set_border_width_all(border_w)
	return sb


## 숲 위에 뜨는 반투명 판(윗줄·버튼 바탕).
static func glass(radius := 24) -> StyleBoxFlat:
	var sb := box(Color(FOREST, 0.78), radius, Color(CREAM, 0.25), 2, 18)
	sb.set_content_margin_all(20)
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.set_stylebox(&"normal", &"Button", box(Color(FOREST, 0.85), 20, Color(CREAM, 0.35), 3, 12))
	t.set_stylebox(&"hover", &"Button", box(FOREST.lightened(0.12), 20, CREAM, 3, 16))
	t.set_stylebox(&"pressed", &"Button", box(FOREST.darkened(0.1), 20, SUNSET, 3, 4))
	t.set_stylebox(&"disabled", &"Button", box(Color(FOREST, 0.5), 20, Color(CREAM, 0.12), 3))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 20, SUNSET, 6))
	t.set_color(&"font_disabled_color", &"Button", Color(CREAM, 0.3))
	t.set_constant(&"icon_max_width", &"Button", 64)
	t.set_constant(&"h_separation", &"Button", 20)
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"Button", CREAM)
	t.set_font_size(&"font_size", &"Button", BODY)
	t.set_color(&"font_color", &"Label", CREAM)
	t.set_font_size(&"font_size", &"Label", BODY)
	t.set_color(&"font_shadow_color", &"Label", Color(FOREST, 0.8))
	t.set_constant(&"shadow_offset_x", &"Label", 0)
	t.set_constant(&"shadow_offset_y", &"Label", 4)
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", box(SUNSET, 20, SUNSET.lightened(0.35), 3, 12))
	t.set_stylebox(&"hover", &"AccentButton", box(SUNSET.lightened(0.12), 20, CREAM, 3, 16))
	t.set_stylebox(&"pressed", &"AccentButton", box(SUNSET.darkened(0.15), 20, SUNSET, 3, 4))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"AccentButton", FOREST)
	return t

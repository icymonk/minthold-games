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
## 배송 집 색(색약 구분용 Okabe–Ito 계열). 번호와 함께 쓴다.
const STOPS: Array[Color] = [
	Color("#E69F00"), Color("#56B4E9"), Color("#009E73"), Color("#F0E442"),
	Color("#0072B2"), Color("#D55E00"), Color("#CC79A7"), Color("#B8B8B8"),
]


static func stop_color(stop: int) -> Color:
	return STOPS[(stop - 1) % STOPS.size()]

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


## Kenney UI 팩 버튼 그림(CC0)을 늘려 쓰는 스타일.
static func tex(path: String, tint := Color.WHITE, down := 0.0) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load(path)
	sb.set_texture_margin_all(12)
	sb.texture_margin_bottom = 16
	sb.content_margin_left = 24
	sb.content_margin_right = 24
	sb.content_margin_top = 8 + down
	sb.content_margin_bottom = 12 - down
	sb.modulate_color = tint
	return sb


static func panel() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/art/kenney/panel.png")
	sb.set_texture_margin_all(10)
	sb.set_content_margin_all(6)
	return sb


static func tag() -> StyleBoxTexture:
	return tex("res://assets/art/kenney/button_accent.png")


static func make_theme() -> Theme:
	var t := Theme.new()
	const GREY := "res://assets/art/kenney/button.png"
	const FLAT := "res://assets/art/kenney/button_pressed.png"
	const GOLD := "res://assets/art/kenney/button_accent.png"
	t.set_stylebox(&"normal", &"Button", tex(GREY))
	t.set_stylebox(&"hover", &"Button", tex(GREY, Color(1.08, 1.08, 1.12)))
	t.set_stylebox(&"pressed", &"Button", tex(FLAT, Color(0.9, 0.9, 0.95), 4))
	t.set_stylebox(&"disabled", &"Button", tex(GREY, Color(1, 1, 1, 0.45)))
	t.set_stylebox(&"focus", &"Button", StyleBoxEmpty.new())
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color", &"font_hover_pressed_color"]:
		t.set_color(c, &"Button", DAWN_DEEP)
	t.set_color(&"font_disabled_color", &"Button", Color(DAWN_DEEP, 0.45))
	t.set_color(&"font_color", &"Label", TAPE)
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", tex(GOLD))
	t.set_stylebox(&"hover", &"AccentButton", tex(GOLD, Color(1.08, 1.08, 1.08)))
	t.set_stylebox(&"pressed", &"AccentButton", tex(GOLD, Color(0.92, 0.92, 0.92), 4))
	t.set_stylebox(&"disabled", &"AccentButton", tex(GOLD, Color(1, 1, 1, 0.4)))
	t.set_stylebox(&"normal", &"LineEdit", tex(GREY))
	t.set_stylebox(&"focus", &"LineEdit", tex(GOLD))
	t.set_color(&"font_color", &"LineEdit", DAWN_DEEP)
	t.set_color(&"font_placeholder_color", &"LineEdit", Color(DAWN_DEEP, 0.5))
	return t

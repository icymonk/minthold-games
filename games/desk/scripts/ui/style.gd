class_name Style
extends RefCounted
## 아트 가이드 색상표(기획서 8장)와 공용 테마. 콘솔 게임처럼 크게(1920×1080 기준).

const SUNLIGHT := Color("#F6E7C8")
const PARTITION := Color("#7FA7B5")
const POSTIT := Color("#F2C94C")
const INK := Color("#2A2A30")
const ALERT := Color("#D9534F")
## 화면 바탕(저녁 사무실 창밖)과 그 위 글자.
const NIGHT := Color("#1E2A3B")
const NIGHT_TOP := Color("#33465E")
const ON_NIGHT := Color("#F6E7C8")

## 글자 크기: 본문·제목·큰 제목.
const BODY := 28
const HEAD := 34
const BIG := 44

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


## 바탕 위에 뜬 판: 둥근 모서리, 그림자, 넉넉한 안쪽 여백.
static func panel(color := SUNLIGHT, pad := 22) -> StyleBoxFlat:
	var sb := box(color, 22)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 14
	sb.shadow_offset = Vector2(0, 6)
	sb.set_content_margin_all(pad)
	return sb


## 위에서 아래로 밝아지는 바탕.
static func backdrop() -> TextureRect:
	var g := Gradient.new()
	g.set_color(0, NIGHT_TOP)
	g.set_color(1, NIGHT)
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill_from = Vector2(0.5, 0)
	tex.fill_to = Vector2(0.5, 1)
	var r := TextureRect.new()
	r.texture = tex
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	r.stretch_mode = TextureRect.STRETCH_SCALE
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func _button(color: Color, border: Color, border_w: int) -> StyleBoxFlat:
	var sb := box(color, 16, border, border_w)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


static func make_theme() -> Theme:
	var t := Theme.new()
	t.default_font_size = BODY
	t.set_stylebox(&"normal", &"Button", _button(Color.WHITE, Color(INK, 0.35), 3))
	t.set_stylebox(&"hover", &"Button", _button(Color(POSTIT, 0.35), INK, 3))
	t.set_stylebox(&"pressed", &"Button", _button(Color(POSTIT, 0.6), INK, 3))
	t.set_stylebox(&"focus", &"Button", box(Color(0, 0, 0, 0), 18, POSTIT, 6))
	t.set_stylebox(&"disabled", &"Button", _button(Color(SUNLIGHT, 0.5), Color(INK, 0.15), 3))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"Button", INK)
	t.set_color(&"font_disabled_color", &"Button", Color(INK, 0.45))
	t.set_font_size(&"font_size", &"Button", BODY)
	t.set_color(&"font_color", &"Label", INK)
	t.set_font_size(&"font_size", &"Label", BODY)
	t.set_color(&"font_color", &"LineEdit", INK)
	t.set_font_size(&"font_size", &"LineEdit", BODY)
	t.set_stylebox(&"normal", &"LineEdit", _button(Color.WHITE, Color(INK, 0.35), 3))
	t.set_stylebox(&"focus", &"LineEdit", box(Color(0, 0, 0, 0), 18, POSTIT, 6))
	t.set_font_size(&"font_size", &"TooltipLabel", BODY)
	t.set_type_variation(&"AccentButton", &"Button")
	t.set_stylebox(&"normal", &"AccentButton", _button(ALERT, ALERT.darkened(0.25), 3))
	t.set_stylebox(&"hover", &"AccentButton", _button(ALERT.lightened(0.12), INK, 3))
	t.set_stylebox(&"pressed", &"AccentButton", _button(ALERT.darkened(0.15), INK, 3))
	for c in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_focus_color"]:
		t.set_color(c, &"AccentButton", Color.WHITE)
	t.set_type_variation(&"NightLabel", &"Label")
	t.set_color(&"font_color", &"NightLabel", ON_NIGHT)
	return t

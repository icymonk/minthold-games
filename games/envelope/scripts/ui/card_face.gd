class_name CardFace
extends Control
## 손패 카드 앞면. 부모 Button의 상태(골랐음·올림·못 냄)를 따라 그린다.

const BAND := 54.0
const LIFT := 12.0

var kind := -1
## 결정 요청에서 고를 수 있는 카드.
var lit := false
var lift := 0.0:
	set(v):
		lift = v
		queue_redraw()
var _title: Label
var _sub: Label


func _init(card_kind := -1, title := "", sub := "", sub_color := Style.INK) -> void:
	kind = card_kind
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_title = _label(title, 17, Color.WHITE)
	_title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_title.offset_top = 6
	_title.offset_bottom = BAND
	_sub = _label(sub, 22, sub_color)
	_sub.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_sub.offset_top = -40
	_sub.offset_bottom = -8


func _ready() -> void:
	var b := get_parent() as BaseButton
	if b == null:
		return
	b.mouse_entered.connect(_raise.bind(true))
	b.mouse_exited.connect(_raise.bind(false))
	b.toggled.connect(func(_on: bool) -> void: queue_redraw())


func _raise(up: bool) -> void:
	var b := get_parent() as BaseButton
	var to := LIFT if up and not b.disabled else 0.0
	create_tween().tween_property(self, ^"lift", to, 0.1)


func _label(value: String, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = value
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_font_override(&"font", Style.bold())
	l.add_theme_color_override(&"font_color", color)
	add_child(l)
	return l


func _draw() -> void:
	var b := get_parent() as BaseButton
	var picked := b != null and b.button_pressed
	var up := lift + (LIFT if picked else 0.0)
	_title.position.y = 6 - up
	_sub.position.y = size.y - 40 - up
	var card := Rect2(Vector2(4, 4 - up), size - Vector2(8, 8))
	var border := Style.STAMP if picked else (Style.PARTITION.darkened(0.3) if lit else Color(Style.INK, 0.5))
	draw_style_box(Style.box(Color(Style.INK, 0.15), 12), card.grow_individual(-2, -2, 2, 2 + up))
	draw_style_box(Style.box(Style.PAPER, 12, border, 4 if picked or lit else 2), card)
	var band := Style.box(Art.band(kind), 12)
	band.corner_radius_bottom_left = 0
	band.corner_radius_bottom_right = 0
	draw_style_box(band, Rect2(card.position + Vector2(2, 2), Vector2(card.size.x - 4, BAND - 2)))
	var face := Rect2(card.position + Vector2(10, BAND + 4), Vector2(card.size.x - 20, card.size.y - BAND - 46))
	draw_rect(face, Color(Art.band(kind), 0.12))
	Art.portrait(self, face, kind)
	modulate.a = 0.55 if b != null and b.disabled else 1.0

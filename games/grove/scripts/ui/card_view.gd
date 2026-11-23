class_name CardView
extends Control
## 손패의 카드 한 장. 나무 카드는 그림 하나, 이웃 카드는 반쪽 둘(위/아래 또는 왼/오른).

const CARD := Vector2(210, 300)

var card: Dictionary
var half := 0
var _halves: Array[Control] = []
var _frame: Panel


static func make(c: Dictionary, portraits: Portrait) -> CardView:
	var v := CardView.new()
	v.card = c
	v._build(portraits)
	return v


func _build(portraits: Portrait) -> void:
	custom_minimum_size = CARD
	size = CARD
	pivot_offset = CARD / 2.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_frame = Panel.new()
	_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_frame)
	var inner := Rect2(Vector2(10, 10), CARD - Vector2(20, 20))
	if DemoCards.is_tree(card):
		_halves.append(_half_box(card.tree, inner, Style.SPROUT, portraits))
	elif card.axis == &"v":
		var h := inner.size.y / 2.0
		_halves.append(_half_box(card.halves[0], Rect2(inner.position, Vector2(inner.size.x, h - 4)), Dweller.KINDS[card.halves[0]].color, portraits))
		_halves.append(_half_box(card.halves[1], Rect2(inner.position + Vector2(0, h + 4), Vector2(inner.size.x, h - 4)), Dweller.KINDS[card.halves[1]].color, portraits))
	else:
		var w := inner.size.x / 2.0
		_halves.append(_half_box(card.halves[0], Rect2(inner.position, Vector2(w - 4, inner.size.y)), Dweller.KINDS[card.halves[0]].color, portraits))
		_halves.append(_half_box(card.halves[1], Rect2(inner.position + Vector2(w + 4, 0), Vector2(w - 4, inner.size.y)), Dweller.KINDS[card.halves[1]].color, portraits))
	set_half(0)


func _half_box(kind: StringName, r: Rect2, color: Color, portraits: Portrait) -> Control:
	var box := Panel.new()
	box.position = r.position
	box.size = r.size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_stylebox_override(&"panel", Style.box(color.lightened(0.45), 12))
	add_child(box)
	var pic := TextureRect.new()
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pic.position = Vector2(4, 4)
	pic.size = r.size - Vector2(8, 44)
	pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(pic)
	if portraits:
		portraits.request(kind, func(tex: Texture2D) -> void:
			if is_instance_valid(pic):
				pic.texture = tex)
	var name_label := Label.new()
	name_label.text = tr("KIND_%s" % String(kind).to_upper())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_override(&"font", Style.bold())
	name_label.add_theme_font_size_override(&"font_size", 26 if r.size.x > 150 else 22)
	name_label.clip_text = true
	name_label.add_theme_color_override(&"font_color", Style.FOREST)
	name_label.add_theme_constant_override(&"shadow_offset_y", 0)
	name_label.position = Vector2(0, r.size.y - 40)
	name_label.size = Vector2(r.size.x, 36)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	return box


## 쓸 반쪽을 밝히고 다른 반쪽은 어둡게
func set_half(i: int) -> void:
	half = i
	for k in _halves.size():
		_halves[k].modulate = Color.WHITE if k == i or _halves.size() == 1 else Color(0.45, 0.45, 0.5)
	var border := Style.SUNSET if _halves.size() > 1 else Style.MOSS
	_frame.add_theme_stylebox_override(&"panel", Style.box(Style.CREAM, 18, border, 5, 10))


## 잡은 곳이 어느 반쪽인지(local: 카드 안 좌표)
func half_at(local: Vector2) -> int:
	if DemoCards.is_tree(card):
		return 0
	if card.axis == &"v":
		return 1 if local.y > CARD.y / 2.0 else 0
	return 1 if local.x > CARD.x / 2.0 else 0


func kind() -> StringName:
	return DemoCards.kind_of(card, half)


func side() -> StringName:
	return DemoCards.side_of(card, half)


## 붙일 곳이 없을 때: 빨갛게 떨린다
func shake() -> void:
	var x := position.x
	var tw := create_tween()
	modulate = Style.BERRY.lightened(0.3)
	for i in 4:
		tw.tween_property(self, ^"position:x", x + (12.0 if i % 2 == 0 else -12.0), 0.05)
	tw.tween_property(self, ^"position:x", x, 0.05)
	tw.tween_property(self, ^"modulate", Color.WHITE, 0.2)

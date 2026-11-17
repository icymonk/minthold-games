class_name ScreenBase
extends Control
## 임시 화면용: 가운데 정렬된 세로 목록을 만든다.

var _list: VBoxContainer


func _make_list() -> VBoxContainer:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", Style.GAP)
	_list.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(_list)
	return _list


func _label(text: String, size: int = Style.BODY) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_font_override(&"font", Style.bold())
	_list.add_child(label)
	return label


func _button(icon: Texture2D, text: String, on_pressed: Callable, parent: Control = null) -> Button:
	var button := Button.new()
	button.icon = icon
	button.text = text
	button.custom_minimum_size = Vector2(560, Style.BUTTON_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override(&"font", Style.bold())
	button.pressed.connect(func() -> void: Sfx.play(&"click"))
	button.pressed.connect(on_pressed)
	(parent if parent else _list).add_child(button)
	return button


## 화면 틀: 가장자리 여백 + 세로 목록. 윗줄(제목·가진 돈)을 만들고 돈 표시를 돌려준다.
func _frame(title: String) -> Label:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, 96)
	for side in [&"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 54)
	add_child(margin)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override(&"separation", Style.GAP)
	margin.add_child(_list)
	var top := HBoxContainer.new()
	top.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(top)
	_button(Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), top).custom_minimum_size = Vector2(300, 112)
	var head := _text(top, title, Style.HEADLINE)
	head.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var money := _text(top, "", Style.HEADLINE, Style.PRICE)
	money.custom_minimum_size.x = 300
	money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	return money


func _text(parent: Control, text: String, size: int = Style.BODY, color: Color = Style.FLUORESCENT) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_font_override(&"font", Style.bold())
	label.add_theme_color_override(&"font_color", color)
	parent.add_child(label)
	return label


## 그림자와 테두리가 있는 판. 안쪽 세로 목록을 돌려준다.
func _panel(parent: Control, size: Vector2, border: Color = Color(Style.FLUORESCENT, 0.25)) -> VBoxContainer:
	var panel := PanelContainer.new()
	var sb := Style.box(Style.NIGHT.lightened(0.06), 20, border, 4 if border != Color(Style.FLUORESCENT, 0.25) else 2, 20)
	sb.set_content_margin_all(24)
	panel.add_theme_stylebox_override(&"panel", sb)
	panel.custom_minimum_size = size
	parent.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(col)
	return col


func _clear() -> void:
	for child in get_children():
		if not child is Coach:
			remove_child(child)
			child.queue_free()

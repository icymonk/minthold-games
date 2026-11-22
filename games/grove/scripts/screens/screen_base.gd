class_name ScreenBase
extends Control
## 화면 공용: 숲 위에 뜨는 글자·버튼·판.


func _label(parent: Control, text: String, size: int = Style.BODY, color: Color = Style.CREAM) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_font_override(&"font", Style.bold())
	label.add_theme_color_override(&"font_color", color)
	parent.add_child(label)
	return label


func _button(parent: Control, icon: Texture2D, text: String, on_pressed: Callable, width := 480) -> Button:
	var button := Button.new()
	button.icon = icon
	button.text = text
	button.custom_minimum_size = Vector2(width, Style.BUTTON_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override(&"font", Style.bold())
	button.add_theme_font_size_override(&"font_size", Style.BODY)
	button.pressed.connect(func() -> void: Sfx.play(&"click"))
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button


func _row(parent: Control, gap: int = Style.GAP) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", gap)
	parent.add_child(row)
	return row


## 가장자리 여백을 둔 세로 틀(위·가운데 빈칸·아래).
func _frame() -> VBoxContainer:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [&"margin_left", &"margin_right"]:
		margin.add_theme_constant_override(side, 72)
	for side in [&"margin_top", &"margin_bottom"]:
		margin.add_theme_constant_override(side, 48)
	add_child(margin)
	var col := VBoxContainer.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_theme_constant_override(&"separation", Style.GAP)
	margin.add_child(col)
	return col


func _spacer(parent: Control) -> Control:
	var s := Control.new()
	s.size_flags_vertical = Control.SIZE_EXPAND_FILL
	s.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(s)
	return s


func _glass(parent: Control) -> HBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.glass())
	parent.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", Style.GAP)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(row)
	return row

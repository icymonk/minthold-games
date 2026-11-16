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


func _button(icon: String, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = "%s  %s" % [icon, text]
	button.custom_minimum_size = Vector2(560, Style.BUTTON_H)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.add_theme_font_override(&"font", Style.bold())
	button.pressed.connect(on_pressed)
	_list.add_child(button)
	return button

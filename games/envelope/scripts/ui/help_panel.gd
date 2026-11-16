class_name HelpPanel
extends Control
## 규칙 요약·카드 사전·첫 판 안내. 제목 화면과 테이블에서 언제든 연다.

signal closed

const TABS := [&"FIRST", &"RULES", &"CARDS"]

var tab: StringName = &"RULES"
var _body: VBoxContainer
var _tabs: HBoxContainer
var _close_button: Button
var _return_focus: Control


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	var shade := ColorRect.new()
	shade.color = Color(Style.INK, 0.45)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	var sb := Style.box(Style.PAPER, 16, Style.INK, 2)
	sb.set_content_margin_all(28)
	panel.add_theme_stylebox_override(&"panel", sb)
	center.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 16)
	panel.add_child(col)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override(&"separation", 10)
	col.add_child(_tabs)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(1100, 700)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override(&"separation", 14)
	scroll.add_child(_body)
	_close_button = Button.new()
	_close_button.text = tr("HELP_CLOSE")
	_close_button.theme_type_variation = &"AccentButton"
	_close_button.custom_minimum_size = Vector2(0, 60)
	_close_button.add_theme_font_size_override(&"font_size", 26)
	_close_button.pressed.connect(close)
	col.add_child(_close_button)


func open(which: StringName = &"RULES") -> void:
	if not visible:
		_return_focus = get_viewport().gui_get_focus_owner() if is_inside_tree() else null
	tab = which
	visible = true
	_render()
	if is_inside_tree():
		_close_button.grab_focus()


func close() -> void:
	visible = false
	if is_instance_valid(_return_focus) and _return_focus.is_visible_in_tree():
		_return_focus.grab_focus()
	_return_focus = null
	closed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed(&"ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


func _render() -> void:
	for box in [_tabs, _body]:
		for c in box.get_children():
			box.remove_child(c)
			c.queue_free()
	for t in TABS:
		var b := Button.new()
		b.text = tr("HELP_TAB_%s" % t)
		b.toggle_mode = true
		b.button_pressed = t == tab
		b.custom_minimum_size = Vector2(220, 52)
		b.add_theme_font_size_override(&"font_size", 24)
		b.pressed.connect(open.bind(t))
		_tabs.add_child(b)
	_trap_focus()
	match tab:
		&"CARDS":
			for id in Cards.DEFS:
				_body.add_child(_card_row(id))
		_:
			_body.add_child(_text(26, false, tr("HELP_%s" % tab)))


## 도움말이 열려 있는 동안 키보드 포커스가 뒤 화면으로 빠져나가지 않게 한다.
func _trap_focus() -> void:
	var first: Button = _tabs.get_child(0)
	var last: Button = _tabs.get_child(_tabs.get_child_count() - 1)
	first.focus_previous = first.get_path_to(_close_button)
	_close_button.focus_next = _close_button.get_path_to(first)
	first.focus_neighbor_left = first.get_path_to(first)
	last.focus_neighbor_right = last.get_path_to(last)
	_close_button.focus_neighbor_top = _close_button.get_path_to(first)
	_close_button.focus_neighbor_bottom = _close_button.get_path_to(_close_button)
	_close_button.focus_neighbor_left = _close_button.get_path_to(_close_button)
	_close_button.focus_neighbor_right = _close_button.get_path_to(_close_button)
	for b: Button in _tabs.get_children():
		b.focus_neighbor_top = b.get_path_to(b)
		b.focus_neighbor_bottom = b.get_path_to(_close_button)


func _card_row(id: int) -> Control:
	var box := VBoxContainer.new()
	box.add_child(_text(28, true, tr(Cards.name_key(id))))
	box.add_child(_text(22, false, card_meta(id)))
	box.add_child(_text(24, false, ability(id)))
	return box


static func ability(id: int) -> String:
	return TranslationServer.translate("ABILITY_%s" % Cards.DEFS[id].key)


static func card_meta(id: int) -> String:
	var amount: String = TranslationServer.translate("CARD_LOCKED") if not Cards.playable(id) else money(Cards.amount(id))
	return TranslationServer.translate("HELP_CARD_META") % [
		amount,
		Cards.deck(Game.players).count(id),
		Cards.priority(id),
		TranslationServer.translate("WIN_%s" % Cards.Win.keys()[Cards.win(id)]),
	]


static func money(n: int) -> String:
	if n == 0:
		return TranslationServer.translate("MONEY_ZERO")
	return TranslationServer.translate("CARD_AMOUNT") % n


func _text(size: int, bold: bool, value: String) -> Label:
	var l := Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.add_theme_font_size_override(&"font_size", size)
	if bold:
		l.add_theme_font_override(&"font", Style.bold())
	return l

extends ScreenBase

var _seed_input: LineEdit
var _role_button: Button
var _level_button: Button
var _events_button: Button
var _records: Control


func _ready() -> void:
	_make_list()
	_list.add_theme_constant_override(&"separation", 20)
	_label(tr("GAME_TITLE"), 96)
	_label(tr("TITLE_SUBTITLE"), 28).modulate = Color(Style.INK, 0.7)
	var cast := HBoxContainer.new()
	cast.alignment = BoxContainer.ALIGNMENT_CENTER
	cast.add_theme_constant_override(&"separation", 12)
	cast.add_child(Art.picture(Art.person(&"chief_think"), Vector2(150, 200)))
	cast.add_child(Art.picture(Art.ZONES[Cards.Zone.FLOOR], Vector2(260, 200)))
	cast.add_child(Art.picture(Art.person(&"staff_run0"), Vector2(150, 200)))
	_list.add_child(cast)
	var settings := _row()
	_role_button = _in(settings, _button("", _on_toggle_role))
	_refresh_role()
	_level_button = _in(settings, _button("", _on_cycle_level))
	_refresh_level()
	_events_button = _in(settings, _button("", _on_toggle_events))
	_refresh_events()
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(420, 56)
	_seed_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_seed_input.add_theme_font_size_override(&"font_size", 24)
	_list.add_child(_seed_input)
	var play := _row()
	var start := _in(play, _button(tr("TITLE_START"), _on_start))
	start.theme_type_variation = &"AccentButton"
	start.grab_focus()
	_in(play, _button(tr("TITLE_WEEK"), _on_start_week))
	if Game.can_continue_week():
		var w := Game.week
		var text := tr("TITLE_CONTINUE") % [tr("DAY_%d" % w.day()), w.day() + 1, Week.DAYS]
		_in(play, _button(text, Game.play_day)).theme_type_variation = &"AccentButton"
	var more := _row()
	_in(more, _button(tr("RECORDS_BTN"), show_records.bind(true)))
	_in(more, _button(tr("TITLE_LANGUAGE"), _on_toggle_language))
	_build_records()


func _row() -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 16)
	_list.add_child(row)
	return row


func _in(row: HBoxContainer, b: Button) -> Button:
	_list.remove_child(b)
	row.add_child(b)
	return b


func _seed() -> int:
	var text := _seed_input.text.strip_edges()
	return int(text) if text.is_valid_int() else -1


## 역할별 기록 한 줄씩.
func records_text() -> String:
	var st := Game.stats
	var lines := PackedStringArray()
	for s in [Match.Side.CHIEF, Match.Side.STAFF]:
		var name := tr("ROLE_STAFF" if s == Match.Side.STAFF else "ROLE_CHIEF")
		if st.games[s] == 0:
			lines.append(tr("RECORDS_NONE") % name)
			continue
		var mh := st.manhunt_pct(s)
		lines.append(tr("RECORDS_LINE") % [
			name, st.games[s], st.win_pct(s), "%.1f" % st.avg_turns(s),
			"-" if mh < 0 else "%d%%" % mh, st.weeks[s],
			"-" if st.best_week[s] < 0 else "%d/%d" % [st.best_week[s], Week.DAYS],
		])
	return "\n\n".join(lines)


func _build_records() -> void:
	_records = Control.new()
	_records.set_anchors_preset(Control.PRESET_FULL_RECT)
	_records.visible = false
	add_child(_records)
	var shade := ColorRect.new()
	shade.color = Color(Style.INK, 0.55)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_records.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_records.add_child(center)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override(&"panel", Style.box(Color.WHITE, 16))
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		pad.add_theme_constant_override(side, 32)
	panel.add_child(pad)
	var box := VBoxContainer.new()
	box.add_theme_constant_override(&"separation", 20)
	box.custom_minimum_size = Vector2(900, 0)
	pad.add_child(box)
	var head := Label.new()
	head.text = tr("RECORDS_BTN")
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override(&"font_size", 40)
	head.add_theme_font_override(&"font", Style.bold())
	box.add_child(head)
	var body := Label.new()
	body.name = &"Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override(&"font_size", 24)
	box.add_child(body)
	var close := Button.new()
	close.text = tr("CLOSE")
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close.custom_minimum_size = Vector2(240, 60)
	close.add_theme_font_size_override(&"font_size", 24)
	close.pressed.connect(show_records.bind(false))
	box.add_child(close)


func show_records(on: bool) -> void:
	_records.visible = on
	if on:
		(_records.find_child("Body", true, false) as Label).text = records_text()


func _refresh_role() -> void:
	_role_button.text = tr("TITLE_ROLE_CHIEF" if Game.role == Game.Role.CHIEF else "TITLE_ROLE_STAFF")


func _refresh_level() -> void:
	_level_button.text = tr("TITLE_LEVEL") % tr("LEVEL_%d" % Game.level)


func _refresh_events() -> void:
	_events_button.text = tr("TITLE_EVENTS_ON" if Game.events else "TITLE_EVENTS_OFF")


func _on_toggle_events() -> void:
	Game.toggle_events()
	_refresh_events()


func _on_cycle_level() -> void:
	Game.cycle_level()
	_refresh_level()


func _on_toggle_role() -> void:
	Game.toggle_role()
	_refresh_role()


func _on_start() -> void:
	Game.start_match(_seed())


func _on_start_week() -> void:
	Game.start_week(_seed())


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

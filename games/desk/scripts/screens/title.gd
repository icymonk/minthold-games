extends ScreenBase

const ROLE_CARD := Vector2(420, 440)

var _seed_input: LineEdit
var _role_cards := {}
var _level_button: Button
var _events_button: Button
var _records: Control


func _ready() -> void:
	add_child(Style.backdrop())
	_make_list()
	_list.add_theme_constant_override(&"separation", 22)
	var title := _label(tr("GAME_TITLE"), 110)
	title.theme_type_variation = &"NightLabel"
	var sub := _label(tr("TITLE_SUBTITLE"), Style.HEAD)
	sub.theme_type_variation = &"NightLabel"
	sub.modulate.a = 0.8
	var roles := _row()
	roles.add_theme_constant_override(&"separation", 40)
	_role_cards[Game.Role.CHIEF] = _in(roles, _role_card(Game.Role.CHIEF))
	var vs := Label.new()
	vs.text = "VS"
	vs.theme_type_variation = &"NightLabel"
	vs.add_theme_font_override(&"font", Style.bold())
	vs.add_theme_font_size_override(&"font_size", 64)
	vs.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	roles.add_child(vs)
	_role_cards[Game.Role.STAFF] = _in(roles, _role_card(Game.Role.STAFF))
	_refresh_role()
	var settings := _row()
	_level_button = _in(settings, _button("", _on_cycle_level))
	_refresh_level()
	_events_button = _in(settings, _button("", _on_toggle_events))
	_refresh_events()
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(300, 80)
	settings.add_child(_seed_input)
	var play := _row()
	var start := _in(play, _button(tr("TITLE_START"), _on_start))
	start.theme_type_variation = &"AccentButton"
	start.custom_minimum_size = Vector2(440, 104)
	start.add_theme_font_size_override(&"font_size", Style.BIG)
	_in(play, _button(tr("TITLE_WEEK"), _on_start_week)).custom_minimum_size = Vector2(440, 104)
	if Game.can_continue_week():
		var w := Game.week
		var text := tr("TITLE_CONTINUE") % [tr("DAY_%d" % w.day()), w.day() + 1, Week.DAYS]
		var cont := _in(play, _button(text, Game.play_day))
		cont.theme_type_variation = &"AccentButton"
		cont.custom_minimum_size = Vector2(440, 104)
	var more := _row()
	_in(more, _button(tr("RECORDS_BTN"), show_records.bind(true))).custom_minimum_size = Vector2(300, 68)
	_in(more, _button(tr("TITLE_LANGUAGE"), _on_toggle_language)).custom_minimum_size = Vector2(300, 68)
	var prompt := _label(tr("TITLE_PROMPT"), 22)
	prompt.theme_type_variation = &"NightLabel"
	prompt.modulate.a = 0.6
	start.grab_focus()
	_build_records()


## 역할 고르기 카드: 인물 그림, 이름, 한 줄 설명. 고른 쪽은 노란 테두리로 띄운다.
func _role_card(r: int) -> Button:
	var chief := r == Game.Role.CHIEF
	var b := Button.new()
	b.custom_minimum_size = ROLE_CARD
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pivot_offset = ROLE_CARD / 2
	b.pressed.connect(pick_role.bind(r))
	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_FULL_RECT)
	col.offset_top = 18
	col.offset_bottom = -18
	col.offset_left = 18
	col.offset_right = -18
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(col)
	col.add_child(Art.picture(Art.person(&"chief_think" if chief else &"staff_run0"), Vector2(0, 190)))
	var who := Label.new()
	who.text = tr("ROLE_CHIEF" if chief else "ROLE_STAFF")
	who.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	who.add_theme_font_override(&"font", Style.bold())
	who.add_theme_font_size_override(&"font_size", 52)
	col.add_child(who)
	var desc := Label.new()
	desc.text = tr("ROLE_CHIEF_DESC" if chief else "ROLE_STAFF_DESC")
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.add_theme_font_size_override(&"font_size", 26)
	col.add_child(desc)
	var badge := Label.new()
	badge.name = &"Badge"
	badge.text = tr("ROLE_PICKED")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_override(&"font", Style.bold())
	badge.modulate = Style.ALERT
	col.add_child(badge)
	return b


func pick_role(r: int) -> void:
	Game.role = r as Game.Role
	_refresh_role()


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
	for r in _role_cards:
		var b: Button = _role_cards[r]
		var on: bool = r == Game.role
		var sb := Style.panel(Color.WHITE if on else Color(Style.SUNLIGHT, 0.75))
		sb.border_color = Style.POSTIT if on else Color(0, 0, 0, 0)
		sb.set_border_width_all(8 if on else 0)
		for st in [&"normal", &"hover", &"pressed", &"focus"]:
			b.add_theme_stylebox_override(st, sb)
		b.modulate = Color.WHITE if on else Color(1, 1, 1, 0.6)
		b.create_tween().tween_property(b, ^"scale", Vector2.ONE * (1.04 if on else 0.94), 0.15)
		(b.find_child("Badge", true, false) as Label).modulate.a = 1.0 if on else 0.0


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


func _on_start() -> void:
	Game.start_match(_seed())


func _on_start_week() -> void:
	Game.start_week(_seed())


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

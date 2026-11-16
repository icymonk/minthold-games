extends ScreenBase

var _seed_input: LineEdit


func _ready() -> void:
	_make_list()
	_label(tr("GAME_TITLE"), Style.SCORE).add_theme_color_override(&"font_color", Style.NEON)
	_label(tr("TITLE_SUBTITLE")).modulate = Color(Style.FLUORESCENT, 0.75)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(560, 96)
	_seed_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_list.add_child(_seed_input)
	var start := _button("▶", tr("TITLE_NEW_RUN"), _on_new_run)
	start.theme_type_variation = &"AccentButton"
	start.grab_focus()
	_button("A/가", tr("TITLE_LANGUAGE"), _on_toggle_language)


func _on_new_run() -> void:
	var text := _seed_input.text.strip_edges()
	Game.start_run(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

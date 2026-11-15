extends ScreenBase

var _seed_input: LineEdit


func _ready() -> void:
	_make_list()
	_label(tr("GAME_TITLE"), 72)
	_label(tr("TITLE_SUBTITLE"), 28)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(360, 56)
	_seed_input.add_theme_font_size_override(&"font_size", 24)
	_list.add_child(_seed_input)
	_button(tr("TITLE_NEW_RUN"), _on_new_run).grab_focus()
	_button(tr("TITLE_LANGUAGE"), _on_toggle_language)


func _on_new_run() -> void:
	var text := _seed_input.text.strip_edges()
	Game.start_run(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

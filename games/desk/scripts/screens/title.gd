extends ScreenBase

var _seed_input: LineEdit
var _role_button: Button


func _ready() -> void:
	_make_list()
	_label(tr("GAME_TITLE"), 96)
	_label(tr("TITLE_SUBTITLE"), 28).modulate = Color(Style.INK, 0.7)
	_role_button = _button("", _on_toggle_role)
	_refresh_role()
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(420, 56)
	_seed_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_seed_input.add_theme_font_size_override(&"font_size", 24)
	_list.add_child(_seed_input)
	var start := _button(tr("TITLE_START"), _on_start)
	start.theme_type_variation = &"AccentButton"
	start.grab_focus()
	_button(tr("TITLE_LANGUAGE"), _on_toggle_language)


func _refresh_role() -> void:
	_role_button.text = tr("TITLE_ROLE_CHIEF" if Game.role == Game.Role.CHIEF else "TITLE_ROLE_STAFF")


func _on_toggle_role() -> void:
	Game.toggle_role()
	_refresh_role()


func _on_start() -> void:
	var text := _seed_input.text.strip_edges()
	Game.start_match(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

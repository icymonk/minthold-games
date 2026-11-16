extends ScreenBase

var _seed_input: LineEdit
var _players_button: Button
var help: HelpPanel


func _ready() -> void:
	_make_list()
	_label(tr("GAME_TITLE"), 96)
	_label(tr("TITLE_SUBTITLE"), 28).modulate = Color(Style.INK, 0.7)
	_players_button = _button("", _on_cycle_players)
	_refresh_players()
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
	_button(tr("TITLE_HELP"), func() -> void: help.open())
	_button(tr("TITLE_LANGUAGE"), _on_toggle_language)
	help = HelpPanel.new()
	add_child(help)


func _refresh_players() -> void:
	_players_button.text = tr("TITLE_PLAYERS") % Game.players


func _on_cycle_players() -> void:
	var n := Game.players + 1
	Game.set_players(Game.MIN_PLAYERS if n > Game.MAX_PLAYERS else n)
	_refresh_players()


func _on_start() -> void:
	var text := _seed_input.text.strip_edges()
	Game.start_match(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

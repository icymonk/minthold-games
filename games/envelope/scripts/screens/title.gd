extends ScreenBase

var _seed_input: LineEdit
var _players_button: Button
var _sound_button: Button
var help: HelpPanel


func _ready() -> void:
	_make_list()
	_list.add_theme_constant_override(&"separation", 16)
	var faces := HBoxContainer.new()
	faces.alignment = BoxContainer.ALIGNMENT_CENTER
	faces.add_theme_constant_override(&"separation", 18)
	for s in range(1, 6):
		faces.add_child(Portrait.new(s, -1, 80))
	_list.add_child(faces)
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
	_button(tr("TITLE_LEAGUE") % League.GAMES, Game.start_league)
	_button(tr("TITLE_RECORDS"), func() -> void: Game.goto(&"records"))
	_button(tr("TITLE_HELP"), func() -> void: help.open())
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", 12)
	_list.add_child(row)
	_sound_button = _button("", _on_toggle_sound)
	_refresh_sound()
	var lang := _button(tr("TITLE_LANGUAGE"), _on_toggle_language)
	for b in [_sound_button, lang]:
		b.custom_minimum_size = Vector2(204, 72)
		b.reparent(row)
	help = HelpPanel.new()
	add_child(help)


func _refresh_players() -> void:
	_players_button.text = tr("TITLE_PLAYERS") % Game.players


func _on_cycle_players() -> void:
	var n := Game.players + 1
	Game.set_players(Game.MIN_PLAYERS if n > Game.MAX_PLAYERS else n)
	_refresh_players()


func _refresh_sound() -> void:
	_sound_button.text = tr("TITLE_SOUND_ON" if Game.sound else "TITLE_SOUND_OFF")


func _on_toggle_sound() -> void:
	Game.set_sound(not Game.sound)
	_refresh_sound()
	Sfx.play(&"card")


func _on_start() -> void:
	var text := _seed_input.text.strip_edges()
	Game.league = null
	Game.start_match(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

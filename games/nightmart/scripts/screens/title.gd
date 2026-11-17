extends ScreenBase

var _seed_input: LineEdit
var _sound: Button


func _ready() -> void:
	_make_list()
	_list.add_child(_shelf())
	_label(tr("GAME_TITLE"), Style.SCORE).add_theme_color_override(&"font_color", Style.NEON)
	_label(tr("TITLE_SUBTITLE")).modulate = Color(Style.FLUORESCENT, 0.75)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.alignment = HORIZONTAL_ALIGNMENT_CENTER
	_seed_input.custom_minimum_size = Vector2(560, 96)
	_seed_input.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_list.add_child(_seed_input)
	var starts := HBoxContainer.new()
	starts.alignment = BoxContainer.ALIGNMENT_CENTER
	starts.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(starts)
	if Game.has_save():
		var go_on := _button(Art.ICON_NEXT, tr("TITLE_CONTINUE"), _on_continue, starts)
		go_on.theme_type_variation = &"AccentButton"
		go_on.grab_focus()
	var start := _button(Art.ICON_NEXT, tr("TITLE_NEW_RUN"), _on_new_run, starts)
	if not Game.has_save():
		start.theme_type_variation = &"AccentButton"
		start.grab_focus()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(row)
	_button(Art.ICON_HELP, tr("TITLE_LEDGER"), Game.goto.bind(&"ledger"), row).custom_minimum_size.x = 264
	_button(Art.ICON_SETTINGS, tr("TITLE_LANGUAGE"), _on_toggle_language, row).custom_minimum_size.x = 264
	_sound = _button(Art.ICON_SOUND_ON, "", _on_toggle_sound, row)
	_sound.custom_minimum_size.x = 264
	_show_sound()


## 코너마다 상품 하나씩, 천천히 떠다니는 진열대.
func _shelf() -> Control:
	var shelf := HBoxContainer.new()
	shelf.alignment = BoxContainer.ALIGNMENT_CENTER
	shelf.add_theme_constant_override(&"separation", 48)
	var picks := [[&"meal", 10], [&"snack", 13], [&"drink", 8], [&"goods", 4]]
	for i in picks.size():
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(150, 150)
		var art := TextureRect.new()
		art.texture = Art.product(picks[i][0], picks[i][1])
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.size = holder.custom_minimum_size
		holder.add_child(art)
		shelf.add_child(holder)
		var tw := create_tween().set_loops()
		tw.tween_interval(i * 0.25)
		tw.tween_property(art, ^"position:y", -14.0, 0.9).set_trans(Tween.TRANS_SINE)
		tw.tween_property(art, ^"position:y", 0.0, 0.9).set_trans(Tween.TRANS_SINE)
	return shelf


func _show_sound() -> void:
	_sound.icon = Art.ICON_SOUND_OFF if Sfx.muted else Art.ICON_SOUND_ON
	_sound.text = tr("TITLE_SOUND_OFF" if Sfx.muted else "TITLE_SOUND_ON")


func _on_toggle_sound() -> void:
	Sfx.set_muted(not Sfx.muted)
	_show_sound()


func _on_new_run() -> void:
	var text := _seed_input.text.strip_edges()
	Game.start_run(int(text) if text.is_valid_int() else randi())


func _on_continue() -> void:
	if not Game.continue_run():
		Game.goto(&"title")


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

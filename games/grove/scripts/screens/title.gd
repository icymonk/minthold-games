extends ScreenBase
## 제목: 천천히 도는 숲 섬 위에 제목과 시작 버튼.

var _sound: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	_label(col, tr("GAME_TITLE"), Style.SCORE)
	_label(col, tr("TITLE_SUBTITLE"), Style.BODY, Color(Style.CREAM, 0.85))
	_spacer(col)
	var start := _button(col, Art.ICON_NEXT, tr("TITLE_NEW_RUN"), Game.start_run, 560)
	start.theme_type_variation = &"AccentButton"
	start.grab_focus()
	var row := _row(col)
	_button(row, Art.ICON_SETTINGS, tr("TITLE_LANGUAGE"), _on_toggle_language, 300)
	_sound = _button(row, Art.ICON_SOUND_ON, "", _on_toggle_sound, 300)
	_show_sound()


func _show_sound() -> void:
	_sound.icon = Art.ICON_SOUND_OFF if Sfx.muted else Art.ICON_SOUND_ON
	_sound.text = tr("TITLE_SOUND_OFF" if Sfx.muted else "TITLE_SOUND_ON")


func _on_toggle_sound() -> void:
	Sfx.set_muted(not Sfx.muted)
	_show_sound()


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

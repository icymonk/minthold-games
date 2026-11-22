extends ScreenBase
## 런 끝 뼈대: 숲이 한 바퀴 도는 동안 결과(점수·도감은 2-2·3-3에서).


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	_label(col, tr("RUN_END_WIN"), Style.SCORE, Style.SPROUT)
	_spacer(col)
	var row := _row(col)
	_button(row, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	var again := _button(row, Art.ICON_RETRY, tr("RUN_END_RETRY"), Game.start_run, 480)
	again.theme_type_variation = &"AccentButton"
	again.grab_focus()

extends ScreenBase


func _ready() -> void:
	var run := Game.run
	_make_list()
	_label(tr("NIGHT_LABEL") % [run.night, RunState.NIGHTS], 64)
	if run.is_boss_night():
		_label(tr("NIGHT_BOSS"), 36).modulate = Color(1, 0.45, 0.4)
	_label(tr("NIGHT_LANTERNS") % run.lanterns, 36)
	_label(tr("NIGHT_PLACEHOLDER"), 24).modulate = Color(1, 1, 1, 0.6)
	_label(tr("TITLE_SEED") + " %d" % run.seed, 20).modulate = Color(1, 1, 1, 0.5)
	_button(tr("NIGHT_WIN"), _finish.bind(true)).grab_focus()
	_button(tr("NIGHT_LOSE"), _finish.bind(false))


func _finish(won: bool) -> void:
	if won:
		Game.run.win_night()
	else:
		Game.run.lose_night()
	Game.goto(&"result" if Game.run.is_over() else &"night")

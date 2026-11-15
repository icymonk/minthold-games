extends ScreenBase


func _ready() -> void:
	var run := Game.run
	_make_list()
	_label(tr("RESULT_VICTORY") if run.is_victory() else tr("RESULT_DEFEAT"), 56)
	_label(tr("RESULT_REACHED") % mini(run.night, RunState.NIGHTS), 32)
	_button(tr("RESULT_AGAIN"), Game.start_run.bind(-1)).grab_focus()
	_button(tr("RESULT_TITLE"), Game.goto.bind(&"title"))

extends ScreenBase


func _ready() -> void:
	_make_list()
	_label(tr("COUNTER_PLACEHOLDER") % Game.run_seed, Style.HEADLINE)
	_button("⌂", tr("BACK_TO_TITLE"), Game.goto.bind(&"title")).grab_focus()

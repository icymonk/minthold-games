extends ScreenBase


func _ready() -> void:
	_make_list()
	_label(tr("TOUR_PLACEHOLDER") % Game.run_seed, 32)
	_button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title"))

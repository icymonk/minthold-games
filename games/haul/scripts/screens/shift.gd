extends ScreenBase


func _ready() -> void:
	_make_list()
	_label(tr("SHIFT_PLACEHOLDER") % [Game.shift.bay.boxes.size(), Game.shift.queue.size()], 32)
	_button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title"))

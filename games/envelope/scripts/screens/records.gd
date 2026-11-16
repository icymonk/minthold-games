extends ScreenBase
## 기록(기획서 6장): 정체별 승률, 최고 사내 평판.


func _ready() -> void:
	_make_list()
	_label(tr("RECORDS_TITLE"), 64)
	var plays: Dictionary = Game.records.plays
	var wins: Dictionary = Game.records.wins
	if plays.is_empty():
		_label(tr("RECORDS_EMPTY"), 28)
	var total := 0
	var won := 0
	for id in Cards.DEFS:
		var key := String(Cards.DEFS[id].key)
		var n: int = plays.get(key, 0)
		if n == 0:
			continue
		var w: int = wins.get(key, 0)
		total += n
		won += w
		_label(tr("RECORDS_ROW") % [tr(Cards.name_key(id)), n, w, roundi(100.0 * w / n)], 26)
	if total > 0:
		_label(tr("RECORDS_TOTAL") % [total, won], 30)
	_label(tr("RECORDS_BEST") % Game.records.best, 30)
	var back := _button(tr("BACK_TO_TITLE"), func() -> void: Game.goto(&"title"))
	back.grab_focus()

extends ScreenBase
## 해금 장부: 기록, 도감 칸 수, 과제 10개(채우면 꿀팁이 풀린다).

const COLUMNS := 3


func _ready() -> void:
	var l: Ledger = Game.ledger
	var records := _frame(tr("LEDGER_TITLE"))
	records.text = tr("LEDGER_RECORDS") % [l.runs, l.wins, l.best_night, Style.num(l.best_checkout)]
	records.add_theme_font_size_override(&"font_size", Style.BODY)
	var counts := []
	for k in Ledger.KINDS:
		counts.append_array([l.seen[k].size(), Ledger.total(k)])
	_text(_list, tr("LEDGER_SEEN") % counts, Style.BODY, Color(Style.FLUORESCENT, 0.8))
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", Style.GAP)
	grid.add_theme_constant_override(&"v_separation", Style.GAP)
	grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_list.add_child(grid)
	for id in Ledger.CHALLENGES:
		var done: bool = l.done.has(id)
		var col := _panel(grid, Vector2(552, 136), Style.NEON if done else Color(Style.FLUORESCENT, 0.25))
		var goal := _text(col, tr("CH_%s" % String(id).to_upper()), Style.BODY, Style.FLUORESCENT if done else Color(Style.FLUORESCENT, 0.7))
		goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_text(col, (tr("LEDGER_UNLOCKED") if done else tr("LEDGER_LOCKED")) % Names.tip(Ledger.CHALLENGES[id]), Style.BODY, Style.NEON if done else Color(Style.FLUORESCENT, 0.4))

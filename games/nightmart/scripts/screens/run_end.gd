extends ScreenBase
## 영업 끝: 완주했는지, 어디까지 갔는지, 가장 큰 매출, 들고 있던 꿀팁.

var run: Run


func _ready() -> void:
	run = Game.run if Game.run else Run.new(Game.run_seed)
	_make_list()
	var won := run.phase == Run.Phase.WON
	var head := _label(tr("END_WON") if won else tr("END_LOST"), Style.SCORE)
	head.add_theme_color_override(&"font_color", Style.NEON if won else Style.ANGRY)
	_label(tr("END_REACHED") % [run.night, tr("SLOT_%d" % run.slot)], Style.HEADLINE)
	var served := run.history.filter(func(h: Dictionary) -> bool: return h.cleared).size()
	_label(tr("END_SERVED") % served)
	var best := 0
	for h in run.history:
		best = maxi(best, h.score)
	_label(tr("END_BEST") % Style.num(best)).add_theme_color_override(&"font_color", Style.PRICE)
	if not run.tips.is_empty():
		_label(", ".join(run.tips.map(func(h: Hook) -> String: return Names.tip(h.id))), Style.BODY).add_theme_color_override(&"font_color", Style.CORNER[&"goods"])
	_button(Art.ICON_RETRY, tr("END_RETRY"), func() -> void: Game.start_run(randi())).theme_type_variation = &"AccentButton"
	_button(Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"))
	Sfx.play(&"chime" if won else &"error")

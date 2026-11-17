extends ScreenBase
## 밤 지도: 오늘 밤 손님 3명(목표·보상·건너뛰기 보상)을 미리 보고, 받거나 건너뛴다.

var run: Run
var _serve: Button
var _skip: Button


func _ready() -> void:
	if Game.run == null:
		Game.run = Run.new(Game.run_seed)
	run = Game.run
	_build()


func _build() -> void:
	_clear()
	var money := _frame(tr("MAP_TITLE") % run.night)
	money.text = Names.money(run.money)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override(&"separation", Style.GAP)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.add_child(row)
	for s in 3:
		_customer(row, s)
	var w := run.weather_id()
	_label(tr("MAP_WEATHER") % [Names.weather(w), Names.weather_desc(w)], Style.BODY)
	if not run.skip_tokens.is_empty():
		_label(tr("MAP_TOKENS") % ", ".join(run.skip_tokens.map(Names.token)), Style.BODY).add_theme_color_override(&"font_color", Style.NEON)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override(&"separation", Style.GAP)
	_list.add_child(buttons)
	_serve = _button(Art.ICON_NEXT, tr("MAP_SERVE"), Game.goto.bind(&"counter"), buttons)
	_serve.theme_type_variation = &"AccentButton"
	_skip = _button(Art.ICON_DISCARD, tr("MAP_SKIP"), _on_skip, buttons)
	_skip.disabled = not run.can_skip()


func _customer(row: HBoxContainer, s: int) -> void:
	var now := s == run.slot
	var col := _panel(row, Vector2(520, 460), Style.NEON if now else Color(Style.FLUORESCENT, 0.25))
	var past := s < run.slot
	col.get_parent().modulate.a = 0.45 if past else 1.0
	_text(col, tr("SLOT_%d" % s), Style.HEADLINE, Style.ANGRY if s == Run.BOSS else Style.FLUORESCENT)
	_text(col, Style.num(run.target_at(s)), Style.SCORE * 2 / 3, Style.PRICE)
	_text(col, tr("COUNTER_TARGET") % "", Style.BODY, Color(Style.FLUORESCENT, 0.6))
	if past:
		var done := run.history.filter(func(h: Dictionary) -> bool: return h.night == run.night and h.slot == s)
		var skipped: bool = not done.is_empty() and done[-1].skipped
		_text(col, tr("MAP_SKIPPED") if skipped else tr("MAP_DONE"), Style.HEADLINE, Style.NEON)
		return
	_text(col, tr("MAP_REWARD") % Names.money(Run.PAYOUT[s]), Style.BODY)
	if s == Run.BOSS:
		_text(col, Names.boss(run.boss_id()), Style.BODY, Style.ANGRY)
		var rule := _text(col, Names.boss_desc(run.boss_id()), Style.BODY, Color(Style.FLUORESCENT, 0.8))
		rule.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rule.custom_minimum_size.x = 440
	elif now:
		_text(col, tr("MAP_SKIP_GETS") % Names.token(run.skip_reward), Style.BODY, Style.NEON)


func _on_skip() -> void:
	if run.skip():
		Sfx.play(&"deal")
		_build()

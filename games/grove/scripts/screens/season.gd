extends ScreenBase
## 계절 화면: 윗줄(계절·바람 칸·목표·섬 돌리기), 아래(손패·바람). 빈터는 2-1에서.
## 0-3: 손패의 카드를 끌어 숲에 붙인다(규칙 없음). 처음이면 Coach가 안내한다.

var hand: Hand
var _dots: Array[Panel] = []
var _turns: Array[Button] = []
var _wind: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	var top := _row(col)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	_button(top, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 220).custom_minimum_size.y = 112
	var info := _glass(top)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(info, Game.season_name(), Style.HEADLINE)
	var wind := _row(info, 16)
	_label(wind, tr("SEASON_WIND"), Style.BODY, Color(Style.CREAM, 0.8))
	for i in Game.WINDS_PER_SEASON:
		var dot := Panel.new()
		dot.custom_minimum_size = Vector2(40, 40)
		dot.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		wind.add_child(dot)
		_dots.append(dot)
	_label(info, tr("SEASON_GOAL") % Game.GOALS[Game.season], Style.HEADLINE, Style.SPROUT)
	_show_winds()
	Game.winds_changed.connect(_on_winds_changed)
	for d in [-1, 1]:
		var b := _button(top, null, tr("SEASON_TURN_LEFT" if d < 0 else "SEASON_TURN_RIGHT"), Game.turn_requested.emit.bind(d), 220)
		b.custom_minimum_size.y = 112
		_turns.append(b)
	var help := _button(top, Art.ICON_HELP, "", start_coach, 112)
	help.custom_minimum_size.y = 112
	help.tooltip_text = tr("COACH_HELP")
	_spacer(col)
	_label(col, tr("SEASON_HAND_HINT"), 30, Color(Style.CREAM, 0.9))
	var bottom := _row(col)
	bottom.alignment = BoxContainer.ALIGNMENT_END
	hand = Hand.new()
	hand.world = get_tree().get_first_node_in_group(&"forest_view") as ForestView
	hand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_child(hand)
	_wind = _button(bottom, Art.ICON_NEXT, tr("SEASON_WIND"), _on_wind, 400)
	_wind.theme_type_variation = &"AccentButton"
	_wind.size_flags_vertical = Control.SIZE_SHRINK_END
	_wind.grab_focus()
	if hand.world == null:
		hand.queue_free()
		hand = null
	elif Game.season == 0 and Game.winds == 0 and not Coach.seen():
		start_coach.call_deferred()


func start_coach() -> void:
	if not hand:
		return
	for c in get_children():
		if c is Coach:
			c.queue_free()
	var coach := Coach.new()
	add_child(coach)
	var world := hand.world
	coach.start([
		{text = "COACH_PLANT", hole = hand.card_rect.bind(DemoCards.is_tree), wait = world.placed,
			check = func(a: Array) -> bool: return a[0].side == &""},
		{text = "COACH_HALF", hole = hand.card_rect.bind(func(c: Dictionary) -> bool: return not DemoCards.is_tree(c)),
			wait = world.placed, check = func(a: Array) -> bool: return a[0].side != &""},
		{text = "COACH_TURN", hole = func() -> Rect2: return _turns[0].get_global_rect().merge(_turns[1].get_global_rect()),
			wait = Game.turn_requested},
		{text = "COACH_WIND", hole = _wind.get_global_rect},
	] as Array[Dictionary])


## 화살표·십자키는 버튼 사이 이동에 쓰이니, 섬 돌리기는 Q/E·LB/RB로 한다.
func _unhandled_input(event: InputEvent) -> void:
	var dir := _turn_dir(event)
	if dir != 0:
		Game.turn_requested.emit(dir)
		get_viewport().set_input_as_handled()


static func _turn_dir(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed and not event.echo:
		return {KEY_Q: -1, KEY_E: 1}.get(event.keycode, 0)
	if event is InputEventJoypadButton and event.pressed:
		return {JOY_BUTTON_LEFT_SHOULDER: -1, JOY_BUTTON_RIGHT_SHOULDER: 1}.get(event.button_index, 0)
	return 0


func _show_winds() -> void:
	for i in _dots.size():
		var on := i < Game.winds
		_dots[i].add_theme_stylebox_override(&"panel", Style.box(Style.SUNSET if on else Color(Style.CREAM, 0.15), 20, Style.CREAM if on else Color(Style.CREAM, 0.4), 3))


func _on_wind() -> void:
	Sfx.play(&"chime")
	Game.blow_wind()


func _on_winds_changed(winds: int) -> void:
	if Game.screen != &"season" or winds > _dots.size():
		return
	_show_winds()
	var dot := _dots[winds - 1]
	dot.pivot_offset = dot.size / 2.0
	dot.scale = Vector2.ONE * 1.6
	create_tween().tween_property(dot, ^"scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

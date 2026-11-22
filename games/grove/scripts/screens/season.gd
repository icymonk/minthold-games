extends ScreenBase
## 계절 화면 뼈대: 윗줄(계절·바람 칸·목표), 아래(섬 돌리기·바람). 손패·빈터는 0-3·2-1에서.

var _dots: Array[Panel] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	var top := _row(col)
	top.alignment = BoxContainer.ALIGNMENT_BEGIN
	_button(top, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 260).custom_minimum_size.y = 112
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
	_spacer(col)
	_label(col, tr("SEASON_DEMO_HINT"), Style.BODY, Color(Style.CREAM, 0.9))
	var bottom := _row(col)
	_button(bottom, null, tr("SEASON_TURN_LEFT"), Game.turn_requested.emit.bind(-1), 360)
	var blow := _button(bottom, Art.ICON_NEXT, tr("SEASON_WIND"), _on_wind, 480)
	blow.theme_type_variation = &"AccentButton"
	blow.grab_focus()
	_button(bottom, null, tr("SEASON_TURN_RIGHT"), Game.turn_requested.emit.bind(1), 360)


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

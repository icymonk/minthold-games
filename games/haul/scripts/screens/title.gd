extends Control
## 첫 화면: 배경과 트럭 그림, 게임 한 줄 설명 세 개, 시작 버튼.

const PREVIEW_CELL := 64.0

var _font: Font
var _seed_input: LineEdit
var _sample: Array[Dictionary] = [
	{box = Box.new(1, &"2x2", 3), at = Vector2i(0, 0)},
	{box = Box.new(2, &"1x2", 2), at = Vector2i(2, 0)},
	{box = Box.new(3, &"2x1", 2), at = Vector2i(3, 0)},
	{box = Box.new(4, &"1x1", 1), at = Vector2i(5, 0)},
	{box = Box.new(5, &"2x1", 1), at = Vector2i(3, 1)},
]


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_font = Style.bold()
	var col := VBoxContainer.new()
	col.add_theme_constant_override(&"separation", 18)
	col.position = Vector2(140, 170)
	add_child(col)
	_label(col, tr("GAME_TITLE"), 110, Style.TAPE)
	_label(col, tr("TITLE_SUBTITLE"), 34, Style.LAMP)
	col.add_child(_spacer(20))
	for i in 3:
		col.add_child(_premise(i + 1, tr("TITLE_PREMISE_%d" % (i + 1))))
	col.add_child(_spacer(30))
	var first := _button(col, tr("TITLE_NEW_RUN") if Game.tutorial_done else tr("TITLE_FIRST_RUN"), _on_new_run)
	first.theme_type_variation = &"AccentButton"
	first.grab_focus()
	if Game.tutorial_done:
		_button(col, tr("TITLE_TUTORIAL"), Game.start_tutorial)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 16)
	col.add_child(row)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = tr("TITLE_SEED")
	_seed_input.custom_minimum_size = Vector2(200, 52)
	_seed_input.add_theme_font_size_override(&"font_size", 22)
	_seed_input.visible = Game.tutorial_done
	row.add_child(_seed_input)
	var lang := Button.new()
	lang.text = tr("TITLE_LANGUAGE")
	lang.custom_minimum_size = Vector2(200, 52)
	lang.add_theme_font_size_override(&"font_size", 22)
	lang.pressed.connect(_on_toggle_language)
	row.add_child(lang)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var bay := Rect2(Vector2(size.x - 160 - 8 * PREVIEW_CELL, 520), Vector2(8, 4) * PREVIEW_CELL)
	var floor_y := bay.end.y + 12 + Art.CAB_CHASSIS * Art.BAKE_SCALE * PREVIEW_CELL / 104.0 - 4
	var t := Time.get_ticks_msec() / 1000.0
	Art.draw_scene(self, size, floor_y, t)
	var shade := Color(Style.DAWN_DEEP, 0.7)
	draw_polygon(PackedVector2Array([Vector2.ZERO, Vector2(size.x * 0.6, 0), Vector2(size.x * 0.6, size.y), Vector2(0, size.y)]),
		PackedColorArray([shade, Color(shade, 0), Color(shade, 0), shade]))
	var bob := sin(Time.get_ticks_msec() / 400.0) * 2.0
	draw_set_transform(Vector2(0, bob))
	Art.draw_truck(self, bay, PREVIEW_CELL, 12)
	for s in _sample:
		var at: Vector2i = s.at
		var pos := bay.position + Vector2(at.x, 3 - at.y) * PREVIEW_CELL
		Art.draw_box(self, _font, s.box, pos, PREVIEW_CELL)
	draw_set_transform(Vector2.ZERO)


func _premise(n: int, text: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", 18)
	var badge := Label.new()
	badge.text = str(n)
	badge.custom_minimum_size = Vector2(52, 52)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_override(&"font", _font)
	badge.add_theme_font_size_override(&"font_size", 28)
	badge.add_theme_color_override(&"font_color", Style.DAWN_DEEP)
	badge.add_theme_stylebox_override(&"normal", Style.box(Style.stop_color(n), 26))
	row.add_child(badge)
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override(&"font_size", 30)
	row.add_child(label)
	return row


func _label(parent: Control, text: String, fs: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override(&"font", _font)
	l.add_theme_font_size_override(&"font_size", fs)
	l.add_theme_color_override(&"font_color", color)
	parent.add_child(l)
	return l


func _spacer(h: float) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _button(parent: Control, text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(460, 76)
	b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	b.add_theme_font_size_override(&"font_size", 30)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b


func _on_new_run() -> void:
	if not Game.tutorial_done:
		Game.start_tutorial()
		return
	var text := _seed_input.text.strip_edges()
	Game.start_run(int(text) if text.is_valid_int() else -1)


func _on_toggle_language() -> void:
	TranslationServer.set_locale("en" if TranslationServer.get_locale().begins_with("ko") else "ko")
	Game.goto(&"title")

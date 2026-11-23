extends ScreenBase
## 새 한 해 준비(4-1): 숲지기 8명 중 하나와 숲 등급을 고른다. 잠긴 숲지기는 해금 조건을 보여 준다.

var _keepers: Array[Button] = []
var _grade: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	_label(col, tr("SETUP_TITLE"), Style.HEADLINE)
	var ids: Array = Keepers.ALL.keys()
	if not Keepers.unlocked(Game.keeper, Game.records):
		Game.keeper = &"grandma"
	Game.grade = mini(Game.grade, Game.records.open_grade())
	for r in 2:
		var row := _row(col, 16)
		for i in range(r * 4, r * 4 + 4):
			var id: StringName = ids[i]
			var b := _button(row, null, "", _pick.bind(id), 400)
			b.custom_minimum_size.y = 150
			b.add_theme_font_size_override(&"font_size", 26)
			b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			var open := Keepers.unlocked(id, Game.records)
			b.text = "%s\n%s" % [tr("KEEPER_%s" % String(id).to_upper()), _desc(id) if open else _lock(id)]
			b.disabled = not open
			b.set_meta(&"id", id)
			_keepers.append(b)
	var g := _row(col)
	_button(g, null, "-", _step.bind(-1), 120)
	_grade = _label(g, "", 32)
	_grade.custom_minimum_size.x = 760
	_grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(g, null, "+", _step.bind(1), 120)
	_spacer(col)
	var buttons := _row(col)
	_button(buttons, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	var go := _button(buttons, Art.ICON_NEXT, tr("SETUP_START"), Game.start_run.bind(-1), 480)
	go.theme_type_variation = &"AccentButton"
	go.grab_focus()
	_show()


static func _desc(id: StringName) -> String:
	var k := Keepers.def_of(id)
	var parts: Array[String] = []
	if not k.pairs.is_empty():
		parts.append(TranslationServer.translate("KEEPER_PAIRS") % k.pairs.size())
	if k.acorns > 0:
		parts.append(TranslationServer.translate("KEEPER_ACORNS") % k.acorns)
	if k.spirit != &"":
		parts.append(TranslationServer.translate("KEEPER_SPIRIT") % TranslationServer.translate("SPIRIT_%s" % String(k.spirit).to_upper()))
	return " · ".join(parts) if not parts.is_empty() else TranslationServer.translate("KEEPER_PLAIN")


static func _lock(id: StringName) -> String:
	var u: Dictionary = Keepers.def_of(id).unlock
	for key in u:
		return TranslationServer.translate("UNLOCK_%s" % String(key).to_upper()) % u[key]
	return ""


func _pick(id: StringName) -> void:
	Game.keeper = id
	_show()


func _step(d: int) -> void:
	Game.grade = clampi(Game.grade + d, 0, Game.records.open_grade())
	_show()


func _show() -> void:
	for b in _keepers:
		b.theme_type_variation = &"AccentButton" if b.get_meta(&"id") == Game.keeper else &""
	_grade.text = tr("SETUP_GRADE") % [Game.grade, tr("GRADE_%d" % Game.grade)]

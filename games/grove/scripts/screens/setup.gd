extends ScreenBase
## 새 한 해 준비(4-1): 숲지기 8명 중 하나와 숲 등급을 고른다.
## 숲지기 카드: 대표 이웃 그림, 한 줄 소개, 시작 혜택(카드·정령·솔방울). 잠긴 숲지기는 자물쇠와 해금 진행 막대.

const CARD := Vector2(400, 288)
const PIC := 84

var _keepers: Array[Button] = []
var _grade: Label
var _portrait: Portrait


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim()
	_portrait = Portrait.new()
	add_child(_portrait)
	var col := _frame()
	_label(col, tr("SETUP_TITLE"), Style.HEADLINE)
	var ids: Array = Keepers.ALL.keys()
	if not Keepers.unlocked(Game.keeper, Game.records):
		Game.keeper = &"grandma"
	Game.grade = mini(Game.grade, Game.records.open_grade())
	for r in 2:
		var row := _row(col, 16)
		for i in range(r * 4, r * 4 + 4):
			_keepers.append(_keeper(row, ids[i]))
	var g := _row(col)
	_button(g, null, "-", _step.bind(-1), 120).custom_minimum_size.y = 72
	_grade = _label(g, "", 30)
	_grade.custom_minimum_size.x = 760
	_grade.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_button(g, null, "+", _step.bind(1), 120).custom_minimum_size.y = 72
	_spacer(col)
	var buttons := _row(col)
	_button(buttons, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	var go := _button(buttons, Art.ICON_NEXT, tr("SETUP_START"), Game.start_run.bind(-1), 480)
	go.theme_type_variation = &"AccentButton"
	go.grab_focus()
	_show()


func _keeper(row: HBoxContainer, id: StringName) -> Button:
	var open := Keepers.unlocked(id, Game.records)
	var b := Button.new()
	b.custom_minimum_size = CARD
	b.disabled = not open
	b.focus_mode = Control.FOCUS_ALL if open else Control.FOCUS_NONE
	b.pressed.connect(_pick.bind(id))
	b.set_meta(&"id", id)
	b.tooltip_text = _perks_text(id)
	row.add_child(b)
	var pad := MarginContainer.new()
	pad.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for side in [&"margin_left", &"margin_right", &"margin_top", &"margin_bottom"]:
		pad.add_theme_constant_override(side, 16)
	b.add_child(pad)
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override(&"separation", 6)
	pad.add_child(box)
	var pics := HBoxContainer.new()
	pics.alignment = BoxContainer.ALIGNMENT_CENTER
	pics.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pics.add_theme_constant_override(&"separation", 4)
	box.add_child(pics)
	for k in faces(id):
		var pic := TextureRect.new()
		pic.custom_minimum_size = Vector2(PIC, PIC)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pics.add_child(pic)
		if Art.ICONS.has(k) or k == &"acorn":
			pic.texture = Art.icon(k)
			pic.custom_minimum_size = Vector2(PIC - 16, PIC)
		else:
			_portrait.request(k, func(tex: Texture2D) -> void:
				if is_instance_valid(pic):
					pic.texture = tex)
	var name := _label(box, tr("KEEPER_%s" % String(id).to_upper()), 30)
	name.add_theme_font_override(&"font", Style.bold())
	var tag := _label(box, tr("KEEPER_%s_TAG" % String(id).to_upper()), 20, Color(Style.CREAM, 0.85))
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = CARD.x - 32
	if open:
		var perks := _label(box, _perks_text(id, false), 19, Style.SUNSET.lightened(0.35))
		perks.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		perks.custom_minimum_size.x = CARD.x - 32
		var k := Keepers.def_of(id)
		if k.spirit != &"":
			var d := _label(box, tr("SPIRIT_%s_DESC" % String(k.spirit).to_upper()), 17, Color(Style.CREAM, 0.7))
			d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			d.custom_minimum_size.x = CARD.x - 32
	else:
		pics.modulate = Color(0.25, 0.3, 0.28, 0.9)
		name.modulate = Color(1, 1, 1, 0.6)
		tag.modulate = Color(1, 1, 1, 0.55)
		var lock := TextureRect.new()
		lock.texture = Art.lock()
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		lock.size = Vector2(48, 48)
		lock.position = Vector2(CARD.x - 60, 12)
		b.add_child(lock)
		var goal := progress(id, Game.records)
		var need := _label(box, _lock(id), 19, Color("#FFD27A"))
		need.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		need.custom_minimum_size.x = CARD.x - 32
		var bar := ProgressBar.new()
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.custom_minimum_size = Vector2(CARD.x - 32, 22)
		bar.max_value = goal.y
		bar.value = goal.x
		bar.show_percentage = false
		bar.add_theme_stylebox_override(&"background", Style.box(Color(0, 0, 0, 0.35), 11))
		bar.add_theme_stylebox_override(&"fill", Style.box(Color("#FFD27A"), 11))
		box.add_child(bar)
		_label(box, "%d / %d" % [goal.x, goal.y], 18, Color(Style.CREAM, 0.75))
	return b


## 숲지기 카드에 그릴 그림: 시작 이웃 중 숲지기 주제(가장 많은 분류)의 반쪽들. 이웃이 없으면 아이콘.
static func faces(id: StringName) -> Array[StringName]:
	var k := Keepers.def_of(id)
	var out: Array[StringName] = []
	if k.pairs.is_empty():
		out.append(&"acorn" if k.acorns > 0 else &"t_oak")
		if k.acorns <= 0:
			out.append(&"t_birch")
			out.append(&"t_maple")
		return out
	var count := {}
	for i in k.pairs:
		for h in Cards.full_pair(0, i).halves:
			var g: StringName = CardText.def_of(h).get("kind", &"")
			count[g] = count.get(g, 0) + 1
	var top: StringName = count.keys()[0]
	for g in count:
		if count[g] > count[top]:
			top = g
	for i in k.pairs.slice(0, 3):
		var halves: Array = Cards.full_pair(0, i).halves
		var pick: StringName = halves[0]
		for h in halves:
			if CardText.def_of(h).get("kind", &"") == top:
				pick = h
				break
		if not pick in out:
			out.append(pick)
	return out


## 해금 진행도: (지금, 목표)
static func progress(id: StringName, r: Records) -> Vector2i:
	var u: Dictionary = Keepers.def_of(id).unlock
	for key in u:
		var now: int = {runs = r.runs, finished = r.finished, found = r.found()}.get(key, 0)
		return Vector2i(mini(now, u[key]), u[key])
	return Vector2i(1, 1)


static func _perks_text(id: StringName, full := true) -> String:
	var k := Keepers.def_of(id)
	var parts: Array[String] = []
	if not k.pairs.is_empty():
		parts.append(TranslationServer.translate("KEEPER_PAIRS") % k.pairs.size())
	if k.acorns > 0:
		parts.append(TranslationServer.translate("KEEPER_ACORNS") % k.acorns)
	if k.spirit != &"":
		var s := String(k.spirit).to_upper()
		parts.append(TranslationServer.translate("KEEPER_SPIRIT") % TranslationServer.translate("SPIRIT_%s" % s)
			+ ("\n" + TranslationServer.translate("SPIRIT_%s_DESC" % s) if full else ""))
	return ("\n" if full else " · ").join(parts) if not parts.is_empty() else TranslationServer.translate("KEEPER_PLAIN")


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
		var on: bool = b.get_meta(&"id") == Game.keeper
		var st := Style.box(Color(Style.FOREST, 0.9).lerp(Style.SUNSET, 0.18) if on else Color(Style.FOREST, 0.82), 18, Style.SUNSET if on else Color(Style.CREAM, 0.25), 4 if on else 2)
		for s in [&"normal", &"hover", &"pressed", &"focus", &"disabled"]:
			b.add_theme_stylebox_override(s, st)
	var rule := tr("GRADE_%d" % Game.grade).trim_prefix("+ ")
	if Game.grade >= 2:
		rule += tr("SETUP_GRADE_STACK")
	_grade.text = tr("SETUP_GRADE") % [Game.grade, rule]

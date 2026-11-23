extends ScreenBase
## 숲 도감과 기록(3-3): 숲에 들인 적 있는 나무·이웃만 그림과 이름이 보인다.

const COLUMNS := 12
const CELL := 118

var _portrait: Portrait


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	var r: Records = Game.records
	var kinds := Records.all_kinds()
	_label(col, tr("CODEX_TITLE"), Style.HEADLINE)
	_label(col, "%s   ·   %s" % [tr("CODEX_FOUND") % [r.found(), kinds.size()], tr("CODEX_RECORDS") % [r.runs, r.finished, r.best_year]], 28, Color(Style.CREAM, 0.85))
	var glass := _glass(col)
	glass.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override(&"h_separation", 8)
	grid.add_theme_constant_override(&"v_separation", 4)
	glass.add_child(grid)
	_portrait = Portrait.new()
	add_child(_portrait)
	for k in kinds:
		grid.add_child(_cell(k, r.seen.has(k)))
	_spacer(col)
	var back := _button(col, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	back.grab_focus()


func _cell(kind: StringName, found: bool) -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(CELL, CELL + 22)
	box.add_theme_constant_override(&"separation", 0)
	var pic := TextureRect.new()
	pic.custom_minimum_size = Vector2(CELL, CELL - 12)
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if not found:
		pic.modulate = Color(0.08, 0.12, 0.1, 0.75)
	box.add_child(pic)
	_portrait.request(kind, func(tex: Texture2D) -> void:
		if is_instance_valid(pic):
			pic.texture = tex)
	var name := _label(box, tr("KIND_%s" % String(kind).to_upper()) if found else tr("CODEX_UNKNOWN"), 18, Style.CREAM if found else Color(Style.CREAM, 0.5))
	name.clip_text = true
	name.custom_minimum_size.x = CELL
	name.tooltip_text = name.text
	return box

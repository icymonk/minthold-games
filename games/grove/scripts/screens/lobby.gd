extends ScreenBase
## 온라인 대기실: 이름 정하기 → 방 만들기 또는 방 코드로 들어가기 → 2~5명이 모이면 방장이 시작.

var _net: Online
var _nick: LineEdit
var _code: LineEdit
var _status: Label
var _body: VBoxContainer
var _busy := false


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim()
	_net = Game.net()
	_net.changed.connect(_on_changed)
	_net.failed.connect(_on_failed)
	var col := _frame()
	_label(col, tr("LOBBY_TITLE"), Style.HEADLINE)
	_label(col, tr("LOBBY_SUB"), Style.BODY, Color(Style.CREAM, 0.85))
	_spacer(col)
	_body = VBoxContainer.new()
	_body.add_theme_constant_override(&"separation", Style.GAP)
	_body.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(_body)
	_status = _label(col, "", 28, Style.SUNSET)
	_spacer(col)
	_button(col, Art.ICON_HOME, tr("BACK_TO_TITLE"), _back, 360)
	_build()


func _back() -> void:
	_net.leave()
	Game.goto(&"title")


func _field(parent: Control, text: String, hint: String, width: int, max_len: int) -> LineEdit:
	var e := LineEdit.new()
	e.text = text
	e.placeholder_text = hint
	e.max_length = max_len
	e.custom_minimum_size = Vector2(width, Style.BUTTON_H)
	e.alignment = HORIZONTAL_ALIGNMENT_CENTER
	e.add_theme_font_override(&"font", Style.bold())
	e.add_theme_font_size_override(&"font_size", Style.BODY)
	parent.add_child(e)
	return e


func _build() -> void:
	for c in _body.get_children():
		c.queue_free()
	if _net.code == "":
		_build_entry()
	else:
		_build_room()


func _build_entry() -> void:
	var row := _row(_body)
	_label(row, tr("LOBBY_NAME"), Style.BODY)
	if Game.nick == "":
		Game.nick = tr("LOBBY_DEFAULT_NAME") % (randi() % 90 + 10)
	_nick = _field(row, Game.nick, tr("LOBBY_NAME"), 420, 16)
	var create := _button(_body, Art.ICON_NEXT, tr("LOBBY_CREATE"), _create, 560)
	create.theme_type_variation = &"AccentButton"
	var join := _row(_body)
	_code = _field(join, "", tr("LOBBY_CODE_HINT"), 300, Online.CODE_LEN)
	_code.text_submitted.connect(func(_t: String) -> void: _join())
	_button(join, Art.ICON_NEXT, tr("LOBBY_JOIN"), _join, 300)


func _build_room() -> void:
	_label(_body, tr("LOBBY_CODE") % _net.code, Style.SCORE, Style.SPROUT)
	var copy := _button(_body, null, tr("LOBBY_COPY"), func() -> void:
		DisplayServer.clipboard_set(_net.code)
		_status.text = tr("LOBBY_COPIED"), 300)
	copy.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var list := _glass(_body)
	list.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var names := VBoxContainer.new()
	list.add_child(names)
	var m := _net.members()
	for i in m.size():
		var who: String = m[i].name
		if m[i].uid == _net.room.get("host", ""):
			who += "  · " + tr("LOBBY_HOST")
		if m[i].uid == _net.me:
			who += "  · " + tr("LOBBY_ME")
		_label(names, "%d. %s" % [i + 1, who], Style.BODY)
	_label(_body, tr("LOBBY_COUNT") % [m.size(), Match.MAX_PLAYERS], 26, Color(Style.CREAM, 0.8))
	if _net.is_host():
		var start := _button(_body, Art.ICON_NEXT, tr("LOBBY_START"), _start, 480)
		start.theme_type_variation = &"AccentButton"
		start.disabled = _busy or m.size() < Match.MIN_PLAYERS
	else:
		_label(_body, tr("LOBBY_WAIT"), 28, Color(Style.CREAM, 0.8))


func _create() -> void:
	if _busy:
		return
	Game.nick = _nick_text()
	_set_busy(true)
	await _net.create(Game.nick)
	_set_busy(false)


func _join() -> void:
	if _busy:
		return
	if _code.text.strip_edges().length() != Online.CODE_LEN:
		_status.text = tr("NET_ERR_NO_ROOM")
		return
	Game.nick = _nick_text()
	var c := _code.text
	_set_busy(true)
	await _net.join(c, Game.nick)
	_set_busy(false)


func _start() -> void:
	if _busy:
		return
	_set_busy(true)
	await _net.start()
	_set_busy(false)


func _nick_text() -> String:
	var t := _nick.text.strip_edges() if _nick else Game.nick
	return t.substr(0, 16) if t != "" else tr("LOBBY_DEFAULT_NAME") % (randi() % 90 + 10)


func _set_busy(on: bool) -> void:
	_busy = on
	if on:
		_status.text = tr("LOBBY_WORKING")
		return
	if _status.text == tr("LOBBY_WORKING"):
		_status.text = ""
	_build()


func _on_changed() -> void:
	if not is_inside_tree():
		return
	if Game.in_match():
		Game.begin_match()
		return
	if not _busy:
		_build()


func _on_failed(msg: String) -> void:
	_status.text = tr(msg)
	if not _busy:
		_build()

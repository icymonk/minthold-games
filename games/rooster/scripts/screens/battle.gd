extends Control
## 전투 재생 화면. BattleSim이 미리 계산한 이벤트를 시간 순서대로 보여 준다.

const BAG_POS := Vector2(80, 230)
const CELL := 100.0
const ENEMY_X0 := 780.0
const ENEMY_GAP := 112.0
const LOG_RECT := Rect2(80, 690, 1150, 360)
const BAR := Rect2(240, 110, 1440, 18)
const LOG_LINES := 9
const FLASH_TIME := 0.3

var sim: BattleSim
var _font: Font
var _state: Array[Dictionary] = []
var _cursor := 0
var _time := 0.0
var _speed := 1.0
var _paused := false
var _done := false
var _log: Array[String] = []
var _flashes: Array[Dictionary] = []
var _floats: Array[Dictionary] = []
var _bound_row := -1
var _bound_until := 0.0
var _end_panel: Control


func _ready() -> void:
	sim = Game.battle
	_font = get_theme_default_font()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	for u in sim.units:
		var init: Dictionary = sim.initial[u.index]
		_state.append({"hp": init["hp"], "max": init["hp"], "atk": init["atk"], "shield": 0, "skip": 0, "alive": true})
	var x := 1280.0
	for s in [1.0, 2.0, 4.0]:
		_button("%d×" % s, Rect2(x, 960, 110, 80), _set_speed.bind(s))
		x += 120
	_button(tr("BATTLE_PAUSE"), Rect2(x, 960, 140, 80), func() -> void: _paused = not _paused)
	_button(tr("BATTLE_SKIP"), Rect2(x + 150, 960, 150, 80), _skip)


func _button(text: String, rect: Rect2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.position = rect.position
	b.size = rect.size
	b.add_theme_font_size_override(&"font_size", 24)
	b.pressed.connect(cb)
	add_child(b)
	return b


func _set_speed(s: float) -> void:
	_speed = s
	_paused = false


func _skip() -> void:
	_time = 1e9


func _process(delta: float) -> void:
	if not _paused and not _done:
		_time += delta * _speed
		while _cursor < sim.events.size() and sim.events[_cursor]["t"] <= _time:
			_apply(sim.events[_cursor])
			_cursor += 1
		if _cursor >= sim.events.size():
			_finish()
	queue_redraw()


func _name(i: int) -> String:
	return Ink.name_of(sim.units[i].kind)


func _apply(e: Dictionary) -> void:
	var src: int = e["src"]
	var dst: int = e["dst"]
	var v: int = e["value"]
	match e["kind"]:
		&"attack":
			_flashes.append({"from": src, "to": dst, "t0": _time, "ally": sim.units[src].ally})
		&"hp":
			var dmg: int = _state[dst]["hp"] - v
			_state[dst]["hp"] = v
			_float(dst, "-%d" % dmg, Ink.VERMILION)
			if src >= 0:
				_log_line(tr("LOG_HIT") % [_name(src), _name(dst), dmg])
		&"die":
			_state[dst]["alive"] = false
			_log_line(tr("LOG_DIE") % _name(dst))
		&"shield":
			_state[dst]["shield"] += 1
			_log_line(tr("LOG_SHIELD") % [_name(src), _name(dst)])
		&"blocked":
			_state[dst]["shield"] -= 1
			_float(dst, tr("FLOAT_BLOCK"), Ink.JADE)
		&"bind", &"charm":
			_state[dst]["skip"] += 1
			_log_line(tr("LOG_" + String(e["kind"]).to_upper()) % [_name(src), _name(dst)])
		&"skip":
			_state[src]["skip"] = maxi(_state[src]["skip"] - 1, 0)
			_float(src, tr("FLOAT_SKIP"), Ink.SLATE)
		&"coin":
			_float(src, tr("FLOAT_COIN"), Ink.GOLD)
			_log_line(tr("LOG_COIN") % _name(src))
		&"atk":
			_state[dst]["atk"] = v
			_float(dst, tr("FLOAT_ATK") % v, Ink.VERMILION)
			if src != dst:
				_log_line(tr("LOG_RAGE") % [_name(src), _name(dst)])
		&"devour":
			_state[src]["hp"] = v
			_state[src]["max"] = maxi(_state[src]["max"], v)
			_log_line(tr("LOG_DEVOUR") % [_name(src), _name(dst)])
		&"hungry":
			_log_line(tr("LOG_HUNGRY"))
		&"reap":
			_flashes.append({"from": src, "to": dst, "t0": _time, "ally": false})
			_state[dst]["hp"] = 0
			_log_line(tr("LOG_REAP") % [_name(src), _name(dst)])
		&"bind_row":
			_bound_row = v
			_bound_until = _time + 1.5
			for i in sim.units.size():
				if sim.units[i].ally and _state[i]["alive"] and v in sim.units[i].rows:
					_state[i]["skip"] += 1
			_log_line(tr("LOG_BIND_ROW") % [_name(src), v + 1])
		&"dawn":
			_log_line(tr("LOG_DAWN"))


func _log_line(s: String) -> void:
	_log.append(s)
	if _log.size() > 200:
		_log.pop_front()


func _float(i: int, text: String, color: Color) -> void:
	_floats.append({"pos": _center(i), "text": text, "color": color, "t0": _time})


func _center(i: int) -> Vector2:
	var u: BattleSim.Unit = sim.units[i]
	if u.ally:
		return BAG_POS + Ink.centroid(u.cells) * CELL
	var idx := 0
	for o in sim.units:
		if o == u:
			break
		if not o.ally and o.lane == u.lane and _state[o.index]["alive"]:
			idx += 1
	return Vector2(ENEMY_X0 + idx * ENEMY_GAP + 50, BAG_POS.y + (u.lane + 0.5) * CELL)


func _finish() -> void:
	_done = true
	var panel := PanelContainer.new()
	panel.position = Vector2(560, 300)
	panel.custom_minimum_size = Vector2(800, 360)
	add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override(&"separation", 24)
	panel.add_child(box)
	var title := Label.new()
	title.text = tr("BATTLE_WON") if sim.won else (tr("BATTLE_LOST_BOSS") if Game.run.is_boss_night() else tr("BATTLE_LOST"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 48)
	title.add_theme_color_override(&"font_color", Ink.GOLD if sim.won else Ink.VERMILION)
	box.add_child(title)
	if sim.coins > 0:
		var coins := Label.new()
		coins.text = tr("BATTLE_COINS") % sim.coins
		coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coins.add_theme_font_size_override(&"font_size", 28)
		box.add_child(coins)
	var next := Button.new()
	next.text = tr("BATTLE_NEXT")
	next.custom_minimum_size = Vector2(360, 80)
	next.add_theme_font_size_override(&"font_size", 30)
	next.pressed.connect(_on_next)
	box.add_child(next)
	next.grab_focus()
	_end_panel = panel


func _on_next() -> void:
	Game.run.finish_battle(sim)
	Game.goto(&"result" if Game.run.is_over() else &"night")


func _draw() -> void:
	var limit := sim.procession.time_limit
	var shown := minf(_time, sim.t)
	var title := tr("NIGHT_LABEL") % [Game.run.night, RunState.NIGHTS]
	draw_string(_font, Vector2(80, 70), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 36, Ink.CREAM)
	draw_string(_font, Vector2(400, 70), tr("RULE_" + String(sim.procession.rule).to_upper()), HORIZONTAL_ALIGNMENT_LEFT, 1400, 20, Ink.GOLD)
	draw_rect(BAR, Ink.NIGHT_DEEP)
	draw_rect(Rect2(BAR.position, Vector2(BAR.size.x * clampf(shown / limit, 0, 1), BAR.size.y)), Color(Ink.GOLD, 0.7))
	draw_circle(BAR.position + Vector2(-30, 9), 22, Ink.CREAM)
	draw_string(_font, BAR.end + Vector2(16, 6), tr("BATTLE_ROOSTER"), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Ink.VERMILION)
	draw_string(_font, BAR.position + Vector2(0, 50), tr("BATTLE_TIME") % maxi(ceili(limit - shown), 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(Ink.CREAM, 0.7))
	var grid := Rect2(BAG_POS, Vector2(sim.bag.width, sim.bag.height) * CELL)
	draw_rect(grid.grow(8), Ink.NIGHT_DEEP)
	for y in sim.bag.height:
		var row_color := Color(Ink.VERMILION, 0.25) if y == _bound_row and _time < _bound_until else Color(Ink.CREAM, 0.05)
		draw_rect(Rect2(BAG_POS.x, BAG_POS.y + y * CELL, 1800, CELL).grow(-3), row_color)
	for u in sim.units:
		var st := _state[u.index]
		if not st["alive"]:
			continue
		if u.ally:
			_draw_ally(u, st)
		else:
			_draw_enemy(u, st)
	for f in _flashes:
		var age: float = _time - f["t0"]
		if age < FLASH_TIME:
			var a := _center(f["from"])
			var b := _center(f["to"])
			draw_line(a, a.lerp(b, minf(age / FLASH_TIME * 2, 1)), Color(Ink.VERMILION if f["ally"] else Ink.INK, 1 - age / FLASH_TIME), 8)
	for f in _floats:
		var age: float = _time - f["t0"]
		if age < 1.0:
			var p: Vector2 = f["pos"] + Vector2(-60, -30 - age * 40)
			draw_string(_font, p, f["text"], HORIZONTAL_ALIGNMENT_CENTER, 120, 28, Color(f["color"], 1 - age))
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return _time - f["t0"] < FLASH_TIME)
	_floats = _floats.filter(func(f: Dictionary) -> bool: return _time - f["t0"] < 1.0)
	draw_rect(LOG_RECT, Color(Ink.NIGHT_DEEP, 0.9))
	var start := maxi(_log.size() - LOG_LINES, 0)
	for i in range(start, _log.size()):
		draw_string(_font, LOG_RECT.position + Vector2(20, 40 + (i - start) * 36), _log[i], HORIZONTAL_ALIGNMENT_LEFT, LOG_RECT.size.x - 40, 22, Color(Ink.CREAM, 0.5 + 0.5 * float(i - start + 1) / LOG_LINES))


func _bar(pos: Vector2, width: float, st: Dictionary) -> void:
	draw_rect(Rect2(pos, Vector2(width, 10)), Ink.INK)
	draw_rect(Rect2(pos, Vector2(width * float(st["hp"]) / maxf(st["max"], 1), 10)), Ink.JADE)


func _draw_ally(u: BattleSim.Unit, st: Dictionary) -> void:
	Ink.draw_shape(self, BAG_POS, u.cells, CELL, Ink.CREAM, Ink.INK)
	Ink.draw_portrait(self, BAG_POS, u.cells, CELL, u.kind)
	var c := BAG_POS + Ink.centroid(u.cells) * CELL
	_bar(c + Vector2(-40, 30), 80, st)
	Ink.draw_badge(self, c + Vector2(-26, -30), st["atk"], Ink.VERMILION, _font, 16)
	Ink.draw_badge(self, c + Vector2(26, -30), st["hp"], Ink.JADE, _font, 16)
	_status(c, st)


func _draw_enemy(u: BattleSim.Unit, st: Dictionary) -> void:
	var c := _center(u.index)
	var big := u.kind == &"reaper" or u.kind == &"leader"
	var side := 120.0 if big else 96.0
	draw_texture_rect(YokaiDb.texture(u.kind), Rect2(c - Vector2(side, side) / 2, Vector2(side, side)), false)
	_bar(c + Vector2(-40, 40), 80, st)
	Ink.draw_badge(self, c + Vector2(-34, -38), st["atk"], Ink.VERMILION, _font, 14)
	draw_string(_font, c + Vector2(-10, -30), str(st["hp"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Ink.CREAM)
	_status(c, st)


func _status(c: Vector2, st: Dictionary) -> void:
	if st["shield"] > 0:
		draw_arc(c, 46, 0, TAU, 32, Color(Ink.JADE, 0.9), 4)
	if st["skip"] > 0:
		draw_line(c + Vector2(-40, 0), c + Vector2(40, 0), Color(Ink.SLATE, 0.9), 6)

extends Control
## 전투 재생 화면. BattleSim이 미리 계산한 이벤트를 시간 순서대로 보여 준다.

const BAG_POS := Vector2(100, 392)
const CELL := 96.0
const ENEMY_X0 := 860.0
const ENEMY_GAP := 130.0
const LOG_RECT := Rect2(80, 830, 1060, 220)
const BAR := Rect2(300, 300, 1360, 6)
const GAUGE_Y := 34.0
const LOG_LINES := 5
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
	var x := 1200.0
	for s in [1.0, 2.0, 4.0]:
		_button("%d×" % s, Rect2(x, 970, 100, 76), _set_speed.bind(s))
		x += 112
	_button(tr("BATTLE_PAUSE"), Rect2(x, 970, 150, 76), func() -> void: _paused = not _paused)
	_button(tr("BATTLE_SKIP"), Rect2(x + 162, 970, 160, 76), _skip)


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
			_log_line(tr("LOG_DEVOUR") % [Ink.with_josa(_name(src), "이가"), Ink.with_josa(_name(dst), "을를")])
		&"hungry":
			_log_line(tr("LOG_HUNGRY"))
		&"reap":
			_flashes.append({"from": src, "to": dst, "t0": _time, "ally": false})
			_state[dst]["hp"] = 0
			_log_line(tr("LOG_REAP") % [Ink.with_josa(_name(src), "이가"), Ink.with_josa(_name(dst), "을를")])
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
	title.theme_type_variation = &"PaperLabel"
	title.text = tr("BATTLE_WON") if sim.won else (tr("BATTLE_LOST_BOSS") if Game.run.is_boss_night() else tr("BATTLE_LOST"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override(&"font_size", 48)
	title.add_theme_color_override(&"font_color", Ink.JADE.darkened(0.3) if sim.won else Ink.VERMILION)
	box.add_child(title)
	if sim.coins > 0:
		var coins := Label.new()
		coins.theme_type_variation = &"PaperLabel"
		coins.text = tr("BATTLE_COINS") % sim.coins
		coins.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		coins.add_theme_font_size_override(&"font_size", 28)
		box.add_child(coins)
	var next := Button.new()
	next.text = tr("BATTLE_NEXT")
	next.custom_minimum_size = Vector2(360, 80)
	next.add_theme_font_size_override(&"font_size", 30)
	next.theme_type_variation = &"AccentButton"
	next.pressed.connect(_on_next)
	box.add_child(next)
	next.grab_focus()
	_end_panel = panel


func _on_next() -> void:
	Game.run.finish_battle(sim)
	Game.goto(&"result" if Game.run.is_over() else &"night")


func _draw() -> void:
	draw_texture_rect(Ink.ui("bg_battle.jpg"), Rect2(Vector2.ZERO, size), false)
	var limit := sim.procession.time_limit
	var shown := minf(_time, sim.t)
	_draw_gauge(clampf(shown / limit, 0, 1), maxi(ceili(limit - shown), 0))
	Ink.draw_label(self, Vector2(70, 300), tr("NIGHT_LABEL") % [Game.run.night, RunState.NIGHTS], 36, Ink.CREAM, -1, HORIZONTAL_ALIGNMENT_LEFT, 8)
	Ink.draw_label(self, Vector2(70, 338), tr("RULE_" + String(sim.procession.rule).to_upper()), 20, Ink.GOLD, 1400, HORIZONTAL_ALIGNMENT_LEFT, 6)
	Ink.draw_bundle(self, BAG_POS, sim.bag.width, sim.bag.height, CELL)
	for y in sim.bag.height:
		var cy := BAG_POS.y + (y + 0.5) * CELL
		var bound := y == _bound_row and _time < _bound_until
		if bound:
			draw_rect(Rect2(BAG_POS.x, BAG_POS.y + y * CELL, sim.bag.width * CELL, CELL).grow(-4), Color(Ink.VERMILION, 0.3))
		draw_dashed_line(Vector2(BAG_POS.x + sim.bag.width * CELL + 30, cy), Vector2(1860, cy), Color(Ink.CREAM, 0.12), 2.0, 14.0)
	for u in sim.units:
		var st := _state[u.index]
		if st["alive"] and not u.ally:
			_draw_enemy(u, st)
	for u in sim.units:
		var st := _state[u.index]
		if st["alive"] and u.ally:
			_draw_ally(u, st)
	for f in _flashes:
		var age: float = _time - f["t0"]
		if age < FLASH_TIME:
			_brush(_center(f["from"]), _center(f["to"]), age / FLASH_TIME, Ink.VERMILION if f["ally"] else Color(0.6, 0.55, 0.85))
	for f in _floats:
		var age: float = _time - f["t0"]
		if age < 1.0:
			var p: Vector2 = f["pos"] + Vector2(-80, -36 - age * 50)
			Ink.draw_label(self, p, f["text"], 36, Color(f["color"], 1 - age * age), 160, HORIZONTAL_ALIGNMENT_CENTER, 8)
	_flashes = _flashes.filter(func(f: Dictionary) -> bool: return _time - f["t0"] < FLASH_TIME)
	_floats = _floats.filter(func(f: Dictionary) -> bool: return _time - f["t0"] < 1.0)
	Ink.draw_panel(self, LOG_RECT)
	var start := maxi(_log.size() - LOG_LINES, 0)
	for i in range(start, _log.size()):
		draw_string(_font, LOG_RECT.position + Vector2(24, 44 + (i - start) * 38), _log[i], HORIZONTAL_ALIGNMENT_LEFT, LOG_RECT.size.x - 48, 21, Color(Ink.CREAM, 0.45 + 0.55 * float(i - start + 1) / LOG_LINES))


## 달에서 닭까지 이어지는 시간 줄. 달이 줄을 따라 닭 쪽으로 간다.
func _draw_gauge(ratio: float, seconds: int) -> void:
	var a := Vector2(BAR.position.x, GAUGE_Y)
	var b := Vector2(BAR.end.x, GAUGE_Y)
	draw_line(a, b, Color(Ink.CREAM, 0.35), 4)
	draw_line(a, a.lerp(b, ratio), Ink.GOLD, 6)
	for i in range(1, 5):
		draw_circle(a.lerp(b, i / 5.0), 7, Ink.CREAM if ratio >= i / 5.0 else Color(Ink.CREAM, 0.4))
	var moon := Ink.ui("crescent.png")
	draw_texture_rect(moon, Rect2(a.lerp(b, ratio) - Vector2(26, 26), Vector2(52, 52)), false)
	draw_texture_rect(Ink.ui("rooster.png"), Rect2(b + Vector2(16, -24), Vector2(96, 86)), false)
	Ink.draw_label(self, b + Vector2(-300, 44), tr("BATTLE_TIME") % seconds, 22, Ink.CREAM, 300, HORIZONTAL_ALIGNMENT_RIGHT, 6)


## 붓으로 긋는 듯한 공격 자국.
func _brush(from: Vector2, to: Vector2, t: float, color: Color) -> void:
	var head := from.lerp(to, minf(t * 2.0, 1.0))
	var tail := from.lerp(to, clampf(t * 2.0 - 0.7, 0.0, 1.0))
	var d := (head - tail)
	if d.length() < 2:
		return
	var n := Vector2(-d.y, d.x).normalized()
	var bend := n * d.length() * 0.12
	var pts := PackedVector2Array()
	var back := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		var p := tail.lerp(head, k) + bend * sin(k * PI)
		var w := 14.0 * sin(k * PI * 0.9 + 0.1) * (1.0 - t * 0.5)
		pts.append(p + n * w)
		back.append(p - n * w * 0.5)
	back.reverse()
	pts.append_array(back)
	draw_colored_polygon(pts, Color(color, 1.0 - t * t))


func _bar(pos: Vector2, width: float, st: Dictionary) -> void:
	draw_style_box(Ink.box(Color(Ink.INK, 0.85), 4), Rect2(pos, Vector2(width, 10)))
	var ratio := float(st["hp"]) / maxf(st["max"], 1)
	if ratio > 0:
		draw_style_box(Ink.box(Ink.JADE if ratio > 0.35 else Ink.VERMILION, 4), Rect2(pos, Vector2(width * ratio, 10)))


func _draw_ally(u: BattleSim.Unit, st: Dictionary) -> void:
	Ink.draw_paper_shape(self, BAG_POS, u.cells, CELL)
	Ink.draw_portrait(self, BAG_POS, u.cells, CELL, u.kind)
	var c := BAG_POS + Ink.centroid(u.cells) * CELL
	_bar(c + Vector2(-38, 30), 76, st)
	Ink.draw_badge(self, c + Vector2(-24, -30), st["atk"], Ink.VERMILION, null, 15)
	Ink.draw_badge(self, c + Vector2(24, -30), st["hp"], Ink.JADE, null, 15)
	_status(c, st)


func _draw_enemy(u: BattleSim.Unit, st: Dictionary) -> void:
	var c := _center(u.index)
	var big := u.kind == &"reaper" or u.kind == &"leader"
	var side := 170.0 if big else 136.0
	draw_set_transform(c + Vector2(0, side * 0.42), 0, Vector2(1, 0.28))
	draw_circle(Vector2.ZERO, side * 0.4, Color(Ink.NIGHT_DEEP, 0.55))
	draw_set_transform(Vector2.ZERO)
	draw_circle(c, side * 0.42, Color(Ink.CREAM, 0.07))
	draw_texture_rect(YokaiDb.texture(u.kind), Rect2(c - Vector2(side, side) * Vector2(0.5, 0.58), Vector2(side, side)), false)
	_bar(c + Vector2(-38, side * 0.42 + 4), 76, st)
	Ink.draw_badge(self, c + Vector2(-side * 0.38, -side * 0.42), st["atk"], Ink.VERMILION, null, 14)
	Ink.draw_label(self, c + Vector2(-side * 0.38 + 16, -side * 0.42 + 8), str(st["hp"]), 20, Ink.CREAM, -1, HORIZONTAL_ALIGNMENT_LEFT, 6)
	_status(c, st)


func _status(c: Vector2, st: Dictionary) -> void:
	if st["shield"] > 0:
		draw_arc(c, 50, 0, TAU, 40, Color(Ink.JADE, 0.95), 5)
	if st["skip"] > 0:
		draw_arc(c, 44, -PI * 0.9, -PI * 0.1, 16, Color(Ink.SLATE, 0.95), 6)

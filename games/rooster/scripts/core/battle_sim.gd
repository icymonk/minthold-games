class_name BattleSim
extends RefCounted
## 자동 전투를 끝까지 계산해 이벤트 목록을 만든다. 화면은 이 목록을 재생만 한다.

const DT := 0.1
const REAPER_PERIOD := 10.0
const LEADER_PERIOD := 15.0
const CHARM_CHANCE := 0.3


class Unit:
	var index: int
	var ally: bool
	var kind: StringName
	var piece_id := -1
	var cells: Array[Vector2i] = []
	var rows: Array[int] = []
	var lane := -1
	var atk: int
	var hp: int
	var max_hp: int
	var interval: float
	var gauge := 0.0
	var traits: Array[StringName] = []
	var shield := 0
	var skip := 0
	var actions := 0
	var alive := true

	func has_trait(tr_id: StringName) -> bool:
		return tr_id in traits

	func front_x(row: int) -> int:
		var best := -1
		for c in cells:
			if c.y == row:
				best = maxi(best, c.x)
		return best


var units: Array[Unit] = []
var events: Array[Dictionary] = []
var bag: Bag
var procession: Procession
var rng: RandomNumberGenerator
var t := 0.0
var coins := 0
var won := false
var initial: Array[Dictionary] = []
var _enemy_lanes: Array = []


func _init(the_bag: Bag, the_procession: Procession, the_rng: RandomNumberGenerator) -> void:
	bag = the_bag
	procession = the_procession
	rng = the_rng
	for p in bag.pieces:
		var u := _add(true, p.kind, p.atk, p.hp, p.interval)
		u.piece_id = p.id
		u.cells = p.world_cells()
		u.traits = p.traits.duplicate()
		for c in u.cells:
			if c.y not in u.rows:
				u.rows.append(c.y)
	for lane in procession.lanes.size():
		var queue: Array[Unit] = []
		for kind in procession.lanes[lane]:
			var def: Dictionary = YokaiDb.ENEMIES[kind]
			var hp := ceili(def["hp"] * procession.hp_scale)
			var u := _add(false, kind, def["atk"] + procession.atk_bonus, hp, def["interval"])
			u.lane = lane
			queue.append(u)
		_enemy_lanes.append(queue)


func _add(ally: bool, kind: StringName, atk: int, hp: int, interval: float) -> Unit:
	var u := Unit.new()
	u.index = units.size()
	u.ally = ally
	u.kind = kind
	u.atk = atk
	u.hp = hp
	u.max_hp = hp
	u.interval = interval
	units.append(u)
	return u


func run() -> BattleSim:
	for u in units:
		initial.append({"hp": u.hp, "atk": u.atk})
	_battle_start()
	var next_rule := REAPER_PERIOD if procession.rule == &"reaper" else LEADER_PERIOD
	while t < procession.time_limit and not _side_dead(true) and not _side_dead(false):
		t = snappedf(t + DT, 0.001)
		for u in _acting_order():
			if not u.alive:
				continue
			u.gauge += DT
			if u.gauge + 0.0001 >= u.interval:
				u.gauge -= u.interval
				_act(u)
		if t + 0.0001 >= next_rule:
			_apply_rule()
			next_rule += REAPER_PERIOD if procession.rule == &"reaper" else LEADER_PERIOD
	if _side_dead(false) and not _side_dead(true):
		won = true
	elif _side_dead(true):
		won = false
	else:
		won = _hp_sum(true) > _hp_sum(false)
		_emit(&"dawn", -1, -1, 0)
	_emit(&"end", -1, -1, 1 if won else 0)
	return self


func _battle_start() -> void:
	for u in _alive(true):
		if u.has_trait(&"guard"):
			for o in _touching(u):
				o.shield += 1
				_emit(&"shield", u.index, o.index, 1)
		if u.has_trait(&"bind"):
			for row in u.rows:
				var e := _front_enemy(row)
				if e != null:
					e.skip += 1
					_emit(&"bind", u.index, e.index, 1)


func _acting_order() -> Array[Unit]:
	var order: Array[Unit] = []
	for u in units:
		if u.alive and (u.ally or _front_enemy(u.lane) == u):
			order.append(u)
	return order


func _act(u: Unit) -> void:
	if u.skip > 0:
		u.skip -= 1
		_emit(&"skip", u.index, -1, 0)
		return
	u.actions += 1
	var target := _pick_target(u)
	if target == null:
		return
	_emit(&"attack", u.index, target.index, u.atk)
	_damage(u, target, u.atk)
	if u.has_trait(&"charm") and target.alive and rng.randf() < CHARM_CHANCE:
		target.skip += 1
		_emit(&"charm", u.index, target.index, 1)
	if u.has_trait(&"coin") and u.actions % 3 == 0:
		coins += 1
		_emit(&"coin", u.index, -1, 1)


func _pick_target(u: Unit) -> Unit:
	if u.ally:
		for dist in bag.height:
			for row in u.rows:
				for r in [row - dist, row + dist]:
					var e := _front_enemy(r)
					if e != null:
						return e
		return null
	for dist in bag.height:
		var best: Unit = null
		var best_x := -1
		for r in [u.lane - dist, u.lane + dist]:
			for a in _alive(true):
				var x := a.front_x(r)
				if x > best_x:
					best_x = x
					best = a
		if best != null:
			return best
	return null


func _damage(src: Unit, dst: Unit, amount: int) -> void:
	if dst.shield > 0:
		dst.shield -= 1
		_emit(&"blocked", src.index if src else -1, dst.index, 0)
		return
	dst.hp = maxi(dst.hp - amount, 0)
	_emit(&"hp", src.index if src else -1, dst.index, dst.hp)
	if dst.hp == 0:
		_die(dst)


func _die(u: Unit) -> void:
	u.alive = false
	_emit(&"die", -1, u.index, 0)
	if not u.ally:
		return
	var weak := procession.rule == &"plague"
	var neighbors := _touching(u)
	if u.has_trait(&"rage"):
		var bonus := 1 if weak else 2
		for o in neighbors:
			o.atk += bonus
			_emit(&"atk", u.index, o.index, o.atk)
	for o in neighbors:
		if o.has_trait(&"devour"):
			var div := 4.0 if weak else 2.0
			o.atk += ceili(u.atk / div)
			o.max_hp += ceili(u.max_hp / div)
			o.hp += ceili(u.max_hp / div)
			_emit(&"devour", o.index, u.index, o.hp)
			_emit(&"atk", o.index, o.index, o.atk)
	if procession.rule == &"hungry":
		for e in _alive(false):
			e.atk += 1
		_emit(&"hungry", -1, u.index, 1)


func _apply_rule() -> void:
	if procession.rule == &"reaper":
		var reaper := _find_enemy(&"reaper")
		var victims := _alive(true)
		if reaper == null or victims.is_empty():
			return
		victims.sort_custom(func(a: Unit, b: Unit) -> bool: return a.hp < b.hp or (a.hp == b.hp and a.index < b.index))
		var v: Unit = victims[0]
		v.hp = 0
		_emit(&"reap", reaper.index, v.index, 0)
		_die(v)
	elif procession.rule == &"leader":
		var leader := _find_enemy(&"leader")
		if leader == null:
			return
		var row := rng.randi_range(0, bag.height - 1)
		_emit(&"bind_row", leader.index, -1, row)
		for a in _alive(true):
			if row in a.rows:
				a.skip += 1


func _find_enemy(kind: StringName) -> Unit:
	for u in _alive(false):
		if u.kind == kind:
			return u
	return null


func _front_enemy(lane: int) -> Unit:
	if lane < 0 or lane >= _enemy_lanes.size():
		return null
	for e in _enemy_lanes[lane]:
		if e.alive:
			return e
	return null


func _touching(u: Unit) -> Array[Unit]:
	var out: Array[Unit] = []
	for o in _alive(true):
		if o == u:
			continue
		for c in u.cells:
			if c + Vector2i.LEFT in o.cells or c + Vector2i.RIGHT in o.cells or c + Vector2i.UP in o.cells or c + Vector2i.DOWN in o.cells:
				out.append(o)
				break
	return out


func _alive(ally: bool) -> Array[Unit]:
	var out: Array[Unit] = []
	for u in units:
		if u.alive and u.ally == ally:
			out.append(u)
	return out


func _side_dead(ally: bool) -> bool:
	return _alive(ally).is_empty()


func _hp_sum(ally: bool) -> int:
	var s := 0
	for u in _alive(ally):
		s += u.hp
	return s


func _emit(kind: StringName, src: int, dst: int, value: int) -> void:
	events.append({"t": t, "kind": kind, "src": src, "dst": dst, "value": value})

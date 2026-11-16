class_name BattleSim
extends RefCounted
## 자동 전투를 끝까지 계산해 이벤트 목록을 만든다. 화면은 이 목록을 재생만 한다.

const DT := 0.1
const REAPER_PERIOD := 10.0
const LEADER_PERIOD := 15.0
const CHARM_CHANCE := 0.3
const BURN_STACKS := 2
const DROUGHT_DAMAGE := 2
const SPRING_HEAL := 2
const TIDE_HEAL := 2
const TIDE_EVERY := 4
const CURSE_ATK := 2
const HOARD_COINS := 2
const METAL_COINS := 2


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
	var family: StringName
	var shield := 0
	var burn := 0
	var used_undying := false
	var used_rebirth := false
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
var levels := {}
var _enemy_lanes: Array = []
var _grudge_revive := false


func _init(the_bag: Bag, the_procession: Procession, the_rng: RandomNumberGenerator) -> void:
	bag = the_bag
	procession = the_procession
	rng = the_rng
	levels = Synergy.levels(bag)
	_grudge_revive = levels[&"grudge"] >= 2
	var bonus := Synergy.bonuses(bag)
	for p in bag.pieces:
		var b: Dictionary = bonus[p.id]
		var u := _add(true, p.kind, maxi(p.atk + b["atk"], 1), p.hp + b["hp"], p.interval * b["interval"])
		u.family = p.family()
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
	_battle_end()
	_emit(&"end", -1, -1, 1 if won else 0)
	return self


func _battle_start() -> void:
	for u in _alive(true):
		if u.has_trait(&"mimic"):
			_mimic(u)
	for u in _alive(true):
		var divine: bool = levels[&"divine"] >= 2 or (levels[&"divine"] >= 1 and u.family == &"divine")
		if divine:
			u.shield += 1
			_emit(&"shield", u.index, u.index, 1)
	for u in _alive(true):
		if u.has_trait(&"guard"):
			for o in _touching(u):
				o.shield += 1
				_emit(&"shield", u.index, o.index, 1)
		if u.has_trait(&"ward"):
			for o in _alive(true):
				if o != u and _shares_row(u, o):
					o.shield += 1
					_emit(&"shield", u.index, o.index, 1)
		if u.has_trait(&"hearth"):
			for o in _touching(u):
				o.atk += 2 if o.family == &"fire" else 1
				_emit(&"atk", u.index, o.index, o.atk)
		if u.has_trait(&"bind"):
			for row in u.rows:
				var e := _front_enemy(row)
				if e != null:
					e.skip += 1
					_emit(&"bind", u.index, e.index, 1)
		if u.has_trait(&"dread"):
			for row in u.rows:
				for e in _lane_enemies(row):
					if e.atk > 1:
						e.atk -= 1
						_emit(&"atk", u.index, e.index, e.atk)
		if u.has_trait(&"drought"):
			for row in u.rows:
				var e := _front_enemy(row)
				if e != null:
					_emit(&"attack", u.index, e.index, DROUGHT_DAMAGE)
					_damage(u, e, DROUGHT_DAMAGE)


## 맞닿은 아군 중 공격이 가장 높은 요괴의 첫 능력을 이번 전투 동안 흉내 낸다.
func _mimic(u: Unit) -> void:
	var best: Unit = null
	for o in _touching(u):
		if o.traits.is_empty() or o.traits[0] == &"mimic":
			continue
		if best == null or o.atk > best.atk:
			best = o
	if best == null or u.has_trait(best.traits[0]):
		return
	u.traits.append(best.traits[0])
	_emit(&"mimic", u.index, best.index, 0)


func _battle_end() -> void:
	var metal: Unit = null
	for u in units:
		if not u.ally:
			continue
		if u.family == &"metal" and metal == null:
			metal = u
		if u.alive and u.has_trait(&"hoard"):
			coins += HOARD_COINS
			_emit(&"coin", u.index, -1, HOARD_COINS)
	if metal != null and levels[&"metal"] >= 2:
		coins += METAL_COINS
		_emit(&"coin", metal.index, -1, METAL_COINS)


func _acting_order() -> Array[Unit]:
	var order: Array[Unit] = []
	for u in units:
		if u.alive and (u.ally or _front_enemy(u.lane) == u):
			order.append(u)
	return order


func _act(u: Unit) -> void:
	if u.burn > 0:
		u.burn -= 1
		_emit(&"burn_tick", -1, u.index, 1)
		_damage(null, u, 1)
		if not u.alive:
			return
	if u.skip > 0:
		u.skip -= 1
		_emit(&"skip", u.index, -1, 0)
		return
	u.actions += 1
	var target := _pick_target(u)
	if target == null:
		return
	var targets: Array[Unit] = [target]
	if u.has_trait(&"triple"):
		for lane in [target.lane - 1, target.lane + 1]:
			var e := _front_enemy(lane)
			if e != null:
				targets.append(e)
	for tgt in targets:
		_strike(u, tgt)
	if u.has_trait(&"cleave"):
		var behind := _behind(target) if target.alive else _front_enemy(target.lane)
		if behind != null:
			_emit(&"attack", u.index, behind.index, ceili(u.atk / 2.0))
			_damage(u, behind, ceili(u.atk / 2.0))
	if u.has_trait(&"coin") and u.actions % 3 == 0:
		coins += 1
		_emit(&"coin", u.index, -1, 1)
	if u.has_trait(&"grow"):
		u.atk += 1
		_emit(&"atk", u.index, u.index, u.atk)
	if u.has_trait(&"spring"):
		var hurt := _most_hurt(_touching(u))
		if hurt != null:
			_heal(u, hurt, SPRING_HEAL)
	if u.has_trait(&"tide") and u.actions % TIDE_EVERY == 0:
		for o in _alive(true):
			_heal(u, o, TIDE_HEAL)
	if u.ally and u.family == &"water" and levels[&"water"] >= 2:
		var hurt := _most_hurt(_alive(true))
		if hurt != null:
			_heal(u, hurt, 1)


## 한 대상을 한 번 치고, 치는 순간 붙는 능력을 적용한다.
func _strike(u: Unit, target: Unit) -> void:
	_emit(&"attack", u.index, target.index, u.atk)
	var killed := _damage(u, target, u.atk)
	if killed or not target.alive:
		return
	var burn := 0
	if u.has_trait(&"burn"):
		burn += BURN_STACKS
	if u.ally and u.family == &"fire" and levels[&"fire"] >= 2:
		burn += 1
	if burn > 0:
		target.burn += burn
		_emit(&"burn", u.index, target.index, target.burn)
	if u.has_trait(&"charm") and rng.randf() < CHARM_CHANCE:
		target.skip += 1
		_emit(&"charm", u.index, target.index, 1)


func _heal(src: Unit, dst: Unit, amount: int) -> void:
	var healed := mini(amount, dst.max_hp - dst.hp)
	if healed <= 0:
		return
	dst.hp += healed
	_emit(&"heal", src.index, dst.index, dst.hp)


func _most_hurt(pool: Array[Unit]) -> Unit:
	var best: Unit = null
	for o in pool:
		if o.hp < o.max_hp and (best == null or o.max_hp - o.hp > best.max_hp - best.hp):
			best = o
	return best


func _pick_target(u: Unit) -> Unit:
	if u.ally and u.has_trait(&"hunt"):
		var prey: Unit = null
		for lane in _enemy_lanes.size():
			var e := _front_enemy(lane)
			if e != null and (prey == null or e.hp < prey.hp):
				prey = e
		return prey
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


## 피해를 주고, 대상이 쓰러졌으면 true.
func _damage(src: Unit, dst: Unit, amount: int) -> bool:
	if dst.shield > 0:
		dst.shield -= 1
		_emit(&"blocked", src.index if src else -1, dst.index, 0)
		return false
	dst.hp = maxi(dst.hp - amount, 0)
	_emit(&"hp", src.index if src else -1, dst.index, dst.hp)
	if dst.hp > 0:
		return false
	if dst.ally and _revive(dst):
		return false
	_die(dst, src)
	if src != null and src.alive and src.has_trait(&"steal"):
		src.atk += ceili(dst.atk / 2.0)
		_emit(&"steal", src.index, dst.index, src.atk)
		_emit(&"atk", src.index, src.index, src.atk)
	return true


## 쓰러지려는 아군을 되살릴 수 있으면 되살린다. 저승사자에게 데려가진 요괴는 되살아나지 않는다.
func _revive(u: Unit) -> bool:
	if u.has_trait(&"undying") and not u.used_undying:
		u.used_undying = true
		u.hp = 1
		_emit(&"revive", u.index, u.index, u.hp)
		return true
	for o in _alive(true):
		if o != u and o.has_trait(&"rebirth") and not o.used_rebirth:
			o.used_rebirth = true
			u.hp = ceili(u.max_hp / 2.0)
			_emit(&"revive", o.index, u.index, u.hp)
			return true
	if u.family == &"grudge" and _grudge_revive:
		_grudge_revive = false
		u.hp = ceili(u.max_hp / 2.0)
		_emit(&"revive", u.index, u.index, u.hp)
		return true
	return false


func _die(u: Unit, killer: Unit = null) -> void:
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
	if u.family == &"grudge" and levels[&"grudge"] >= 1:
		for o in neighbors:
			o.atk += 1
			_emit(&"atk", u.index, o.index, o.atk)
	if u.has_trait(&"curse") and killer != null and killer.alive and killer.atk > 1:
		killer.atk = maxi(killer.atk - CURSE_ATK, 1)
		_emit(&"curse", u.index, killer.index, killer.atk)
		_emit(&"atk", u.index, killer.index, killer.atk)
	if u.has_trait(&"sorrow"):
		for row in u.rows:
			var e := _front_enemy(row)
			if e != null:
				e.skip += 1
				_emit(&"bind", u.index, e.index, 1)
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


func _lane_enemies(lane: int) -> Array[Unit]:
	var out: Array[Unit] = []
	if lane < 0 or lane >= _enemy_lanes.size():
		return out
	for e in _enemy_lanes[lane]:
		if e.alive:
			out.append(e)
	return out


func _behind(e: Unit) -> Unit:
	var queue := _lane_enemies(e.lane)
	var i := queue.find(e)
	return queue[i + 1] if i >= 0 and i + 1 < queue.size() else null


func _shares_row(a: Unit, b: Unit) -> bool:
	for r in a.rows:
		if r in b.rows:
			return true
	return false


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

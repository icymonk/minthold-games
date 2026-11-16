class_name StaffBot
extends Bot
## AI 사원. 많이 나아가되 살아 있는 카드를 뛰기로 버리는 건 아끼고, 팀장이 방금 틀린 번호를 좋아한다.
## 뛰기는 이미 지나간(더는 낼 수 없는) 카드부터 쓰고, 가끔 그런 카드를 필요 없이 더 깔아 허세를 부린다.

const PASS_SCORE := 0.3
const STEP_GAIN := 0.08
const LIVE_SPRINT_COST := 0.25
const DEAD_SPRINT_COST := 0.03
const MISSED_BONUS := 0.3
const BLUFF := { Bot.Persona.CAREFUL: 0.2, Bot.Persona.REACTIVE: 0.3, Bot.Persona.WILD: 0.5 }
const DRAW_WINDOW := 5

const A := Match.Action


func _init(r: RandomNumberGenerator, p: Bot.Persona = Bot.Persona.CAREFUL, l: Bot.Level = Bot.Level.HARD) -> void:
	super(Match.Side.STAFF, r, p, l)


func choose(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	if moves[0].action == A.DRAW:
		return _draw(k, moves)
	var last := _last(k)
	var missed := _recent_misses(k)
	var best: Dictionary = moves[0]
	var best_s := -INF
	for mv in moves:
		var cand := mv
		var s: float = PASS_SCORE
		if mv.action == A.PLACE:
			var spr: Variant = sprints_for(k, mv.card)
			if spr == null:
				continue
			cand = { side = side, action = A.PLACE, card = mv.card, sprints = spr }
			s = _place_score(mv.card, spr, last, missed)
		s += _noise()
		if s > best_s:
			best_s = s
			best = cand
	if best.action == A.PLACE and best.card != Cards.LAST and rng.randf() < BLUFF[persona]:
		_add_bluff(k, best, last)
	return best


## card를 낼 뛰기 묶음. 지나간 카드부터, 뛰기 값이 큰 것부터. 못 내면 null.
func sprints_for(k: Knowledge, card: int) -> Variant:
	var last := _last(k)
	var need := card - (last + Cards.BASE_STEP)
	var out: Array[int] = []
	if need <= 0:
		return out
	var pool: Array[int] = []
	for c in k.hand:
		if c != card and Cards.sprint_of(c) > 0:
			pool.append(c)
	pool.sort_custom(func(a: int, b: int) -> bool:
		var da := a <= last
		var db := b <= last
		if da != db:
			return da
		return Cards.sprint_of(a) > Cards.sprint_of(b) or (Cards.sprint_of(a) == Cards.sprint_of(b) and a < b))
	for c in pool:
		if need <= 0:
			break
		out.append(c)
		need -= Cards.sprint_of(c)
	return out if need <= 0 else null


func _place_score(card: int, spr: Array, last: int, missed: Array[int]) -> float:
	if card == Cards.LAST:
		return 100.0
	var s := 0.5 + STEP_GAIN * (card - last)
	for c in spr:
		s -= DEAD_SPRINT_COST if c <= last else LIVE_SPRINT_COST
	if card in missed:
		s += MISSED_BONUS
	return s


func _add_bluff(k: Knowledge, mv: Dictionary, last: int) -> void:
	for c in k.hand:
		if c <= last and c != mv.card and Cards.sprint_of(c) > 0 and not c in mv.sprints:
			mv.sprints.append(c)
			return


func _draw(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	var last := _last(k)
	var best: Dictionary = moves[0]
	var best_s := -INF
	for mv in moves:
		var r: Vector2i = Cards.ZONE_RANGES[mv.zone]
		var hits := 0
		for c in range(last + 1, last + 1 + DRAW_WINDOW):
			if c >= r.x and c <= r.y and not c in k.hand:
				hits += 1
		var s: float = float(hits) / DRAW_WINDOW - 0.01 * absi(r.x - last) / Cards.LAST + _noise()
		if s > best_s:
			best_s = s
			best = mv
	return best


func _last(k: Knowledge) -> int:
	return k.hideouts[-1].card


## 마지막 틀린 짚기 번호들(사원 쪽에서 아직 앞에 있는 것만).
func _recent_misses(k: Knowledge) -> Array[int]:
	var out: Array[int] = []
	if not k.misses.is_empty():
		for n in k.misses[-1].numbers:
			if n > _last(k):
				out.append(n)
	return out

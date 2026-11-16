class_name Match
extends RefCounted
## 한 판의 규칙(기획서 3장). 씬 트리에 의존하지 않는다.
## 사원이 42를 냈을 때 조건이 맞으면 마지막 추궁은 자동으로 시작한다(팀장에게 손해가 없으므로).

signal moved(move: Dictionary)

enum Side { STAFF, CHIEF }
enum Action { DRAW, PLACE, PASS, GUESS }
enum Phase { DRAW, ACT, MANHUNT, OVER }

const NONE := -1

var decks: Array = []                 # zone → Array[int], 맨 뒤가 맨 위
var hands: Array = []                 # side → Array[int]
## 구역마다 사원이 처음 받은 장수(규칙상 공개 정보).
var start_counts: Array[int] = []
## 가운데 줄. 0번은 시작 기록(17:18, 앞면). { card, sprints: Array[int], revealed }
var hideouts: Array[Dictionary] = []
var side := Side.STAFF
var phase := Phase.ACT
var draws_left := 0
var turns: Array[int] = [0, 0]        # side → 시작한 차례 수
var placed_this_turn := 0
var winner := NONE
## 마지막 추궁까지 갔는지.
var manhunted := false
var history: Array[Dictionary] = []
## 사건 카드(선택 규칙). limits = 쪽마다 이번 차례에 걸린 효과, pending = 그 쪽 다음 차례에 걸 효과.
## 키: no_place, one_guess, no_draw, corridor(bool), bonus, extra_draws(int)
var events_on := false
var limits: Array[Dictionary] = [{}, {}]
var pending: Array[Dictionary] = [{}, {}]
var event_rng := RandomNumberGenerator.new()


## 구역 더미를 섞고 사원 처음 손패(1, 2, 3, 42 + Cards.START_DRAWS)를 준다.
## events면 손패를 준 뒤 사건 카드 10종 중 6장을 더미마다 2장씩 섞어 넣는다.
static func deal(deal_rng: RandomNumberGenerator, events := false) -> Match:
	var by_zone: Array = []
	for z in Cards.ZONE_RANGES:
		var deck := Cards.zone_cards(z)
		for i in range(deck.size() - 1, 0, -1):
			var j := deal_rng.randi_range(0, i)
			var t := deck[i]
			deck[i] = deck[j]
			deck[j] = t
		by_zone.append(deck)
	var hand: Array[int] = Cards.START_HAND.duplicate()
	for z in Cards.START_DRAWS:
		for i in Cards.START_DRAWS[z]:
			hand.append(by_zone[z].pop_back())
	if not events:
		return setup(hand, by_zone)
	var ids: Array = Events.Id.values()
	for i in range(ids.size() - 1, 0, -1):
		var j := deal_rng.randi_range(0, i)
		var t: int = ids[i]
		ids[i] = ids[j]
		ids[j] = t
	for deck in by_zone:
		for k in Events.PER_ZONE:
			deck.insert(deal_rng.randi_range(0, deck.size()), Events.card_of(ids.pop_back()))
	var m := setup(hand, by_zone)
	m.events_on = true
	m.event_rng.seed = deal_rng.randi()
	return m


## 테스트·연습용: 손패와 더미(맨 뒤가 맨 위)를 직접 준다.
static func setup(staff_hand: Array, decks_by_zone: Array, chief_hand: Array = []) -> Match:
	var m := Match.new()
	m.hands = [_ints(staff_hand), _ints(chief_hand)]
	for z in Cards.ZONE_RANGES:
		m.start_counts.append(staff_hand.filter(func(c: int) -> bool: return Cards.zone_of(c) == z).size())
	for d in decks_by_zone:
		m.decks.append(_ints(d))
	m.hideouts.append({ card = 0, sprints = [] as Array[int], revealed = true })
	m._begin_turn(Side.STAFF)
	return m


static func _ints(a: Array) -> Array[int]:
	var out: Array[int] = []
	out.assign(a)
	return out


func is_over() -> bool:
	return phase == Phase.OVER


func last_card() -> int:
	return hideouts[-1].card


func hidden_count() -> int:
	var n := 0
	for h in hideouts:
		if not h.revealed:
			n += 1
	return n


func is_first_turn(s: int) -> bool:
	return turns[s] == 1


## 이번 기록이 닿을 수 있는 가장 큰 번호.
func reach(sprints: Array) -> int:
	var total := 0
	for c in sprints:
		total += Cards.sprint_of(c)
	return last_card() + Cards.BASE_STEP + total + bonus()


## 이번 차례 사원이 공짜로 더 갈 수 있는 거리(엘리베이터).
func bonus() -> int:
	return limits[Side.STAFF].get(&"bonus", 0) if side == Side.STAFF else 0


func limited(s: int, key: StringName) -> bool:
	return side == s and limits[s].get(key, false)


## card를 내는 데 필요한 가장 적은 뛰기 카드 묶음. 못 내면 null.
func minimal_sprints(card: int) -> Variant:
	var hand: Array[int] = hands[Side.STAFF]
	if not card in hand or card <= last_card():
		return null
	var need := card - reach([])
	var picked: Array[int] = []
	if need <= 0:
		return picked
	var pool: Array[int] = []
	for c in hand:
		if c != card and Cards.sprint_of(c) > 0:
			pool.append(c)
	pool.sort_custom(func(a: int, b: int) -> bool:
		return Cards.sprint_of(a) > Cards.sprint_of(b) or (Cards.sprint_of(a) == Cards.sprint_of(b) and a > b))
	for c in pool:
		if need <= 0:
			break
		picked.append(c)
		need -= Cards.sprint_of(c)
	return picked if need <= 0 else null


func legal_moves(s: int) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	if is_over() or s != side:
		return moves
	match phase:
		Phase.DRAW:
			for z in decks.size():
				if not decks[z].is_empty():
					moves.append({ side = s, action = Action.DRAW, zone = z })
		Phase.ACT when s == Side.STAFF:
			if _can_place_more():
				for card in hands[s]:
					var sprints: Variant = minimal_sprints(card)
					if sprints != null:
						moves.append({ side = s, action = Action.PLACE, card = card, sprints = sprints })
			if _can_pass():
				moves.append({ side = s, action = Action.PASS })
		_:
			for n in range(1, Cards.LAST):
				if not _is_revealed_card(n):
					moves.append({ side = s, action = Action.GUESS, numbers = [n] as Array[int] })
	return moves


func is_legal(move: Dictionary) -> bool:
	var s: int = move.get(&"side", NONE)
	if is_over() or s != side:
		return false
	match move.get(&"action", NONE):
		Action.DRAW:
			var z: int = move.get(&"zone", NONE)
			return phase == Phase.DRAW and z >= 0 and z < decks.size() and not decks[z].is_empty()
		Action.PASS:
			return phase == Phase.ACT and s == Side.STAFF and _can_pass()
		Action.PLACE:
			return phase == Phase.ACT and s == Side.STAFF and _can_place_more() \
				and _placement_ok(move.get(&"card", NONE), move.get(&"sprints", []))
		Action.GUESS:
			if s != Side.CHIEF or not (phase == Phase.ACT or phase == Phase.MANHUNT):
				return false
			return _guess_ok(move.get(&"numbers", []))
	return false


## 행동 하나를 적용한다. 불법이면 false.
func apply(move: Dictionary) -> bool:
	if not is_legal(move):
		return false
	var record := move.duplicate(true)
	match move.action:
		Action.DRAW:
			var card: int = decks[move.zone].pop_back()
			record.card = card
			if Events.is_event(card):
				_event(Events.id_of(card), record)
			else:
				hands[side].append(card)
				draws_left -= 1
			if draws_left <= 0 or _decks_empty():
				phase = Phase.ACT
		Action.PASS:
			_begin_turn(Side.CHIEF)
		Action.PLACE:
			_place(move.card, _ints(move.get(&"sprints", [])))
		Action.GUESS:
			var corridor: bool = phase == Phase.ACT and limits[Side.CHIEF].get(&"corridor", false)
			limits[Side.CHIEF].erase(&"corridor")
			record.hit = _guess(_ints(move.numbers))
			if corridor and not record.hit:
				var below := 0
				for i in range(1, hideouts.size()):
					if hideouts[i].card < move.numbers[0]:
						below += 1
				record.below = { number = move.numbers[0], before = hideouts.size(), count = below }
	history.append(record)
	moved.emit(record)
	return true


func _begin_turn(s: int) -> void:
	side = s
	turns[s] += 1
	placed_this_turn = 0
	limits[s] = pending[s]
	pending[s] = {}
	if s == Side.STAFF and is_first_turn(s):
		draws_left = 0
	else:
		draws_left = 2 if s == Side.CHIEF and is_first_turn(s) else 1
	if limits[s].get(&"no_draw", false):
		draws_left = 0
	draws_left += limits[s].get(&"extra_draws", 0)
	if _decks_empty():
		draws_left = 0
	phase = Phase.DRAW if draws_left > 0 else Phase.ACT


func _decks_empty() -> bool:
	for d in decks:
		if not d.is_empty():
			return false
	return true


## 첫 차례는 1~2장, 그 뒤로는 차례마다 1장까지.
func _can_place_more() -> bool:
	if limited(Side.STAFF, &"no_place"):
		return false
	return placed_this_turn < (2 if is_first_turn(Side.STAFF) else 1)


func _can_pass() -> bool:
	if limited(Side.STAFF, &"no_place"):
		return true
	return not is_first_turn(Side.STAFF) or placed_this_turn >= 1


func _placement_ok(card: int, sprints: Array) -> bool:
	var hand: Array[int] = hands[Side.STAFF]
	if not card in hand or card <= last_card():
		return false
	var used := { card: true }
	for c in sprints:
		if typeof(c) != TYPE_INT or used.has(c) or not c in hand or Cards.sprint_of(c) == 0:
			return false
		used[c] = true
	return card <= reach(sprints)


func _place(card: int, sprints: Array[int]) -> void:
	var hand: Array[int] = hands[Side.STAFF]
	hand.erase(card)
	for c in sprints:
		hand.erase(c)
	hideouts.append({ card = card, sprints = sprints, revealed = card == Cards.LAST, bonus = bonus() })
	placed_this_turn += 1
	if card == Cards.LAST:
		_on_escape()
	elif not _can_place_more():
		_begin_turn(Side.CHIEF)


func _on_escape() -> void:
	var highest := 0
	for i in hideouts.size() - 1:
		if hideouts[i].revealed:
			highest = maxi(highest, hideouts[i].card)
	if hidden_count() > 0 and highest <= Cards.MANHUNT_MAX:
		side = Side.CHIEF
		phase = Phase.MANHUNT
		manhunted = true
		draws_left = 0
	else:
		_finish(Side.STAFF)


func _is_revealed_card(n: int) -> bool:
	for h in hideouts:
		if h.revealed and h.card == n:
			return true
	return false


func _guess_ok(numbers: Array) -> bool:
	var single := phase == Phase.MANHUNT or limited(Side.CHIEF, &"one_guess")
	if numbers.is_empty() or (single and numbers.size() != 1):
		return false
	var seen := {}
	for n in numbers:
		if typeof(n) != TYPE_INT or n < 1 or n >= Cards.LAST or seen.has(n) or _is_revealed_card(n):
			return false
		seen[n] = true
	return true


## 모두 맞아야 뒤집는다. 맞았으면 true.
func _guess(numbers: Array[int]) -> bool:
	var found: Array[Dictionary] = []
	for n in numbers:
		for h in hideouts:
			if not h.revealed and h.card == n:
				found.append(h)
	var hit := found.size() == numbers.size()
	if hit:
		for h in found:
			h.revealed = true
	if hidden_count() == 0:
		_finish(Side.CHIEF)
	elif phase == Phase.MANHUNT:
		if not hit:
			_finish(Side.STAFF)
	else:
		_begin_turn(Side.STAFF)
	return hit


## 뽑은 사건을 바로 처리한다. 공개되는 단서는 record.clue에 남긴다.
func _event(id: int, record: Dictionary) -> void:
	record.event = id
	match id:
		Events.Id.BADGE:
			for i in range(1, hideouts.size()):
				if not hideouts[i].revealed:
					record.clue = { index = i, zone = Cards.zone_of(hideouts[i].card) }
					break
		Events.Id.CCTV:
			for i in range(hideouts.size() - 1, 0, -1):
				if not hideouts[i].revealed:
					record.clue = { index = i, odd = hideouts[i].card % 2 == 1 }
					break
		Events.Id.TIP_OFF:
			var pool: Array[int] = hands[Side.STAFF].filter(func(c: int) -> bool: return c != Cards.LAST)
			if not pool.is_empty():
				record.clue = { card = pool[event_rng.randi() % pool.size()], before = hideouts.size() }
		Events.Id.MEETING:
			pending[Side.STAFF].no_place = true
		Events.Id.BUSY:
			pending[Side.CHIEF].one_guess = true
		Events.Id.ON_CALL:
			pending[Side.CHIEF].no_draw = true
		Events.Id.ELEVATOR:
			var l := _soon(Side.STAFF)
			l.bonus = l.get(&"bonus", 0) + Events.ELEVATOR_BONUS
		Events.Id.EXCUSE:
			_more(Side.STAFF, 2)
		Events.Id.DINNER:
			_more(Side.STAFF, 1)
			_more(Side.CHIEF, 1)
		Events.Id.CORRIDOR:
			_soon(Side.CHIEF).corridor = true


## 이번 차례(그 쪽 차례면) 또는 그 쪽 다음 차례의 효과.
func _soon(s: int) -> Dictionary:
	return limits[s] if s == side else pending[s]


func _more(s: int, n: int) -> void:
	if s == side:
		draws_left += n
	else:
		pending[s].extra_draws = pending[s].get(&"extra_draws", 0) + n


func _finish(w: int) -> void:
	winner = w
	phase = Phase.OVER

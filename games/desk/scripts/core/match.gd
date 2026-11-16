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
var history: Array[Dictionary] = []


## 구역 더미를 섞고 사원 처음 손패(1, 2, 3, 42 + 층 안 3장 + 건물 안 2장)를 준다.
static func deal(deal_rng: RandomNumberGenerator) -> Match:
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
	return setup(hand, by_zone)


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
	return last_card() + Cards.BASE_STEP + total


## card를 내는 데 필요한 가장 적은 뛰기 카드 묶음. 못 내면 null.
func minimal_sprints(card: int) -> Variant:
	var hand: Array[int] = hands[Side.STAFF]
	if not card in hand or card <= last_card():
		return null
	var need := card - (last_card() + Cards.BASE_STEP)
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
			hands[side].append(card)
			record.card = card
			draws_left -= 1
			if draws_left <= 0 or _decks_empty():
				phase = Phase.ACT
		Action.PASS:
			_begin_turn(Side.CHIEF)
		Action.PLACE:
			_place(move.card, _ints(move.get(&"sprints", [])))
		Action.GUESS:
			record.hit = _guess(_ints(move.numbers))
	history.append(record)
	moved.emit(record)
	return true


func _begin_turn(s: int) -> void:
	side = s
	turns[s] += 1
	placed_this_turn = 0
	if s == Side.STAFF and is_first_turn(s):
		draws_left = 0
	else:
		draws_left = 2 if s == Side.CHIEF and is_first_turn(s) else 1
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
	return placed_this_turn < (2 if is_first_turn(Side.STAFF) else 1)


func _can_pass() -> bool:
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
	hideouts.append({ card = card, sprints = sprints, revealed = card == Cards.LAST })
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
		draws_left = 0
	else:
		_finish(Side.STAFF)


func _is_revealed_card(n: int) -> bool:
	for h in hideouts:
		if h.revealed and h.card == n:
			return true
	return false


func _guess_ok(numbers: Array) -> bool:
	if numbers.is_empty() or (phase == Phase.MANHUNT and numbers.size() != 1):
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


func _finish(w: int) -> void:
	winner = w
	phase = Phase.OVER

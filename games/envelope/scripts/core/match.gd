class_name Match
extends RefCounted
## 한 판의 규칙(기획서 2장). 씬 트리에 의존하지 않는다.
## 카드는 판 안에서 고유 번호(uid)로 다룬다. `kinds[uid]`가 카드 종류(Cards.Id).

signal moved(move: Dictionary)

enum Action { PLAY, ENVELOPE, NOTE }

var players: int
var target: int
var kinds: Array[int] = []
var hands: Array = []      # seat → Array[int] uid
var face_up: Array = []    # seat → Array[int] uid (시키기로 낸 카드)
var notes: Array = []      # seat → Array[int] uid (받은 쪽지, 뒷면)
var envelope: Array[int] = []
var placed_by := {}        # uid → 낸 사람 seat (봉투·쪽지·앞면)
var out: Array[bool] = []
var turn := 0
var history: Array[Dictionary] = []
var rng: RandomNumberGenerator


## 섞어서 똑같이 나누고, 총무를 가진 사람부터 시작한다.
static func deal(n: int, deal_rng: RandomNumberGenerator, play_rng: RandomNumberGenerator = null) -> Match:
	var deck := Cards.deck(n)
	for i in range(deck.size() - 1, 0, -1):
		var j := deal_rng.randi_range(0, i)
		var t := deck[i]
		deck[i] = deck[j]
		deck[j] = t
	var per := deck.size() / n
	var hands_by_kind: Array = []
	for s in n:
		hands_by_kind.append(deck.slice(s * per, (s + 1) * per))
	return from_hands(hands_by_kind, play_rng)


## 테스트·연습용: 손패를 카드 종류로 직접 준다.
static func from_hands(hands_by_kind: Array, play_rng: RandomNumberGenerator = null) -> Match:
	var m := Match.new()
	m.players = hands_by_kind.size()
	m.target = Cards.target(m.players)
	m.rng = play_rng if play_rng != null else RandomNumberGenerator.new()
	for s in m.players:
		var hand: Array[int] = []
		for kind in hands_by_kind[s]:
			hand.append(m.kinds.size())
			m.kinds.append(kind)
		m.hands.append(hand)
		m.face_up.append([] as Array[int])
		m.notes.append([] as Array[int])
		m.out.append(hand.size() <= 1)
	m.turn = maxi(0, m.seat_holding(Cards.Id.CHAIR))
	if m.out[m.turn]:
		m.turn = m._next_seat(m.turn)
	return m


func kind(uid: int) -> int:
	return kinds[uid]


func seat_holding(card_kind: int) -> int:
	for s in players:
		for uid in hands[s]:
			if kinds[uid] == card_kind:
				return s
	return -1


func is_over() -> bool:
	return not out.has(false)


func legal_moves(seat: int) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	if is_over() or seat != turn:
		return moves
	for uid in hands[seat]:
		if not Cards.playable(kinds[uid]):
			continue
		moves.append(_move(seat, uid, Action.PLAY))
		moves.append(_move(seat, uid, Action.ENVELOPE))
		for other in players:
			if other != seat:
				moves.append(_move(seat, uid, Action.NOTE, other))
	return moves


func is_legal(move: Dictionary) -> bool:
	var seat: int = move.get(&"seat", -1)
	if is_over() or seat != turn:
		return false
	var uid: int = move.get(&"card", -1)
	if not uid in hands[seat] or not Cards.playable(kinds[uid]):
		return false
	if move.action == Action.NOTE:
		var to: int = move.get(&"to", -1)
		return to >= 0 and to < players and to != seat
	return move.action == Action.PLAY or move.action == Action.ENVELOPE


## 행동 하나를 적용하고 차례를 넘긴다. 불법이면 false.
func apply(move: Dictionary) -> bool:
	if not is_legal(move):
		return false
	var seat: int = move.seat
	var uid: int = move.card
	hands[seat].erase(uid)
	placed_by[uid] = seat
	match move.action:
		Action.PLAY:
			face_up[seat].append(uid)
		Action.ENVELOPE:
			envelope.append(uid)
		Action.NOTE:
			notes[move.to].append(uid)
	history.append(move)
	_end_turn(seat)
	moved.emit(move)
	return true


func _end_turn(seat: int) -> void:
	if hands[seat].size() <= 1:
		out[seat] = true
	if not is_over():
		turn = _next_seat(seat)


func _next_seat(from: int) -> int:
	for i in range(1, players + 1):
		var s := (from + i) % players
		if not out[s]:
			return s
	return from


static func _move(seat: int, uid: int, action: Action, to: int = -1) -> Dictionary:
	var m := { seat = seat, card = uid, action = action }
	if to >= 0:
		m.to = to
	return m


## 결산(기획서 2.1): 봉투 개봉 → 감사 → 우선순위 승리 판정.
func resolve() -> Dictionary:
	var fund := 0
	for uid in envelope:
		fund += Cards.amount(kinds[uid])
	var funded := fund >= target
	var suspicion: Array[int] = []
	for s in players:
		var total := 0
		for uid in notes[s]:
			total += Cards.amount(kinds[uid])
		suspicion.append(maxi(0, total))
	var top: int = suspicion.max()
	var confined: Array[bool] = []
	var all_same := suspicion.count(top) == players
	for s in players:
		confined.append(not all_same and suspicion[s] == top)
	var roles: Array[int] = []
	for s in players:
		roles.append(kinds[hands[s][0]] if not hands[s].is_empty() else -1)
	var thief_free := false
	for s in players:
		if roles[s] == Cards.Id.THIEF and not confined[s]:
			thief_free = true
	var winners: Array[int] = []
	var won_priority := 0
	for p in range(1, Cards.MAX_PRIORITY + 1):
		for s in players:
			if roles[s] >= 0 and Cards.priority(roles[s]) == p and _meets(roles[s], confined[s], funded, thief_free):
				winners.append(s)
		if not winners.is_empty():
			won_priority = p
			break
	return {
		fund = fund, target = target, funded = funded,
		suspicion = suspicion, confined = confined, roles = roles,
		no_thief = not roles.has(Cards.Id.THIEF),
		winners = winners, priority = won_priority,
	}


static func _meets(role: int, confined: bool, funded: bool, thief_free: bool) -> bool:
	match Cards.win(role):
		Cards.Win.CONFINED: return confined
		Cards.Win.NOT_CONFINED: return not confined
		Cards.Win.THIEF_WINS: return thief_free
		Cards.Win.FUND_FAILED: return not funded
		Cards.Win.FUND_OK: return funded
		Cards.Win.NOBODY_WON: return true
	return false

class_name Match
extends RefCounted
## 한 판의 규칙(기획서 2장). 씬 트리에 의존하지 않는다.
## 카드는 판 안에서 고유 번호(uid)로 다룬다. `kinds[uid]`가 카드 종류(Cards.Id).

signal moved(move: Dictionary)
signal asked(request: Dictionary)

enum Action { PLAY, ENVELOPE, NOTE }

const C := Cards.Id
const NO_HINT := -2

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
## 능력이 고르기를 기다리는 동안 쌓이는 결정 요청. 비어 있어야 다음 행동을 할 수 있다.
## { seat, ask: StringName, options: Array, by: 능력을 쓴 seat, kind: 능력 카드 종류 }
var pending: Array[Dictionary] = []
var armed := {}            # 구두쇠 uid → 낸 seat (다음 차례 시작에 발동)
var seen: Array = []       # seat → { uid: true } 그 자리가 앞면을 본 적 있는 카드
var located: Array = []    # seat → { uid: 마지막으로 그 카드를 쥐고 있던 걸 안 seat }
var sniffs: Array[int] = []  # seat → 눈치왕으로 알게 된 범인 자리 (-1 없음, NO_HINT 모름)
var _effect := {}


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
		m.seen.append({})
		m.located.append({})
		for uid in hand:
			m._see(s, uid)
		m.sniffs.append(NO_HINT)
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
	return pending.is_empty() and not out.has(false)


func request_for(seat: int) -> Dictionary:
	for r in pending:
		if r.seat == seat:
			return r
	return {}


func legal_moves(seat: int) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	if is_over() or seat != turn or not pending.is_empty():
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
	if is_over() or seat != turn or not pending.is_empty():
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
			for p in players:
				_see(p, uid)
		Action.ENVELOPE:
			envelope.append(uid)
		Action.NOTE:
			notes[move.to].append(uid)
	history.append(move)
	if move.action == Action.PLAY:
		_begin_ability(seat, uid)
	if pending.is_empty():
		_end_turn(seat)
	moved.emit(move)
	_announce()
	return true


## 결정 요청에 답한다. 요청이 없거나 보기에 없는 답이면 false.
func answer(seat: int, choice: Variant) -> bool:
	var req := request_for(seat)
	if req.is_empty() or not req.options.has(choice):
		return false
	pending.erase(req)
	_effect.answers[seat] = choice
	history.append({ seat = seat, ask = req.ask, answer = choice })
	if pending.is_empty():
		_advance()
		_announce()
	return true


## 듣는 쪽이 신호 안에서 바로 answer()해도 남은 요청을 빠뜨리지 않는다.
func _announce() -> void:
	for r in pending.duplicate():
		if pending.has(r):
			asked.emit(r)


func _end_turn(seat: int) -> void:
	_effect = {}
	if hands[seat].size() <= 1:
		out[seat] = true
	if not out.has(false):
		return
	turn = _next_seat(seat)
	_check_miser(turn)


func _check_miser(seat: int) -> void:
	for uid in face_up[seat]:
		if armed.get(uid, -1) == seat:
			armed.erase(uid)
			if not envelope.is_empty():
				_effect = { kind = C.MISER, seat = seat, step = &"", answers = {} }
				_ask(seat, &"MISER_TAKE", range(envelope.size()))
				return


func _see(seat: int, uid: int) -> void:
	seen[seat][uid] = true


func _ask(seat: int, ask: StringName, options: Array) -> void:
	pending.append({ seat = seat, ask = ask, options = options, by = _effect.seat, kind = _effect.kind })


func _others(seat: int) -> Array:
	return range(players).filter(func(s: int) -> bool: return s != seat)


func _to_hand(seat: int, uid: int) -> void:
	hands[seat].append(uid)
	placed_by.erase(uid)
	_see(seat, uid)


## 기획서 3장 능력표. 고를 것이 없으면 능력은 건너뛴다.
func _begin_ability(seat: int, uid: int) -> void:
	var k := kinds[uid]
	_effect = { kind = k, seat = seat, step = &"", answers = {} }
	match k:
		C.BUDDY:
			var opts := []
			for from in players:
				for n in notes[from]:
					for to in players:
						if to != from:
							opts.append({ note = n, to = to })
			if not opts.is_empty():
				_ask(seat, &"NOTE_MOVE", opts)
		C.MISER:
			armed[uid] = seat
		C.ACCOUNTANT:
			for u in envelope:
				_see(seat, u)
		C.HR:
			_ask(seat, &"PEEK_HAND", _others(seat))
		C.SNIFFER:
			var newbie := seat_holding(C.NEWBIE)
			if newbie >= 0 and newbie != seat:
				_ask(newbie, &"CLAIM", [false, true])
			else:
				sniffs[seat] = seat_holding(C.THIEF)
		C.BUSYBODY:
			_ask(seat, &"SWAP_TARGET", _others(seat))
		C.BROADCAST:
			var ring := range(players).filter(func(s: int) -> bool: return hands[s].size() >= 2)
			if ring.size() >= 2:
				_effect.ring = ring
				for s in ring:
					_ask(s, &"PASS", hands[s].duplicate())
		C.SUPPLIES:
			var opts := []
			for s in _others(seat):
				for u in face_up[s]:
					if kinds[u] != C.SUPPLIES:
						opts.append(u)
			if not opts.is_empty():
				_ask(seat, &"TAKE_FACE_UP", opts)
		C.BOSS:
			_ask(seat, &"DRAW_FROM", _others(seat))
		C.QUITTER:
			var opts := []
			for slot in envelope.size():
				for u in hands[seat]:
					opts.append({ slot = slot, card = u })
			if not opts.is_empty():
				_ask(seat, &"ENVELOPE_SWAP", opts)


func _advance() -> void:
	var seat: int = _effect.seat
	var a: Dictionary = _effect.answers
	_effect.answers = {}
	match _effect.kind:
		C.BUDDY:
			var n: int = a[seat].note
			for s in players:
				notes[s].erase(n)
			notes[a[seat].to].append(n)
		C.MISER:
			var e: int = envelope[a[seat]]
			envelope.remove_at(a[seat])
			_to_hand(seat, e)
			_effect = {}
			_check_miser(seat)
			return
		C.HR:
			for u in hands[a[seat]]:
				_see(seat, u)
				located[seat][u] = a[seat]
		C.SNIFFER:
			var newbie: int = a.keys()[0]
			sniffs[seat] = newbie if a[newbie] else seat_holding(C.THIEF)
		C.BUSYBODY:
			if _effect.step == &"":
				_effect.step = &"give"
				_effect.target = a[seat]
				_ask(seat, &"SWAP_GIVE", hands[seat].duplicate())
				_ask(_effect.target, &"SWAP_GIVE", hands[_effect.target].duplicate())
				return
			var t: int = _effect.target
			hands[seat].erase(a[seat])
			hands[t].erase(a[t])
			_to_hand(seat, a[t])
			_to_hand(t, a[seat])
			located[seat][a[seat]] = t
			located[t][a[t]] = seat
		C.BROADCAST:
			var ring: Array = _effect.ring
			for s in ring:
				hands[s].erase(a[s])
			for i in ring.size():
				var to: int = ring[(i + 1) % ring.size()]
				_to_hand(to, a[ring[i]])
				located[ring[i]][a[ring[i]]] = to
		C.SUPPLIES:
			var u: int = a[seat]
			for s in players:
				face_up[s].erase(u)
			armed.erase(u)
			_to_hand(seat, u)
		C.BOSS:
			if _effect.step == &"":
				var t: int = a[seat]
				var drawn: int = hands[t][rng.randi_range(0, hands[t].size() - 1)]
				hands[t].erase(drawn)
				_to_hand(seat, drawn)
				located[t][drawn] = seat
				_effect.step = &"give"
				_effect.target = t
				_ask(seat, &"GIVE_BACK", hands[seat].duplicate())
				return
			hands[seat].erase(a[seat])
			_to_hand(_effect.target, a[seat])
			located[seat][a[seat]] = _effect.target
		C.QUITTER:
			var slot: int = a[seat].slot
			var card: int = a[seat].card
			var e: int = envelope[slot]
			hands[seat].erase(card)
			envelope[slot] = card
			placed_by[card] = seat
			_to_hand(seat, e)
	if pending.is_empty():
		_end_turn(seat)


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
		envelope_kinds = envelope.map(func(u: int) -> int: return kinds[u]),
		note_kinds = notes.map(func(ns: Array) -> Array: return ns.map(func(u: int) -> int: return kinds[u])),
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

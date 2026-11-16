class_name Bot
extends RefCounted
## AI 1차(기획서 4장). `Knowledge`만 읽고 행동과 결정 요청의 답을 고른다.
## 매번 손패에서 끝까지 남길 카드(`keep`)를 정하고, 그 정체가 이기는 쪽으로 나머지 카드에 점수를 매긴다.

enum Persona { CAREFUL, FOLLOWER, WILD }

const C := Cards.Id
const NOISE := { Persona.CAREFUL: 0.15, Persona.FOLLOWER: 0.3, Persona.WILD: 1.2 }
const UNKNOWN_AMOUNT := 1.5

var seat: int
var persona: Persona
var rng: RandomNumberGenerator
var keep := -1


## 시뮬레이터 전용 덮어쓰기: { habit, follow, herd }.
static var tune := {}

func _init(s: int, r: RandomNumberGenerator, p: Persona = Persona.CAREFUL) -> void:
	seat = s
	rng = r
	persona = p


## Match 하나를 결정 요청 → 차례 순서로 한 걸음 진행한다. 끝났으면 false.
static func step(m: Match, bots: Array) -> bool:
	if m.is_over():
		return false
	if not m.pending.is_empty():
		var req: Dictionary = m.pending[0]
		var b: Bot = bots[req.seat]
		m.answer(req.seat, b.choose_answer(Knowledge.of(m, req.seat)))
		return true
	var bot: Bot = bots[m.turn]
	return m.apply(bot.choose_move(Knowledge.of(m, m.turn), m.legal_moves(m.turn)))


func choose_move(k: Knowledge, moves: Array[Dictionary]) -> Dictionary:
	keep = _pick_keep(k)
	var best: Dictionary = moves[0]
	var best_score := -INF
	for mv in moves:
		var s: float = _score_move(k, mv) + rng.randf() * NOISE[persona]
		if s > best_score:
			best_score = s
			best = mv
	return best


func choose_answer(k: Knowledge) -> Variant:
	keep = _pick_keep(k)
	var req := k.request
	var opts: Array = req.options
	var best: Variant = opts[0]
	var best_score := -INF
	for o in opts:
		var s: float = _score_answer(k, req.ask, o) + rng.randf() * NOISE[persona]
		if s > best_score:
			best_score = s
			best = o
	return best


# --- 판세 읽기 ---

func _amount(k: Knowledge, uid: int) -> float:
	var kind := k.kind_of(uid)
	return float(Cards.amount(kind)) if kind >= 0 else UNKNOWN_AMOUNT


func fund_estimate(k: Knowledge) -> float:
	var total := 0.0
	for uid in k.envelope:
		total += _amount(k, uid)
	return total


func suspicion_estimate(k: Knowledge, s: int) -> float:
	var total := 0.0
	for uid in k.notes[s]:
		total += _amount(k, uid)
	return total


## 각 자리가 범인일 것 같은 정도. 눈치왕 정보가 있으면 거의 확정.
func thief_belief(k: Knowledge, s: int) -> float:
	if s == seat:
		return 1.0 if _holds(k, C.THIEF) else 0.0
	if _holds(k, C.THIEF):
		return 0.0
	if k.thief_hint >= 0:
		return 0.9 if s == k.thief_hint else 0.05
	for uid in k.located:
		if k.kind_of(uid) == C.THIEF and not k.envelope.has(uid):
			return 0.85 if k.located[uid] == s else 0.05
	var b := 1.0 / maxf(1.0, k.players - 1)
	b += _note_habit(k, s) * tune.get(&"habit", 0.3)
	b += suspicion_estimate(k, s) * (tune.get(&"follow", 0.1) if persona == Persona.FOLLOWER else tune.get(&"herd", 0.05))
	return b


## 봉투보다 쪽지를 많이 놓는 사람은 수상하다(범인은 봉투에 돈을 잘 안 넣는다).
func _note_habit(k: Knowledge, s: int) -> float:
	var n := 0
	var e := 0
	for uid in k.placed_by:
		if k.placed_by[uid] != s:
			continue
		if k.envelope.has(uid):
			e += 1
		elif _note_owner(k, uid) >= 0:
			n += 1
	return float(n - e) / maxf(1.0, n + e)


func _holds(k: Knowledge, kind: int) -> bool:
	for uid in k.hand:
		if k.kind_of(uid) == kind:
			return true
	return false


func _most(k: Knowledge, others_only: bool, f: Callable) -> int:
	var best := -1
	var best_v := -INF
	for s in k.players:
		if others_only and s == seat:
			continue
		var v: float = f.call(s)
		if v > best_v:
			best_v = v
			best = s
	return best


# --- 남길 카드 ---

func _pick_keep(k: Knowledge) -> int:
	var best := -1
	var best_v := -INF
	for uid in k.hand:
		var v := _identity_value(k, k.kind_of(uid))
		if v > best_v:
			best_v = v
			best = uid
	return best


func _identity_value(k: Knowledge, kind: int) -> float:
	var est := fund_estimate(k)
	var cards_left := 0
	for c in k.hand_counts:
		cards_left += maxi(0, c - 1)
	var p_fund := clampf(0.5 + (est + cards_left * 0.7 - k.target) * 0.12, 0.05, 0.95)
	var my_heat := suspicion_estimate(k, seat) / maxf(1.0, _max_heat(k))
	match Cards.win(kind):
		Cards.Win.FUND_OK: return p_fund
		Cards.Win.FUND_FAILED: return 1.0 - p_fund
		Cards.Win.NOT_CONFINED:
			return 10.0 if kind == C.THIEF else 0.6 - my_heat * 0.5
		Cards.Win.THIEF_WINS: return 0.35
		Cards.Win.CONFINED: return my_heat * 0.8
		Cards.Win.NOBODY_WON: return 0.15
	return 0.0


func _max_heat(k: Knowledge) -> float:
	var m := 0.0
	for s in k.players:
		m = maxf(m, suspicion_estimate(k, s))
	return m


# --- 행동 점수 ---

func _score_move(k: Knowledge, mv: Dictionary) -> float:
	var uid: int = mv.card
	if uid == keep:
		return -100.0
	var kind := k.kind_of(uid)
	var amt := float(Cards.amount(kind))
	var goal := k.kind_of(keep)
	var win := Cards.win(goal)
	match mv.action:
		Match.Action.ENVELOPE:
			var need := clampf((k.target - fund_estimate(k)) / float(k.target), 0.0, 1.0)
			match win:
				Cards.Win.FUND_OK: return amt * (0.2 + need)
				Cards.Win.FUND_FAILED: return 1.0 - amt
				Cards.Win.NOT_CONFINED, Cards.Win.THIEF_WINS: return 0.5 - amt * 0.3
				_: return amt * 0.3
		Match.Action.NOTE:
			var to: int = mv.to
			var belief := thief_belief(k, to)
			match win:
				Cards.Win.NOT_CONFINED, Cards.Win.THIEF_WINS:
					if goal == C.THIEF or goal == C.BUDDY:
						return amt * (1.0 - belief) * (0.5 + suspicion_estimate(k, to) * 0.2) - 0.2
					return amt * belief * 1.2
				Cards.Win.CONFINED:
					return amt * 0.1
				_:
					return amt * minf(1.5, belief * (k.players - 1) * 0.5)
		Match.Action.PLAY:
			return _ability_value(k, kind, goal)
	return 0.0


func _ability_value(k: Knowledge, kind: int, goal: int) -> float:
	match kind:
		C.HR, C.SNIFFER:
			return 1.2 if k.thief_hint == Match.NO_HINT and not _holds(k, C.THIEF) else 0.2
		C.ACCOUNTANT:
			return 0.4 + k.envelope.size() * 0.15
		C.MISER:
			return 2.0 if goal == C.MISER else -0.5
		C.QUITTER:
			return 1.5 if goal == C.MISER or goal == C.THIEF else 0.0
		C.BUDDY:
			return 2.0 if goal == C.THIEF or goal == C.BUDDY else 0.6
		C.SUPPLIES:
			return 0.5
		C.BOSS:
			return 0.4
		C.BUSYBODY, C.BROADCAST:
			return 0.3
	return 0.1


# --- 결정 요청 점수 ---

func _score_answer(k: Knowledge, ask: StringName, o: Variant) -> float:
	var goal := k.kind_of(keep)
	var thief_side := goal == C.THIEF or goal == C.BUDDY
	match ask:
		&"PEEK_HAND", &"DRAW_FROM", &"SWAP_TARGET":
			return thief_belief(k, o)
		&"SWAP_GIVE", &"PASS", &"GIVE_BACK":
			if o == keep and k.hand.size() > 1:
				return -100.0
			return -_identity_value(k, k.kind_of(o)) - (0.0 if k.kind_of(o) != C.THIEF else (5.0 if goal == C.THIEF else -1.0))
		&"NOTE_MOVE":
			var from := _note_owner(k, o.note)
			var amt := _amount(k, o.note)
			if thief_side:
				return amt * (thief_belief(k, from) - thief_belief(k, o.to)) + (2.0 if from == seat else 0.0)
			return amt * (thief_belief(k, o.to) - thief_belief(k, from))
		&"MISER_TAKE":
			var u: int = k.envelope[o]
			return _amount(k, u) * (1.0 if goal == C.MISER else -1.0)
		&"TAKE_FACE_UP":
			return _identity_value(k, k.kind_of(o))
		&"ENVELOPE_SWAP":
			var slot_amt := _amount(k, k.envelope[o.slot])
			var hand_amt := float(Cards.amount(k.kind_of(o.card)))
			if o.card == keep:
				return -100.0
			var gain := hand_amt - slot_amt
			return -gain if goal == C.MISER else gain
		&"CLAIM":
			return 1.0 if (o == (goal == C.NEWBIE)) else 0.0
	return 0.0


func _note_owner(k: Knowledge, uid: int) -> int:
	for s in k.players:
		if k.notes[s].has(uid):
			return s
	return -1

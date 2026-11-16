class_name Knowledge
extends RefCounted
## 한 쪽이 아는 것만 모은 보기. 화면·Bot·Deduce는 Match 대신 이것만 읽는다.
## 팀장에게 뒷면 기록은 번호 없이(HIDDEN) 밑에 깐 뛰기 장수만 보인다.

const HIDDEN := -1

var side: int
var turn_side: int
var phase: int
var winner: int
var hand: Array[int] = []
var staff_hand_count := 0
var deck_counts: Array[int] = []
var start_counts: Array[int] = []
## 가운데 줄. { card (모르면 HIDDEN), sprint_count, sprints (모르면 []), revealed }
var hideouts: Array[Dictionary] = []
## 사원이 뽑은 더미. before = 그때 가운데 줄에 놓여 있던 기록 수(0번 포함)
var staff_draws: Array[Dictionary] = []   # { zone, before }
## 틀린 짚기. 앞의 before개 기록에 numbers가 모두 있지는 않았다.
var misses: Array[Dictionary] = []        # { numbers, before }
## 사건 카드. events = 뽑힌 사건 { id, side }. 단서는 양쪽 모두 안다.
var events: Array[Dictionary] = []
var clues: Array[Dictionary] = []         # { kind, ... } 아래 CLUE_* 참고
var limits: Array[Dictionary] = [{}, {}]
var pending: Array[Dictionary] = [{}, {}]

## 단서 종류: ZONE { index, zone }, PARITY { index, odd }, HAND { card, before } = 앞 before개 기록에는 없음,
## BELOW { number, before, count } = 1..before-1번 기록 중 number보다 작은 것이 count장.
enum Clue { ZONE, PARITY, HAND, BELOW }


static func of(m: Match, s: int) -> Knowledge:
	var k := Knowledge.new()
	k.side = s
	k.turn_side = m.side
	k.phase = m.phase
	k.winner = m.winner
	k.hand = m.hands[s].duplicate()
	k.staff_hand_count = m.hands[Match.Side.STAFF].size()
	for d in m.decks:
		k.deck_counts.append(d.size())
	k.start_counts = m.start_counts.duplicate()
	k.limits = [m.limits[0].duplicate(), m.limits[1].duplicate()]
	k.pending = [m.pending[0].duplicate(), m.pending[1].duplicate()]
	for h in m.hideouts:
		var open: bool = h.revealed or s == Match.Side.STAFF
		k.hideouts.append({
			card = h.card if open else HIDDEN,
			sprint_count = h.sprints.size(),
			sprints = h.sprints.duplicate() if open else ([] as Array[int]),
			revealed = h.revealed,
			bonus = h.get(&"bonus", 0),
		})
	var placed := 1
	for r in m.history:
		match r.action:
			Match.Action.PLACE:
				placed += 1
			Match.Action.DRAW when r.has(&"event"):
				k.events.append({ id = r.event, side = r.side })
				if r.has(&"clue"):
					k.clues.append(_clue(r.event, r.clue))
			Match.Action.DRAW when r.side == Match.Side.STAFF:
				k.staff_draws.append({ zone = r.zone, before = placed })
			Match.Action.GUESS when not r.hit:
				k.misses.append({ numbers = r.numbers.duplicate(), before = placed })
				if r.has(&"below"):
					var b: Dictionary = r.below.duplicate()
					b.kind = Clue.BELOW
					k.clues.append(b)
	return k


static func _clue(id: int, c: Dictionary) -> Dictionary:
	var out := c.duplicate()
	match id:
		Events.Id.BADGE:
			out.kind = Clue.ZONE
		Events.Id.CCTV:
			out.kind = Clue.PARITY
		_:
			out.kind = Clue.HAND
	return out


func is_known(i: int) -> bool:
	return hideouts[i].card != HIDDEN


## 뒷면 기록에 있을 수 없는 번호: 내 손패, 이미 아는 기록과 뛰기 카드.
func excluded() -> Dictionary:
	var out := {}
	for c in hand:
		out[c] = true
	for h in hideouts:
		if h.card != HIDDEN:
			out[h.card] = true
		for c in h.sprints:
			out[c] = true
	return out

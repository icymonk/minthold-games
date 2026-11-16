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
	for h in m.hideouts:
		var open: bool = h.revealed or s == Match.Side.STAFF
		k.hideouts.append({
			card = h.card if open else HIDDEN,
			sprint_count = h.sprints.size(),
			sprints = h.sprints.duplicate() if open else ([] as Array[int]),
			revealed = h.revealed,
		})
	var placed := 1
	for r in m.history:
		match r.action:
			Match.Action.PLACE:
				placed += 1
			Match.Action.DRAW when r.side == Match.Side.STAFF:
				k.staff_draws.append({ zone = r.zone, before = placed })
			Match.Action.GUESS when not r.hit:
				k.misses.append({ numbers = r.numbers.duplicate(), before = placed })
	return k


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

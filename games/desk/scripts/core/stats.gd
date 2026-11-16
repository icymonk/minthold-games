class_name Stats
extends RefCounted
## 역할(Match.Side)별 누적 기록. 사람 쪽에서 본 값이다.

var games: Array[int] = [0, 0]
var wins: Array[int] = [0, 0]
var staff_turns: Array[int] = [0, 0]
var manhunts: Array[int] = [0, 0]
var manhunt_wins: Array[int] = [0, 0]
var weeks: Array[int] = [0, 0]
var best_week: Array[int] = [-1, -1]

const KEYS := [&"games", &"wins", &"staff_turns", &"manhunts", &"manhunt_wins", &"weeks", &"best_week"]


func add(m: Match, human: int) -> void:
	if not m.is_over():
		return
	games[human] += 1
	staff_turns[human] += m.turns[Match.Side.STAFF]
	var won := m.winner == human
	if won:
		wins[human] += 1
	if m.manhunted:
		manhunts[human] += 1
		if won:
			manhunt_wins[human] += 1


func add_week(w: Week) -> void:
	if not w.is_done():
		return
	weeks[w.side] += 1
	best_week[w.side] = maxi(best_week[w.side], w.score())


## 비율은 0~100, 판이 없으면 -1.
func win_pct(s: int) -> int:
	return _pct(wins[s], games[s])


func manhunt_pct(s: int) -> int:
	return _pct(manhunt_wins[s], manhunts[s])


func avg_turns(s: int) -> float:
	return float(staff_turns[s]) / games[s] if games[s] > 0 else -1.0


func _pct(a: int, b: int) -> int:
	return roundi(100.0 * a / b) if b > 0 else -1


func to_dict() -> Dictionary:
	var d := {}
	for k in KEYS:
		d[String(k)] = (get(k) as Array).duplicate()
	return d


static func from_dict(d: Dictionary) -> Stats:
	var st := Stats.new()
	for k in KEYS:
		var v: Array = d.get(String(k), [])
		if v.size() == 2:
			(st.get(k) as Array).assign([int(v[0]), int(v[1])])
	return st

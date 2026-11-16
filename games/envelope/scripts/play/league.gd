class_name League
extends RefCounted
## 리그(기획서 6장): 5판 연속, 이긴 판마다 사내 평판. 먼저 판정되는(우선순위 숫자가 작은) 승리일수록 크다.

const GAMES := 5

var scores: Array[int] = []


static func points(r: Dictionary, seat: int) -> int:
	if not r.winners.has(seat):
		return 0
	return Cards.MAX_PRIORITY + 1 - r.priority


func add(r: Dictionary, seat: int) -> int:
	var p := points(r, seat)
	scores.append(p)
	return p


func played() -> int:
	return scores.size()


func total() -> int:
	var t := 0
	for p in scores:
		t += p
	return t


func done() -> bool:
	return scores.size() >= GAMES

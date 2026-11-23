class_name ScoreLog
extends RefCounted
## 계절 끝 점수 기록(규칙 1-2). 화면(6.6 연출)은 lines를 차례로 띄우기만 한다.
## line = {card, plot, side(나무면 ""), what(나무 종 또는 이웃 종), pts, rule}

var lines: Array[Dictionary] = []
var cave := 0
## 나무·이웃 점수 합 + 굴
var base := 0
## 숲 정령 배수(Run이 마지막에 곱한다)
var mult := 1.0
var total := 0


func add(line: Dictionary) -> void:
	lines.append(line)
	base += line.pts
	total = base


func add_cave(n: int, each := 1) -> void:
	cave = n * each
	base += cave
	total = base


func apply(m: float) -> void:
	mult = m
	total = int(base * m)


## 종(나무 종 또는 이웃 종)별 합
func by_what() -> Dictionary:
	var out := {}
	for l in lines:
		out[l.what] = out.get(l.what, 0) + l.pts
	return out

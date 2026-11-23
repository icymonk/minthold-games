class_name Match
extends RefCounted
## 여러 명 한 판(원작 규칙): 덱·공터는 함께 쓰고, 손패·숲·굴은 사람마다 따로. 차례대로 돌고
## 「한 번 더」가 나오면 같은 사람이 한 차례 더 한다. 세 번째 겨울(바람)이 뜨면 끝난다.
## 행동은 사전 하나: {k = draw, from} | {k = play, id, half, plot, pay, picks} | {k = sapling, id, plot} | {k = stash, ids} | {k = skip}.
## 같은 seed·사람 수·행동 목록이면 어느 기기에서 돌려도 결과가 같다(온라인 방은 행동만 주고받는다).

const MIN_PLAYERS := 2
const MAX_PLAYERS := 5
## 원작: 사람이 적으면 덱에서 이만큼 빼고 시작한다
const REMOVE := {2: 30, 3: 20, 4: 10, 5: 0}

## 차례를 도는 계절 하나. hand·forest는 지금 차례인 사람 것으로 바꿔 끼운다.
var season: Season
var hands: Array = []
var forests: Array[Forest] = []
var players := 0
var turn := 0
## 지금까지 받아들인 행동(온라인 방의 행동 목록과 같다)
var actions: Array[Dictionary] = []
## 차례마다 {who, from, to}: season.log에서 그 차례가 남긴 구간
var turns: Array[Dictionary] = []
var _from := 0


func _init(count: int, seed_value: int) -> void:
	players = clampi(count, MIN_PLAYERS, MAX_PLAYERS)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var bag := Cards.full_bag()
	for i in REMOVE[players]:
		bag.remove_at(rng.randi_range(0, bag.size() - 1))
	for p in players:
		var f := Forest.new()
		f.grows = true
		forests.append(f)
	season = Season.new(bag, rng.randi(), forests[0])
	hands.append(season.hand)
	for p in range(1, players):
		var h: Array[Dictionary] = []
		season.hand = h
		season.deal(Season.START_HAND)
		hands.append(h)
	_seat(0)
	_from = season.log.size()


func over() -> bool:
	return season.over


func hand_of(p: int) -> Array[Dictionary]:
	return hands[p]


## p가 a를 하려 한다. 차례가 아니거나 규칙에 맞지 않으면 false(아무것도 바뀌지 않는다).
func act(p: int, a: Dictionary) -> bool:
	if season.over or p != turn:
		return false
	var s := season
	var logged := s.log.size()
	var ok := false
	match String(a.get("k", "")):
		"draw":
			ok = s.draw(int(a.get("from", -1)))
		"play":
			ok = s.play(int(a.get("id", -1)), int(a.get("half", 0)), int(a.get("plot", -1)), _ints(a.get("pay", [])), _ints(a.get("picks", [])))
		"sapling":
			ok = s.sapling(int(a.get("id", -1)), int(a.get("plot", -1)))
		"stash":
			ok = s.stash(_ints(a.get("ids", [])))
		"skip":
			ok = s.can_play_more() or s.wants_stash()
			if ok:
				s.skip()
	# 덱에서 마지막 바람이 나오면 draw는 false지만 계절은 끝났다: 기록해야 다시 돌려도 같다.
	if not ok and s.log.size() == logged:
		return false
	actions.append(a)
	if _turn_done():
		_next()
	return true


## 다른 숲과 견주는 점수(피나무·오색딱따구리)를 넣어 p의 숲을 센다.
func score_of(p: int) -> ScoreLog:
	return Score.count(forests[p], 0, mods_for(p))


func mods_for(p: int) -> Dictionary:
	var others: Array = forests.duplicate()
	others.remove_at(p)
	return {rivals = Score.rivals(others)}


## 끝난 판의 순위: [{who, total}] 점수 높은 순. 동점이면 굴 카드가 많은 쪽이 앞.
func ranking() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in players:
		out.append({who = p, total = score_of(p).total, cave = forests[p].cave.size()})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.total > b.total or (a.total == b.total and (a.cave > b.cave or (a.cave == b.cave and a.who < b.who))))
	return out


## 이번 차례가 끝났는지: 2장 가져왔거나(손패가 가득 차 더 못 가져오면 1장도), 냈고 남은 기회가 없을 때
func _turn_done() -> bool:
	var s := season
	if s.over:
		return true
	if s.draws() > 0:
		return not s.can_draw()
	return s.played() and not s.can_play_more() and not s.wants_stash()


func _next() -> void:
	var again := false
	for i in range(_from, season.log.size()):
		if season.log[i].t == &"again":
			again = true
	season.end_turn()
	turns.append({who = turn, from = _from, to = season.log.size(), again = again})
	_from = season.log.size()
	if season.over:
		return
	_seat(turn if again else (turn + 1) % players)


func _seat(p: int) -> void:
	turn = p
	season.hand = hands[p]
	season.forest = forests[p]


static func _ints(v: Variant) -> Array[int]:
	var out: Array[int] = []
	if v is Array:
		for x in v:
			out.append(int(x))
	return out

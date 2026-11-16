class_name Week
extends RefCounted
## 한 주: 월~금 5판. 판마다 시드가 주 시드에서 정해지고, 금요일은 사건 카드가 켜진다.

const DAYS := 5
const FRIDAY := 4

var week_seed := 0
var side := Match.Side.CHIEF
var level := Bot.Level.NORMAL
## 월~목에도 사건 카드를 켤지(제목 화면 설정).
var events := false
var wins: Array[bool] = []


static func start(seed_value: int, s: int, lvl: Bot.Level, ev: bool) -> Week:
	var w := Week.new()
	w.week_seed = seed_value
	w.side = s
	w.level = lvl
	w.events = ev
	return w


## 지금 둘 판(0=월요일). 다 끝나면 DAYS.
func day() -> int:
	return wins.size()


func is_done() -> bool:
	return wins.size() >= DAYS


func day_seed(d := day()) -> int:
	return hash("%d:day%d" % [week_seed, d]) & 0x7fffffff


func events_on(d := day()) -> bool:
	return events or d == FRIDAY


func record(won: bool) -> void:
	if not is_done():
		wins.append(won)


## 이긴 판 수(팀장이면 잡은 땡땡이, 사원이면 정시 퇴근).
func score() -> int:
	return wins.count(true)


## 주간 평가 0~3: 0승, 1~2승, 3~4승, 5승.
func grade() -> int:
	var s := score()
	return 3 if s == DAYS else (2 if s >= 3 else (1 if s >= 1 else 0))


func to_dict() -> Dictionary:
	return { seed = week_seed, side = side, level = level, events = events, wins = wins.duplicate() }


static func from_dict(d: Dictionary) -> Week:
	var w := Week.start(d.get("seed", 0), d.get("side", Match.Side.CHIEF), d.get("level", Bot.Level.NORMAL), d.get("events", false))
	for v in d.get("wins", []):
		w.wins.append(bool(v))
	w.wins.resize(mini(w.wins.size(), DAYS))
	return w

class_name Ledger
extends RefCounted
## 해금 장부: 런 사이에 남는 것. 기록, 도감(본 꿀팁·전단지·진상 손님·날씨), 해금 과제.
## 과제를 채우면 꿀팁이 발주에 나오기 시작한다. 능력치는 오르지 않고 고를 거리만 늘어난다.

## 과제 id → 풀리는 꿀팁
const CHALLENGES := {
	&"reach_3": &"order",
	&"serve_boss_3": &"tribe",
	&"big_checkout": &"duo",
	&"flush_3": &"store_tour",
	&"meal_set_5": &"trio",
	&"rich": &"last_five",
	&"full_tips": &"veteran",
	&"no_skip_5": &"premium",
	&"all_weather": &"routine",
	&"win": &"three_price",
}
const BIG_CHECKOUT := 50000
const RICH := 20000
const KINDS: Array[StringName] = [&"tip", &"flyer", &"boss", &"weather"]

var runs := 0
var wins := 0
var best_night := 0
var best_checkout := 0
## 종류 → {id: 본 횟수}
var seen := {&"tip": {}, &"flyer": {}, &"boss": {}, &"weather": {}}
var done := {}


func locked_tips() -> Array:
	var out := []
	for id in CHALLENGES:
		if not done.has(id):
			out.append(CHALLENGES[id])
	return out


static func total(kind: StringName) -> int:
	match kind:
		&"tip":
			return Tips.MAKERS.size()
		&"flyer":
			return Flyers.PICKS.size()
		&"boss":
			return Bosses.MAKERS.size()
	return Weather.MAKERS.size() + 1


## 끝난 런을 장부에 적는다. 새로 풀린 꿀팁 id를 돌려준다.
func record(run: Run) -> Array[StringName]:
	runs += 1
	if run.phase == Run.Phase.WON:
		wins += 1
	best_night = maxi(best_night, run.night)
	best_checkout = maxi(best_checkout, run.best_checkout)
	_see(&"tip", run.bought_tips)
	_see(&"flyer", run.used_flyers + run.flyers)
	var faced: Array = run.history.filter(func(h: Dictionary) -> bool: return h.slot == Run.BOSS).map(func(h: Dictionary) -> StringName: return run.bosses[h.night - 1])
	if run.slot == Run.BOSS and not run.history.any(func(h: Dictionary) -> bool: return h.night == run.night and h.slot == Run.BOSS):
		faced.append(run.boss_id())
	_see(&"boss", faced)
	_see(&"weather", run.weather.slice(0, run.night))
	var fresh: Array[StringName] = []
	for id in CHALLENGES:
		if not done.has(id) and met(id, run):
			done[id] = true
			fresh.append(CHALLENGES[id])
	return fresh


func met(id: StringName, run: Run) -> bool:
	match id:
		&"reach_3":
			return run.night >= 3
		&"serve_boss_3":
			return run.history.filter(func(h: Dictionary) -> bool: return h.slot == Run.BOSS and h.cleared).size() >= 3
		&"big_checkout":
			return run.best_checkout >= BIG_CHECKOUT
		&"flush_3":
			return run.combo_counts.get(Combo.Kind.FLUSH, 0) >= 3
		&"meal_set_5":
			return run.combo_counts.get(Combo.Kind.MEAL_SET, 0) >= 5
		&"rich":
			return run.best_money >= RICH
		&"full_tips":
			return run.max_tips >= Run.TIP_SLOTS
		&"no_skip_5":
			return run.night >= 5 and not run.history.any(func(h: Dictionary) -> bool: return h.skipped)
		&"all_weather":
			return seen[&"weather"].size() >= total(&"weather")
		&"win":
			return run.phase == Run.Phase.WON
	return false


func _see(kind: StringName, ids: Array) -> void:
	for id in ids:
		seen[kind][StringName(id)] = seen[kind].get(StringName(id), 0) + 1


func to_dict() -> Dictionary:
	var s := {}
	for k in KINDS:
		s[String(k)] = seen[k]
	return {"runs": runs, "wins": wins, "best_night": best_night, "best_checkout": best_checkout, "seen": s, "done": done.keys()}


static func from_dict(d: Dictionary) -> Ledger:
	var l := Ledger.new()
	l.runs = int(d.get("runs", 0))
	l.wins = int(d.get("wins", 0))
	l.best_night = int(d.get("best_night", 0))
	l.best_checkout = int(d.get("best_checkout", 0))
	var s: Dictionary = d.get("seen", {})
	for k in KINDS:
		var src: Dictionary = s.get(String(k), {})
		for id in src:
			l.seen[k][StringName(id)] = int(src[id])
	for id in d.get("done", []):
		if CHALLENGES.has(StringName(id)):
			l.done[StringName(id)] = true
	return l

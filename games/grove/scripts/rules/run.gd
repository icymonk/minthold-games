class_name Run
extends RefCounted
## 한 해(규칙 1-3): 봄→여름→가을→겨울. 숲·씨앗 주머니·정령·솔방울는 계절 사이에 남는다.
## begin() → Season을 끝까지 → finish()(점수·목표·솔방울·보상 3장) → take()/buy() → begin() ...
## 계절 덱은 매번 씨앗 주머니 전체를 섞어 만든다(숲에 심은 카드도 씨앗으로 다시 돌아온다).

const TARGETS := [35, 150, 400, 800]
## 솔방울 = 목표 넘긴 점수 / OVER_PER_ACORN + 남은 덱 / DECK_PER_ACORN (4-3에서 조정)
const OVER_PER_ACORN := 10
const DECK_PER_ACORN := 4
## 끝없는 해(4-2): 한 해 지날 때마다 목표 +75%
const YEAR_STEP := 0.75

var rng := RandomNumberGenerator.new()
var bag: Array[Dictionary] = []
var forest := Forest.new()
var spirits: Array[StringName] = []
var acorns := 0
## 계절마다 미리 정해진 사건 id
var events: Array[StringName] = []
var season_index := 0
var season: Season
var scores: Array[ScoreLog] = []
var offers: Array[Dictionary] = []
var lost := false
var done := false
var _next_id := 0
## 숲지기와 숲 등급(4-1)
var keeper: StringName = &"grandma"
var grade := 0
## 끝없는 해: 0 = 첫해. noted = 이 런을 기록에 한 번 셌음. daily = 오늘의 숲 날짜(아니면 "")
var year := 0
var noted := false
var daily := ""


func _init(seed_value: int, keeper_id: StringName = &"grandma", grade_value := 0) -> void:
	rng.seed = seed_value
	keeper = keeper_id
	grade = grade_value
	bag = Cards.start_bag()
	var k := Keepers.def_of(keeper)
	for p in k.pairs:
		bag.append(Cards.pair(bag.size(), p[0], p[1], p[2], p[3]))
	acorns = k.acorns
	_next_id = bag.size()
	_roll_events()


func _roll_events() -> void:
	events.clear()
	for s in Events.BY_SEASON.size():
		var ids: Array = Events.BY_SEASON[s].keys()
		events.append(ids[rng.randi_range(0, ids.size() - 1)])


func new_id() -> int:
	_next_id += 1
	return _next_id - 1


func target() -> int:
	return target_of(season_index)


func target_of(i: int) -> int:
	return int(round(TARGETS[i] * Keepers.grade_mods(grade).target * (1.0 + YEAR_STEP * year) / 5.0)) * 5


## 겨울을 넘긴 숲으로 다음 해 봄을 시작한다. 숲·주머니·정령·솔방울는 그대로.
func next_year() -> bool:
	if not done or lost:
		return false
	year += 1
	season_index = 0
	done = false
	_roll_events()
	offers = Reward.roll(rng, self)
	return true


## 올해 계절 점수들
func year_scores() -> Array[ScoreLog]:
	var out: Array[ScoreLog] = []
	out.assign(scores.slice(year * TARGETS.size()))
	return out


func total() -> int:
	var n := 0
	for s in scores:
		n += s.total
	return n


## 고른 정령 + 숲지기 정령
func owned() -> Array[StringName]:
	var out := spirits.duplicate()
	var s: StringName = Keepers.def_of(keeper).spirit
	if s != &"" and not out.has(s):
		out.append(s)
	return out


## 이번 계절 사건의 규칙(겨울잠 곰이 있으면 겨울 사건은 없음)
func event() -> Dictionary:
	if season_index == 3 and Spirits.value(owned(), "ignore_winter", false):
		return {}
	return Events.def_of(season_index, events[season_index])


func score_mods() -> Dictionary:
	return {score = event().get("score", []), cave = Spirits.value(owned(), "cave", 1)}


func begin() -> Season:
	var e := event()
	var g := Keepers.grade_mods(grade)
	var winds: int = e.get("winds", Season.WINDS) + (g.winter_winds if season_index == 3 else 0)
	season = Season.new(bag, rng.randi(), forest, winds)
	season.hand_limit = e.get("hand", Season.HAND_LIMIT) + Spirits.value(owned(), "hand", 0) + g.hand
	season.clearing_limit = e.get("clearing", Season.CLEARING_LIMIT) + Spirits.value(owned(), "clearing", 0) + g.clearing
	season.wind_bonus = Spirits.value(owned(), "wind_draw", 0)
	season.deal(Spirits.value(owned(), "start_draw", 0))
	offers.clear()
	return season


## 계절 끝: 점수를 세고 목표와 비교한다. 넘으면 솔방울와 보상 3장, 아니면 런 끝.
func finish() -> ScoreLog:
	var e := event()
	if e.get("cut_bare", false):
		forest.cut_bare()
	var log := Score.count(forest, season_index, score_mods())
	log.apply(Spirits.mult(forest, owned(), season_index))
	scores.append(log)
	if log.total < target():
		lost = true
		return log
	var left := season.deck.filter(func(c: Dictionary) -> bool: return not c.get("wind", false)).size()
	acorns += int(((log.total - target()) / OVER_PER_ACORN + left / DECK_PER_ACORN) * e.get("acorns", 1.0) * Keepers.grade_mods(grade).acorns)
	acorns += Spirits.value(owned(), "acorns", 0)
	season_index += 1
	if season_index >= TARGETS.size():
		done = true
	else:
		offers = Reward.roll(rng, self)
	return log


## 보상 하나 고르기. remove는 빼낼 카드 id 2개를 ids로.
func take(i: int, ids: Array[int] = []) -> bool:
	if i < 0 or i >= offers.size():
		return false
	var o := offers[i]
	if not _grant(o, ids):
		return false
	offers.clear()
	return true


## 솔방울 가게: {t = pair|spirit|remove|land|deco, ...}. deco는 꾸밀 카드 id 하나를 ids로.
func buy(item: Dictionary, ids: Array[int] = []) -> bool:
	var price: int = Reward.PRICES[item.t]
	if acorns < price:
		return false
	if item.t == &"land":
		if not forest.expand():
			return false
	elif not _grant(item, ids):
		return false
	acorns -= price
	return true


func _grant(o: Dictionary, ids: Array[int]) -> bool:
	match o.t:
		&"pair":
			for c in o.cards:
				bag.append(c)
		&"spirit":
			if spirits.size() >= Spirits.SLOTS or owned().has(o.id):
				return false
			spirits.append(o.id)
		&"remove":
			if ids.size() != Reward.REMOVE or bag.size() <= 12:
				return false
			for id in ids:
				if not bag.any(func(c: Dictionary) -> bool: return c.id == id):
					return false
			bag = bag.filter(func(c: Dictionary) -> bool: return not ids.has(c.id))
		&"deco":
			if ids.size() != 1:
				return false
			for c in bag:
				if c.id == ids[0] and not c.has("deco"):
					c.deco = o.deco
					return true
			return false
	return true

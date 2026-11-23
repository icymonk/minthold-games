class_name Run
extends RefCounted
## 한 해(규칙 1-3): 봄→여름→가을→겨울. 숲·씨앗 주머니·정령·도토리는 계절 사이에 남는다.
## begin() → Season을 끝까지 → finish()(점수·목표·도토리·보상 3장) → take()/buy() → begin() ...
## 계절 덱은 매번 씨앗 주머니 전체를 섞어 만든다(숲에 심은 카드도 씨앗으로 다시 돌아온다).

const TARGETS := [40, 110, 220, 380]
## 도토리 = 목표 넘긴 점수 / OVER_PER_ACORN + 남은 덱 / DECK_PER_ACORN (4-3에서 조정)
const OVER_PER_ACORN := 10
const DECK_PER_ACORN := 4

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


func _init(seed_value: int) -> void:
	rng.seed = seed_value
	bag = Cards.start_bag()
	_next_id = bag.size()
	for s in Events.BY_SEASON.size():
		var ids: Array = Events.BY_SEASON[s].keys()
		events.append(ids[rng.randi_range(0, ids.size() - 1)])


func new_id() -> int:
	_next_id += 1
	return _next_id - 1


func target() -> int:
	return TARGETS[season_index]


## 이번 계절 사건의 규칙(겨울잠 곰이 있으면 겨울 사건은 없음)
func event() -> Dictionary:
	if season_index == 3 and Spirits.value(spirits, "ignore_winter", false):
		return {}
	return Events.def_of(season_index, events[season_index])


func score_mods() -> Dictionary:
	return {score = event().get("score", []), cave = Spirits.value(spirits, "cave", 1)}


func begin() -> Season:
	var e := event()
	season = Season.new(bag, rng.randi(), forest, e.get("winds", Season.WINDS))
	season.hand_limit = e.get("hand", Season.HAND_LIMIT) + Spirits.value(spirits, "hand", 0)
	season.clearing_limit = e.get("clearing", Season.CLEARING_LIMIT) + Spirits.value(spirits, "clearing", 0)
	season.wind_bonus = Spirits.value(spirits, "wind_draw", 0)
	season.deal(Spirits.value(spirits, "start_draw", 0))
	offers.clear()
	return season


## 계절 끝: 점수를 세고 목표와 비교한다. 넘으면 도토리와 보상 3장, 아니면 런 끝.
func finish() -> ScoreLog:
	var e := event()
	if e.get("cut_bare", false):
		forest.cut_bare()
	var log := Score.count(forest, season_index, score_mods())
	log.apply(Spirits.mult(forest, spirits, season_index))
	scores.append(log)
	if log.total < target():
		lost = true
		return log
	var left := season.deck.filter(func(c: Dictionary) -> bool: return not c.get("wind", false)).size()
	acorns += int(((log.total - target()) / OVER_PER_ACORN + left / DECK_PER_ACORN) * e.get("acorns", 1.0))
	acorns += Spirits.value(spirits, "acorns", 0)
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


## 도토리 가게: {t = pair|spirit|remove|land|deco, ...}. deco는 꾸밀 카드 id 하나를 ids로.
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
			if spirits.size() >= Spirits.SLOTS or spirits.has(o.id):
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

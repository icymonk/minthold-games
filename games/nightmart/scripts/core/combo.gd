class_name Combo
extends RefCounted
## 조합 10종 판정. 폐기 카드는 빼고 본다. 여러 조합이 되면 표에서 아래쪽(더 센) 것을 고른다.

enum Kind { NONE, SINGLE, PAIR, TWO_PAIR, MEAL_SET, TRIPLE, STRAIGHT, FLUSH, FULL_HOUSE, FOUR, STRAIGHT_FLUSH }

## [기본 매출, 기본 만족]
const BASE := {
	Kind.NONE: [0, 0],
	Kind.SINGLE: [500, 1],
	Kind.PAIR: [1000, 2],
	Kind.TWO_PAIR: [2000, 2],
	Kind.MEAL_SET: [2500, 3],
	Kind.TRIPLE: [3000, 3],
	Kind.STRAIGHT: [3000, 4],
	Kind.FLUSH: [3500, 4],
	Kind.FULL_HOUSE: [4000, 4],
	Kind.FOUR: [6000, 7],
	Kind.STRAIGHT_FLUSH: [10000, 8],
}
const NAME_KEYS := {
	Kind.NONE: "COMBO_NONE",
	Kind.SINGLE: "COMBO_SINGLE",
	Kind.PAIR: "COMBO_PAIR",
	Kind.TWO_PAIR: "COMBO_TWO_PAIR",
	Kind.MEAL_SET: "COMBO_MEAL_SET",
	Kind.TRIPLE: "COMBO_TRIPLE",
	Kind.STRAIGHT: "COMBO_STRAIGHT",
	Kind.FLUSH: "COMBO_FLUSH",
	Kind.FULL_HOUSE: "COMBO_FULL_HOUSE",
	Kind.FOUR: "COMBO_FOUR",
	Kind.STRAIGHT_FLUSH: "COMBO_STRAIGHT_FLUSH",
}
const MAX_CARDS := 5


## 꿀팁이 바꿀 수 있는 판정 규칙.
class Rules:
	extends RefCounted
	var run_len := 5
	var flush_len := 5
	var chilled_mult := 1.5


static func detect(cards: Array[Card], rules: Rules = null) -> Kind:
	if rules == null:
		rules = Rules.new()
	var live := cards.filter(func(c: Card) -> bool: return not c.is_waste())
	if live.is_empty():
		return Kind.NONE
	var counts := _rank_counts(live)
	var straight := _is_straight(live, rules.run_len)
	var flush := _is_flush(live, rules.flush_len)
	if _is_straight_flush(live, rules):
		return Kind.STRAIGHT_FLUSH
	if counts[0] >= 4:
		return Kind.FOUR
	if counts[0] >= 3 and counts.size() > 1 and counts[1] >= 2:
		return Kind.FULL_HOUSE
	if flush:
		return Kind.FLUSH
	if straight:
		return Kind.STRAIGHT
	if counts[0] >= 3:
		return Kind.TRIPLE
	if _is_meal_set(live):
		return Kind.MEAL_SET
	if counts[0] >= 2 and counts.size() > 1 and counts[1] >= 2:
		return Kind.TWO_PAIR
	if counts[0] >= 2:
		return Kind.PAIR
	return Kind.SINGLE


## 택배로 올린 레벨 1당 기본 매출의 절반(100원 단위)과 만족 +1.
static func base(kind: Kind, level := 1) -> Vector2i:
	var b: Array = BASE[kind]
	if kind == Kind.NONE:
		return Vector2i.ZERO
	var extra := maxi(level - 1, 0)
	return Vector2i(b[0] + extra * (b[0] / 200) * 100, b[1] + extra)


## 같은 가격 장수, 많은 순.
static func _rank_counts(cards: Array) -> Array[int]:
	var by_rank := {}
	for c: Card in cards:
		by_rank[c.rank] = by_rank.get(c.rank, 0) + 1
	var out: Array[int] = []
	out.assign(by_rank.values())
	out.sort()
	out.reverse()
	return out


## 서로 다른 가격이 run_len개 이상 이어지나. 13 다음은 1이 아니다.
static func _is_straight(cards: Array, run_len: int) -> bool:
	var has := {}
	for c: Card in cards:
		has[c.rank] = true
	var run := 0
	for r in range(1, 14):
		run = run + 1 if has.has(r) else 0
		if run >= run_len:
			return true
	return false


static func _is_flush(cards: Array, flush_len: int) -> bool:
	for corner in Card.CORNERS:
		if cards.filter(func(c: Card) -> bool: return c.counts_as(corner)).size() >= flush_len:
			return true
	return false


## 같은 코너 카드들만으로 이어진 줄이 되어야 한다.
static func _is_straight_flush(cards: Array, rules: Rules) -> bool:
	for corner in Card.CORNERS:
		var same := cards.filter(func(c: Card) -> bool: return c.counts_as(corner))
		if same.size() >= rules.flush_len and _is_straight(same, rules.run_len):
			return true
	return false


## 식사·간식·음료를 서로 다른 카드로 하나씩 채울 수 있나. PB는 빈 칸 하나를 채운다.
static func _is_meal_set(cards: Array) -> bool:
	var need: Array[StringName] = [Card.MEAL, Card.SNACK, Card.DRINK]
	var wild := 0
	var have := {}
	for c: Card in cards:
		if c.tag == Card.TAG_PB:
			wild += 1
		else:
			have[c.corner] = true
	var missing := need.filter(func(n: StringName) -> bool: return not have.has(n)).size()
	return missing <= wild

class_name Shop
extends RefCounted
## 발주 목록. 손님을 보낼 때마다 새로 연다.

const TIP := &"tip"
const PARCEL := &"parcel"
const PACK := &"pack"
const EXPANSION := &"expansion"

## 꿀팁 값은 등급마다 다르다(Tips.PRICE). TIP은 기준값이다.
const PRICES := {TIP: 5000, PARCEL: 3000, PACK: 4000, EXPANSION: 10000}
const REROLL_BASE := 5000
const REROLL_STEP := 1000
const PACK_SIZE := 3
## 상품 팩 카드에 꼬리표가 붙을 확률
const PACK_TAG_CHANCE := 0.4
const PACK_TAGS: Array[StringName] = [Card.TAG_DISCOUNT, Card.TAG_EVENT, Card.TAG_CHILLED, Card.TAG_PB]

## [{kind, id, price, sold}] — 꿀팁 2, 택배 2, 상품 팩 2, 매장 확장 1(남은 것이 있으면)
var offers: Array[Dictionary] = []
var reroll_cost := REROLL_BASE


static func roll(rng: RandomNumberGenerator, owned_tips: Array, owned_expansions: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var tip_pool := Tips.MAKERS.keys().filter(func(t: StringName) -> bool: return not owned_tips.has(t))
	for i in 2:
		var tier := _roll_rarity(rng)
		var pool := tip_pool.filter(func(t: StringName) -> bool: return Tips.rarity(t) == tier)
		var picked := _pick(rng, pool if not pool.is_empty() else tip_pool, 1)
		if picked.is_empty():
			break
		tip_pool.erase(picked[0])
		var o := _offer(TIP, picked[0])
		o.price = Tips.price(picked[0])
		out.append(o)
	for i in 2:
		out.append(_offer(PARCEL, rng.randi_range(Combo.Kind.SINGLE, Combo.Kind.STRAIGHT_FLUSH)))
	for i in 2:
		out.append(_offer(PACK, &"product"))
	for e in _pick(rng, Expansions.MAKERS.keys().filter(func(x: StringName) -> bool: return not owned_expansions.has(x)), 1):
		out.append(_offer(EXPANSION, e))
	return out


## 상품 팩을 열면 나오는 카드 3장.
static func open_pack(rng: RandomNumberGenerator) -> Array[Card]:
	var out: Array[Card] = []
	for i in PACK_SIZE:
		var c := Card.new(Card.CORNERS[rng.randi_range(0, Card.CORNERS.size() - 1)], rng.randi_range(1, 13))
		if rng.randf() < PACK_TAG_CHANCE:
			c.tag = PACK_TAGS[rng.randi_range(0, PACK_TAGS.size() - 1)]
		out.append(c)
	return out


static func _roll_rarity(rng: RandomNumberGenerator) -> StringName:
	var roll := rng.randi_range(1, 100)
	for tier in Tips.RARITIES:
		roll -= Tips.RARITY_WEIGHT[tier]
		if roll <= 0:
			return tier
	return Tips.COMMON


static func _offer(kind: StringName, offer_id: Variant) -> Dictionary:
	return {"kind": kind, "id": offer_id, "price": PRICES[kind], "sold": false}


static func _pick(rng: RandomNumberGenerator, pool: Array, n: int) -> Array:
	var left := pool.duplicate()
	var out := []
	while out.size() < n and not left.is_empty():
		out.append(left.pop_at(rng.randi_range(0, left.size() - 1)))
	return out

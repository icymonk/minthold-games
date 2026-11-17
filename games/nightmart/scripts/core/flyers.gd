class_name Flyers
extends RefCounted
## 전단지 12종(Balatro의 타로). 계산대에서 손패 카드를 골라 쓴다. 바뀐 카드는 덱에 그대로 남는다.

## id → [고를 카드 최소, 최대]
const PICKS := {
	&"discount": [1, 2],
	&"event": [1, 2],
	&"chilled": [1, 1],
	&"pb": [1, 1],
	&"gold": [1, 1],
	&"price_up": [1, 2],
	&"price_down": [1, 2],
	&"same_corner": [2, 3],
	&"copy": [1, 1],
	&"remove": [1, 2],
	&"match": [2, 2],
	&"cash": [0, 0],
}
const TAGS := {
	&"discount": Card.TAG_DISCOUNT,
	&"event": Card.TAG_EVENT,
	&"chilled": Card.TAG_CHILLED,
	&"pb": Card.TAG_PB,
	&"gold": Card.TAG_GOLD,
}
## 사장님 용돈: 가진 돈만큼, 최대 5천 원
const CASH_MAX := 5000
## 빼기 전단지로 덱을 이보다 작게 만들 수 없다.
const MIN_DECK := 20


static func fits(flyer_id: StringName, n: int) -> bool:
	var p: Array = PICKS[flyer_id]
	return n >= p[0] and n <= p[1]


## 카드를 바꾼다. 덱에 넣고 빼는 일과 돈은 Run이 한다.
static func apply(flyer_id: StringName, cards: Array[Card]) -> void:
	if TAGS.has(flyer_id):
		for c in cards:
			c.tag_with(TAGS[flyer_id])
		return
	match flyer_id:
		&"price_up":
			for c in cards:
				c.rank = mini(c.rank + 1, 13)
		&"price_down":
			for c in cards:
				c.rank = maxi(c.rank - 1, 1)
		&"same_corner":
			for c in cards:
				c.corner = cards[-1].corner
		&"match":
			cards[0].corner = cards[1].corner
			cards[0].rank = cards[1].rank
			cards[0].tag = cards[1].tag
			cards[0].shelf_life = cards[1].shelf_life

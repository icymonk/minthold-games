class_name Receipt
extends RefCounted
## 계산 한 번의 영수증. 점수 = (조합 매출 + 가격 합 × 100 + 꼬리표) × (조합 만족 + 꼬리표).
## 꿀팁(Hook)은 1-2에서 sales·satisfaction을 더 고친다.

const PRICE_UNIT := 100
const DISCOUNT_SALES := 500
const EVENT_SATISFACTION := 2
const CHILLED_MULT := 1.5

var kind: Combo.Kind = Combo.Kind.NONE
var sales := 0
var satisfaction := 0.0


static func ring_up(cards: Array[Card], levels: Dictionary = {}) -> Receipt:
	var r := Receipt.new()
	r.kind = Combo.detect(cards)
	var b := Combo.base(r.kind, levels.get(r.kind, 1))
	r.sales = b.x
	r.satisfaction = b.y
	var chilled := 0
	for c in cards:
		if c.is_waste():
			continue
		r.sales += c.rank * PRICE_UNIT
		match c.tag:
			Card.TAG_DISCOUNT:
				r.sales += DISCOUNT_SALES
			Card.TAG_EVENT:
				r.satisfaction += EVENT_SATISFACTION
			Card.TAG_CHILLED:
				chilled += 1
	r.satisfaction *= pow(CHILLED_MULT, chilled)
	return r


func total() -> int:
	return int(floor(sales * satisfaction))

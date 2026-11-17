class_name Receipt
extends RefCounted
## 계산 한 번의 영수증. 점수 = 매출 × 만족.
## 발동 순서: 조합 기본값 → 카드마다(가격 → 꼬리표 → 꿀팁 on_score_card) → 꿀팁 on_checkout(왼쪽부터).
## 바뀐 값은 log에 한 줄씩 남는다(연출·테스트·「무엇 때문에 졌나」가 같은 기록을 쓴다).

const PRICE_UNIT := 100
## 금박: 손에 남아 있으면 계산마다 돈
const GOLD_MONEY := 500
const DISCOUNT_SALES := 500
const EVENT_SATISFACTION := 2

var kind: Combo.Kind = Combo.Kind.NONE
var sales := 0
var satisfaction := 0.0
## 이번 계산으로 번 돈(원). 꿀팁이 더한다.
var money := 0
var cards: Array[Card] = []
## 계산할 때 손에 남아 있던 카드.
var held: Array[Card] = []
## 이번 계산을 포함한 남은 계산 수. 1이면 마지막 계산.
var checkouts_left := 1
var rules := Combo.Rules.new()
## [{source, sales, sat_add, sat_mul}]
var log: Array[Dictionary] = []
## 미리 보기 계산이면 꿀팁이 쌓는 값을 바꾸지 않는다.
var preview := false


static func ring_up(played: Array[Card], levels: Dictionary = {}, hooks: Array[Hook] = [], held_cards: Array[Card] = [], left := 1, is_preview := false) -> Receipt:
	var r := Receipt.new()
	r.preview = is_preview
	r.cards = played
	r.held = held_cards
	r.checkouts_left = left
	for h in hooks:
		h.modify_rules(r.rules)
	r.kind = Combo.detect(played, r.rules)
	if r.kind != Combo.Kind.NONE:
		var b := Combo.base(r.kind, levels.get(r.kind, 1))
		r.add("combo", b.x, b.y)
	for c in played:
		if c.is_waste():
			continue
		r.add(str(c), int(c.rank * PRICE_UNIT * r.rules.price_mult.get(c.corner, 1.0)), 0)
		match c.tag:
			Card.TAG_DISCOUNT:
				r.add("tag:discount", DISCOUNT_SALES, 0)
			Card.TAG_EVENT:
				r.add("tag:event", 0, EVENT_SATISFACTION)
			Card.TAG_CHILLED:
				r.multiply("tag:chilled", r.rules.chilled_mult)
		for h in hooks:
			h.on_score_card(r, c)
	for c in held_cards:
		if c.tag == Card.TAG_GOLD:
			r.money += GOLD_MONEY
	for h in hooks:
		h.on_checkout(r)
	return r


func add(source: String, sales_delta: int, sat_delta: float) -> void:
	sales += sales_delta
	satisfaction += sat_delta
	log.append({"source": source, "sales": sales_delta, "sat_add": sat_delta, "sat_mul": 1.0})


func multiply(source: String, factor: float) -> void:
	satisfaction *= factor
	log.append({"source": source, "sales": 0, "sat_add": 0.0, "sat_mul": factor})


func live_cards() -> Array[Card]:
	return cards.filter(func(c: Card) -> bool: return not c.is_waste())


func total() -> int:
	return int(floor(sales * satisfaction))

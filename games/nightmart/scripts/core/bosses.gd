class_name Bosses
extends RefCounted
## 진상 손님(밤의 세 번째 손님): 규칙 하나를 깨는 Hook. 꿀팁 뒤에 발동해서 마지막에 깎는다.

const AUDIT := &"audit"
const MAKERS := {
	&"card_only": CardOnly,
	&"pair_picky": PairPicky,
	&"drunk": Drunk,
	&"bag": Bag,
	&"barcode": Barcode,
	&"diet": Diet,
	&"coins": Coins,
	&"hurry": Hurry,
	&"armful": Armful,
	&"repeat": Repeat,
	&"no_coupon": NoCoupon,
	AUDIT: Audit,
}
const BAG_MONEY := 500
const ARMFUL_MAX := 3


static func make(boss_id: StringName) -> Hook:
	var h: Hook = MAKERS[boss_id].new()
	h.id = boss_id
	return h


## 1~7일째는 감사를 뺀 11종에서 겹치지 않게, 마지막 밤은 본사 감사.
static func roll(rng: RandomNumberGenerator, nights: int) -> Array[StringName]:
	var pool: Array[StringName] = []
	for k in MAKERS:
		if k != AUDIT:
			pool.append(k)
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t := pool[i]
		pool[i] = pool[j]
		pool[j] = t
	var out: Array[StringName] = []
	for n in nights - 1:
		out.append(pool[n % pool.size()])
	out.append(AUDIT)
	return out


## 카드만 내미는 손님: 생활 코너 카드 가격이 매출에 안 들어간다.
class CardOnly:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.corner == Card.GOODS:
			r.add(id, -c.rank * Receipt.PRICE_UNIT, 0)


## 1+1 따지는 손님: 1+1·2+2는 0점
class PairPicky:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.PAIR, Combo.Kind.TWO_PAIR]:
			r.multiply(id, 0.0)


## 술 취한 손님: 손패 -1
class Drunk:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.hand_size -= 1


## 봉투 달라는 손님: 계산할 때마다 돈 -500
class Bag:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		r.money -= BAG_MONEY


## 바코드 안 찍힘: 첫 계산은 0점
class Barcode:
	extends Hook
	var first := true

	func on_shift_start(_shift: Shift) -> void:
		first = true

	func on_checkout(r: Receipt) -> void:
		if first:
			r.multiply(id, 0.0)
		if not r.preview:
			first = false


## 다이어트 중: 간식 카드가 뒷면으로 나온다.
class Diet:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.hidden_corners.append(Card.SNACK)


## 거스름돈 동전으로: 바꾸기 0번
class Coins:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.swaps_left = 0


## 급한 손님: 계산 -1
class Hurry:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.checkouts_left = maxi(shift.checkouts_left - 1, 1)


## 한 아름 손님: 한 번에 3장까지만 계산
class Armful:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.max_cards = mini(shift.max_cards, ARMFUL_MAX)


## 같은 거 또?: 이미 계산한 조합은 0점
class Repeat:
	extends Hook
	var seen := {}

	func on_shift_start(_shift: Shift) -> void:
		seen.clear()

	func on_checkout(r: Receipt) -> void:
		if seen.has(r.kind):
			r.multiply(id, 0.0)
		if not r.preview:
			seen[r.kind] = true


## 쿠폰 안 받는 손님: 할인·행사 꼬리표가 효과 없음
class NoCoupon:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		match c.tag:
			Card.TAG_DISCOUNT:
				r.add(id, -Receipt.DISCOUNT_SALES, 0)
			Card.TAG_EVENT:
				r.add(id, 0, -Receipt.EVENT_SATISFACTION)


## 본사 감사: 꿀팁 하나가 꺼진다(Run이 고른다). 목표 ×3은 Run.FINAL_BOSS_MULT.
class Audit:
	extends Hook

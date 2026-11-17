class_name Expansions
extends RefCounted
## 매장 확장: 그 런 동안 계속 붙어 있는 Hook. 꿀팁보다 먼저 발동한다.

const MAKERS := {
	&"extra_register": ExtraRegister,
	&"storage": Storage,
	&"extra_swap": ExtraSwap,
	&"opening_event": OpeningEvent,
	&"atm": Atm,
	&"loyalty": Loyalty,
	&"hot_case": CornerPrice,
	&"snack_rack": CornerPrice,
	&"coffee_machine": CornerPrice,
	&"goods_shelf": CornerPrice,
	## 아래는 Run이 `has_expansion`으로 직접 본다(발주·정산·밤 전환).
	&"discount_deal": Passive,
	&"fridge_case": Passive,
	&"safe": Passive,
	&"cctv": Passive,
	&"big_pack": Passive,
	&"back_room": Passive,
}
const CORNER := {&"hot_case": Card.MEAL, &"snack_rack": Card.SNACK, &"coffee_machine": Card.DRINK, &"goods_shelf": Card.GOODS}
const CORNER_PRICE := 1.5
const OPENING_SALES := 2000
const ATM_MONEY := 200
const LOYALTY_BONUS := 500
const DISCOUNT := 0.75
const SAFE_INTEREST := 5000
const CCTV_PAYOUT := 2000
const BIG_PACK_SIZE := 4
const BACK_ROOM_REROLL := 2000


static func make(expansion_id: StringName) -> Hook:
	var h: Hook = MAKERS[expansion_id].new()
	h.id = expansion_id
	return h


## Run이 직접 효과를 보는 확장(발주·정산·밤 전환)
class Passive:
	extends Hook


## 계산대 하나 더: 계산 +1
class ExtraRegister:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.checkouts_left += 1


## 창고: 손패 +1
class Storage:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.hand_size += 1


## 교대 근무: 바꾸기 +1
class ExtraSwap:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.swaps_left += 1


## 오픈 이벤트: 손님마다 첫 계산 매출 +2000
class OpeningEvent:
	extends Hook
	var first := true

	func on_shift_start(_shift: Shift) -> void:
		first = true

	func on_checkout(r: Receipt) -> void:
		if first:
			r.add(id, OPENING_SALES, 0)
		if not r.preview:
			first = false


## ATM: 계산마다 돈 +200
class Atm:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		r.money += ATM_MONEY


## 포인트 적립: 남은 계산 1번당 보너스 +500
class Loyalty:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.leftover_unit += LOYALTY_BONUS


## 온장고·과자 진열대·커피 머신·생활용품 매대: 그 코너 가격 ×1.5
class CornerPrice:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		var c: StringName = CORNER[id]
		rules.price_mult[c] = rules.price_mult.get(c, 1.0) * CORNER_PRICE

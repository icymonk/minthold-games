class_name Tips
extends RefCounted
## 알바 꿀팁 40종. 등급은 흔함·보통·귀함이고, 만족을 곱하는 꿀팁은 귀함으로만 낸다(기획서 9장).

const MAKERS := {
	&"meal_pair": MealPair,
	&"pair_master": PairMaster,
	&"fridge_king": FridgeKing,
	&"waste_snack": WasteSnack,
	&"row_obsessed": RowObsessed,
	&"boss_nephew": BossNephew,
	&"three_am": ThreeAm,
	&"same_aisle": SameAisle,
	&"points": Points,
	&"last_five": LastFive,
	&"meal_clerk": CornerClerk,
	&"snack_clerk": CornerClerk,
	&"drink_clerk": CornerClerk,
	&"goods_clerk": CornerClerk,
	&"coffee": Coffee,
	&"same_price": SamePrice,
	&"three_price": ThreePrice,
	&"row_fan": RowFan,
	&"aisle_fan": AisleFan,
	&"set_menu": SetMenu,
	&"small_change": SmallChange,
	&"premium": Premium,
	&"odd_price": OddPrice,
	&"coin_jar": CoinJar,
	&"half_basket": HalfBasket,
	&"discount_hunter": DiscountHunter,
	&"event_fan": EventFan,
	&"opening": Opening,
	&"quick_hands": QuickHands,
	&"spare_swaps": SpareSwaps,
	&"recycling": Recycling,
	&"waste_disposal": WasteDisposal,
	&"last_train": LastTrain,
	&"routine": Routine,
	&"store_tour": StoreTour,
	&"duo": Duo,
	&"trio": Trio,
	&"order": Order,
	&"tribe": Tribe,
	&"veteran": Veteran,
}
const COMMON := &"common"
const UNCOMMON := &"uncommon"
const RARE := &"rare"
const RARITIES: Array[StringName] = [COMMON, UNCOMMON, RARE]
## 발주에 나올 확률(%)
const RARITY_WEIGHT := {COMMON: 70, UNCOMMON: 25, RARE: 5}
const PRICE := {COMMON: 4000, UNCOMMON: 6000, RARE: 8000}
const UNCOMMON_TIPS: Array[StringName] = [
	&"pair_master", &"fridge_king", &"waste_snack", &"row_obsessed", &"boss_nephew", &"same_aisle",
	&"three_price", &"row_fan", &"aisle_fan", &"premium", &"spare_swaps", &"recycling", &"waste_disposal", &"routine",
]
const RARE_TIPS: Array[StringName] = [&"three_am", &"last_five", &"store_tour", &"duo", &"trio", &"order", &"tribe", &"veteran"]
const NEPHEW_MONEY := 2000
const CLERK_CORNER := {&"meal_clerk": Card.MEAL, &"snack_clerk": Card.SNACK, &"drink_clerk": Card.DRINK, &"goods_clerk": Card.GOODS}


static func rarity(tip_id: StringName) -> StringName:
	if RARE_TIPS.has(tip_id):
		return RARE
	return UNCOMMON if UNCOMMON_TIPS.has(tip_id) else COMMON


static func price(tip_id: StringName) -> int:
	return PRICE[rarity(tip_id)]


## 가장 많이 겹친 가격의 장수(1+1이면 2).
static func most_same(r: Receipt) -> int:
	var counts := Combo._rank_counts(r.live_cards())
	return counts[0] if not counts.is_empty() else 0


static func make(tip_id: StringName) -> Hook:
	var h: Hook = MAKERS[tip_id].new()
	h.id = tip_id
	if h is CornerClerk:
		h.corner = CLERK_CORNER[tip_id]
	return h


## 컵라면엔 삼각김밥: 식사 카드 2장 이상 계산하면 만족 +4
class MealPair:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.live_cards().filter(func(c: Card) -> bool: return c.counts_as(Card.MEAL)).size() >= 2:
			r.add(id, 0, 4)


## 1+1 장인: 1+1을 계산할 때마다 만족 +1씩 쌓인다
class PairMaster:
	extends Hook
	var stacks := 0

	func on_checkout(r: Receipt) -> void:
		var next := stacks + (1 if r.kind == Combo.Kind.PAIR else 0)
		if next > 0:
			r.add(id, 0, next)
		if not r.preview:
			stacks = next


## 냉장고 정리왕: 냉장 ×1.5 대신 ×2
class FridgeKing:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		rules.chilled_mult = 2.0


## 폐기 도시락 야식: 손에 남은 폐기 1장당 만족 +2
class WasteSnack:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		var n := r.held.filter(func(c: Card) -> bool: return c.is_waste()).size()
		if n > 0:
			r.add(id, 0, 2 * n)


## 진열 줄 집착: 진열 줄이 4장으로도 된다
class RowObsessed:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		rules.run_len = mini(rules.run_len, 4)


## 사장님 조카: 계산할 때마다 돈 +2천, 바꾸기 1번 줄어듦
class BossNephew:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.swaps_left = maxi(shift.swaps_left - 1, 0)

	func on_checkout(r: Receipt) -> void:
		r.money += NEPHEW_MONEY


## 새벽 3시: 그 손님의 마지막 계산 점수 ×3
class ThreeAm:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.checkouts_left == 1:
			r.multiply(id, 3.0)


## 같은 코너 고집: 같은 코너가 4장으로 된다
class SameAisle:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		rules.flush_len = mini(rules.flush_len, 4)


## 포인트 적립: 계산한 카드 1장당 매출 +50씩 쌓인다
class Points:
	extends Hook
	var stacks := 0

	func on_checkout(r: Receipt) -> void:
		var next := stacks + 50 * r.live_cards().size()
		r.add(id, next, 0)
		if not r.preview:
			stacks = next


## 퇴근 5분 전: 남은 계산이 1번이면 만족 ×2
class LastFive:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.checkouts_left == 1:
			r.multiply(id, 2.0)


## 도시락·과자·음료·생활 담당: 그 코너 카드 1장당 만족 +1
class CornerClerk:
	extends Hook
	var corner: StringName

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.counts_as(corner):
			r.add(id, 0, 1)


## 커피 수혈: 만족 +4
class Coffee:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		r.add(id, 0, 4)


## 같은 가격 2장: 같은 가격이 2장 이상 있으면 만족 +6
class SamePrice:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if Tips.most_same(r) >= 2:
			r.add(id, 0, 6)


## 같은 가격 3장: 같은 가격이 3장 이상 있으면 만족 +12
class ThreePrice:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if Tips.most_same(r) >= 3:
			r.add(id, 0, 12)


## 진열 줄 팬: 진열 줄이 들어 있으면 만족 +12
class RowFan:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.STRAIGHT, Combo.Kind.STRAIGHT_FLUSH]:
			r.add(id, 0, 12)


## 코너 팬: 같은 코너가 들어 있으면 만족 +10
class AisleFan:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.FLUSH, Combo.Kind.STRAIGHT_FLUSH]:
			r.add(id, 0, 10)


## 세트 메뉴판: 한 끼 세트면 매출 +1,500
class SetMenu:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind == Combo.Kind.MEAL_SET:
			r.add(id, 1500, 0)


## 잔돈 모으기: 가격 5 이하 카드 1장당 매출 +300
class SmallChange:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.rank <= 5:
			r.add(id, 300, 0)


## 고급 진열: 가격 10 이상 카드 1장당 만족 +2
class Premium:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.rank >= 10:
			r.add(id, 0, 2)


## 홀수 손님: 홀수 가격 카드 1장당 매출 +300
class OddPrice:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.rank % 2 == 1:
			r.add(id, 300, 0)


## 동전 통: 계산한 카드 1장당 돈 +200
class CoinJar:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		r.money += 200 * r.live_cards().size()


## 반 바구니: 3장 이하로 계산하면 만족 +12
class HalfBasket:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.cards.size() <= 3:
			r.add(id, 0, 12)


## 할인 사냥꾼: 할인 카드 1장당 매출 +800 더
class DiscountHunter:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.tag == Card.TAG_DISCOUNT:
			r.add(id, 800, 0)


## 행사 매니아: 행사 카드 1장당 만족 +3 더
class EventFan:
	extends Hook

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.tag == Card.TAG_EVENT:
			r.add(id, 0, 3)


## 개시 손님: 손님마다 첫 계산 매출 +2,000
class Opening:
	extends Hook
	var first := true

	func on_shift_start(_shift: Shift) -> void:
		first = true

	func on_checkout(r: Receipt) -> void:
		if first:
			r.add(id, 2000, 0)
		if not r.preview:
			first = false


## 손 빠른 알바: 손님마다 바꾸기 +1
class QuickHands:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		shift.swaps_left += 1


## 바꾸기 아끼기: 남은 바꾸기 1번당 만족 +2
class SpareSwaps:
	extends Hook
	var shift_ref: WeakRef

	func on_shift_start(shift: Shift) -> void:
		shift_ref = weakref(shift)

	func on_checkout(r: Receipt) -> void:
		var shift: Shift = shift_ref.get_ref() if shift_ref else null
		if shift and shift.swaps_left > 0:
			r.add(id, 0, 2 * shift.swaps_left)


## 분리수거: 바꾸기를 할 때마다 이 메모 만족 +1 (계속 쌓임)
class Recycling:
	extends Hook
	var stacks := 0

	func on_discard(_shift: Shift, _cards: Array[Card]) -> void:
		stacks += 1

	func on_checkout(r: Receipt) -> void:
		if stacks > 0:
			r.add(id, 0, stacks)


## 폐기 처분: 함께 계산한 폐기 카드 1장당 매출 +1,000
class WasteDisposal:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		var n := r.cards.filter(func(c: Card) -> bool: return c.is_waste()).size()
		if n > 0:
			r.add(id, 1000 * n, 0)


## 막차 손님: 남은 계산이 1번이면 매출 +3,000
class LastTrain:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.checkouts_left == 1:
			r.add(id, 3000, 0)


## 루틴: 같은 조합을 이어서 계산할 때마다 만족 +3씩 쌓이고, 다른 조합이면 처음부터
class Routine:
	extends Hook
	var last := Combo.Kind.NONE
	var stacks := 0

	func on_checkout(r: Receipt) -> void:
		var next := stacks + 3 if r.kind == last else 0
		if next > 0:
			r.add(id, 0, next)
		if not r.preview:
			last = r.kind
			stacks = next


## 편의점 한 바퀴: 4코너가 다 들어 있으면 만족 ×3
class StoreTour:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		# PB 한 장은 빈 코너 하나만 채운다.
		var corners := {}
		var pb := 0
		for c in r.live_cards():
			if c.tag == Card.TAG_PB:
				pb += 1
			else:
				corners[c.corner] = true
		if corners.size() + pb >= Card.CORNERS.size():
			r.multiply(id, 3.0)


## 짝꿍: 같은 가격이 2장 이상 있으면 만족 ×2
class Duo:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if Tips.most_same(r) >= 2:
			r.multiply(id, 2.0)


## 삼총사: 같은 가격이 3장 이상 있으면 만족 ×3
class Trio:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if Tips.most_same(r) >= 3:
			r.multiply(id, 3.0)


## 줄 세우기: 진열 줄이 들어 있으면 만족 ×3
class Order:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.STRAIGHT, Combo.Kind.STRAIGHT_FLUSH]:
			r.multiply(id, 3.0)


## 코너 사수: 같은 코너가 들어 있으면 만족 ×2
class Tribe:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.FLUSH, Combo.Kind.STRAIGHT_FLUSH]:
			r.multiply(id, 2.0)


## 경력직: 손님을 받을 때마다 만족 ×0.1씩 커진다(×1부터)
class Veteran:
	extends Hook
	var served := 0

	func on_shift_start(_shift: Shift) -> void:
		served += 1

	func on_checkout(r: Receipt) -> void:
		r.multiply(id, 1.0 + 0.1 * served)

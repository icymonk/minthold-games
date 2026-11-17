class_name Tips
extends RefCounted
## 알바 꿀팁(기획서 4장 예시 10종). 3-1에서 데이터(.tres)로 옮기고 40종으로 늘린다.

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
}
const NEPHEW_MONEY := 2000


static func make(tip_id: StringName) -> Hook:
	var h: Hook = MAKERS[tip_id].new()
	h.id = tip_id
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

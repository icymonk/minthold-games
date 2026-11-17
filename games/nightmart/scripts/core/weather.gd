class_name Weather
extends RefCounted
## 밤 날씨: 그 밤 손님 3명 모두에게 붙는 Hook. 밤 지도에서 미리 보인다. 첫 밤은 맑음.

const CLEAR := &"clear"
const PAYDAY := &"payday"
const MAKERS := {
	&"rain": Rain,
	&"cold": Cold,
	&"world_cup": WorldCup,
	&"exam": Exam,
	&"blackout": Blackout,
	PAYDAY: Payday,
}
const TARGET_MULT := {&"world_cup": 1.2}
const BLACKOUT_CARDS := 2
const EXAM_SATISFACTION := 3.0


static func make(weather_id: StringName) -> Hook:
	var h: Hook = MAKERS[weather_id].new() if MAKERS.has(weather_id) else Payday.new()
	h.id = weather_id
	return h


static func roll(rng: RandomNumberGenerator, nights: int) -> Array[StringName]:
	var out: Array[StringName] = [CLEAR]
	var keys: Array = MAKERS.keys()
	for n in nights - 1:
		out.append(keys[rng.randi_range(0, keys.size() - 1)])
	return out


## 비: 생활 코너 가격 ×2(우산·봉투가 팔린다)
class Rain:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		rules.price_mult[Card.GOODS] = rules.price_mult.get(Card.GOODS, 1.0) * 2.0


## 한파: 음료 카드 만족 +1, 간식 가격 절반
class Cold:
	extends Hook

	func modify_rules(rules: Combo.Rules) -> void:
		rules.price_mult[Card.SNACK] = rules.price_mult.get(Card.SNACK, 1.0) * 0.5

	func on_score_card(r: Receipt, c: Card) -> void:
		if c.corner == Card.DRINK and not c.is_waste():
			r.add(id, 0, 1)


## 월드컵: 음료와 간식이 함께 든 계산 만족 ×2, 목표 ×1.2
class WorldCup:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		var cards := r.live_cards()
		if cards.any(func(c: Card) -> bool: return c.corner == Card.DRINK) and cards.any(func(c: Card) -> bool: return c.corner == Card.SNACK):
			r.multiply(id, 2.0)


## 시험 기간: 낱개·1+1 만족 +3
class Exam:
	extends Hook

	func on_checkout(r: Receipt) -> void:
		if r.kind in [Combo.Kind.SINGLE, Combo.Kind.PAIR]:
			r.add(id, 0, EXAM_SATISFACTION)


## 정전: 처음 손에 들어오는 카드 2장이 뒷면
class Blackout:
	extends Hook

	func on_shift_start(shift: Shift) -> void:
		for i in mini(BLACKOUT_CARDS, shift.draw_pile.size()):
			shift.hidden_cards.append(shift.draw_pile[-1 - i])


## 월급날: 손님 값 ×2(Run이 정산할 때). 맑음도 이 빈 Hook을 쓴다.
class Payday:
	extends Hook

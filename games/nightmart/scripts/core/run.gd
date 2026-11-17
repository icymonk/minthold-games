class_name Run
extends RefCounted
## 한 런 = 8일 밤 × 손님 3명. 손님을 보낼 때마다 돈을 받고 발주를 연다.
## 같은 seed에 같은 선택이면 같은 판이 나온다(용도별 RNG는 `RngStreams`).

enum Phase { SHIFT, SHOP, PACK, WON, LOST }

const NIGHTS := 8
const NORMAL := 0
const REGULAR := 1
const BOSS := 2
const BASE_TARGETS: Array[int] = [3000, 8000, 20000, 50000, 110000, 200000, 350000, 500000]
const SLOT_MULT: Array[float] = [1.0, 1.5, 2.0]
const FINAL_BOSS_MULT := 3.0
const PAYOUT: Array[int] = [3000, 4000, 5000]
## 목표를 한 배 넘길 때마다 1천 원, 최대 3천 원
const OVERKILL_UNIT := 1000
const OVERKILL_MAX := 3
const INTEREST_STEP := 5000
const INTEREST_UNIT := 1000
const INTEREST_MAX := 5000
const START_MONEY := 4000
const TIP_SLOTS := 5
const CONSUMABLE_SLOTS := 2
const FREE_PARCEL := &"free_parcel"
const SHOP_DISCOUNT := &"shop_discount"
const FREE_REROLL := &"free_reroll"
const FREE_FLYER := &"free_flyer"
const SKIP_REWARDS: Array[StringName] = [FREE_PARCEL, SHOP_DISCOUNT, FREE_REROLL, FREE_FLYER]

var rng: RngStreams
var phase := Phase.SHIFT
var night := 1
var slot := NORMAL
var money := START_MONEY
var deck: Array[Card]
var tips: Array[Hook] = []
var expansions: Array[Hook] = []
## 택배: 조합 Kind
var consumables: Array[int] = []
## 전단지 id. 택배와 같은 칸(CONSUMABLE_SLOTS)을 나눠 쓴다.
var flyers: Array[StringName] = []
var levels := {}
var shift: Shift
var shop := Shop.new()
var pack: Array[Card] = []
var skip_tokens: Array[StringName] = []
## 지금 손님을 건너뛰면 받는 보상(밤 지도에 미리 보인다). 진상 손님은 비어 있다.
var skip_reward: StringName = &""
## 마지막 손님 정산 {interest, payout, leftover, overkill, tips}
var last_pay := {}
## 손님마다 {night, slot, target, score, cleared, skipped}
var history: Array[Dictionary] = []
## 조합별 계산 횟수
var combo_counts := {}
## 밤마다 진상 손님·날씨 id(밤 지도에 미리 보인다)
var bosses: Array[StringName] = []
var weather: Array[StringName] = []
## 본사 감사가 끈 꿀팁 index. -1은 없음.
var off_tip := -1


func _init(run_seed: int) -> void:
	rng = RngStreams.new(run_seed)
	deck = Card.standard_deck()
	bosses = Bosses.roll(rng.night, NIGHTS)
	weather = Weather.roll(rng.night, NIGHTS)
	_start_shift()


static func target_for(n: int, s: int) -> int:
	var mult := SLOT_MULT[s]
	if n == NIGHTS and s == BOSS:
		mult = FINAL_BOSS_MULT
	return int(BASE_TARGETS[n - 1] * mult)


func target() -> int:
	return target_at(slot)


## 날씨까지 넣은 오늘 밤 손님 목표
func target_at(s: int) -> int:
	return int(target_for(night, s) * Weather.TARGET_MULT.get(weather_id(), 1.0))


func boss_id() -> StringName:
	return bosses[mini(night, NIGHTS) - 1]


func weather_id() -> StringName:
	return weather[mini(night, NIGHTS) - 1]


## 발동 순서: 매장 확장 → 날씨 → 꿀팁(감사가 끈 것 빼고) → 진상 손님
func hooks() -> Array[Hook]:
	var out: Array[Hook] = expansions.duplicate()
	out.append(Weather.make(weather_id()))
	for i in tips.size():
		if i != off_tip:
			out.append(tips[i])
	if slot == BOSS:
		out.append(Bosses.make(boss_id()))
	return out


func play(cards: Array[Card]) -> Receipt:
	if phase != Phase.SHIFT:
		return null
	var r := shift.play(cards)
	if r != null:
		combo_counts[r.kind] = combo_counts.get(r.kind, 0) + 1
		if shift.is_over():
			_end_shift()
	return r


func discard(cards: Array[Card]) -> bool:
	if phase != Phase.SHIFT:
		return false
	var ok := shift.discard(cards)
	if ok and shift.is_over():
		_end_shift()
	return ok


## 일반 손님·단골은 첫 행동 전에 건너뛸 수 있다. 돈 대신 건너뛰기 보상.
func can_skip() -> bool:
	return phase == Phase.SHIFT and slot != BOSS and shift.receipts.is_empty() and shift.discard_pile.is_empty()


func skip() -> bool:
	if not can_skip():
		return false
	if skip_reward == FREE_PARCEL:
		if _has_room(Shop.PARCEL):
			consumables.append(rng.shop.randi_range(Combo.Kind.SINGLE, Combo.Kind.STRAIGHT_FLUSH))
	elif skip_reward == FREE_FLYER:
		if _has_room(Shop.FLYER):
			flyers.append(Shop.random_flyer(rng.shop))
	else:
		skip_tokens.append(skip_reward)
	_record(false, true)
	_advance()
	return true


func buy(index: int) -> bool:
	if phase != Phase.SHOP or index < 0 or index >= shop.offers.size():
		return false
	var o := shop.offers[index]
	var price := price_of(index)
	if o.sold or money < price or not _has_room(o.kind):
		return false
	money -= price
	if price < o.price:
		skip_tokens.erase(SHOP_DISCOUNT)
	o.sold = true
	match o.kind:
		Shop.TIP:
			var tip := Tips.make(o.id)
			tip.set_meta(&"paid", price)
			tips.append(tip)
		Shop.PARCEL:
			consumables.append(o.id)
		Shop.FLYER:
			flyers.append(o.id)
		Shop.EXPANSION:
			expansions.append(Expansions.make(o.id))
		Shop.PACK:
			pack = Shop.open_pack(rng.shop)
			phase = Phase.PACK
	return true


## 상품 팩에서 한 장 고른다. -1이면 넘긴다.
func choose_pack(index: int) -> bool:
	if phase != Phase.PACK or index >= pack.size():
		return false
	if index >= 0:
		deck.append(pack[index])
	pack.clear()
	phase = Phase.SHOP
	return true


## 다음 발주 반값 보상이 있으면 한 번 반값이다.
func price_of(index: int) -> int:
	var price: int = shop.offers[index].price
	return price / 2 if skip_tokens.has(SHOP_DISCOUNT) else price


func reroll_price() -> int:
	return 0 if skip_tokens.has(FREE_REROLL) else shop.reroll_cost


func can_buy(index: int) -> bool:
	var o := shop.offers[index]
	return phase == Phase.SHOP and not o.sold and money >= price_of(index) and _has_room(o.kind)


func reroll() -> bool:
	if phase != Phase.SHOP or money < reroll_price():
		return false
	if skip_tokens.has(FREE_REROLL):
		skip_tokens.erase(FREE_REROLL)
	else:
		money -= shop.reroll_cost
		shop.reroll_cost += Shop.REROLL_STEP
	shop.offers = Shop.roll(rng.shop, _ids(tips), _ids(expansions))
	return true


func sell_tip(index: int) -> bool:
	if index < 0 or index >= tips.size() or phase in [Phase.WON, Phase.LOST]:
		return false
	money += sell_price(index)
	shift.hooks.erase(tips[index])
	tips.remove_at(index)
	if index == off_tip:
		off_tip = -1
	elif index < off_tip:
		off_tip -= 1
	return true


## 산 값의 절반. 반값으로 산 꿀팁은 그 값의 절반이다.
func sell_price(index: int) -> int:
	return int(tips[index].get_meta(&"paid", Tips.price(tips[index].id))) / 2


## 택배를 뜯어 그 조합을 1레벨 올린다. 손님을 받는 중에도 쓸 수 있다.
func use_consumable(index: int) -> bool:
	if index < 0 or index >= consumables.size() or phase in [Phase.WON, Phase.LOST]:
		return false
	var kind := consumables[index]
	consumables.remove_at(index)
	levels[kind] = levels.get(kind, 1) + 1
	return true


## 전단지를 쓴다. 카드를 고르는 전단지는 손님을 받는 중에 손패 카드에만 쓴다.
func can_use_flyer(index: int, cards: Array[Card]) -> bool:
	if index < 0 or index >= flyers.size() or phase in [Phase.WON, Phase.LOST]:
		return false
	var id := flyers[index]
	if not Flyers.fits(id, cards.size()):
		return false
	if cards.is_empty():
		return true
	if phase != Phase.SHIFT or shift.is_over() or not cards.all(func(c: Card) -> bool: return shift.hand.has(c)):
		return false
	return id != &"remove" or deck.size() - cards.size() >= Flyers.MIN_DECK


func use_flyer(index: int, cards: Array[Card] = []) -> bool:
	if not can_use_flyer(index, cards):
		return false
	var id := flyers[index]
	flyers.remove_at(index)
	match id:
		&"cash":
			money += clampi(money, 0, Flyers.CASH_MAX)
		&"copy":
			deck.append(cards[0].copy())
		&"remove":
			for c in cards:
				deck.erase(c)
				shift.hand.erase(c)
			shift._refill()
		_:
			Flyers.apply(id, cards)
	return true


func leave_shop() -> bool:
	if phase != Phase.SHOP:
		return false
	_advance()
	return true


func is_over() -> bool:
	return phase == Phase.WON or phase == Phase.LOST


func _end_shift() -> void:
	money += shift.money
	_record(shift.cleared(), false)
	if not shift.cleared():
		phase = Phase.LOST
		return
	var over := mini((shift.score - shift.target) / maxi(shift.target, 1), OVERKILL_MAX)
	last_pay = {
		"tips": shift.money,
		"interest": mini(maxi(money, 0) / INTEREST_STEP * INTEREST_UNIT, INTEREST_MAX),
		"payout": PAYOUT[slot] * (2 if weather_id() == Weather.PAYDAY else 1),
		"leftover": shift.leftover_bonus(),
		"overkill": over * OVERKILL_UNIT,
	}
	money += last_pay.interest + last_pay.payout + last_pay.leftover + last_pay.overkill
	if night == NIGHTS and slot == BOSS:
		phase = Phase.WON
		return
	phase = Phase.SHOP
	shop = Shop.new()
	shop.offers = Shop.roll(rng.shop, _ids(tips), _ids(expansions))


func _advance() -> void:
	slot += 1
	if slot > BOSS:
		slot = NORMAL
		night += 1
		for c in deck:
			c.age()
	_start_shift()


func _start_shift() -> void:
	phase = Phase.SHIFT
	off_tip = -1
	if slot == BOSS and boss_id() == Bosses.AUDIT and not tips.is_empty():
		off_tip = rng.night.randi_range(0, tips.size() - 1)
	shift = Shift.new(deck, target(), rng.deck, hooks(), levels)
	skip_reward = &"" if slot == BOSS else SKIP_REWARDS[rng.night.randi_range(0, SKIP_REWARDS.size() - 1)]


func _record(was_cleared: bool, skipped: bool) -> void:
	history.append({
		"night": night, "slot": slot, "target": shift.target,
		"score": shift.score, "cleared": was_cleared, "skipped": skipped,
	})


func _has_room(kind: StringName) -> bool:
	match kind:
		Shop.TIP:
			return tips.size() < TIP_SLOTS
		Shop.PARCEL, Shop.FLYER:
			return consumables.size() + flyers.size() < CONSUMABLE_SLOTS
	return true


static func _ids(hs: Array[Hook]) -> Array:
	return hs.map(func(h: Hook) -> StringName: return h.id)

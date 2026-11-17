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
const SKIP_REWARDS: Array[StringName] = [&"free_flyer", &"shop_discount", &"free_reroll"]

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
var levels := {}
var shift: Shift
var shop := Shop.new()
var pack: Array[Card] = []
var skip_tokens: Array[StringName] = []
## 마지막 손님 정산 {interest, payout, leftover, overkill, tips}
var last_pay := {}
## 손님마다 {night, slot, target, score, cleared, skipped}
var history: Array[Dictionary] = []
## 조합별 계산 횟수
var combo_counts := {}


func _init(run_seed: int) -> void:
	rng = RngStreams.new(run_seed)
	deck = Card.standard_deck()
	_start_shift()


static func target_for(n: int, s: int) -> int:
	var mult := SLOT_MULT[s]
	if n == NIGHTS and s == BOSS:
		mult = FINAL_BOSS_MULT
	return int(BASE_TARGETS[n - 1] * mult)


func target() -> int:
	return target_for(night, slot)


func hooks() -> Array[Hook]:
	var out: Array[Hook] = expansions.duplicate()
	out.append_array(tips)
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
	skip_tokens.append(SKIP_REWARDS[rng.night.randi_range(0, SKIP_REWARDS.size() - 1)])
	_record(false, true)
	_advance()
	return true


func buy(index: int) -> bool:
	if phase != Phase.SHOP or index < 0 or index >= shop.offers.size():
		return false
	var o := shop.offers[index]
	if o.sold or money < o.price or not _has_room(o.kind):
		return false
	money -= o.price
	o.sold = true
	match o.kind:
		Shop.TIP:
			tips.append(Tips.make(o.id))
		Shop.PARCEL:
			consumables.append(o.id)
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


func reroll() -> bool:
	if phase != Phase.SHOP or money < shop.reroll_cost:
		return false
	money -= shop.reroll_cost
	shop.reroll_cost += Shop.REROLL_STEP
	shop.offers = Shop.roll(rng.shop, _ids(tips), _ids(expansions))
	return true


func sell_tip(index: int) -> bool:
	if index < 0 or index >= tips.size() or phase in [Phase.WON, Phase.LOST]:
		return false
	shift.hooks.erase(tips[index])
	tips.remove_at(index)
	money += Shop.PRICES[Shop.TIP] / 2
	return true


## 택배를 뜯어 그 조합을 1레벨 올린다. 손님을 받는 중에도 쓸 수 있다.
func use_consumable(index: int) -> bool:
	if index < 0 or index >= consumables.size() or phase in [Phase.WON, Phase.LOST]:
		return false
	var kind := consumables[index]
	consumables.remove_at(index)
	levels[kind] = levels.get(kind, 1) + 1
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
		"payout": PAYOUT[slot],
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
	_start_shift()


func _start_shift() -> void:
	phase = Phase.SHIFT
	shift = Shift.new(deck, target(), rng.deck, hooks(), levels)


func _record(was_cleared: bool, skipped: bool) -> void:
	history.append({
		"night": night, "slot": slot, "target": shift.target,
		"score": shift.score, "cleared": was_cleared, "skipped": skipped,
	})


func _has_room(kind: StringName) -> bool:
	match kind:
		Shop.TIP:
			return tips.size() < TIP_SLOTS
		Shop.PARCEL:
			return consumables.size() < CONSUMABLE_SLOTS
	return true


static func _ids(hs: Array[Hook]) -> Array:
	return hs.map(func(h: Hook) -> StringName: return h.id)

class_name Bot
extends RefCounted
## 탐욕 봇: 지금 손패에서 가장 센 계산을 고르고, 남은 계산으로 모자라면 바꾼다.
## 발주에서는 꿀팁·매장 확장·택배를 살 수 있는 대로 산다. `tools/sim.gd`와 테스트가 쓴다.


static func step(run: Run) -> void:
	match run.phase:
		Run.Phase.SHIFT:
			_shift_step(run)
		Run.Phase.PACK:
			run.choose_pack(_best_pack_card(run.pack))
		Run.Phase.SHOP:
			_shop(run)


static func play_out(run: Run, max_steps := 2000) -> void:
	var steps := 0
	while not run.is_over() and steps < max_steps:
		step(run)
		steps += 1


static func best_play(shift: Shift) -> Array[Card]:
	var best: Array[Card] = []
	var best_total := -1
	var n := shift.hand.size()
	for mask in range(1, 1 << n):
		if _bits(mask) > Combo.MAX_CARDS:
			continue
		var pick: Array[Card] = []
		for i in n:
			if mask & (1 << i):
				pick.append(shift.hand[i])
		var t := shift.preview(pick).total()
		if t > best_total:
			best_total = t
			best = pick
	return best


static func _shift_step(run: Run) -> void:
	var s := run.shift
	var pick := best_play(s)
	var need := s.target - s.score
	var expected := s.preview(pick).total() * s.checkouts_left
	if expected < need and s.swaps_left > 0:
		var rest: Array[Card] = s.hand.filter(func(c: Card) -> bool: return not pick.has(c))
		rest.sort_custom(func(a: Card, b: Card) -> bool: return a.rank < b.rank)
		rest.resize(mini(rest.size(), Combo.MAX_CARDS))
		if not rest.is_empty() and run.discard(rest):
			return
	run.play(pick)


static func _shop(run: Run) -> void:
	for i in run.shop.offers.size():
		var o := run.shop.offers[i]
		if o.kind != Shop.PACK and run.buy(i) and o.kind == Shop.PARCEL:
			run.use_consumable(run.consumables.size() - 1)
	run.leave_shop()


static func _best_pack_card(cards: Array[Card]) -> int:
	var best := 0
	for i in cards.size():
		if cards[i].rank > cards[best].rank:
			best = i
	return best


static func _bits(x: int) -> int:
	var n := 0
	while x:
		n += x & 1
		x >>= 1
	return n

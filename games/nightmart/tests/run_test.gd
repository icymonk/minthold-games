extends GdUnitTestSuite


## 지금 손님을 바로 보낸다(목표 1).
func _clear(run: Run) -> Receipt:
	run.shift.target = 1
	return run.play(Bot.best_play(run.shift))


func test_targets() -> void:
	assert_int(Run.target_for(1, Run.NORMAL)).is_equal(3000)
	assert_int(Run.target_for(1, Run.REGULAR)).is_equal(4500)
	assert_int(Run.target_for(1, Run.BOSS)).is_equal(6000)
	assert_int(Run.target_for(7, Run.BOSS)).is_equal(700000)
	assert_int(Run.target_for(8, Run.BOSS)).is_equal(1500000)


func test_start() -> void:
	var run := Run.new(1)
	assert_int(run.phase).is_equal(Run.Phase.SHIFT)
	assert_int(run.money).is_equal(Run.START_MONEY)
	assert_int(run.shift.target).is_equal(3000)
	assert_int(run.shift.hand.size()).is_equal(Shift.HAND_SIZE)


func test_clear_pays_and_opens_shop() -> void:
	var run := Run.new(1)
	_clear(run)
	assert_int(run.phase).is_equal(Run.Phase.SHOP)
	# 시작 4천 → 이자 0, 일반 손님 3천, 남은 계산 3번 3천, 목표를 한참 넘겨 3천
	assert_dict(run.last_pay).is_equal({"tips": 0, "interest": 0, "payout": 3000, "leftover": 3000, "overkill": 3000})
	assert_int(run.money).is_equal(13000)
	assert_int(run.shop.offers.size()).is_equal(7)
	assert_bool(run.leave_shop()).is_true()
	assert_int(run.slot).is_equal(Run.REGULAR)
	assert_int(run.shift.target).is_equal(4500)


func test_interest_caps() -> void:
	var run := Run.new(1)
	run.money = 7000
	_clear(run)
	assert_int(run.last_pay.interest).is_equal(1000)
	run.leave_shop()
	run.money = 99000
	_clear(run)
	assert_int(run.last_pay.interest).is_equal(Run.INTEREST_MAX)


func test_fail_ends_run() -> void:
	var run := Run.new(1)
	run.shift.target = 999_999_999
	for i in Shift.CHECKOUTS:
		run.play([run.shift.hand[0]])
	assert_int(run.phase).is_equal(Run.Phase.LOST)
	assert_bool(run.is_over()).is_true()
	assert_bool(run.history[-1].cleared).is_false()
	assert_object(run.play([run.shift.hand[0]])).is_null()


func test_night_advances_after_boss() -> void:
	var run := Run.new(1)
	for i in 3:
		_clear(run)
		run.leave_shop()
	assert_int(run.night).is_equal(2)
	assert_int(run.slot).is_equal(Run.NORMAL)
	assert_int(run.shift.target).is_equal(8000)


func test_final_boss_wins() -> void:
	var run := Run.new(1)
	run.night = Run.NIGHTS
	run.slot = Run.BOSS
	run._start_shift()
	assert_int(run.shift.target).is_equal(1500000)
	_clear(run)
	assert_int(run.phase).is_equal(Run.Phase.WON)


func test_skip() -> void:
	var run := Run.new(1)
	assert_bool(run.skip()).is_true()
	assert_int(run.slot).is_equal(Run.REGULAR)
	assert_int(run.phase).is_equal(Run.Phase.SHIFT)
	assert_int(run.skip_tokens.size()).is_equal(1)
	assert_int(run.money).is_equal(Run.START_MONEY)
	run.play([run.shift.hand[0]])
	assert_bool(run.can_skip()).is_false()
	var swapped := Run.new(1)
	swapped.discard([swapped.shift.hand[0]])
	assert_bool(swapped.skip()).is_false()
	var boss := Run.new(1)
	boss.skip()
	boss.skip()
	assert_int(boss.slot).is_equal(Run.BOSS)
	assert_bool(boss.skip()).is_false()


func _offer(run: Run, kind: StringName) -> int:
	for i in run.shop.offers.size():
		if run.shop.offers[i].kind == kind:
			return i
	return -1


func test_buy_tip_and_sell() -> void:
	var run := Run.new(1)
	_clear(run)
	var i := _offer(run, Shop.TIP)
	var id: StringName = run.shop.offers[i].id
	assert_bool(run.buy(i)).is_true()
	assert_bool(run.buy(i)).is_false()
	assert_int(run.money).is_equal(8000)
	assert_str(run.tips[0].id).is_equal(id)
	assert_bool(run.sell_tip(0)).is_true()
	assert_int(run.money).is_equal(10500)
	assert_bool(run.tips.is_empty()).is_true()


func test_buy_needs_money_and_room() -> void:
	var run := Run.new(1)
	_clear(run)
	run.money = 100
	assert_bool(run.buy(_offer(run, Shop.TIP))).is_false()
	run.money = 100000
	for i in Run.TIP_SLOTS:
		run.tips.append(Tips.make(&"points"))
	assert_bool(run.buy(_offer(run, Shop.TIP))).is_false()
	assert_bool(run.buy(-1)).is_false()


func test_shop_offers_skip_owned() -> void:
	var rng := RandomNumberGenerator.new()
	var all := Tips.MAKERS.keys()
	var owned := all.slice(0, all.size() - 1)
	var offers := Shop.roll(rng, owned, Expansions.MAKERS.keys())
	var tips := offers.filter(func(o: Dictionary) -> bool: return o.kind == Shop.TIP)
	assert_int(tips.size()).is_equal(1)
	assert_str(tips[0].id).is_equal(all[-1])
	assert_bool(offers.any(func(o: Dictionary) -> bool: return o.kind == Shop.EXPANSION)).is_false()


func test_reroll_costs_more_each_time() -> void:
	var run := Run.new(1)
	_clear(run)
	assert_bool(run.reroll()).is_true()
	assert_int(run.money).is_equal(8000)
	assert_int(run.shop.reroll_cost).is_equal(6000)
	assert_bool(run.reroll()).is_true()
	assert_bool(run.reroll()).is_false()


func test_pack_adds_card() -> void:
	var run := Run.new(1)
	_clear(run)
	assert_bool(run.buy(_offer(run, Shop.PACK))).is_true()
	assert_int(run.phase).is_equal(Run.Phase.PACK)
	assert_int(run.pack.size()).is_equal(Shop.PACK_SIZE)
	assert_bool(run.leave_shop()).is_false()
	var picked := run.pack[2]
	assert_bool(run.choose_pack(2)).is_true()
	assert_int(run.deck.size()).is_equal(53)
	assert_object(run.deck[-1]).is_same(picked)
	assert_int(run.phase).is_equal(Run.Phase.SHOP)


func test_parcel_levels_combo() -> void:
	var run := Run.new(1)
	_clear(run)
	var i := _offer(run, Shop.PARCEL)
	var kind: int = run.shop.offers[i].id
	run.buy(i)
	assert_array(run.consumables).is_equal([kind])
	assert_bool(run.use_consumable(0)).is_true()
	assert_int(run.levels[kind]).is_equal(2)
	assert_bool(run.consumables.is_empty()).is_true()


func test_expansion_applies_next_shift() -> void:
	var run := Run.new(1)
	_clear(run)
	run.expansions.append(Expansions.make(&"extra_register"))
	run.expansions.append(Expansions.make(&"storage"))
	run.leave_shop()
	assert_int(run.shift.checkouts_left).is_equal(Shift.CHECKOUTS + 1)
	assert_int(run.shift.hand.size()).is_equal(Shift.HAND_SIZE + 1)


func test_tip_stacks_carry_over_shifts() -> void:
	var run := Run.new(1)
	var points := Tips.make(&"points")
	run.tips.append(points)
	run._start_shift()
	_clear(run)
	var after_first: int = points.stacks
	assert_int(after_first).is_greater(0)
	run.leave_shop()
	_clear(run)
	assert_int(points.stacks).is_greater(after_first)


func test_preview_does_not_stack() -> void:
	var run := Run.new(1)
	var points := Tips.make(&"points")
	run.tips.append(points)
	run._start_shift()
	Bot.best_play(run.shift)
	assert_int(points.stacks).is_equal(0)


func test_same_seed_same_run() -> void:
	var a := Run.new(42)
	var b := Run.new(42)
	Bot.play_out(a)
	Bot.play_out(b)
	assert_bool(a.is_over()).is_true()
	assert_array(a.history).is_equal(b.history)
	assert_int(a.money).is_equal(b.money)
	var c := Run.new(43)
	Bot.play_out(c)
	assert_array(c.history).is_not_equal(a.history)


func test_sold_tip_stops_during_shift() -> void:
	var run := Run.new(1)
	run.tips.append(Tips.make(&"boss_nephew"))
	run._start_shift()
	assert_bool(run.sell_tip(0)).is_true()
	assert_bool(run.shift.hooks.is_empty()).is_true()
	assert_int(run.play([run.shift.hand[0]]).money).is_equal(0)

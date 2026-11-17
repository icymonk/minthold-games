extends GdUnitTestSuite


func _run_with(ids: Array) -> Run:
	var run := Run.new(1)
	for id in ids:
		run.expansions.append(Expansions.make(id))
	return run


func test_every_expansion_has_text() -> void:
	assert_int(Expansions.MAKERS.size()).is_equal(16)
	for id in Expansions.MAKERS:
		var key := "EXP_%s" % String(id).to_upper()
		assert_str(TranslationServer.translate(key)).is_not_equal(key)
		assert_str(TranslationServer.translate(key + "_DESC")).is_not_equal(key + "_DESC")
		assert_object(Expansions.make(id)).is_not_null()


func test_shift_hooks() -> void:
	var hooks: Array[Hook] = [Expansions.make(&"extra_swap"), Expansions.make(&"loyalty")]
	var shift := Shift.new(Card.standard_deck(), 1000, RandomNumberGenerator.new(), hooks)
	assert_int(shift.swaps_left).is_equal(Shift.SWAPS + 1)
	assert_int(shift.leftover_unit).is_equal(Shift.LEFTOVER_BONUS + Expansions.LOYALTY_BONUS)


func test_opening_event_only_first_checkout() -> void:
	var hooks: Array[Hook] = [Expansions.make(&"opening_event"), Expansions.make(&"atm")]
	var shift := Shift.new(Card.standard_deck(), 10 ** 9, RandomNumberGenerator.new(), hooks)
	var one: Array[Card] = [shift.hand[0]]
	var preview := shift.preview(one)
	assert_bool(preview.log.any(func(e: Dictionary) -> bool: return e.source == "opening_event")).is_true()
	var first := shift.play(one)
	assert_bool(first.log.any(func(e: Dictionary) -> bool: return e.source == "opening_event")).is_true()
	assert_int(first.money).is_greater_equal(Expansions.ATM_MONEY)
	var two: Array[Card] = [shift.hand[0]]
	var second := shift.play(two)
	assert_bool(second.log.any(func(e: Dictionary) -> bool: return e.source == "opening_event")).is_false()


func test_corner_price() -> void:
	var rules := Combo.Rules.new()
	Expansions.make(&"hot_case").modify_rules(rules)
	Expansions.make(&"hot_case").modify_rules(rules)
	assert_float(rules.price_mult[Card.MEAL]).is_equal_approx(2.25, 0.001)


func test_run_level_expansions() -> void:
	var run := _run_with([&"discount_deal", &"cctv"])
	run.shop.offers = [{"kind": Shop.TIP, "id": &"three_am", "price": 4000}]
	assert_int(run.price_of(0)).is_equal(3000)
	assert_int(run.payout_at(Run.BOSS)).is_equal(Run.PAYOUT[Run.BOSS] + Expansions.CCTV_PAYOUT)
	assert_int(run.payout_at(Run.NORMAL)).is_equal(Run.PAYOUT[Run.NORMAL])


func test_big_pack_and_back_room() -> void:
	assert_int(Shop.open_pack(RandomNumberGenerator.new(), Expansions.BIG_PACK_SIZE).size()).is_equal(4)
	var run := _run_with([&"back_room"])
	run.shift.target = 1
	run.play(Bot.best_play(run.shift))
	assert_int(run.shop.reroll_cost).is_equal(Shop.REROLL_BASE - Expansions.BACK_ROOM_REROLL)


func test_fridge_case_keeps_chilled() -> void:
	var run := _run_with([&"fridge_case"])
	var c: Card = run.deck[0]
	c.tag = Card.TAG_CHILLED
	c.shelf_life = 2
	run.night = 1
	run.slot = Run.BOSS
	run._advance()
	assert_int(c.shelf_life).is_equal(2)

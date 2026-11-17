extends GdUnitTestSuite


func _run_with(flyer_id: StringName) -> Run:
	var run := Run.new(1)
	run.flyers.append(flyer_id)
	return run


func test_every_flyer_has_name_and_desc() -> void:
	assert_int(Flyers.PICKS.size()).is_equal(12)
	for id in Flyers.PICKS:
		assert_str(Names.flyer(id)).is_not_equal("FLYER_%s" % String(id).to_upper())
		assert_str(Names.flyer_desc(id)).is_not_equal("FLYER_%s_DESC" % String(id).to_upper())


func test_tag_flyer_sticks_to_deck_card() -> void:
	var run := _run_with(&"event")
	var c := run.shift.hand[0]
	assert_bool(run.use_flyer(0, [c])).is_true()
	assert_str(c.tag).is_equal(Card.TAG_EVENT)
	assert_bool(run.deck.has(c)).is_true()
	assert_bool(run.flyers.is_empty()).is_true()


func test_flyer_needs_right_card_count_and_hand_cards() -> void:
	var run := _run_with(&"match")
	assert_bool(run.use_flyer(0, [run.shift.hand[0]])).is_false()
	assert_bool(run.use_flyer(0, [Card.new(Card.MEAL, 1), Card.new(Card.MEAL, 2)])).is_false()
	var a := run.shift.hand[0]
	var b := run.shift.hand[1]
	assert_bool(run.use_flyer(0, [a, b])).is_true()
	assert_str(a.corner).is_equal(b.corner)
	assert_int(a.rank).is_equal(b.rank)


func test_price_and_corner_flyers() -> void:
	var cards := Card.parse("m13 s1 d5")
	Flyers.apply(&"price_up", [cards[0]])
	Flyers.apply(&"price_down", [cards[1]])
	assert_int(cards[0].rank).is_equal(13)
	assert_int(cards[1].rank).is_equal(1)
	Flyers.apply(&"same_corner", cards)
	for c in cards:
		assert_str(c.corner).is_equal(Card.DRINK)


func test_copy_and_remove_change_deck() -> void:
	var run := _run_with(&"copy")
	run.flyers.append(&"remove")
	var c := run.shift.hand[0]
	assert_bool(run.use_flyer(0, [c])).is_true()
	assert_int(run.deck.size()).is_equal(53)
	assert_bool(run.use_flyer(0, [c])).is_true()
	assert_int(run.deck.size()).is_equal(52)
	assert_bool(run.deck.has(c)).is_false()
	assert_bool(run.shift.hand.has(c)).is_false()
	assert_int(run.shift.hand.size()).is_equal(Shift.HAND_SIZE)


func test_remove_keeps_min_deck() -> void:
	var run := _run_with(&"remove")
	run.deck.resize(Flyers.MIN_DECK)
	run._start_shift()
	assert_bool(run.use_flyer(0, [run.shift.hand[0]])).is_false()


func test_cash_doubles_money_up_to_max() -> void:
	var run := _run_with(&"cash")
	run.money = 3000
	assert_bool(run.use_flyer(0)).is_true()
	assert_int(run.money).is_equal(6000)
	run.flyers.append(&"cash")
	assert_bool(run.use_flyer(0)).is_true()
	assert_int(run.money).is_equal(6000 + Flyers.CASH_MAX)


func test_gold_pays_while_held() -> void:
	var r := Receipt.ring_up(Card.parse("m5"), {}, [], Card.parse("s3$ d4$ g2"))
	assert_int(r.money).is_equal(Receipt.GOLD_MONEY * 2)
	assert_int(Receipt.ring_up(Card.parse("m5$"), {}, []).money).is_equal(0)


func test_flyers_share_parcel_slots() -> void:
	var run := Run.new(1)
	run.flyers.append(&"cash")
	run.consumables.append(Combo.Kind.PAIR)
	assert_bool(run._has_room(Shop.FLYER)).is_false()
	assert_bool(run._has_room(Shop.PARCEL)).is_false()


func test_shop_offers_one_flyer() -> void:
	var rng := RandomNumberGenerator.new()
	var offers := Shop.roll(rng, [], [])
	assert_int(offers.filter(func(o: Dictionary) -> bool: return o.kind == Shop.FLYER).size()).is_equal(1)
	assert_int(offers.filter(func(o: Dictionary) -> bool: return o.kind == Shop.PARCEL).size()).is_equal(2)


func test_skip_for_free_flyer() -> void:
	var run := Run.new(1)
	run.skip_reward = Run.FREE_FLYER
	assert_bool(run.skip()).is_true()
	assert_int(run.flyers.size()).is_equal(1)

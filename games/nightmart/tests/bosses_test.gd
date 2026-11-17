extends GdUnitTestSuite


func _shift(boss_id: StringName, deck := Card.standard_deck()) -> Shift:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return Shift.new(deck, 100000, rng, [Bosses.make(boss_id)])


func test_roll_has_eleven_distinct_and_audit_last() -> void:
	var rng := RandomNumberGenerator.new()
	var b := Bosses.roll(rng, Run.NIGHTS)
	assert_int(b.size()).is_equal(Run.NIGHTS)
	assert_str(b[-1]).is_equal(Bosses.AUDIT)
	var firsts := b.slice(0, Run.NIGHTS - 1)
	assert_bool(firsts.has(Bosses.AUDIT)).is_false()
	var uniq := {}
	for id in firsts:
		uniq[id] = true
	assert_int(uniq.size()).is_equal(Run.NIGHTS - 1)
	assert_int(Bosses.MAKERS.size()).is_equal(12)


func test_every_boss_and_weather_has_text() -> void:
	for id in Bosses.MAKERS:
		assert_str(Names.boss(id)).is_not_equal("BOSS_%s" % String(id).to_upper())
		assert_str(Names.boss_desc(id)).is_not_equal("BOSS_%s_DESC" % String(id).to_upper())
	var ws: Array = Weather.MAKERS.keys()
	ws.append(Weather.CLEAR)
	assert_int(Weather.MAKERS.size()).is_equal(6)
	for id in ws:
		assert_str(Names.weather(id)).is_not_equal("WEATHER_%s" % String(id).to_upper())


func test_shift_rules() -> void:
	assert_int(_shift(&"drunk").hand.size()).is_equal(Shift.HAND_SIZE - 1)
	assert_int(_shift(&"coins").swaps_left).is_equal(0)
	assert_int(_shift(&"hurry").checkouts_left).is_equal(Shift.CHECKOUTS - 1)
	var armful := _shift(&"armful")
	assert_bool(armful.can_play(armful.hand.slice(0, 4))).is_false()
	assert_bool(armful.can_play(armful.hand.slice(0, 3))).is_true()
	assert_bool(armful.can_discard(armful.hand.slice(0, 5))).is_true()
	var diet := _shift(&"diet")
	for c in diet.hand:
		assert_bool(diet.is_hidden(c)).is_equal(c.corner == Card.SNACK)


func test_score_rules() -> void:
	var picky: Array[Hook] = [Bosses.make(&"pair_picky")]
	assert_int(Receipt.ring_up(Card.parse("m5 s5"), {}, picky).total()).is_equal(0)
	assert_int(Receipt.ring_up(Card.parse("m5 s5 d5"), {}, picky).total()).is_greater(0)
	var card_only: Array[Hook] = [Bosses.make(&"card_only")]
	assert_int(Receipt.ring_up(Card.parse("g9"), {}, card_only).sales).is_equal(Receipt.ring_up(Card.parse("g9")).sales - 900)
	var coupon: Array[Hook] = [Bosses.make(&"no_coupon")]
	var plain := Receipt.ring_up(Card.parse("m5"))
	var tagged := Receipt.ring_up(Card.parse("m5+"), {}, coupon)
	assert_int(tagged.sales).is_equal(plain.sales)
	assert_int(Receipt.ring_up(Card.parse("m5"), {}, [Bosses.make(&"bag")]).money).is_equal(-Bosses.BAG_MONEY)


func test_barcode_and_repeat_only_count_real_checkouts() -> void:
	var s := _shift(&"barcode")
	assert_int(s.preview([s.hand[0]]).total()).is_equal(0)
	assert_int(s.play([s.hand[0]]).total()).is_equal(0)
	assert_int(s.play([s.hand[0]]).total()).is_greater(0)
	var hooks: Array[Hook] = [Bosses.make(&"repeat")]
	var rng := RandomNumberGenerator.new()
	var r := Shift.new(Card.parse("m1 m2 m3 m4 m5 m6 m7 m8 m9 m10"), 100000, rng, hooks)
	assert_int(r.preview([r.hand[0]]).total()).is_greater(0)
	assert_int(r.play([r.hand[0]]).total()).is_greater(0)
	assert_int(r.play([r.hand[0]]).total()).is_equal(0)


func test_audit_switches_off_one_tip() -> void:
	var run := Run.new(1)
	run.tips.append(Tips.make(&"three_am"))
	run.tips.append(Tips.make(&"points"))
	run.night = Run.NIGHTS
	run.slot = Run.BOSS
	run._start_shift()
	assert_int(run.off_tip).is_between(0, 1)
	assert_bool(run.shift.hooks.has(run.tips[run.off_tip])).is_false()
	assert_bool(run.shift.hooks.has(run.tips[1 - run.off_tip])).is_true()
	assert_str(run.shift.hooks[-1].id).is_equal(Bosses.AUDIT)
	run.sell_tip(run.off_tip)
	assert_int(run.off_tip).is_equal(-1)


func test_weather_rules() -> void:
	var rain: Array[Hook] = [Weather.make(&"rain")]
	assert_int(Receipt.ring_up(Card.parse("g4"), {}, rain).sales).is_equal(Receipt.ring_up(Card.parse("g4")).sales + 400)
	var cup: Array[Hook] = [Weather.make(&"world_cup")]
	assert_float(Receipt.ring_up(Card.parse("d5 s5"), {}, cup).satisfaction).is_equal(Receipt.ring_up(Card.parse("d5 s5")).satisfaction * 2)
	var exam: Array[Hook] = [Weather.make(&"exam")]
	assert_float(Receipt.ring_up(Card.parse("m5"), {}, exam).satisfaction).is_equal(Receipt.ring_up(Card.parse("m5")).satisfaction + 3)
	var rng := RandomNumberGenerator.new()
	var dark := Shift.new(Card.standard_deck(), 1000, rng, [Weather.make(&"blackout")])
	assert_int(dark.hand.filter(dark.is_hidden).size()).is_equal(Weather.BLACKOUT_CARDS)


func test_run_weather_targets_and_payday() -> void:
	var run := Run.new(1)
	assert_str(run.weather_id()).is_equal(Weather.CLEAR)
	run.weather[0] = &"world_cup"
	assert_int(run.target_at(Run.NORMAL)).is_equal(3600)
	run.weather[0] = Weather.PAYDAY
	run._start_shift()
	run.shift.score = run.shift.target
	run._end_shift()
	assert_int(run.payout_at(Run.BOSS)).is_equal(Run.PAYOUT[Run.BOSS] * 2)
	assert_int(run.last_pay.payout).is_equal(Run.PAYOUT[Run.NORMAL] * 2)


func test_same_seed_same_bosses_and_weather() -> void:
	var a := Run.new(7)
	var b := Run.new(7)
	assert_array(a.bosses).is_equal(b.bosses)
	assert_array(a.weather).is_equal(b.weather)


func test_shelf_life_ages_each_night() -> void:
	var run := Run.new(1)
	var bento: Card = run.deck.filter(func(c: Card) -> bool: return c.corner == Card.MEAL and c.rank == 12)[0]
	assert_int(bento.shelf_life).is_equal(Card.PERISHABLE_LIFE)
	var plain: Card = run.deck[0]
	assert_int(plain.shelf_life).is_equal(-1)
	for i in 3:
		run._advance()
	assert_int(run.night).is_equal(2)
	assert_int(bento.shelf_life).is_equal(Card.PERISHABLE_LIFE - 1)
	for i in Card.PERISHABLE_LIFE * 3:
		run._advance()
	assert_bool(bento.is_waste()).is_true()
	assert_int(plain.shelf_life).is_equal(-1)


func test_chilled_tag_starts_shelf_life() -> void:
	var c := Card.new(Card.SNACK, 5)
	c.tag_with(Card.TAG_CHILLED)
	assert_int(c.shelf_life).is_equal(Card.CHILLED_LIFE)
	var milk := Card.new(Card.DRINK, 4)
	milk.tag_with(Card.TAG_CHILLED)
	assert_int(milk.shelf_life).is_equal(Card.PERISHABLE_LIFE)


func test_card_only_zeroes_goods_even_in_rain() -> void:
	var hooks: Array[Hook] = [Weather.make(&"rain"), Bosses.make(&"card_only")]
	assert_int(Receipt.ring_up(Card.parse("g9"), {}, hooks).sales).is_equal(Receipt.ring_up(Card.parse("g9")).sales - 900)

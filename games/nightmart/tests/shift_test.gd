extends GdUnitTestSuite


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _shift(seed_value := 1, target := 1_000_000, tips: Array[Hook] = []) -> Shift:
	return Shift.new(Card.standard_deck(), target, _rng(seed_value), tips)


func _names(cards: Array[Card]) -> Array:
	return cards.map(func(c: Card) -> String: return str(c))


func test_same_seed_same_hand() -> void:
	var a := _shift(7)
	assert_int(a.hand.size()).is_equal(8)
	assert_int(a.draw_pile.size()).is_equal(44)
	assert_array(_names(_shift(7).hand)).is_equal(_names(a.hand))
	assert_array(_names(_shift(8).hand)).is_not_equal(_names(a.hand))


func test_play_scores_and_refills() -> void:
	var s := _shift()
	var picked: Array[Card] = [s.hand[0]]
	var r := s.play(picked)
	assert_object(r).is_not_null()
	assert_int(s.score).is_equal(r.total())
	assert_int(s.checkouts_left).is_equal(3)
	assert_int(s.hand.size()).is_equal(8)
	assert_bool(s.hand.has(picked[0])).is_false()
	assert_bool(s.discard_pile.has(picked[0])).is_true()


func test_fails_after_four_checkouts() -> void:
	var s := _shift()
	for i in 4:
		assert_bool(s.is_over()).is_false()
		s.play([s.hand[0]] as Array[Card])
	assert_bool(s.failed()).is_true()
	assert_object(s.play([s.hand[0]] as Array[Card])).is_null()
	assert_int(s.leftover_bonus()).is_equal(0)


func test_clears_when_target_reached() -> void:
	var s := _shift(1, 1)
	s.play([s.hand[0]] as Array[Card])
	assert_bool(s.cleared()).is_true()
	assert_bool(s.is_over()).is_true()
	assert_int(s.leftover_bonus()).is_equal(3 * Shift.LEFTOVER_BONUS)
	assert_bool(s.can_discard([s.hand[0]] as Array[Card])).is_false()


func test_discard_uses_swaps() -> void:
	var s := _shift()
	for i in 3:
		var gone := s.hand[0]
		assert_bool(s.discard([gone] as Array[Card])).is_true()
		assert_bool(s.hand.has(gone)).is_false()
		assert_int(s.hand.size()).is_equal(8)
	assert_int(s.swaps_left).is_equal(0)
	assert_bool(s.discard([s.hand[0]] as Array[Card])).is_false()
	assert_int(s.checkouts_left).is_equal(4)


func test_rejects_bad_selection() -> void:
	var s := _shift()
	assert_bool(s.can_play([] as Array[Card])).is_false()
	assert_bool(s.can_play(s.hand.slice(0, 6))).is_false()
	assert_bool(s.can_play(s.hand.slice(0, 5))).is_true()
	assert_bool(s.can_play([s.draw_pile[0]] as Array[Card])).is_false()
	assert_bool(s.can_play([s.hand[0], s.hand[0]] as Array[Card])).is_false()


func test_small_deck_runs_out() -> void:
	var s := Shift.new(Card.parse("m1 m2 m3 m4 m5 m6 m7 m8 m9"), 1_000_000, _rng(1))
	assert_int(s.hand.size()).is_equal(8)
	s.play(s.hand.slice(0, 5))
	assert_int(s.hand.size()).is_equal(4)


func test_boss_nephew_trades_swap_for_money() -> void:
	var s := _shift(1, 1_000_000, [Tips.make(&"boss_nephew")] as Array[Hook])
	assert_int(s.swaps_left).is_equal(2)
	s.play([s.hand[0]] as Array[Card])
	s.play([s.hand[0]] as Array[Card])
	assert_int(s.money).is_equal(2 * Tips.NEPHEW_MONEY)

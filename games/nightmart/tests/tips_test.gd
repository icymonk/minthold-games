extends GdUnitTestSuite


func _ring(text: String, ids: Array, held := "", left := 4) -> Receipt:
	var hooks: Array[Hook] = []
	for id in ids:
		hooks.append(Tips.make(id))
	return Receipt.ring_up(Card.parse(text), {}, hooks, Card.parse(held), left)


func test_every_tip_builds() -> void:
	for id in Tips.MAKERS:
		assert_str(Tips.make(id).id).is_equal(id)


func test_order_matters() -> void:
	# 식사 2장 낱개: 매출 500 + 1100
	# 컵라면 → 새벽 3시: (1 + 4) × 3 = 15
	var add_first := _ring("m9 m2", [&"meal_pair", &"three_am"], "", 1)
	assert_float(add_first.satisfaction).is_equal(15.0)
	# 새벽 3시 → 컵라면: 1 × 3 + 4 = 7
	var mul_first := _ring("m9 m2", [&"three_am", &"meal_pair"], "", 1)
	assert_float(mul_first.satisfaction).is_equal(7.0)
	assert_int(add_first.total()).is_equal(1600 * 15)


func test_last_checkout_only() -> void:
	assert_float(_ring("g9", [&"three_am"], "", 2).satisfaction).is_equal(1.0)
	assert_float(_ring("g9", [&"last_five"], "", 1).satisfaction).is_equal(2.0)


func test_pair_master_stacks() -> void:
	var tip := Tips.make(&"pair_master")
	var hooks: Array[Hook] = [tip]
	assert_float(Receipt.ring_up(Card.parse("m5 g5"), {}, hooks).satisfaction).is_equal(3.0)
	assert_float(Receipt.ring_up(Card.parse("m6 g6"), {}, hooks).satisfaction).is_equal(4.0)
	# 1+1이 아니어도 쌓인 만큼 더한다
	assert_float(Receipt.ring_up(Card.parse("g9"), {}, hooks).satisfaction).is_equal(3.0)


func test_points_stack() -> void:
	var hooks: Array[Hook] = [Tips.make(&"points")]
	assert_int(Receipt.ring_up(Card.parse("g9 m2"), {}, hooks).sales).is_equal(500 + 1100 + 100)
	assert_int(Receipt.ring_up(Card.parse("g9"), {}, hooks).sales).is_equal(500 + 900 + 150)


func test_rule_tips() -> void:
	assert_int(_ring("m3 g4 s5 g6", []).kind).is_equal(Combo.Kind.SINGLE)
	assert_int(_ring("m3 g4 s5 g6", [&"row_obsessed"]).kind).is_equal(Combo.Kind.STRAIGHT)
	assert_int(_ring("g1 g4 g9 g11", [&"same_aisle"]).kind).is_equal(Combo.Kind.FLUSH)
	assert_int(_ring("g1 g4 g9 g11 m2", [&"same_aisle"]).kind).is_equal(Combo.Kind.FLUSH)
	assert_float(_ring("g9~", [&"fridge_king"]).satisfaction).is_equal(2.0)
	# 같은 코너 4장 + 다른 코너로 채운 진열 줄은 완벽 진열이 아니다
	assert_int(_ring("g1 g2 g3 g4 m5", [&"same_aisle"]).kind).is_equal(Combo.Kind.FLUSH)
	assert_int(_ring("g1 g2 g3 g4 m9", [&"same_aisle", &"row_obsessed"]).kind).is_equal(Combo.Kind.STRAIGHT_FLUSH)


func test_waste_snack_counts_held_waste() -> void:
	assert_float(_ring("g9", [&"waste_snack"], "m1x s2x d3").satisfaction).is_equal(5.0)


func test_log_replays_total() -> void:
	var r := _ring("m5 g5~ d8+", [&"meal_pair", &"last_five"], "", 1)
	var sales := 0
	var sat := 0.0
	var sources: Array = []
	for line in r.log:
		sales += line.sales
		sat = (sat + line.sat_add) * line.sat_mul
		sources.append(line.source)
	assert_int(sales).is_equal(r.sales)
	assert_float(sat).is_equal(r.satisfaction)
	assert_array(sources).is_equal(["combo", "m5", "g5+chilled", "tag:chilled", "d8+discount", "tag:discount", "last_five"])


func test_tips_fire_on_waste_only_checkout() -> void:
	var r := _ring("m5x", [&"boss_nephew"])
	assert_int(r.kind).is_equal(Combo.Kind.NONE)
	assert_int(r.total()).is_equal(0)
	assert_int(r.money).is_equal(Tips.NEPHEW_MONEY)


func test_every_tip_has_name_desc_and_price() -> void:
	for id in Tips.MAKERS:
		var key := "TIP_%s" % String(id).to_upper()
		assert_str(Names.t(key)).is_not_equal(key)
		assert_str(Names.t(key + "_DESC")).is_not_equal(key + "_DESC")
		assert_int(Tips.price(id)).is_greater(0)
	assert_int(Tips.MAKERS.size()).is_equal(40)


func test_corner_clerk_counts_its_corner() -> void:
	var base := _ring("m5 g5", []).satisfaction
	assert_float(_ring("m5 g5", [&"meal_clerk"]).satisfaction).is_equal(base + 1)
	assert_float(_ring("m5 g5", [&"drink_clerk"]).satisfaction).is_equal(base)


func test_multiplying_tips_are_rare() -> void:
	var plain := _ring("m5 g5 s5 d9", [])
	for id in Tips.MAKERS:
		var r := _ring("m5 g5 s5 d9", [id], "", 1)
		if r.log.any(func(e: Dictionary) -> bool: return e.source == String(id) and e.sat_mul != 1.0):
			assert_str(Tips.rarity(id)).is_equal(Tips.RARE)
	assert_float(_ring("m5 g5 s5 d9", [&"duo"]).satisfaction).is_equal(plain.satisfaction * 2)
	assert_float(_ring("m5 g5 s5 d9", [&"trio"]).satisfaction).is_equal(plain.satisfaction * 3)
	assert_float(_ring("m5 g5 s5 d9", [&"store_tour"]).satisfaction).is_equal(plain.satisfaction * 3)
	assert_float(_ring("m5 g5 s6", [&"store_tour"]).satisfaction).is_equal(_ring("m5 g5 s6", []).satisfaction)
	assert_float(_ring("m9?", [&"store_tour"]).satisfaction).is_equal(_ring("m9?", []).satisfaction)
	assert_float(_ring("m5 g5 s6 m9?", [&"store_tour"]).satisfaction).is_equal(_ring("m5 g5 s6 m9?", []).satisfaction * 3)


func test_opening_only_first_checkout() -> void:
	var tip := Tips.make(&"opening")
	var hooks: Array[Hook] = [tip]
	var deck := Card.standard_deck()
	var rng := RandomNumberGenerator.new()
	var shift := Shift.new(deck, 999999, rng, hooks)
	var first := shift.play([shift.hand[0]])
	assert_bool(first.log.any(func(e: Dictionary) -> bool: return e.source == "opening")).is_true()
	var second := shift.play([shift.hand[0]])
	assert_bool(second.log.any(func(e: Dictionary) -> bool: return e.source == "opening")).is_false()


func test_recycling_and_spare_swaps_follow_shift() -> void:
	var recycling := Tips.make(&"recycling")
	var spare := Tips.make(&"spare_swaps")
	var hooks: Array[Hook] = [recycling, spare]
	var shift := Shift.new(Card.standard_deck(), 999999, RandomNumberGenerator.new(), hooks)
	var before := shift.preview([shift.hand[0]]).satisfaction
	shift.discard([shift.hand[0]])
	# 분리수거 +1, 남은 바꾸기 1번 줄어 -2
	assert_float(shift.preview([shift.hand[0]]).satisfaction).is_equal(before - 1)


func test_routine_stacks_same_combo() -> void:
	var hooks: Array[Hook] = [Tips.make(&"routine")]
	var base := Receipt.ring_up(Card.parse("g9"), {}, []).satisfaction
	assert_float(Receipt.ring_up(Card.parse("g9"), {}, hooks).satisfaction).is_equal(base)
	assert_float(Receipt.ring_up(Card.parse("m3"), {}, hooks).satisfaction).is_equal(base + 3)
	assert_float(Receipt.ring_up(Card.parse("m3"), {}, hooks, [], 1, true).satisfaction).is_equal(base + 6)
	assert_float(Receipt.ring_up(Card.parse("m3 g3"), {}, hooks).satisfaction).is_equal(Receipt.ring_up(Card.parse("m3 g3"), {}, []).satisfaction)


func test_veteran_grows_per_customer() -> void:
	var vet := Tips.make(&"veteran")
	var hooks: Array[Hook] = [vet]
	assert_float(Receipt.ring_up(Card.parse("g9"), {}, hooks, [], 1, true).satisfaction).is_equal(1.0)
	for i in 3:
		var shift := Shift.new(Card.standard_deck(), 999999, RandomNumberGenerator.new(), hooks)
		shift.play([shift.hand[0]])
	# 건너뛴 손님(계산 없이 다음 손님)은 안 센다
	Shift.new(Card.standard_deck(), 1, RandomNumberGenerator.new(), hooks)
	Shift.new(Card.standard_deck(), 1, RandomNumberGenerator.new(), hooks)
	assert_float(Receipt.ring_up(Card.parse("g9"), {}, hooks).satisfaction).is_equal_approx(1.3, 0.0001)


func test_shop_rarity_mix_and_price() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var counts := {Tips.COMMON: 0, Tips.UNCOMMON: 0, Tips.RARE: 0}
	for i in 500:
		for o in Shop.roll(rng, [], []):
			if o.kind == Shop.TIP:
				counts[Tips.rarity(o.id)] += 1
				assert_int(o.price).is_equal(Tips.price(o.id))
	assert_int(counts[Tips.COMMON]).is_greater(counts[Tips.UNCOMMON])
	assert_int(counts[Tips.UNCOMMON]).is_greater(counts[Tips.RARE])
	assert_int(counts[Tips.RARE]).is_greater(0)


func test_row_and_aisle_tips_check_contains() -> void:
	# 같은 코너 4장 + 진열 줄 5장: 조합은 같은 코너(더 셈)로 정해져도 진열 줄 꿀팁이 켜진다
	var cards := "m1 m2 m3 m4 s5"
	var hooks := [&"same_aisle"]
	assert_int(_ring(cards, hooks).kind).is_not_equal(Combo.Kind.STRAIGHT)
	assert_float(_ring(cards, hooks + [&"row_fan"]).satisfaction).is_equal(_ring(cards, hooks).satisfaction + 12)
	assert_float(_ring(cards, hooks + [&"tribe"]).satisfaction).is_equal(_ring(cards, hooks).satisfaction * 2)

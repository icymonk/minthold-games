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
	assert_int(_ring("g1 g2 g3 g4 m5", [&"same_aisle"]).kind).is_equal(Combo.Kind.STRAIGHT)
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

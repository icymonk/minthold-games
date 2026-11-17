extends GdUnitTestSuite

func _cards(text: String) -> Array[Card]:
	return Card.parse(text)


func _kind(text: String) -> Combo.Kind:
	return Combo.detect(_cards(text))


func test_standard_deck() -> void:
	var deck := Card.standard_deck()
	assert_int(deck.size()).is_equal(52)
	var seen := {}
	for c in deck:
		seen[str(c)] = true
	assert_int(seen.size()).is_equal(52)


func test_each_combo() -> void:
	assert_int(_kind("g9")).is_equal(Combo.Kind.SINGLE)
	assert_int(_kind("m5 g5")).is_equal(Combo.Kind.PAIR)
	assert_int(_kind("m5 g5 m8 d8")).is_equal(Combo.Kind.TWO_PAIR)
	assert_int(_kind("m2 s9 d12")).is_equal(Combo.Kind.MEAL_SET)
	assert_int(_kind("m5 g5 s5")).is_equal(Combo.Kind.TRIPLE)
	assert_int(_kind("m3 g4 s5 d6 m7")).is_equal(Combo.Kind.STRAIGHT)
	assert_int(_kind("g1 g4 g9 g11 g13")).is_equal(Combo.Kind.FLUSH)
	assert_int(_kind("m5 g5 s5 d2 g2")).is_equal(Combo.Kind.FULL_HOUSE)
	assert_int(_kind("m5 g5 s5 d5")).is_equal(Combo.Kind.FOUR)
	assert_int(_kind("d9 d10 d11 d12 d13")).is_equal(Combo.Kind.STRAIGHT_FLUSH)


func test_stronger_combo_wins() -> void:
	# 한 끼 세트이면서 1+1 → 한 끼 세트
	assert_int(_kind("m5 s5 d2")).is_equal(Combo.Kind.MEAL_SET)
	# 한 끼 세트이면서 3개 묶음 → 3개 묶음
	assert_int(_kind("m5 s5 d5")).is_equal(Combo.Kind.TRIPLE)
	# 같은 코너이면서 한 끼 세트가 안 됨
	assert_int(_kind("s1 s3 s5 s7 s9")).is_equal(Combo.Kind.FLUSH)


func test_straight_needs_five_in_a_row() -> void:
	assert_int(_kind("m3 g4 s5 g6")).is_equal(Combo.Kind.SINGLE)
	assert_int(_kind("m3 g4 s5 g6 m8")).is_equal(Combo.Kind.SINGLE)
	assert_int(_kind("m13 g1 s2 g3 m4")).is_equal(Combo.Kind.SINGLE)


func test_pb_counts_as_any_corner() -> void:
	assert_int(_kind("g1 g4 g9 g11 m13?")).is_equal(Combo.Kind.FLUSH)
	assert_int(_kind("m2 g9?")).is_equal(Combo.Kind.SINGLE)
	assert_int(_kind("m2 s9 g12?")).is_equal(Combo.Kind.MEAL_SET)


func test_waste_is_ignored() -> void:
	assert_int(_kind("m5 g5x")).is_equal(Combo.Kind.SINGLE)
	assert_int(_kind("m5x g5x")).is_equal(Combo.Kind.NONE)
	assert_int(Receipt.ring_up(_cards("m5x")).total()).is_equal(0)


func test_score_is_sales_times_satisfaction() -> void:
	# 1+1: (1000 + (5+5+8)×100) × 2
	var r := Receipt.ring_up(_cards("m5 g5 d8"))
	assert_int(r.kind).is_equal(Combo.Kind.PAIR)
	assert_int(r.sales).is_equal(2800)
	assert_int(r.total()).is_equal(5600)
	# 완벽 진열: (10000 + 55×100) × 8
	assert_int(Receipt.ring_up(_cards("d9 d10 d11 d12 d13")).total()).is_equal(124000)


func test_tags() -> void:
	# 낱개 + 할인: (500 + 900 + 500) × 1
	assert_int(Receipt.ring_up(_cards("g9+")).total()).is_equal(1900)
	# 낱개 + 행사: (500 + 900) × 3
	assert_int(Receipt.ring_up(_cards("g9*")).total()).is_equal(4200)
	# 냉장 2장 1+1: (1000 + 1000) × 2 × 1.5 × 1.5
	assert_int(Receipt.ring_up(_cards("g5~ m5~")).total()).is_equal(9000)


func test_levels_raise_base() -> void:
	assert_eq_base(Combo.base(Combo.Kind.PAIR, 1), Vector2i(1000, 2))
	assert_eq_base(Combo.base(Combo.Kind.PAIR, 3), Vector2i(2000, 4))
	assert_eq_base(Combo.base(Combo.Kind.SINGLE, 2), Vector2i(700, 2))
	var r := Receipt.ring_up(_cards("m5 g5"), {Combo.Kind.PAIR: 2})
	assert_int(r.total()).is_equal((1500 + 1000) * 3)


func assert_eq_base(got: Vector2i, want: Vector2i) -> void:
	assert_that(got).is_equal(want)

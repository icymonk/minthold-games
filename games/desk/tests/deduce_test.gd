extends GdUnitTestSuite

const A := Match.Action
const S := Match.Side
const H := Knowledge.HIDDEN


func _act(m: Match, move: Dictionary) -> void:
	assert_bool(m.apply(move)).is_true()


func _place(m: Match, card: int, sprints: Array = []) -> void:
	_act(m, { side = S.STAFF, action = A.PLACE, card = card, sprints = sprints })


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


## 사원 첫 차례 2, 5 → 팀장 첫 차례 더미 0에서 2장. 뒷면 1번은 1~3, 2번은 그 뒤 3칸 안.
func _opening(floor_deck: Array = [7, 8], hand: Array = [1, 2, 3, 4, 5, 6, 42]) -> Match:
	var m := Match.setup(hand, [floor_deck, [15, 16], [29, 30]])
	_place(m, 2)
	_place(m, 5)
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	return m


func _chief(m: Match) -> Deduce:
	return Deduce.run(Knowledge.of(m, S.CHIEF), _rng(7))


## hs: [번호 또는 H, 뛰기 장수]. 0번 기록은 자동으로 앞에 붙는다.
func _know(start: Array, hs: Array, draws: Array = [], misses: Array = []) -> Knowledge:
	var k := Knowledge.new()
	k.side = S.CHIEF
	k.start_counts.assign(start)
	k.hideouts.append({ card = 0, sprint_count = 0, sprints = [] as Array[int], revealed = true })
	for h in hs:
		k.hideouts.append({ card = h[0], sprint_count = h[1], sprints = [] as Array[int], revealed = h[0] != H })
	k.staff_draws.assign(draws)
	k.misses.assign(misses)
	return k


func test_ranges_and_exact_odds_from_steps() -> void:
	var d := _chief(_opening())
	assert_bool(d.sampled).is_false()
	assert_that(d.range_of(1)).is_equal(Vector2i(1, 3))
	assert_that(d.range_of(2)).is_equal(Vector2i(2, 6))
	assert_float(d.probs[1][1]).is_equal_approx(1.0 / 3.0, 1e-9)
	assert_float(d.probs[2][4]).is_equal_approx(1.0 / 3.0, 1e-9)
	assert_float(d.probs[0][0]).is_equal(1.0)


func test_chief_hand_is_excluded() -> void:
	var d := _chief(_opening([7, 4], [1, 2, 3, 5, 6, 9, 42]))
	assert_float(d.odds()[4]).is_equal(0.0)
	assert_that(d.range_of(2)).is_equal(Vector2i(2, 6))


func test_sprint_count_widens_range() -> void:
	var m := Match.setup([1, 2, 3, 6, 9, 12, 42], [[7, 8], [15, 16], [29, 30]])
	_place(m, 6, [9, 12])
	_act(m, { side = S.STAFF, action = A.PASS })
	assert_that(_chief(m).range_of(1)).is_equal(Vector2i(1, 7))


func test_revealed_record_is_fixed_and_narrows_neighbours() -> void:
	var m := _opening()
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [5] })
	var d := _chief(m)
	assert_float(d.probs[2][5]).is_equal(1.0)
	assert_that(d.range_of(1)).is_equal(Vector2i(2, 3))
	assert_array(d.sure()).is_empty()


func test_single_miss_only_rules_out_earlier_records() -> void:
	var m := _opening()
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [6] })
	_act(m, { side = S.STAFF, action = A.DRAW, zone = 1 })
	_place(m, 6)
	var d := _chief(m)
	assert_float(d.probs[2][6]).is_equal(0.0)
	assert_float(d.probs[3][6]).is_greater(0.0)


func test_group_miss_filters_joint_combination() -> void:
	var m := _opening()
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [1, 2] })
	var d := _chief(m)
	assert_bool(d.sampled).is_true()
	assert_float(d.probs[2][2]).is_equal(0.0)
	assert_float(d.probs[1][1]).is_between(0.2, 0.3)


func test_zone_needs_a_draw() -> void:
	assert_that(Deduce.run(_know([0, 0, 0], [[H, 1]])).range_of(1)).is_equal(Vector2i(1, 3))
	var k := _know([0, 0, 0], [[H, 1]], [{ zone = 0, before = 1 }])
	assert_that(Deduce.run(k).range_of(1)).is_equal(Vector2i(1, 5))


func test_hidden_records_share_zone_cards() -> void:
	# 층 안 카드가 1장뿐이라 두 뒷면이 모두 4 이상일 수는 없다.
	var d := Deduce.run(_know([1, 0, 0], [[H, 2], [H, 0]]), _rng(3))
	assert_bool(d.possible(1, 5)).is_true()
	assert_bool(d.sampled).is_true()
	assert_that(d.range_of(1)).is_equal(Vector2i(1, 3))


func test_known_revealed_cards_use_up_zone() -> void:
	# 앞면 16이 건물 안 몫 1장을 써서, 그 앞 뒷면은 13~14(층 안)만 된다.
	var d := Deduce.run(_know([2, 1, 0], [[H, 12], [16, 0]]))
	assert_that(d.range_of(1)).is_equal(Vector2i(13, 14))
	assert_float(d.probs[1][15]).is_equal(0.0)


func test_true_cards_always_stay_possible() -> void:
	var bad := 0
	for seed in 20:
		var rng := _rng(seed)
		var m := Match.deal(rng)
		var steps := 0
		while not m.is_over() and steps < 2000:
			var moves := m.legal_moves(m.side)
			assert_bool(m.apply(moves[rng.randi() % moves.size()])).is_true()
			steps += 1
			if steps % 3 == 0:
				var d := Deduce.run(Knowledge.of(m, S.CHIEF), rng, 100)
				for i in m.hideouts.size():
					if not d.possible(i, m.hideouts[i].card):
						bad += 1
		assert_bool(m.is_over()).is_true()
	assert_int(bad).is_equal(0)

extends GdUnitTestSuite

const A := Match.Action
const S := Match.Side


func _act(m: Match, move: Dictionary) -> void:
	assert_bool(m.apply(move)).is_true()


## 사원 첫 차례 2, 5 → 팀장 첫 차례 층 안에서 8, 7.
func _opening() -> Match:
	var m := Match.setup([1, 2, 3, 4, 5, 6, 42], [[7, 8], [15, 16], [29, 30]])
	_act(m, { side = S.STAFF, action = A.PLACE, card = 2, sprints = [] })
	_act(m, { side = S.STAFF, action = A.PLACE, card = 5, sprints = [] })
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	return m


func test_chief_sees_counts_but_not_hidden_numbers() -> void:
	var m := _opening()
	var k := Knowledge.of(m, S.CHIEF)
	assert_int(k.hideouts.size()).is_equal(3)
	assert_int(k.hideouts[0].card).is_equal(0)
	assert_int(k.hideouts[1].card).is_equal(Knowledge.HIDDEN)
	assert_int(k.hideouts[2].card).is_equal(Knowledge.HIDDEN)
	assert_array(k.hand).contains_exactly([8, 7])
	assert_array(k.deck_counts).is_equal([0, 2, 2])
	assert_int(k.staff_hand_count).is_equal(5)
	assert_array(k.start_counts).is_equal([3, 0, 0])
	var ks := Knowledge.of(m, S.STAFF)
	assert_int(ks.hideouts[1].card).is_equal(2)
	assert_int(ks.hideouts[2].card).is_equal(5)


func test_sprint_count_visible_values_after_reveal() -> void:
	var m := Match.setup([1, 2, 3, 6, 9, 12, 42], [[7, 8], [15, 16], [29, 30]])
	_act(m, { side = S.STAFF, action = A.PLACE, card = 6, sprints = [9, 12] })
	_act(m, { side = S.STAFF, action = A.PASS })
	var k := Knowledge.of(m, S.CHIEF)
	assert_int(k.hideouts[1].sprint_count).is_equal(2)
	assert_array(k.hideouts[1].sprints).is_empty()
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [6] })
	k = Knowledge.of(m, S.CHIEF)
	assert_int(k.hideouts[1].card).is_equal(6)
	assert_array(k.hideouts[1].sprints).is_equal([9, 12])
	var ex := k.excluded()
	for c in [0, 6, 9, 12, 8, 7]:
		assert_bool(ex.has(c)).is_true()


func test_records_staff_draws_and_misses_with_timing() -> void:
	var m := _opening()
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [6] })
	_act(m, { side = S.STAFF, action = A.DRAW, zone = 1 })
	var k := Knowledge.of(m, S.CHIEF)
	assert_int(k.staff_draws.size()).is_equal(1)
	assert_int(k.staff_draws[0].zone).is_equal(1)
	assert_int(k.staff_draws[0].before).is_equal(3)
	assert_int(k.misses.size()).is_equal(1)
	assert_array(k.misses[0].numbers).is_equal([6])
	assert_int(k.misses[0].before).is_equal(3)
	assert_array(k.hand).contains_exactly([8, 7])

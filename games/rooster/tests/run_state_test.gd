extends GdUnitTestSuite


func test_seven_wins_is_victory() -> void:
	var run := RunState.new(1)
	for i in RunState.NIGHTS:
		assert_bool(run.is_over()).is_false()
		run.win_night()
	assert_bool(run.is_victory()).is_true()
	assert_int(run.lanterns).is_equal(RunState.START_LANTERNS)


func test_normal_loss_costs_one_lantern_and_advances() -> void:
	var run := RunState.new(1)
	run.lose_night()
	assert_int(run.lanterns).is_equal(2)
	assert_int(run.night).is_equal(2)


func test_boss_loss_costs_two_lanterns() -> void:
	var run := RunState.new(1)
	run.win_night()
	run.win_night()
	assert_bool(run.is_boss_night()).is_true()
	run.lose_night()
	assert_int(run.lanterns).is_equal(1)


func test_running_out_of_lanterns_is_defeat_without_advancing() -> void:
	var run := RunState.new(1)
	run.lose_night()
	run.lose_night()
	run.lose_night()
	assert_bool(run.is_defeat()).is_true()
	assert_bool(run.is_victory()).is_false()
	assert_int(run.night).is_equal(3)


func test_hire_to_bag_places_directly_and_charges() -> void:
	var run := RunState.new(1)
	run.shelf[0] = &"dokkaebi"
	var coins := run.coins
	var cells := YokaiDb.base_cells(&"dokkaebi")
	var p := run.hire_to_bag(0, cells, Vector2i(1, 1))
	assert_object(p).is_not_null()
	assert_array(run.bag.pieces).contains_exactly([p])
	assert_array(run.bench).is_empty()
	assert_int(run.coins).is_equal(coins - YokaiDb.cost(&"dokkaebi"))
	assert_that(run.shelf[0]).is_equal(&"")


func test_hire_to_bag_without_room_changes_nothing() -> void:
	var run := RunState.new(1)
	run.shelf[0] = &"bulgasari"
	var coins := run.coins
	var p := run.hire_to_bag(0, YokaiDb.base_cells(&"bulgasari"), Vector2i(run.bag.width - 2, 0))
	assert_object(p).is_null()
	assert_array(run.bag.pieces).is_empty()
	assert_int(run.coins).is_equal(coins)
	assert_that(run.shelf[0]).is_equal(&"bulgasari")


func test_portrait_rotation_follows_piece_rotation() -> void:
	var p := Piece.create(&"dokkaebi")
	var base := YokaiDb.base_cells(&"dokkaebi")
	for turns in 4:
		assert_int(Ink.rotation_of(base, p.cells)).is_equal(turns)
		p.rotate_cw()

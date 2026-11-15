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

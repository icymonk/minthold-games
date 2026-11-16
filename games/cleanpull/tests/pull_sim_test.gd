extends GdUnitTestSuite


func _one(kind: StringName, x: float, pull: PullSim.Pull) -> PullSim.Result:
	var dishes: Array[Dish] = [Dish.new(kind, x)]
	return PullSim.new().run(dishes, pull)[0]


func test_fast_level_pull_keeps_plate() -> void:
	var r := _one(&"plate", 80.0, PullSim.Pull.new(1000.0))
	assert_int(r.outcome).is_equal(PullSim.Outcome.STAYED)
	assert_float(r.slide).is_less(5.0)


func test_slow_pull_drags_plate_off() -> void:
	var r := _one(&"plate", 80.0, PullSim.Pull.new(100.0))
	assert_int(r.outcome).is_equal(PullSim.Outcome.FELL)


func test_faster_pull_slides_less() -> void:
	var slow := _one(&"plate", 80.0, PullSim.Pull.new(400.0))
	var fast := _one(&"plate", 80.0, PullSim.Pull.new(800.0))
	assert_float(fast.slide).is_less(slow.slide)


func test_dish_near_cloth_end_slides_less() -> void:
	var near := _one(&"plate", 20.0, PullSim.Pull.new(400.0))
	var far := _one(&"plate", 120.0, PullSim.Pull.new(400.0))
	assert_float(near.slide).is_less(far.slide)


func test_upward_pull_tips_wine_glass() -> void:
	var level := _one(&"wine_glass", 60.0, PullSim.Pull.new(800.0))
	var upward := _one(&"wine_glass", 60.0, PullSim.Pull.new(800.0, 25.0))
	assert_int(level.outcome).is_equal(PullSim.Outcome.STAYED)
	assert_int(upward.outcome).is_equal(PullSim.Outcome.TIPPED)


func test_plate_never_tips_from_upward_pull() -> void:
	var r := _one(&"plate", 60.0, PullSim.Pull.new(800.0, 40.0))
	assert_int(r.outcome).is_equal(PullSim.Outcome.STAYED)


func test_wobble_increases_slide() -> void:
	var clean := _one(&"plate", 80.0, PullSim.Pull.new(600.0))
	var shaky := _one(&"plate", 80.0, PullSim.Pull.new(600.0, 0.0, 0.5))
	assert_float(shaky.slide).is_greater(clean.slide)


func test_perfect_when_barely_moved() -> void:
	var r := _one(&"plate", 10.0, PullSim.Pull.new(2000.0))
	assert_bool(r.perfect()).is_true()


func test_near_edge_flag() -> void:
	var sim := PullSim.new()
	var dishes: Array[Dish] = [Dish.new(&"plate", 145.0)]
	var r := sim.run(dishes, PullSim.Pull.new(1000.0))[0]
	assert_int(r.outcome).is_equal(PullSim.Outcome.STAYED)
	assert_bool(sim.near_edge(r)).is_true()


func test_overlapping_dishes_bump() -> void:
	var dishes: Array[Dish] = [Dish.new(&"jelly", 100.0), Dish.new(&"wine_glass", 110.0)]
	var results := PullSim.new(400.0).run(dishes, PullSim.Pull.new(350.0))
	assert_bool(results[0].bumped).is_true()
	assert_bool(results[1].bumped).is_true()


func test_same_input_same_result() -> void:
	var a := _one(&"vase", 70.0, PullSim.Pull.new(650.0, 5.0, 0.2))
	var b := _one(&"vase", 70.0, PullSim.Pull.new(650.0, 5.0, 0.2))
	assert_float(a.slide).is_equal(b.slide)
	assert_float(a.tip).is_equal(b.tip)


func test_bump_checks_non_neighbors() -> void:
	var dishes: Array[Dish] = [Dish.new(&"jelly", 100.0), Dish.new(&"wine_glass", 110.0), Dish.new(&"wine_glass", 120.0)]
	var results := PullSim.new(400.0).run(dishes, PullSim.Pull.new(350.0))
	assert_bool(results[2].bumped).is_true()

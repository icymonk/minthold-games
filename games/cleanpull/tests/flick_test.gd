extends GdUnitTestSuite


func _drag(to: Vector2, seconds: float, steps := 10) -> Flick:
	var f := Flick.new()
	f.begin(Vector2.ZERO, 0.0)
	for i in range(1, steps + 1):
		f.move(to * i / steps, seconds * i / steps)
	return f


func test_steady_level_flick() -> void:
	var p := _drag(Vector2(200, 0), 0.1).to_pull()
	assert_float(p.speed).is_equal_approx(2000.0 * Flick.GAIN, 1.0)
	assert_float(p.angle).is_equal_approx(0.0, 0.01)
	assert_float(p.wobble).is_equal_approx(0.0, 0.01)


func test_upward_flick_has_angle() -> void:
	var p := _drag(Vector2(200, -200 * tan(deg_to_rad(30))), 0.1).to_pull()
	assert_float(p.angle).is_equal_approx(30.0, 0.1)


func test_slowing_down_is_wobble() -> void:
	var f := Flick.new()
	f.begin(Vector2.ZERO, 0.0)
	for i in range(1, 6):
		f.move(Vector2(30 * i, 0), 0.01 * i)
	for i in range(1, 6):
		f.move(Vector2(150 + 3 * i, 0), 0.05 + 0.01 * i)
	assert_float(f.to_pull().wobble).is_greater(0.5)


func test_commit_after_distance() -> void:
	assert_bool(_drag(Vector2(Flick.COMMIT - 1, 0), 0.1).committed()).is_false()
	assert_bool(_drag(Vector2(Flick.COMMIT, 0), 0.1).committed()).is_true()


func test_no_motion_is_slow() -> void:
	var f := Flick.new()
	f.begin(Vector2.ZERO, 0.0)
	assert_float(f.to_pull().speed).is_equal(PullSim.Pull.new(0.0).speed)


func test_pause_before_release_is_slow() -> void:
	var f := _drag(Vector2(100, 0), 0.05)
	f.move(Vector2(100, 0), 0.5)
	assert_float(f.to_pull().speed).is_equal_approx(0.0, 0.01)


func test_leftward_drag_never_pulls() -> void:
	var f := _drag(Vector2(-300, 0), 0.05)
	assert_bool(f.committed()).is_false()
	assert_bool(f.tugged()).is_false()
	assert_bool(_drag(Vector2(Flick.MIN_TUG, 0), 0.05).tugged()).is_true()

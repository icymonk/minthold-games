extends GdUnitTestSuite


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_practice_is_deterministic() -> void:
	var a := ShiftState.practice(_rng(7))
	var b := ShiftState.practice(_rng(7))
	assert_array(a.queue.map(func(x: Box) -> StringName: return x.shape)) \
		.is_equal(b.queue.map(func(x: Box) -> StringName: return x.shape))


func test_practice_fits_budget() -> void:
	for s in 50:
		var shift := ShiftState.practice(_rng(s))
		var total := 0
		for b in shift.queue:
			total += b.cells.size()
		assert_int(total).is_less_equal(24)
		assert_int(shift.queue.size()).is_equal(8)


func test_restore_undoes_placement() -> void:
	var shift := ShiftState.practice(_rng(1))
	var snap := shift.snapshot()
	var box: Box = shift.queue.pop_front()
	shift.bay.place(box, Vector2i(0, 0))
	shift.restore(snap)
	assert_int(shift.queue.size()).is_equal(8)
	assert_int(shift.bay.boxes.size()).is_equal(0)

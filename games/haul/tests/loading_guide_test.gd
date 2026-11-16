extends GdUnitTestSuite


func _take(shift: ShiftState, stop: int) -> Box:
	for i in shift.queue.size():
		if shift.queue[i].stop == stop:
			return shift.queue.pop_at(i)
	return null


func test_tutorial_walkthrough() -> void:
	var shift := LoadingGuide.tutorial_shift()
	var g := LoadingGuide.new()
	assert_bool(g.is_manual()).is_true()
	g.next()
	assert_int(g.step).is_equal(LoadingGuide.Step.ROUTE)
	g.next()
	assert_int(g.step).is_equal(LoadingGuide.Step.LOAD_LAST)
	assert_that(g.target(shift, null)).is_equal({kind = &"slot", box_id = 3})
	var b3 := _take(shift, 3)
	assert_that(g.target(shift, b3)).is_equal({kind = &"cell", cell = Vector2i(0, 0)})
	shift.bay.place(b3, Vector2i(0, 0))
	assert_bool(g.update(shift, null)).is_true()
	assert_int(g.step).is_equal(LoadingGuide.Step.LOAD_MIDDLE)
	var b2 := _take(shift, 2)
	assert_that(g.target(shift, b2)).is_equal({kind = &"cell", cell = Vector2i(2, 0)})
	shift.bay.place(b2, Vector2i(2, 0))
	g.update(shift, null)
	assert_int(g.step).is_equal(LoadingGuide.Step.ROTATE)
	var b1 := _take(shift, 1)
	assert_that(g.target(shift, b1)).is_equal({kind = &"button", name = &"rotate"})
	b1.rotate()
	g.on_rotated()
	g.update(shift, b1)
	assert_int(g.step).is_equal(LoadingGuide.Step.LOAD_FIRST)
	shift.bay.place(b1, Vector2i(3, 0))
	g.update(shift, null)
	assert_int(g.step).is_equal(LoadingGuide.Step.FIX_TIP)
	g.next()
	assert_int(g.step).is_equal(LoadingGuide.Step.DEPART)
	g.on_departed()
	assert_int(g.step).is_equal(LoadingGuide.Step.DONE)


func test_tutorial_warns_on_wrong_order() -> void:
	var shift := LoadingGuide.tutorial_shift()
	var g := LoadingGuide.new()
	g.next()
	g.next()
	shift.bay.place(_take(shift, 3), Vector2i(0, 0))
	g.update(shift, null)
	shift.bay.place(_take(shift, 1), Vector2i(2, 0))
	shift.bay.place(_take(shift, 2), Vector2i(5, 0))
	g.update(shift, null)
	assert_array(shift.bay.out_of_order()).is_not_empty()
	assert_str(g.text_key(shift)).is_equal("TUT_WRONG_ORDER")


func test_hint_suggests_latest_stop() -> void:
	var shift := LoadingGuide.tutorial_shift()
	var h := LoadingGuide.hint(shift, null)
	assert_str(h.key).is_equal("HINT_NEXT")
	assert_int(h.arg).is_equal(3)
	assert_int(h.suggest).is_equal(3)


func test_hint_depart_when_queue_empty() -> void:
	var shift := ShiftState.new(1)
	assert_str(LoadingGuide.hint(shift, null).key).is_equal("HINT_DEPART")


func test_undo_returns_to_missing_box_step() -> void:
	var shift := LoadingGuide.tutorial_shift()
	var g := LoadingGuide.new()
	g.next()
	g.next()
	var snap := shift.snapshot()
	shift.bay.place(_take(shift, 3), Vector2i(0, 0))
	g.update(shift, null)
	assert_int(g.step).is_equal(LoadingGuide.Step.LOAD_MIDDLE)
	shift.restore(snap)
	assert_bool(g.update(shift, null)).is_true()
	assert_int(g.step).is_equal(LoadingGuide.Step.LOAD_LAST)

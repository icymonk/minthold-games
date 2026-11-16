extends GdUnitTestSuite


func _box(id: int, shape := &"1x1", stop := 0, traits: Array[Box.Trait] = []) -> Box:
	return Box.new(id, shape, stop, traits)


func test_box_falls_to_floor() -> void:
	var bay := Bay.new()
	var r := bay.place(_box(1), Vector2i(3, 3))
	assert_int(r.error).is_equal(Bay.Fail.OK)
	assert_that(r.origin).is_equal(Vector2i(3, 0))
	assert_int(r.fall).is_equal(3)


func test_box_stacks_on_another() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(2, 0))
	var r := bay.place(_box(2), Vector2i(2, 3))
	assert_that(r.origin).is_equal(Vector2i(2, 1))


func test_cannot_push_past_box_in_same_row() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(5, 0))
	assert_int(bay.place(_box(2), Vector2i(2, 0)).error).is_equal(Bay.Fail.BLOCKED)
	# 위 줄로 넘겨 밀면 지나간 뒤 떨어진다.
	var r := bay.place(_box(3), Vector2i(2, 1))
	assert_int(r.error).is_equal(Bay.Fail.OK)
	assert_that(r.origin).is_equal(Vector2i(2, 0))


func test_out_of_bounds() -> void:
	var bay := Bay.new()
	assert_int(bay.place(_box(1, &"3x1"), Vector2i(6, 0)).error).is_equal(Bay.Fail.OUT_OF_BOUNDS)


func test_unload_needs_clear_top_and_path() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(0, 0))
	bay.place(_box(2), Vector2i(0, 1))
	bay.place(_box(4), Vector2i(1, 0))
	bay.place(_box(3), Vector2i(1, 1))
	assert_int(bay.can_unload(1)).is_equal(Bay.Fail.COVERED)
	assert_int(bay.can_unload(2)).is_equal(Bay.Fail.PATH_BLOCKED)
	assert_int(bay.can_unload(3)).is_equal(Bay.Fail.OK)


func test_unload_drops_boxes_above() -> void:
	var bay := Bay.new()
	bay.place(_box(1, &"2x1"), Vector2i(6, 0))
	bay.place(_box(2), Vector2i(7, 1))
	bay.unload(2)
	bay.place(_box(3), Vector2i(7, 1))
	# 바닥 상자 1을 꺼내려면 위의 3이 막는다.
	assert_int(bay.can_unload(1)).is_equal(Bay.Fail.COVERED)
	bay.unload(3)
	var r := bay.unload(1)
	assert_int(r.error).is_equal(Bay.Fail.OK)
	assert_int(bay.free_cells()).is_equal(32)


func test_settle_after_unload_moves_unsupported_box() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(7, 0))
	bay.place(_box(2, &"2x1"), Vector2i(6, 1))  # 1 위에 반쯤 걸쳐 있음
	bay._remove(1)
	var r := bay.settle()
	assert_array(r.moved).contains([2])
	assert_that(bay.origins[2]).is_equal(Vector2i(6, 0))


func test_fragile_breaks_when_box_put_on_top() -> void:
	var bay := Bay.new()
	var glass := _box(1, &"1x1", 0, [Box.Trait.FRAGILE])
	bay.place(glass, Vector2i(4, 0))
	var r := bay.place(_box(2), Vector2i(4, 1))
	assert_array(r.broken).contains([1])
	assert_bool(glass.broken).is_true()


func test_fragile_breaks_on_long_fall() -> void:
	var bay := Bay.new()
	var glass := _box(1, &"1x1", 0, [Box.Trait.FRAGILE])
	assert_array(bay.place(glass, Vector2i(4, 2)).broken).contains([1])
	var cup := _box(2, &"1x1", 0, [Box.Trait.FRAGILE])
	assert_array(bay.place(cup, Vector2i(5, 1)).broken).is_empty()


func test_heavy_only_on_floor_or_heavy() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(3, 0))
	var iron := _box(2, &"1x1", 0, [Box.Trait.HEAVY])
	assert_int(bay.place(iron, Vector2i(3, 2)).error).is_equal(Bay.Fail.NOT_ON_HEAVY)
	assert_int(bay.place(iron, Vector2i(4, 0)).error).is_equal(Bay.Fail.OK)
	var iron2 := _box(3, &"1x1", 0, [Box.Trait.HEAVY])
	assert_that(bay.place(iron2, Vector2i(4, 3)).origin).is_equal(Vector2i(4, 1))


func test_rotate_and_upright() -> void:
	var bar := _box(1, &"3x1")
	assert_bool(bar.rotate()).is_true()
	assert_that(bar.size()).is_equal(Vector2i(1, 3))
	var tv := _box(2, &"3x1", 0, [Box.Trait.UPRIGHT])
	assert_bool(tv.rotate()).is_false()
	assert_that(tv.size()).is_equal(Vector2i(3, 1))


func test_rotate_four_times_is_identity() -> void:
	var t := _box(1, &"T")
	var before := t.cells.duplicate()
	for i in 4:
		t.rotate()
	assert_array(t.cells).contains_exactly_in_any_order(before)


func test_copy_is_independent() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(0, 0))
	var snap := bay.copy()
	bay.unload(1)
	assert_int(snap.free_cells()).is_equal(31)
	assert_int(bay.free_cells()).is_equal(32)


func test_fragile_breaks_when_slid_under_overhang() -> void:
	var bay := Bay.new()
	bay.place(_box(1), Vector2i(0, 0))
	bay.place(_box(2, &"2x1"), Vector2i(0, 1))  # (1,0) 위로 처마
	var glass := _box(3, &"1x1", 0, [Box.Trait.FRAGILE])
	assert_array(bay.place(glass, Vector2i(1, 0)).broken).contains([3])


func test_place_same_box_twice_is_rejected() -> void:
	var bay := Bay.new()
	var box := _box(1)
	bay.place(box, Vector2i(0, 0))
	assert_int(bay.place(box, Vector2i(5, 0)).error).is_equal(Bay.Fail.ALREADY_IN_BAY)
	bay.unload(1)
	assert_int(bay.free_cells()).is_equal(32)

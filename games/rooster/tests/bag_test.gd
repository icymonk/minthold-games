extends GdUnitTestSuite


func test_place_respects_bounds_and_overlap() -> void:
	var bag := Bag.new(5, 4)
	var haetae := Piece.create(&"haetae")
	assert_bool(bag.place(haetae, Vector2i(4, 0))).is_false()
	assert_bool(bag.place(haetae, Vector2i(3, 2))).is_true()
	var fox := Piece.create(&"foxfire")
	assert_bool(bag.place(fox, Vector2i(4, 3))).is_false()
	assert_bool(bag.place(fox, Vector2i(2, 3))).is_true()


func test_rotate_keeps_shape_normalized() -> void:
	var b := Piece.create(&"bulgasari")
	b.rotate_cw()
	assert_vector(b.size()).is_equal(Vector2i(1, 3))
	b.rotate_cw()
	assert_vector(b.size()).is_equal(Vector2i(3, 1))


func test_feed_does_not_need_touching() -> void:
	var bag := Bag.new(5, 4)
	var a := Piece.create(&"haetae")
	var b := Piece.create(&"foxfire")
	bag.place(a, Vector2i(0, 0))
	bag.place(b, Vector2i(4, 3))
	assert_int(bag.feed(a, b)).is_equal(Bag.Feed.OK)
	assert_object(bag.piece_at(Vector2i(4, 3))).is_null()


func test_same_kind_fills_two_and_gives_full_stats() -> void:
	var bag := Bag.new(5, 4)
	var a := Piece.create(&"haetae")
	var b := Piece.create(&"haetae")
	bag.place(a, Vector2i(0, 0))
	assert_int(bag.feed(a, b)).is_equal(Bag.Feed.OK)
	assert_int(a.eaten).is_equal(2)
	assert_int(a.hp).is_equal(18)
	assert_array(a.traits).contains_exactly([&"guard"])


func test_eaten_belly_carries_over() -> void:
	var bag := Bag.new(5, 4)
	var mid := Piece.create(&"dokkaebi")
	mid.eaten = 1
	var eater := Piece.create(&"haetae")
	bag.place(eater, Vector2i(0, 0))
	assert_int(bag.feed(eater, mid)).is_equal(Bag.Feed.OK)
	assert_int(eater.eaten).is_equal(2)


func test_eater_outside_bag_evolves_without_room() -> void:
	var bag := Bag.new(1, 1)
	var fox := Piece.create(&"foxfire")
	assert_int(bag.feed(fox, Piece.create(&"bulgae"))).is_equal(Bag.Feed.EVOLVED)
	assert_str(String(fox.kind)).is_equal("gumiho")


func test_run_feed_removes_food_from_bench_and_hire_feed_charges() -> void:
	var run := RunState.new(5)
	run.coins = 20
	var eater := Piece.create(&"haetae")
	var food := Piece.create(&"mongdal")
	run.bench.append(eater)
	run.bench.append(food)
	assert_int(run.feed(eater, food)).is_equal(Bag.Feed.OK)
	assert_array(run.bench).contains_exactly([eater])
	run.shelf[0] = &"foxfire"
	assert_int(run.hire_feed(0, eater)).is_equal(Bag.Feed.OK)
	assert_int(run.coins).is_equal(20 - YokaiDb.cost(&"foxfire"))
	assert_str(String(run.shelf[0])).is_equal("")
	run.coins = 0
	run.shelf[1] = &"foxfire"
	assert_int(run.hire_feed(1, Piece.create(&"haetae"))).is_equal(Bag.Feed.SELF)
	assert_str(String(run.shelf[1])).is_equal("foxfire")


func test_feed_frees_cells_and_inherits() -> void:
	var bag := Bag.new(5, 4)
	var eater := Piece.create(&"haetae")
	var food := Piece.create(&"mongdal")
	bag.place(eater, Vector2i(0, 0))
	bag.place(food, Vector2i(2, 0))
	assert_int(bag.feed(eater, food)).is_equal(Bag.Feed.OK)
	assert_int(bag.pieces.size()).is_equal(1)
	assert_int(eater.cells.size()).is_equal(4)
	assert_object(bag.piece_at(Vector2i(2, 0))).is_null()
	assert_int(eater.atk).is_equal(1 + 2)
	assert_int(eater.hp).is_equal(9 + 2)
	assert_array(eater.traits).contains_exactly([&"guard", &"rage"])
	assert_bool(eater.hungry()).is_true()


func test_full_belly_evolves_into_form_shape() -> void:
	var bag := Bag.new(5, 4)
	var fox := Piece.create(&"foxfire")
	var food := Piece.create(&"foxfire")
	bag.place(fox, Vector2i(3, 1))
	bag.place(food, Vector2i(4, 1))
	assert_int(bag.feed(fox, food)).is_equal(Bag.Feed.EVOLVED)
	assert_bool(fox.evolved).is_true()
	assert_str(String(fox.kind)).is_equal("gumiho")
	assert_int(fox.cells.size()).is_equal(3)
	assert_bool(fox.world_cells().has(Vector2i(3, 1))).is_true()
	assert_int(fox.atk).is_equal(2 + 2 + 1)
	assert_float(fox.interval).is_equal(0.9)
	var more := Piece.create(&"foxfire")
	bag.place(more, fox.world_cells()[0] + Vector2i.LEFT)
	assert_int(bag.feed(fox, more)).is_equal(Bag.Feed.FULL)
	assert_int(bag.feed(more, fox)).is_equal(Bag.Feed.FOOD_EVOLVED)


func test_evolution_needs_room() -> void:
	var bag := Bag.new(2, 1)
	var fox := Piece.create(&"foxfire")
	var food := Piece.create(&"foxfire")
	bag.place(fox, Vector2i(0, 0))
	bag.place(food, Vector2i(1, 0))
	assert_int(bag.feed(fox, food)).is_equal(Bag.Feed.NO_ROOM)
	assert_array(bag.pieces).contains_exactly([fox, food])
	assert_int(fox.eaten).is_equal(0)
	assert_int(fox.atk).is_equal(2)


func test_plot_must_touch_edge_and_keeps_special_on_rotate() -> void:
	var bag := Bag.new(4, 2, false)
	bag.open[Vector2i(3, 0)] = true
	var plot := Plot.new()
	plot.cells.assign([Vector2i(0, 0), Vector2i(1, 0)])
	plot.special[Vector2i(1, 0)] = &"well"
	assert_bool(bag.can_expand(plot, Vector2i(0, 1))).is_false()
	assert_bool(bag.can_expand(plot, Vector2i(3, 0))).is_false()
	plot.rotate_cw()
	assert_array(plot.cells).contains_exactly_in_any_order([Vector2i(0, 0), Vector2i(0, 1)])
	assert_str(String(plot.special[Vector2i(0, 1)])).is_equal("well")
	assert_bool(bag.expand(plot, Vector2i(2, 0))).is_true()
	assert_str(String(bag.special[Vector2i(2, 1)])).is_equal("well")


func test_special_cell_buffs_matching_family() -> void:
	var bag := Bag.new(3, 1)
	bag.special[Vector2i(0, 0)] = &"hearth"
	var fire := Piece.create(&"foxfire")
	var water := Piece.create(&"ureong")
	bag.place(fire, Vector2i(0, 0))
	assert_int(Synergy.bonuses(bag)[fire.id]["atk"]).is_equal(2)
	bag.remove(fire)
	bag.place(water, Vector2i(0, 0))
	assert_int(Synergy.bonuses(bag)[water.id]["atk"]).is_equal(0)

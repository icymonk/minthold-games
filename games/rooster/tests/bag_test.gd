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


func test_feed_requires_touching() -> void:
	var bag := Bag.new(5, 4)
	var a := Piece.create(&"mongdal")
	var b := Piece.create(&"foxfire")
	bag.place(a, Vector2i(0, 0))
	bag.place(b, Vector2i(4, 3))
	assert_int(bag.feed(a, b)).is_equal(Bag.Feed.NOT_TOUCHING)


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
	assert_int(fox.atk).is_equal(2 + 1 + 1)
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
	assert_int(bag.pieces.size()).is_equal(2)
	assert_int(fox.eaten).is_equal(0)
	assert_int(fox.atk).is_equal(2)

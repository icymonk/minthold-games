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


func test_merge_requires_touching() -> void:
	var bag := Bag.new(5, 4)
	var a := Piece.create(&"mongdal")
	var b := Piece.create(&"foxfire")
	bag.place(a, Vector2i(0, 0))
	bag.place(b, Vector2i(4, 3))
	assert_bool(bag.merge(a, b)).is_false()


func test_merge_unions_shape_and_inherits() -> void:
	var bag := Bag.new(5, 4)
	var eater := Piece.create(&"mongdal")
	var food := Piece.create(&"haetae")
	bag.place(eater, Vector2i(0, 0))
	bag.place(food, Vector2i(0, 1))
	assert_bool(bag.merge(eater, food)).is_true()
	assert_int(bag.pieces.size()).is_equal(1)
	assert_int(eater.cells.size()).is_equal(6)
	assert_vector(eater.size()).is_equal(Vector2i(2, 3))
	assert_int(eater.atk).is_equal(3 + 1)
	assert_int(eater.hp).is_equal(3 + 5)
	assert_array(eater.traits).contains_exactly([&"rage", &"guard"])
	assert_int(eater.eaten).is_equal(1)

extends GdUnitTestSuite


func test_every_product_has_art() -> void:
	for corner in Art.CORNERS:
		assert_int(Art.PRODUCTS[corner].size()).is_equal(13)
		for rank in range(1, 14):
			assert_object(Art.product(corner, rank)).override_failure_message("%s %d" % [corner, rank]).is_not_null()
		assert_bool(Style.CORNER.has(corner)).is_true()


func test_every_sound_loads() -> void:
	for key in Sfx.SOUNDS:
		assert_object(Sfx.SOUNDS[key]).override_failure_message(key).is_not_null()

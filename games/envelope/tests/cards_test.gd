extends GdUnitTestSuite


func test_deck_sizes_match_design() -> void:
	assert_int(Cards.deck(3).size()).is_equal(18)
	assert_int(Cards.deck(4).size()).is_equal(24)
	assert_int(Cards.deck(5).size()).is_equal(25)
	assert_int(Cards.deck(6).size()).is_equal(30)


func test_every_deck_has_one_thief_and_chair() -> void:
	for n in range(3, 7):
		assert_int(Cards.deck(n).count(Cards.Id.THIEF)).is_equal(1)
		assert_int(Cards.deck(n).count(Cards.Id.CHAIR)).is_equal(1)


func test_target_follows_table() -> void:
	assert_int(Cards.target(3)).is_equal(6)
	assert_int(Cards.target(4)).is_equal(8)
	assert_int(Cards.target(5)).is_equal(7)
	assert_int(Cards.target(6)).is_equal(8)


func test_thief_cannot_be_played() -> void:
	assert_bool(Cards.playable(Cards.Id.THIEF)).is_false()
	assert_bool(Cards.playable(Cards.Id.BOSS)).is_true()

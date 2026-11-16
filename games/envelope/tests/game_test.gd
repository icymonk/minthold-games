extends GdUnitTestSuite


func test_players_clamped_to_3_6() -> void:
	var before: int = Game.players
	Game.set_players(2)
	assert_int(Game.players).is_equal(3)
	Game.set_players(9)
	assert_int(Game.players).is_equal(6)
	Game.set_players(before)

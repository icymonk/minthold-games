extends GdUnitTestSuite


func test_toggle_role_switches_between_chief_and_staff() -> void:
	var before: int = Game.role
	Game.role = Game.Role.CHIEF
	Game.toggle_role()
	assert_int(Game.role).is_equal(Game.Role.STAFF)
	Game.toggle_role()
	assert_int(Game.role).is_equal(Game.Role.CHIEF)
	Game.role = before

extends GdUnitTestSuite


func test_start_run_keeps_given_seed() -> void:
	Game.start_run(1234)
	assert_int(Game.run_seed).is_equal(1234)
	assert_object(Game.rng).is_not_null()
	Game.goto(&"title")


func test_every_screen_instantiates() -> void:
	for key in Game.SCREENS:
		var node: Node = Game.SCREENS[key].instantiate()
		assert_object(node).is_not_null()
		node.free()

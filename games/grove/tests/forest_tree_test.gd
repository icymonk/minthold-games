extends GdUnitTestSuite


func test_eight_species() -> void:
	assert_int(ForestTree.SPECIES.size()).is_equal(8)
	for kind in ForestTree.SPECIES:
		assert_int(ForestTree.SPECIES[kind].leaves.size()).is_equal(4)


func test_every_tree_has_four_sockets_around_it() -> void:
	for kind in ForestTree.SPECIES:
		var t: ForestTree = auto_free(ForestTree.make(kind))
		for side in ForestTree.SOCKETS:
			assert_object(t.socket(side)).is_not_null()
		assert_float(t.socket(&"Top").position.y).is_greater(t.socket(&"Bottom").position.y + 2.0)
		assert_float(t.socket(&"Left").position.x).is_less(0.0)
		assert_float(t.socket(&"Right").position.x).is_greater(0.0)


func test_sockets_turn_with_the_tree() -> void:
	var t: ForestTree = auto_free(ForestTree.make(&"oak"))
	add_child(t)
	t.rotation.y = PI
	assert_float(t.socket(&"Left").global_position.x).is_greater(0.0)


func test_season_recolors_leaves() -> void:
	var t: ForestTree = auto_free(ForestTree.make(&"maple"))
	t.set_season(2, false)
	assert_that(t._leaves.get_shader_parameter(&"tint")).is_equal(ForestTree.SPECIES[&"maple"].leaves[2])


func test_demo_forest_leaves_center_plot_empty() -> void:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	var kinds := {}
	for i in ForestView.plot_positions().size():
		var t := view.tree_at(i)
		if i == 4:
			assert_object(t).is_null()
		else:
			kinds[t.species] = true
	assert_int(kinds.size()).is_equal(8)

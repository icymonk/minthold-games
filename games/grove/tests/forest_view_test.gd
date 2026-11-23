extends GdUnitTestSuite


func test_nine_plots_fit_on_island() -> void:
	var plots := ForestView.plot_positions()
	assert_int(plots.size()).is_equal(9)
	var seen := {}
	for p in plots:
		assert_float(Vector2(p.x, p.z).length() + 1.1).is_less(ForestView.ISLAND_RADIUS)
		seen[p] = true
	assert_int(seen.size()).is_equal(9)


func test_land_opens_islets_up_to_25() -> void:
	var all := ForestView.plot_positions(ForestView.MAX_PLOTS)
	assert_int(all.size()).is_equal(25)
	for i in range(9, 25):
		assert_float(Vector2(all[i].x, all[i].z).length() - ForestView.ISLET_RADIUS).is_greater(ForestView.ISLAND_RADIUS)
		for j in range(9, i):
			assert_float(all[i].distance_to(all[j])).is_greater(ForestView.ISLET_RADIUS * 2.0)
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.plant_layout(ForestView.EMPTY_FOREST)
	assert_int(view.targets_for(&"oak").size()).is_equal(9)
	view.open_plots(11, false)
	assert_int(view.targets_for(&"oak").size()).is_equal(11)
	assert_int(view.targets_for(&"oak")[10].plot).is_equal(10)
	view.plant(10, &"fir")
	view.reset_plots()
	assert_int(view.open_count()).is_equal(9)
	assert_object(view.tree_at(10)).is_null()


func test_turn_wraps_in_quarter_steps() -> void:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.turn(-1)
	assert_int(view.turn_step).is_equal(3)
	view.turn(1)
	view.turn(1)
	assert_int(view.turn_step).is_equal(1)


func test_season_changes_grass_color() -> void:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.set_season(2, false)
	assert_that(view.grass_color()).is_equal(ForestView.SEASONS[2][0])


func test_seasons_look_different() -> void:
	var seen := {}
	for s in ForestView.SEASONS:
		seen[s[0].to_html()] = true
	assert_int(seen.size()).is_equal(ForestView.SEASONS.size())

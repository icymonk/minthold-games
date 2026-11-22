extends GdUnitTestSuite


func test_nine_plots_fit_on_island() -> void:
	var plots := ForestView.plot_positions()
	assert_int(plots.size()).is_equal(9)
	var seen := {}
	for p in plots:
		assert_float(Vector2(p.x, p.z).length() + 1.1).is_less(ForestView.ISLAND_RADIUS)
		seen[p] = true
	assert_int(seen.size()).is_equal(9)


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

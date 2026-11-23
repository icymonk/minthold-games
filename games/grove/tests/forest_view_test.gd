extends GdUnitTestSuite


func test_nine_plots_fit_on_island() -> void:
	var plots := ForestView.plot_positions()
	assert_int(plots.size()).is_equal(9)
	var seen := {}
	for p in plots:
		assert_float(Vector2(p.x, p.z).length() + 1.1).is_less(ForestView.ISLAND_RADIUS)
		seen[p] = true
	assert_int(seen.size()).is_equal(9)


func test_online_plots_grow_in_outer_rings() -> void:
	var all := ForestView.plot_positions(70)
	assert_int(all.size()).is_equal(70)
	for i in range(9, 70):
		for j in range(9, i):
			assert_float(all[i].distance_to(all[j])).is_greater(ForestView.ISLET_RADIUS * 2.0)
	assert_array(ForestView.plot_positions(25)).is_equal(all.slice(0, 25))
	assert_float(ForestView.zoom_for(25)).is_equal(ForestView.WIDE_ZOOM)
	assert_float(ForestView.zoom_for(26)).is_greater(ForestView.WIDE_ZOOM)
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.plant_layout(ForestView.EMPTY_FOREST)
	view.open_plots(40, false)
	assert_int(view.targets_for(&"oak").size()).is_equal(40)
	assert_object(view.plant(39, &"fir")).is_not_null()


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


func test_season_props_swap_with_season() -> void:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	for i in 4:
		view.set_season(i, false)
		var props := view.find_children("SeasonProps", "CPUParticles3D", true, false)
		assert_int(props.size()).is_equal(1)
		assert_bool(props[0].emitting).is_true()
	assert_float(auto_free(Fx.season_props(0, 5.0)).gravity.y).is_less(0.0)
	assert_float(auto_free(Fx.season_props(1, 5.0)).gravity.y).is_equal(0.0)


func test_season_ambience_crossfades() -> void:
	var sfx: Node = get_tree().root.get_node(^"Sfx")
	assert_int(sfx.AMBIENCE.size()).is_equal(4)
	sfx.ambience(2)
	assert_int(sfx.ambience_season).is_equal(2)
	sfx.ambience(3)
	assert_int(sfx.ambience_season).is_equal(3)


func test_sapling_preview_of_non_tree_card_shows_sapling() -> void:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.plant_layout(ForestView.EMPTY_FOREST)
	view.preview({plot = 0, side = &""}, &"boar")
	assert_object(view._ghost).is_instanceof(ForestTree)
	assert_str(String(view._ghost.species)).is_equal(String(ForestView.SAPLING_LOOK))
	var t := view.place({plot = 1, side = &""}, &"boar")
	assert_str(String(t.species)).is_equal(String(ForestView.SAPLING_LOOK))

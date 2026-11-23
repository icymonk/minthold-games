extends GdUnitTestSuite

var _screens: Array[StringName] = []


func before_test() -> void:
	_screens = []
	Game.save_path = "user://test_game.save"
	Game.records_path = "user://test_game_records.cfg"
	Game.screen_changed.connect(_on_screen)


func after_test() -> void:
	Game.screen_changed.disconnect(_on_screen)
	Save.clear(Game.save_path)
	Save.clear(Game.records_path)


func _on_screen(screen: StringName, _scene: PackedScene) -> void:
	_screens.append(screen)


func _grow(n: int) -> void:
	for p in n:
		Game.run.forest.plant(p, {id = 5000 + p, sym = &""}, &"fir")


func test_start_run_opens_spring() -> void:
	Game.start_run(1)
	assert_int(Game.season).is_equal(0)
	assert_object(Game.run.season).is_not_null()
	assert_int(Game.run.season.hand.size()).is_equal(Season.START_HAND)
	assert_array(_screens).is_equal([&"season"])


func test_passing_season_goes_to_cabin_then_summer() -> void:
	Game.start_run(2)
	Game.run.events[0] = &"doves"
	_grow(9)
	Game.finish_season()
	Game.after_season()
	assert_str(String(Game.screen)).is_equal("cabin")
	Game.next_season()
	assert_int(Game.season).is_equal(1)
	assert_int(Game.winds).is_equal(0)
	assert_object(Game.run.season.forest).is_same(Game.run.forest)


func test_failing_season_ends_run() -> void:
	Game.start_run(3)
	Game.finish_season()
	Game.after_season()
	assert_str(String(Game.screen)).is_equal("run_end")
	assert_bool(Game.run.lost).is_true()


func test_every_season_has_goal_and_name() -> void:
	assert_int(Game.GOALS.size()).is_equal(Game.SEASON_KEYS.size())
	assert_array(Game.GOALS).is_equal(Run.TARGETS)
	assert_int(ForestView.SEASONS.size()).is_equal(Game.SEASON_KEYS.size())


func test_every_event_has_a_name() -> void:
	for s in Events.BY_SEASON:
		for id: StringName in s:
			assert_str(tr("EVENT_%s" % String(id).to_upper())).is_not_equal("EVENT_%s" % String(id).to_upper())


func test_turn_keys_do_not_use_arrows() -> void:
	var season: GDScript = load("res://scripts/screens/season.gd")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_E
	assert_int(season._turn_dir(key)).is_equal(1)


func test_cabin_land_and_rewards() -> void:
	Game.start_run(5)
	Game.run.events[0] = &"doves"
	_grow(9)
	Game.finish_season()
	var plots := [0]
	var on_plots := func(n: int) -> void: plots[0] = n
	Game.plots_changed.connect(on_plots)
	Game.run.acorns = 10
	assert_bool(Game.buy({t = &"land"})).is_true()
	assert_int(plots[0]).is_equal(11)
	var spirit := Game.run.offers.map(func(o: Dictionary) -> StringName: return o.t).find(&"spirit")
	assert_bool(Game.take_reward(spirit)).is_true()
	assert_int(Game.run.spirits.size()).is_equal(1)
	assert_int(Game.run.offers.size()).is_equal(0)
	Game.plots_changed.disconnect(on_plots)


func test_cabin_saves_and_continue_restores() -> void:
	Game.start_run(3)
	assert_bool(Game.can_continue()).is_false()
	_grow(9)
	Game.finish_season()
	assert_bool(Game.run.lost).is_false()
	Game.after_season()
	assert_bool(Game.can_continue()).is_true()
	var acorns := Game.run.acorns
	Game.run = null
	assert_bool(Game.continue_run()).is_true()
	assert_int(Game.run.acorns).is_equal(acorns)
	assert_int(Game.season).is_equal(0)
	assert_str(String(_screens.back())).is_equal("cabin")
	assert_int(Game.records.seen.get(&"fir", 0)).is_greater(0)

extends GdUnitTestSuite

var _screens: Array[StringName] = []


func before_test() -> void:
	_screens = []
	Game.screen_changed.connect(_on_screen)


func after_test() -> void:
	Game.screen_changed.disconnect(_on_screen)


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

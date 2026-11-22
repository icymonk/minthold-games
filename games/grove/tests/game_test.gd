extends GdUnitTestSuite

var _screens: Array[StringName] = []


func before_test() -> void:
	_screens = []
	Game.screen_changed.connect(_on_screen)


func after_test() -> void:
	Game.screen_changed.disconnect(_on_screen)


func _on_screen(screen: StringName, _scene: PackedScene) -> void:
	_screens.append(screen)


func test_start_run_opens_spring() -> void:
	Game.start_run()
	assert_int(Game.season).is_equal(0)
	assert_int(Game.winds).is_equal(0)
	assert_array(_screens).is_equal([&"season"])


func test_third_wind_ends_season_into_cabin() -> void:
	Game.start_run()
	Game.blow_wind()
	Game.blow_wind()
	assert_str(String(Game.screen)).is_equal("season")
	Game.blow_wind()
	assert_str(String(Game.screen)).is_equal("cabin")
	Game.next_season()
	assert_int(Game.season).is_equal(1)
	assert_int(Game.winds).is_equal(0)


func test_winter_ends_run() -> void:
	Game.start_run()
	for s in 3:
		for w in Game.WINDS_PER_SEASON:
			Game.blow_wind()
		Game.next_season()
	assert_int(Game.season).is_equal(3)
	for w in Game.WINDS_PER_SEASON:
		Game.blow_wind()
	assert_str(String(Game.screen)).is_equal("run_end")


func test_every_season_has_goal_and_name() -> void:
	assert_int(Game.GOALS.size()).is_equal(Game.SEASON_KEYS.size())
	assert_int(ForestView.SEASONS.size()).is_equal(Game.SEASON_KEYS.size())


func test_turn_keys_do_not_use_arrows() -> void:
	var season: GDScript = load("res://scripts/screens/season.gd")
	var key := InputEventKey.new()
	key.pressed = true
	key.keycode = KEY_E
	assert_int(season._turn_dir(key)).is_equal(1)
	key.keycode = KEY_LEFT
	assert_int(season._turn_dir(key)).is_equal(0)
	var pad := InputEventJoypadButton.new()
	pad.pressed = true
	pad.button_index = JOY_BUTTON_LEFT_SHOULDER
	assert_int(season._turn_dir(pad)).is_equal(-1)

extends GdUnitTestSuite
## 규칙 1-3: 한 해(Run)·계절 사건·숲 정령·오두막 보상·도토리·봇


func _fill(run: Run, pts_tree: StringName, n: int) -> void:
	for p in n:
		run.forest.plant(p, {id = 1000 + p, sym = &""}, pts_tree)


func test_events_are_picked_per_season_and_deterministic() -> void:
	var a := Run.new(7)
	var b := Run.new(7)
	assert_array(a.events).is_equal(b.events)
	for s in 4:
		assert_bool(Events.BY_SEASON[s].has(a.events[s])).is_true()


func test_season_uses_event_limits() -> void:
	var run := Run.new(1)
	run.events[0] = &"doves"
	var s := run.begin()
	assert_int(s.clearing_limit).is_equal(8)
	run.season_index = 2
	run.events[2] = &"typhoon"
	s = run.begin()
	assert_int(s.winds).is_equal(4)


func test_pass_target_gives_acorns_and_offers() -> void:
	var run := Run.new(2)
	run.events[0] = &"doves"
	run.begin()
	_fill(run, &"fir", 9)
	var log := run.finish()
	assert_int(log.total).is_equal(54)
	assert_bool(run.lost).is_false()
	assert_int(run.season_index).is_equal(1)
	assert_int(run.acorns).is_greater(0)
	assert_int(run.offers.size()).is_equal(3)


func test_miss_target_loses() -> void:
	var run := Run.new(2)
	run.begin()
	_fill(run, &"birch", 2)
	run.finish()
	assert_bool(run.lost).is_true()
	assert_int(run.season_index).is_equal(0)


func test_forest_stays_between_seasons() -> void:
	var run := Run.new(3)
	run.events[0] = &"doves"
	run.begin()
	_fill(run, &"fir", 9)
	run.finish()
	var s := run.begin()
	assert_object(s.forest).is_same(run.forest)
	assert_int(s.forest.trees.size()).is_equal(9)


func test_event_score_modifier() -> void:
	var run := Run.new(4)
	run.events[0] = &"late_frost"
	run.begin()
	run.forest.plant(0, {id = 900, sym = &""}, &"oak")
	run.forest.attach(0, &"Bottom", {id = 901}, &"flower")
	assert_int(Score.count(run.forest, 0, run.score_mods()).by_what()[&"flower"]).is_equal(1)


func test_survey_cuts_bare_trees() -> void:
	var run := Run.new(5)
	run.season_index = 2
	run.events[2] = &"survey"
	run.begin()
	run.forest.plant(0, {id = 900, sym = &""}, &"fir")
	run.forest.plant(1, {id = 901, sym = &""}, &"fir")
	run.forest.attach(1, &"Bottom", {id = 902}, &"flower")
	run.finish()
	assert_bool(run.forest.trees.has(0)).is_false()
	assert_bool(run.forest.trees.has(1)).is_true()


func test_spirit_multiplier() -> void:
	var f := Forest.new()
	f.plant(0, {id = 1}, &"oak")
	f.plant(1, {id = 2}, &"birch")
	f.attach(0, &"Top", {id = 3}, &"owl")
	f.attach(1, &"Top", {id = 4}, &"finch")
	var owned: Array[StringName] = [&"old_owl"]
	assert_float(Spirits.mult(f, owned)).is_equal_approx(1.2, 0.001)
	owned = [&"firefly"]
	assert_float(Spirits.mult(f, owned)).is_equal(1.0)


func test_bear_ignores_winter_event() -> void:
	var run := Run.new(6)
	run.season_index = 3
	run.events[3] = &"blizzard"
	assert_int(run.begin().hand_limit).is_equal(7)
	run.spirits.append(&"hibernating_bear")
	assert_int(run.begin().hand_limit).is_equal(Season.HAND_LIMIT)


func test_wind_child_draws_extra_on_first_wind() -> void:
	var s := Season.new(Cards.start_bag(), 9)
	s.wind_bonus = 2
	while s.winds_seen == 0:
		s.hand.clear()
		s.draw()
		s.end_turn()
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.get("from") == &"wind")).is_true()


func test_rewards_and_shop() -> void:
	var run := Run.new(8)
	run.offers = Reward.roll(run.rng, run)
	var kinds := run.offers.map(func(o: Dictionary) -> StringName: return o.t)
	assert_array(kinds).is_equal([&"pair", &"spirit", &"remove"])
	for c in run.offers[0].cards:
		for h in 2:
			assert_bool(Cards.fits(c.halves[h], Cards.side_of(c, h))).is_true()
	var size := run.bag.size()
	assert_bool(run.take(0)).is_true()
	assert_int(run.bag.size()).is_equal(size + 2)
	assert_bool(run.buy({t = &"land"})).is_false()
	run.acorns = 10
	assert_bool(run.buy({t = &"land"})).is_true()
	assert_int(run.forest.plots).is_equal(11)
	var ids: Array[int] = [run.bag[0].id, run.bag[1].id]
	assert_bool(run.buy({t = &"remove"}, ids)).is_true()
	assert_int(run.bag.size()).is_equal(size)
	assert_int(run.acorns).is_equal(4)


func test_bot_plays_a_whole_year() -> void:
	var run := Run.new(11)
	Bot.play_run(run)
	assert_bool(run.lost or run.done).is_true()
	assert_int(run.scores.size()).is_greater(0)
	assert_int(run.scores[0].total).is_greater(0)
	var again := Run.new(11)
	Bot.play_run(again)
	assert_int(again.scores.back().total).is_equal(run.scores.back().total)

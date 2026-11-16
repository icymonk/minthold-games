extends GdUnitTestSuite

const S := Match.Side
const TABLE := preload("res://scenes/screens/table.tscn")


func test_day_seeds_are_fixed_by_week_seed() -> void:
	var a := Week.start(11, S.CHIEF, Bot.Level.NORMAL, false)
	var b := Week.start(11, S.STAFF, Bot.Level.HARD, true)
	var seen := {}
	for d in Week.DAYS:
		assert_int(a.day_seed(d)).is_equal(b.day_seed(d))
		seen[a.day_seed(d)] = true
	assert_int(seen.size()).is_equal(Week.DAYS)
	assert_int(Week.start(12, S.CHIEF, Bot.Level.NORMAL, false).day_seed(0)).is_not_equal(a.day_seed(0))


func test_friday_always_has_events() -> void:
	var w := Week.start(1, S.CHIEF, Bot.Level.NORMAL, false)
	for d in Week.FRIDAY:
		assert_bool(w.events_on(d)).is_false()
	assert_bool(w.events_on(Week.FRIDAY)).is_true()
	assert_bool(Week.start(1, S.CHIEF, Bot.Level.NORMAL, true).events_on(0)).is_true()


func test_score_grade_and_roundtrip() -> void:
	var w := Week.start(5, S.STAFF, Bot.Level.EASY, false)
	assert_int(w.grade()).is_equal(0)
	for won in [true, false, true, true]:
		w.record(won)
	assert_int(w.day()).is_equal(4)
	assert_bool(w.is_done()).is_false()
	w.record(false)
	w.record(true)
	assert_bool(w.is_done()).is_true()
	assert_int(w.score()).is_equal(3)
	assert_int(w.grade()).is_equal(2)
	var c := Week.from_dict(w.to_dict())
	assert_int(c.week_seed).is_equal(5)
	assert_int(c.side).is_equal(S.STAFF)
	assert_int(c.level).is_equal(Bot.Level.EASY)
	assert_that(c.wins).is_equal(w.wins)


func _played(winner: int, manhunt: bool) -> Match:
	var m := Match.setup([1, 2, 3, 42], [[4], [15], [29]])
	m.turns[S.STAFF] = 10
	m.manhunted = manhunt
	m.winner = winner
	m.phase = Match.Phase.OVER
	return m


func test_stats_count_per_role() -> void:
	var st := Stats.new()
	st.add(_played(S.CHIEF, true), S.CHIEF)
	st.add(_played(S.STAFF, true), S.CHIEF)
	st.add(_played(S.STAFF, false), S.CHIEF)
	st.add(_played(S.STAFF, false), S.STAFF)
	assert_int(st.games[S.CHIEF]).is_equal(3)
	assert_int(st.win_pct(S.CHIEF)).is_equal(33)
	assert_int(st.manhunt_pct(S.CHIEF)).is_equal(50)
	assert_float(st.avg_turns(S.CHIEF)).is_equal(10.0)
	assert_int(st.win_pct(S.STAFF)).is_equal(100)
	assert_int(st.manhunt_pct(S.STAFF)).is_equal(-1)
	var w := Week.start(1, S.STAFF, Bot.Level.NORMAL, false)
	for i in Week.DAYS:
		w.record(i < 4)
	st.add_week(w)
	var c := Stats.from_dict(st.to_dict())
	assert_int(c.weeks[S.STAFF]).is_equal(1)
	assert_int(c.best_week[S.STAFF]).is_equal(4)
	assert_int(c.best_week[S.CHIEF]).is_equal(-1)
	assert_int(c.games[S.CHIEF]).is_equal(3)


func test_game_runs_a_week_and_saves_it() -> void:
	var saved := [Game.role, Game.level, Game.week, Game.stats, Game.in_week]
	Game.stats = Stats.new()
	Game.role = Game.Role.STAFF
	Game.start_week(77)
	assert_bool(Game.in_week).is_true()
	assert_int(Game.run_seed).is_equal(Game.week.day_seed(0))
	assert_bool(Game.match_events).is_false()
	for d in Week.FRIDAY:
		Game.finish_match(_played(S.STAFF, false))
		Game.play_day()
	assert_bool(Game.match_events).is_true()
	assert_int(Game.run_seed).is_equal(Game.week.day_seed(Week.FRIDAY))
	var cfg := ConfigFile.new()
	assert_int(cfg.load(Game.PREFS)).is_equal(OK)
	assert_that(Week.from_dict(cfg.get_value("record", "week")).wins).is_equal([true, true, true, true])
	Game.finish_match(_played(S.CHIEF, true))
	assert_bool(Game.can_continue_week()).is_false()
	assert_int(Game.stats.weeks[S.STAFF]).is_equal(1)
	assert_int(Game.stats.best_week[S.STAFF]).is_equal(4)
	Game.start_match(5)
	assert_bool(Game.in_week).is_false()
	assert_bool(Game.match_events).is_equal(Game.events)
	Game.role = saved[0]
	Game.level = saved[1]
	Game.week = saved[2]
	Game.stats = saved[3]
	Game.in_week = saved[4]
	Game._save_prefs()


func test_week_result_offers_next_day() -> void:
	var saved := [Game.role, Game.week, Game.stats, Game.in_week]
	Game.stats = Stats.new()
	Game.week = Week.start(3, S.STAFF, Bot.Level.NORMAL, false)
	Game.role = Game.Role.STAFF
	Game.in_week = true
	Game.rng = RngStreams.new(Game.week.day_seed())
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	var guard := 0
	while not t.session.is_over() and guard < 500:
		guard += 1
		if t.session.waiting_for_human():
			t.session.play(t.session.human_moves()[0])
		else:
			t.session.ai_step()
		t.refresh()
	assert_int(Game.week.day()).is_equal(1)
	assert_int(Game.stats.games[S.STAFF]).is_equal(1)
	var texts := PackedStringArray()
	for b in t._overlay.find_children("*", "Button", true, false):
		texts.append(b.text)
	assert_str(" ".join(texts)).contains(tr("RESULT_NEXT_DAY") % tr("DAY_1"))
	assert_str(" ".join(texts)).not_contains(tr("RESULT_SAME"))
	Game.role = saved[0]
	Game.week = saved[1]
	Game.stats = saved[2]
	Game.in_week = saved[3]
	Game._save_prefs()

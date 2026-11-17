extends GdUnitTestSuite


func _played(seed_value: int, steps: int) -> Run:
	var run := Run.new(seed_value, Ledger.new().locked_tips())
	for i in steps:
		if run.is_over():
			break
		Bot.step(run)
	return run


func _same(a: Run, b: Run) -> void:
	assert_int(b.night).is_equal(a.night)
	assert_int(b.slot).is_equal(a.slot)
	assert_int(b.phase).is_equal(a.phase)
	assert_int(b.money).is_equal(a.money)
	assert_int(b.deck.size()).is_equal(a.deck.size())
	assert_array(Run._ids(b.tips)).is_equal(Run._ids(a.tips))
	assert_str(str(b.shift.hand)).is_equal(str(a.shift.hand))
	assert_array(b.history).is_equal(a.history)


func test_replay_rebuilds_the_same_run() -> void:
	for steps in [5, 40, 120]:
		var a := _played(3, steps)
		_same(a, Run.replay(3, a.locked, a.actions))


func test_replay_survives_json() -> void:
	var a := _played(11, 80)
	var data = JSON.parse_string(JSON.stringify({"locked": a.locked, "actions": a.actions}))
	_same(a, Run.replay(11, data.locked, data.actions))


func test_flyer_actions_replay() -> void:
	var a := Run.new(2)
	a.flyers.append(&"gold")
	assert_bool(a.use_flyer(0, [a.shift.hand[2]])).is_true()
	var b := Run.new(2)
	b.flyers.append(&"gold")
	assert_bool(b.apply(a.actions[0])).is_true()
	assert_str(b.shift.hand[2].tag).is_equal(Card.TAG_GOLD)


func test_bad_log_returns_null() -> void:
	assert_object(Run.replay(1, [], [["leave"]])).is_null()


func test_locked_tips_never_offered() -> void:
	var locked := Ledger.new().locked_tips()
	assert_int(locked.size()).is_equal(Ledger.CHALLENGES.size())
	var run := Run.new(5, locked)
	for i in 30:
		run.shop.offers = Shop.roll(run.rng.shop, Run._ids(run.tips) + run.locked, [])
		for o in run.shop.offers:
			if o.kind == Shop.TIP:
				assert_bool(locked.has(o.id)).is_false()


func test_record_unlocks_and_counts() -> void:
	var l := Ledger.new()
	var run := _played(4, 3000)
	var fresh := l.record(run)
	assert_int(l.runs).is_equal(1)
	assert_bool(l.done.has(&"reach_3")).is_equal(run.night >= 3)
	for id in fresh:
		assert_bool(l.locked_tips().has(id)).is_false()
	assert_int(l.seen[&"weather"].size()).is_greater(0)
	assert_int(l.seen[&"boss"].size()).is_greater(0)
	assert_array(l.record(run)).is_empty()


func test_ledger_round_trips_json() -> void:
	var l := Ledger.new()
	l.record(_played(4, 3000))
	var back := Ledger.from_dict(JSON.parse_string(JSON.stringify(l.to_dict())))
	assert_int(back.runs).is_equal(l.runs)
	assert_int(back.best_checkout).is_equal(l.best_checkout)
	assert_array(back.locked_tips()).is_equal(l.locked_tips())
	assert_int(back.seen[&"tip"].size()).is_equal(l.seen[&"tip"].size())


func test_every_challenge_has_text_and_real_tip() -> void:
	for id in Ledger.CHALLENGES:
		assert_str(tr("CH_%s" % String(id).to_upper())).is_not_equal("CH_%s" % String(id).to_upper())
		assert_bool(Tips.MAKERS.has(Ledger.CHALLENGES[id])).is_true()


func test_game_saves_and_continues() -> void:
	Game.save_path = "user://test_run.json"
	Game.ledger_path = "user://test_ledger.json"
	Game.ledger = Ledger.new()
	Game.start_run(9)
	for i in 30:
		Bot.step(Game.run)
	var before := Game.run
	assert_bool(Game.has_save()).is_true()
	Game.run = null
	assert_bool(Game.continue_run()).is_true()
	_same(before, Game.run)
	Bot.play_out(Game.run)
	assert_bool(Game.has_save()).is_false()
	assert_int(Game.ledger.runs).is_equal(1)
	assert_bool(FileAccess.file_exists(Game.ledger_path)).is_true()
	DirAccess.remove_absolute(Game.ledger_path)
	Game.save_path = "user://nightmart_run.json"
	Game.ledger_path = "user://nightmart_ledger.json"
	Game.ledger = Ledger.new()


func test_rich_counts_money_from_flyers_and_sales() -> void:
	var run := Run.new(1)
	run.money = 12000
	run.flyers.append(&"cash")
	assert_bool(run.use_flyer(0)).is_true()
	assert_int(run.best_money).is_equal(17000)
	run.tips.append(Tips.make(&"three_am"))
	run.money = 19000
	assert_bool(run.sell_tip(0)).is_true()
	assert_bool(Ledger.new().met(&"rich", run)).is_true()


func test_no_skip_ignores_skips_after_night_five() -> void:
	var run := Run.new(1)
	run.night = 6
	run.history.append({"night": 5, "slot": Run.NORMAL, "target": 1, "score": 0, "cleared": false, "skipped": true})
	assert_bool(Ledger.new().met(&"no_skip_5", run)).is_true()
	run.history.append({"night": 4, "slot": Run.NORMAL, "target": 1, "score": 0, "cleared": false, "skipped": true})
	assert_bool(Ledger.new().met(&"no_skip_5", run)).is_false()


func test_old_save_version_is_dropped() -> void:
	Game.save_path = "user://test_old_run.json"
	var f := FileAccess.open(Game.save_path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"version": Game.SAVE_VERSION - 1, "seed": "1", "locked": [], "actions": []}))
	f.close()
	assert_bool(Game.continue_run()).is_false()
	assert_bool(Game.has_save()).is_false()
	Game.save_path = "user://nightmart_run.json"

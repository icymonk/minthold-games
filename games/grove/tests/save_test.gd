extends GdUnitTestSuite
## 3-3: 이어 하기 저장·기록·도감

const SAVE := "user://test_run.save"
const RECORDS := "user://test_records.cfg"


func after_test() -> void:
	Save.clear(SAVE)
	Save.clear(RECORDS)


func _passed_spring(seed_value: int) -> Run:
	var run := Run.new(seed_value)
	run.begin()
	for p in 9:
		run.forest.plant(p, {id = 1000 + p, sym = &""}, &"pine")
	run.forest.attach(0, &"Top", {id = 2000}, &"goshawk")
	run.finish()
	return run


func test_round_trip_keeps_run_and_rng() -> void:
	var run := _passed_spring(11)
	run.spirits.append(&"firefly")
	assert_int(run.season_index).is_equal(1)
	Save.write(run, SAVE)
	var back := Save.read(SAVE)
	assert_object(back).is_not_null()
	assert_int(back.season_index).is_equal(1)
	assert_int(back.acorns).is_equal(run.acorns)
	assert_int(back.bag.size()).is_equal(run.bag.size())
	assert_int(back.forest.trees.size()).is_equal(9)
	assert_str(String(back.forest.occupants(0, &"Top")[0].species)).is_equal("goshawk")
	assert_array(back.spirits).is_equal(run.spirits)
	assert_int(back.scores[0].total).is_equal(run.scores[0].total)
	assert_int(back.offers.size()).is_equal(run.offers.size())
	assert_int(back.new_id()).is_equal(run.new_id())
	# 같은 rng 상태에서 이어지므로 다음 계절도 똑같다
	var a := run.begin()
	var b := back.begin()
	assert_array(b.hand.map(func(c: Dictionary) -> int: return c.id)).is_equal(a.hand.map(func(c: Dictionary) -> int: return c.id))


func test_bad_or_missing_save_is_ignored() -> void:
	assert_object(Save.read(SAVE)).is_null()
	var f := FileAccess.open(SAVE, FileAccess.WRITE)
	f.store_string("{\"v\": 99}")
	f.close()
	assert_object(Save.read(SAVE)).is_null()


func test_records_track_seasons_runs_and_codex() -> void:
	var r := Records.new()
	var run := _passed_spring(12)
	var fresh := r.note_season(0, run.scores[0], run.forest)
	assert_array(fresh).contains([&"pine", &"goshawk"])
	assert_array(r.note_season(0, run.scores[0], run.forest)).is_empty()
	assert_int(r.found()).is_equal(2)
	assert_int(r.best_season[0]).is_equal(run.scores[0].total)
	run.lost = true
	r.note_run(run)
	r.save(RECORDS)
	var back := Records.load_file(RECORDS)
	assert_int(back.runs).is_equal(1)
	assert_int(back.finished).is_equal(0)
	assert_int(back.best_year).is_equal(run.scores[0].total)
	assert_int(back.seen[&"goshawk"]).is_equal(2)
	assert_int(Records.all_kinds().size()).is_equal(Cards.TREES.size() + 49)


func test_keepers_change_bag_spirit_and_unlock() -> void:
	assert_int(Keepers.ALL.size()).is_equal(8)
	var base := Run.new(3)
	var bird := Run.new(3, &"bird_doctor")
	assert_int(bird.bag.size()).is_equal(base.bag.size() + 3)
	assert_array(bird.owned()).contains([&"old_owl"])
	assert_array(bird.spirits).is_empty()
	assert_int(Run.new(3, &"acorn_merchant").acorns).is_equal(8)
	for id: StringName in Keepers.ALL:
		for p: int in Keepers.ALL[id].pairs:
			var card := Cards.full_pair(0, p)
			assert_bool(Cards.fits(card.halves[0], Cards.side_of(card, 0)) and Cards.fits(card.halves[1], Cards.side_of(card, 1))).override_failure_message(str(p)).is_true()
		var s: StringName = Keepers.ALL[id].spirit
		assert_bool(s == &"" or Spirits.ALL.has(s)).is_true()
	var r := Records.new()
	assert_bool(Keepers.unlocked(&"grandma", r)).is_true()
	assert_bool(Keepers.unlocked(&"bird_doctor", r)).is_false()
	r.runs = 1
	assert_bool(Keepers.unlocked(&"bird_doctor", r)).is_true()


func test_grades_stack_and_round_trip() -> void:
	assert_int(Run.new(1).target_of(0)).is_equal(35)
	var hard := Run.new(1, &"grandma", 8)
	assert_int(hard.target_of(3)).is_equal(1080)
	var s := hard.begin()
	assert_int(s.clearing_limit).is_less(Run.new(1).begin().clearing_limit + 1)
	var m := Keepers.grade_mods(6)
	assert_float(m.target).is_equal(1.2)
	assert_int(m.winter_winds).is_equal(-1)
	assert_float(m.acorns).is_equal(0.75)
	var r := Records.new()
	assert_int(r.open_grade()).is_equal(0)
	hard.done = true
	r.note_run(hard)
	assert_int(r.open_grade()).is_equal(8)
	Save.write(Run.new(4, &"ranger", 3), SAVE)
	var back := Save.read(SAVE)
	assert_str(String(back.keeper)).is_equal("ranger")
	assert_int(back.grade).is_equal(3)


func test_album_keeps_latest_photos() -> void:
	var r := Records.new()
	for i in Records.ALBUM_MAX + 3:
		r.add_photo({file = "user://none_%d.png" % i, year = i, keeper = &"grandma", grade = 0})
	assert_int(r.album.size()).is_equal(Records.ALBUM_MAX)
	assert_int(r.album[0].year).is_equal(3)


func test_endless_year_keeps_forest_and_counts_once() -> void:
	var run := Run.new(5)
	run.forest.plant(4, {id = 900, sym = &""}, &"oak")
	assert_bool(run.next_year()).is_false()
	run.season_index = 4
	run.done = true
	var r := Records.new()
	r.note_run(run)
	assert_bool(run.next_year()).is_true()
	assert_int(run.year).is_equal(1)
	assert_int(run.season_index).is_equal(0)
	assert_int(run.target_of(0)).is_equal(60)
	assert_int(run.offers.size()).is_equal(3)
	assert_int(run.events.size()).is_equal(4)
	assert_bool(run.forest.trees.has(4)).is_true()
	run.lost = true
	r.note_run(run)
	assert_int(r.runs).is_equal(1)
	assert_int(r.finished).is_equal(1)
	assert_int(r.best_endless).is_equal(1)
	Save.write(run, SAVE)
	assert_int(Save.read(SAVE).year).is_equal(1)


func test_daily_forest_is_same_for_the_day() -> void:
	assert_int(Game.daily_seed("2026-11-23")).is_equal(Game.daily_seed("2026-11-23"))
	assert_int(Game.daily_seed("2026-11-23")).is_not_equal(Game.daily_seed("2026-11-24"))
	assert_bool(Keepers.ALL.has(Game.daily_keeper("2026-11-23"))).is_true()
	var run := Run.new(Game.daily_seed("2026-11-23"), Game.daily_keeper("2026-11-23"))
	run.daily = "2026-11-23"
	run.lost = true
	var r := Records.new()
	r.note_run(run)
	assert_bool(r.daily.has("2026-11-23")).is_true()


func test_content_counts_and_models() -> void:
	assert_int(Cards.SPECIES.size()).is_equal(49)
	assert_int(Spirits.ALL.size()).is_equal(60)
	for s in Events.BY_SEASON:
		assert_int(s.size()).is_equal(8)
	for k: StringName in Cards.SPECIES:
		assert_bool(Dweller.KINDS.has(k)).override_failure_message(String(k)).is_true()
		assert_str(tr("KIND_%s" % String(k).to_upper())).is_not_equal("KIND_%s" % String(k).to_upper())
	for k: StringName in Spirits.ALL:
		assert_str(tr("SPIRIT_%s_DESC" % String(k).to_upper())).is_not_equal("SPIRIT_%s_DESC" % String(k).to_upper())

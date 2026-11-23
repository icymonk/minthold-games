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
		run.forest.plant(p, {id = 1000 + p, sym = &""}, &"fir")
	run.forest.attach(0, &"Top", {id = 2000}, &"eagle")
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
	assert_str(String(back.forest.occupants(0, &"Top")[0].species)).is_equal("eagle")
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
	assert_array(fresh).contains([&"fir", &"eagle"])
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
	assert_int(back.seen[&"eagle"]).is_equal(2)
	assert_int(Records.all_kinds().size()).is_equal(Cards.TREES.size() + 40)

extends GdUnitTestSuite
## 번역 표(ko/en) 검수: 빈 칸, 자리표시자 차이, 코드에서 쓰는 키 누락.

const CSV := "res://i18n/strings.csv"


func _rows() -> Dictionary:
	var f := FileAccess.open(CSV, FileAccess.READ)
	var out := {}
	f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 3 and not line[0].is_empty():
			out[line[0]] = line
	return out


func _placeholders(s: String) -> PackedStringArray:
	var re := RegEx.create_from_string("%(?:\\.\\d+)?[sdf%]")
	var out := PackedStringArray()
	for m in re.search_all(s):
		out.append(m.get_string())
	return out


func _scripts(dir: String, out: PackedStringArray) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".gd"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_scripts(dir.path_join(d), out)


func test_every_row_is_filled_and_placeholders_match() -> void:
	var rows := _rows()
	assert_int(rows.size()).is_greater(100)
	for key in rows:
		var r: PackedStringArray = rows[key]
		assert_str(r[1].strip_edges()).override_failure_message("ko empty: " + key).is_not_empty()
		assert_str(r[2].strip_edges()).override_failure_message("en empty: " + key).is_not_empty()
		assert_that(_placeholders(r[2])).override_failure_message("placeholders differ: " + key).is_equal(_placeholders(r[1]))


func test_keys_used_in_code_exist() -> void:
	var rows := _rows()
	var files := PackedStringArray()
	_scripts("res://scripts", files)
	var re := RegEx.create_from_string("tr\\(\"([A-Z0-9_\\-]+)\"\\)")
	var used := {}
	for path in files:
		for m in re.search_all(FileAccess.get_file_as_string(path)):
			used[m.get_string(1)] = true
	for i in range(-1, 3):
		used["ZONE_%d" % i] = true
	for i in Events.Id.size():
		used["EVENT_%d" % i] = true
		used["EVENT_%d_DESC" % i] = true
	for i in Bot.Level.size():
		used["LEVEL_%d" % i] = true
	for i in Week.DAYS:
		used["DAY_%d" % i] = true
	for who in ["STAFF", "CHIEF"]:
		for g in 4:
			used["WEEK_GRADE_%s_%d" % [who, g]] = true
	assert_int(used.size()).is_greater(80)
	for key in used:
		assert_bool(rows.has(key)).override_failure_message("missing key: " + key).is_true()


func test_english_times_use_the_wall_clock_format() -> void:
	var rows := _rows()
	for key in rows:
		var en: String = rows[key][2]
		for old in ["5:18", "6:00", "5:49", " PM"]:
			assert_str(en).override_failure_message("%s uses 12h time" % key).not_contains(old)

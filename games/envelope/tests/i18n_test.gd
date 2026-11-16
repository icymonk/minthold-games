extends GdUnitTestSuite
## 3-4 번역 검수: 모든 줄에 ko·en이 있고, 서식 자리(%d, %s)가 두 언어에서 같은 순서인지 본다.

var _fmt := RegEx.create_from_string("%[ds]")
var _used := RegEx.create_from_string("tr\\(\"([A-Z0-9_]+)\"")


func _rows() -> Dictionary:
	var out := {}
	var f := FileAccess.open("res://i18n/strings.csv", FileAccess.READ)
	f.get_csv_line()
	while not f.eof_reached():
		var line := f.get_csv_line()
		if line.size() >= 3 and not line[0].is_empty():
			out[line[0]] = line
	return out


func _specs(text: String) -> Array[String]:
	var out: Array[String] = []
	for m in _fmt.search_all(text.replace("%%", "")):
		out.append(m.get_string())
	return out


func test_every_row_has_both_languages_with_matching_placeholders() -> void:
	var rows := _rows()
	assert_int(rows.size()).is_greater(100)
	for key in rows:
		var row: PackedStringArray = rows[key]
		assert_str(row[1]).override_failure_message("%s ko" % key).is_not_empty()
		assert_str(row[2]).override_failure_message("%s en" % key).is_not_empty()
		assert_array(_specs(row[2])).override_failure_message(key).is_equal(_specs(row[1]))


func test_every_literal_key_in_scripts_exists() -> void:
	var rows := _rows()
	for dir in ["res://scripts/screens", "res://scripts/ui", "res://scripts/play"]:
		for file in DirAccess.get_files_at(dir):
			if not file.ends_with(".gd"):
				continue
			var src := FileAccess.get_file_as_string("%s/%s" % [dir, file])
			for m in _used.search_all(src):
				assert_bool(rows.has(m.get_string(1))).override_failure_message("%s: %s" % [file, m.get_string(1)]).is_true()

extends ScreenBase
## 런 끝(2-2): 숲이 한 바퀴 도는 동안 결과 — 계절별 점수와 목표, 정령, 도토리.


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var col := _frame()
	var run: Run = Game.run
	var lost := run != null and run.lost
	_label(col, tr("RUN_END_LOSE") if lost else tr("RUN_END_WIN"), Style.SCORE, Style.BERRY if lost else Style.SPROUT)
	if run and (run.year > 0 or run.daily != ""):
		var tags: Array[String] = []
		if run.daily != "":
			tags.append(tr("DAILY_TAG") % run.daily)
		if run.year > 0:
			tags.append(tr("RUN_END_YEAR") % (run.year + 1))
		_label(col, " · ".join(tags), 32, Style.SUNSET)
	if run:
		var row := _glass(col)
		row.get_parent().size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var year := run.year_scores()
		for i in year.size():
			var cell := VBoxContainer.new()
			cell.custom_minimum_size.x = 220
			row.add_child(cell)
			_label(cell, Game.season_name(i), Style.BODY)
			var passed: bool = year[i].total >= run.target_of(i)
			_label(cell, str(year[i].total), Style.HEADLINE, Style.SPROUT if passed else Style.BERRY)
			_label(cell, tr("SEASON_GOAL") % run.target_of(i), 28, Color(Style.CREAM, 0.8))
		var trees := run.forest.trees.size()
		_label(col, tr("RUN_END_FOREST") % [trees, run.forest.neighbors().size()], 32)
	_spacer(col)
	var buttons := _row(col)
	_button(buttons, Art.ICON_HOME, tr("BACK_TO_TITLE"), Game.goto.bind(&"title"), 360)
	var again := _button(buttons, Art.ICON_RETRY, tr("RUN_END_RETRY"), Game.start_run.bind(-1), 480)
	again.theme_type_variation = &"AccentButton"
	again.grab_focus()
	if run and run.done and not run.lost:
		var more := _button(buttons, Art.ICON_NEXT, tr("RUN_END_NEXT_YEAR") % (run.year + 2), Game.next_year, 420)
		again.theme_type_variation = &""
		more.theme_type_variation = &"AccentButton"
		more.grab_focus()

	if Game.photo_pending:
		_snap.call_deferred()


## 화면 글자를 잠깐 숨기고 숲만 찍어 앨범에 남긴다
func _snap() -> void:
	modulate.a = 0.0
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	modulate.a = 1.0
	if img and not img.is_empty():
		img.resize(480, 270, Image.INTERPOLATE_LANCZOS)
	Game.save_photo(img)

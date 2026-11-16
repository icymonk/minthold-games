extends GdUnitTestSuite


func test_theme_has_accent_button() -> void:
	var t := Style.make_theme()
	assert_bool(t.is_type_variation(&"AccentButton", &"Button")).is_true()


func test_sizes_follow_game_guide() -> void:
	assert_int(Style.HEADLINE).is_greater_equal(64)
	assert_int(Style.BODY).is_greater_equal(40)
	assert_int(Style.SCORE).is_greater_equal(120)
	assert_int(Style.BUTTON_H).is_greater_equal(160)

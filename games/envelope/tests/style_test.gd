extends GdUnitTestSuite


func test_theme_has_accent_button() -> void:
	var t := Style.make_theme()
	assert_bool(t.is_type_variation(&"AccentButton", &"Button")).is_true()

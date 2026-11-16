extends GdUnitTestSuite

const STEPS := [
	{"id": &"grab", "text": "COACH_PICK", "wait": &"grabbed"},
	{"id": &"gauge", "text": "COACH_CHECKOUT", "wait": &"tap"},
]
const PATH := "user://coach_test.cfg"


func before_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))


func _coach() -> Coach:
	var c: Coach = auto_free(Coach.new())
	c.save_path = PATH
	c.rect_of = func(_id: StringName) -> Rect2: return Rect2(100, 100, 50, 50)
	add_child(c)
	return c


func test_waits_for_the_right_event() -> void:
	var c := _coach()
	assert_bool(c.start(&"t", STEPS)).is_true()
	c.notify(&"tap")
	assert_str(c.current_id()).is_equal("grab")
	c.notify(&"grabbed")
	assert_str(c.current_id()).is_equal("gauge")
	c.notify(&"tap")
	assert_bool(c.running()).is_false()
	assert_bool(c.seen()).is_true()


func test_spotlight_passes_clicks_inside_only() -> void:
	var c := _coach()
	c.start(&"t", STEPS)
	assert_bool(c.current_rect().has_point(Vector2(120, 120))).is_true()
	assert_bool(c.current_rect().has_point(Vector2(10, 10))).is_false()
	assert_bool(c._shade._has_point(Vector2(120, 120))).is_false()
	c.notify(&"grabbed")
	assert_bool(c._shade._has_point(Vector2(120, 120))).is_true()
	c.pause()
	assert_bool(c.current_rect().has_area()).is_false()
	c.resume()
	assert_bool(c.current_rect().has_area()).is_true()


func test_skip_finishes_and_is_remembered() -> void:
	var c := _coach()
	c.start(&"t", STEPS)
	c.skip()
	assert_bool(c.running()).is_false()
	assert_bool(_coach().start(&"t", STEPS)).is_false()
	assert_bool(_coach().start(&"other", STEPS)).is_true()

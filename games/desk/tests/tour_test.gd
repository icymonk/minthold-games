extends GdUnitTestSuite

const TABLE := preload("res://scenes/screens/table.tscn")


func test_bubble_stays_on_screen() -> void:
	var screen := Vector2(1920, 1080)
	var bubble := Vector2(620, 300)
	for r in [Rect2(0, 0, 1920, 120), Rect2(20, 900, 400, 160), Rect2(1400, 100, 500, 900), Rect2(0, 0, 1920, 1080)]:
		var p := Tour.bubble_position(r, bubble, screen)
		assert_bool(Rect2(Vector2.ZERO, screen).encloses(Rect2(p, bubble))).is_true()
	var below := Tour.bubble_position(Rect2(100, 100, 200, 100), bubble, screen)
	assert_float(below.y).is_greater(200.0)


func _table(role: int) -> Control:
	var keep := Game.role
	Game.role = role as Game.Role
	var holder := Control.new()
	holder.size = Vector2(1920, 1080)
	add_child(auto_free(holder))
	var t: Control = TABLE.instantiate()
	holder.add_child(t)
	Game.role = keep
	return t


func test_tour_walks_each_role_and_is_remembered() -> void:
	var seen: Dictionary = Game.tour_seen
	var off: bool = Game.tips_off
	Game.tour_seen = {}
	Game.tips_off = false
	for role in [Game.Role.CHIEF, Game.Role.STAFF]:
		var t := _table(role)
		await await_idle_frame()
		await await_idle_frame()
		await await_idle_frame()
		var tour: Tour = t._tour
		assert_bool(tour.is_active()).is_true()
		assert_vector(t.size).is_equal(Vector2(1920, 1080))
		assert_vector(tour.size).is_equal(Vector2(1920, 1080))
		var targets := tour.steps.map(func(s: Dictionary) -> Control: return s.target)
		if role == Game.Role.CHIEF:
			assert_bool(t._memo_box in targets).is_true()
			assert_bool(t._guess in targets).is_true()
		else:
			assert_bool(t._slot_panel in targets).is_true()
			assert_bool(t._pass in targets).is_true()
		assert_object(tour.current().target).is_same(t._clock_panel)
		tour.go(1)
		assert_object(tour.current().target).is_same(t._decks_panel)
		for i in tour.steps.size():
			tour.go(1)
		assert_bool(tour.is_active()).is_false()
		assert_bool(Game.tour_seen.has(t.session.human)).is_true()
		t.start_tour()
		assert_bool(tour.is_active()).is_true()
		for i in 4:
			tour._cycle_focus(1)
			assert_bool(tour._owns_focus()).is_true()
		assert_int(t._menu.get_child(0).focus_mode).is_equal(Control.FOCUS_ALL)
		tour.stop()
	var again := _table(Game.Role.CHIEF)
	await await_idle_frame()
	await await_idle_frame()
	assert_bool(again._tour.is_active()).is_false()
	Game.tour_seen = seen
	Game.tips_off = off


func test_title_role_cards_pick_role() -> void:
	var keep := Game.role
	var title: Control = auto_free(load("res://scenes/screens/title.tscn").instantiate())
	add_child(title)
	var staff: Button = title._role_cards[Game.Role.STAFF]
	var chief: Button = title._role_cards[Game.Role.CHIEF]
	assert_object(staff.find_children("*", "TextureRect", true, false)[0].texture).is_not_null()
	staff.pressed.emit()
	assert_int(Game.role).is_equal(Game.Role.STAFF)
	assert_float(staff.modulate.a).is_equal(1.0)
	assert_float(chief.modulate.a).is_less(1.0)
	chief.pressed.emit()
	assert_int(Game.role).is_equal(Game.Role.CHIEF)
	Game.role = keep

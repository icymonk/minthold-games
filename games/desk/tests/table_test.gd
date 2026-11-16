extends GdUnitTestSuite

const TABLE := preload("res://scenes/screens/table.tscn")
const S := Match.Side


func _human_bot(s: Session) -> Bot:
	var r := RandomNumberGenerator.new()
	r.seed = 5
	return StaffBot.new(r) if s.human == S.STAFF else ChiefBot.new(r)


func _finish(s: Session, on_step: Callable = Callable()) -> void:
	var me := _human_bot(s)
	var guard := 0
	while not s.is_over() and guard < 500:
		guard += 1
		if s.waiting_for_human():
			var moves := s.human_moves()
			assert_bool(s.play(me.choose(s.view(), moves)) or s.play(moves[0])).is_true()
		else:
			assert_bool(s.ai_step()).is_true()
		if on_step.is_valid():
			on_step.call()
	assert_bool(s.is_over()).is_true()


func test_session_finishes_for_both_roles() -> void:
	for side in [S.STAFF, S.CHIEF]:
		for g in 8:
			_finish(Session.new(side, RngStreams.new(g)))


func test_turns_are_enforced() -> void:
	var s := Session.new(S.CHIEF, RngStreams.new(2))
	assert_bool(s.waiting_for_human()).is_false()
	assert_bool(s.play({ side = S.CHIEF, action = Match.Action.DRAW, zone = 0 })).is_false()
	while not s.waiting_for_human():
		assert_bool(s.ai_step()).is_true()
	assert_bool(s.ai_step()).is_false()
	assert_bool(s.play(s.human_moves()[0])).is_true()


func test_chief_log_never_names_hidden_records() -> void:
	var before: int = Game.role
	Game.role = Game.Role.CHIEF
	Game.rng = RngStreams.new(7)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	_finish(t.session, t.refresh)
	for rec in t.session.m.history:
		var line: String = t.describe(rec)
		assert_str(line).is_not_empty()
		if rec.side == S.STAFF and rec.has(&"card") and rec.card != Cards.LAST:
			assert_str(line).not_contains(Cards.time_text(rec.card))
	Game.role = before


func test_table_shows_result_for_staff() -> void:
	var before: int = Game.role
	Game.role = Game.Role.STAFF
	Game.rng = RngStreams.new(3)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	assert_bool(t._overlay.visible).is_false()
	_finish(t.session, t.refresh)
	assert_bool(t._overlay.visible).is_true()
	Game.role = before


func test_big_hand_wraps_inside_screen() -> void:
	var before: int = Game.role
	Game.role = Game.Role.CHIEF
	Game.rng = RngStreams.new(4)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	t.size = Vector2(1920, 1080)
	t.session.m.hands[S.CHIEF].assign(range(4, 29))
	t.refresh()
	await await_idle_frame()
	assert_float(t._guess.get_global_rect().end.x).is_less_equal(1920.0)
	Game.role = before

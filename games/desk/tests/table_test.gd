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


func test_revealed_sprint_cards_are_shown_and_struck() -> void:
	var before: int = Game.role
	Game.role = Game.Role.CHIEF
	Game.rng = RngStreams.new(4)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	var m: Match = t.session.m
	m.hideouts.append({ card = 9, sprints = [6] as Array[int], revealed = true })
	m.side = S.CHIEF
	m.phase = Match.Phase.ACT
	t.refresh()
	var texts := PackedStringArray()
	for l in t._row.get_child(1).find_children("*", "Label", true, false):
		texts.append(l.text)
	assert_str(" ".join(texts)).contains("6")
	var six: Button = t._memo.get_child(5)
	assert_str(six.text).is_equal("6")
	assert_bool(six.disabled).is_true()
	Game.role = before


## 사원이 2를 내고 쉰 뒤, 팀장(사람)이 5·6을 뽑은 판.
func _chief_table() -> Control:
	Game.role = Game.Role.CHIEF
	Game.rng = RngStreams.new(1)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	var m := Match.setup([1, 2, 3, 42], [[4, 5, 6], [15, 16], [29, 30]])
	assert_bool(m.apply({ side = S.STAFF, action = Match.Action.PLACE, card = 2, sprints = [] as Array[int] })).is_true()
	assert_bool(m.apply({ side = S.STAFF, action = Match.Action.PASS })).is_true()
	for i in 2:
		assert_bool(m.apply({ side = S.CHIEF, action = Match.Action.DRAW, zone = 0 })).is_true()
	t.session.m = m
	t.refresh()
	return t


func _memo_button(t: Control, n: int) -> Button:
	return t._memo.get_child(n - 1)


func test_memo_strikes_impossible_numbers() -> void:
	var before: int = Game.role
	var t := _chief_table()
	for n in [1, 2, 3]:
		assert_bool(_memo_button(t, n).disabled).is_false()
	for n in [4, 5, 20]:
		assert_bool(_memo_button(t, n).disabled).is_true()
	Game.role = before


func test_multi_guess_sends_every_pick() -> void:
	var before: int = Game.role
	var t := _chief_table()
	t._on_memo(3)
	t._on_memo(1)
	assert_str(t._warn.text).is_not_empty()
	t._on_guess()
	var last: Dictionary = t.session.m.history[-1]
	assert_array(last.numbers).is_equal([1, 3])
	assert_bool(last.hit).is_false()
	assert_str(t._banner.text).is_not_empty()
	Game.role = before


func test_manhunt_keeps_single_pick() -> void:
	var before: int = Game.role
	var t := _chief_table()
	t.session.m.phase = Match.Phase.MANHUNT
	t._on_memo(1)
	t._on_memo(2)
	assert_array(t._picked).is_equal([2])
	Game.role = before


func test_manual_marks_lock_numbers() -> void:
	var before: int = Game.role
	var t := _chief_table()
	t._on_memo(3)
	t.set_mark_mode(true)
	t._on_memo(3)
	assert_bool(t.marks.has(3)).is_true()
	assert_array(t._picked).is_empty()
	t.set_mark_mode(false)
	assert_bool(_memo_button(t, 3).disabled).is_true()
	t.set_mark_mode(true)
	t._on_memo(3)
	assert_bool(t.marks.has(3)).is_false()
	Game.role = before


func test_hit_flips_card() -> void:
	var before: int = Game.role
	var t := _chief_table()
	t._on_memo(2)
	t._on_guess()
	assert_bool(t.session.m.history[-1].hit).is_true()
	var card: Control = t._row.get_child(1)
	assert_float(card.scale.x).is_less(1.0)
	Game.role = before


func test_marks_work_outside_guess_phase() -> void:
	var before: int = Game.role
	var t := _chief_table()
	t.session.m.side = S.STAFF
	t.session.m.phase = Match.Phase.ACT
	t._timer.paused = true
	t.refresh()
	assert_bool(_memo_button(t, 3).disabled).is_true()
	t.set_mark_mode(true)
	assert_bool(_memo_button(t, 3).disabled).is_false()
	t._on_memo(3)
	assert_bool(t.marks.has(3)).is_true()
	Game.role = before


func _staff_table(hand: Array) -> Control:
	Game.role = Game.Role.STAFF
	Game.rng = RngStreams.new(1)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	t.session.m = Match.setup(hand, [[4, 6, 7], [15, 16], [29, 30]])
	t.refresh()
	return t


func _hand_button(t: Control, c: int) -> Button:
	for b in t._hand.get_children():
		if (b as Button).text.ends_with("\n%d" % c) or (b as Button).text.contains("\n%d\n" % c):
			return b
	return null


func test_drag_to_row_places_card() -> void:
	var before: int = Game.role
	var t := _staff_table([1, 3, 5, 42])
	assert_bool(t.can_drop_row(Vector2.ZERO, { card = 42 })).is_false()
	assert_bool(t.can_drop_row(Vector2.ZERO, { card = 3 })).is_true()
	t.drop_row(Vector2.ZERO, { card = 3 })
	var last: Dictionary = t.session.m.history[-1]
	assert_int(last.card).is_equal(3)
	assert_array(last.sprints).is_empty()
	Game.role = before


func test_slot_extends_reach_and_is_spent() -> void:
	var before: int = Game.role
	var t := _staff_table([1, 3, 5, 42])
	assert_bool(t.can_drop_slot(Vector2.ZERO, { card = 42 })).is_false()
	t.drop_slot(Vector2.ZERO, { card = 3 })
	assert_array(t._slot).is_equal([3])
	assert_object(_hand_button(t, 3)).is_null()
	assert_str(t._slot_title.text).contains("+2")
	var lit: Panel = t._clock.get_child(5)
	assert_object(lit.get_theme_stylebox(&"panel").bg_color).is_equal(Style.POSTIT)
	t.drop_row(Vector2.ZERO, { card = 5 })
	var last: Dictionary = t.session.m.history[-1]
	assert_int(last.card).is_equal(5)
	assert_array(last.sprints).is_equal([3])
	assert_array(t._slot).is_empty()
	Game.role = before


func test_slot_bluff_spends_extra_sprints() -> void:
	var before: int = Game.role
	var t := _staff_table([1, 3, 5, 42])
	t.drop_slot(Vector2.ZERO, { card = 1 })
	t._play(t.place_move(3))
	assert_array(t.session.m.history[-1].sprints).is_equal([1])
	Game.role = before


func test_slot_card_returns_to_hand() -> void:
	var before: int = Game.role
	var t := _staff_table([1, 3, 5, 42])
	t.drop_slot(Vector2.ZERO, { card = 1 })
	assert_bool(t.can_drop_hand(Vector2.ZERO, { card = 1 })).is_true()
	t.drop_hand(Vector2.ZERO, { card = 1 })
	assert_array(t._slot).is_empty()
	for card in t._row.get_children():
		assert_int((card as Control).mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)
	assert_object(_hand_button(t, 1)).is_not_null()
	Game.role = before


func test_chief_has_no_sprint_slot() -> void:
	var before: int = Game.role
	var t := _chief_table()
	assert_bool(t._slot_panel.visible).is_false()
	assert_bool(t.can_drop_slot(Vector2.ZERO, { card = 1 })).is_false()
	Game.role = before

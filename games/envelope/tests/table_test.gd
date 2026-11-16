extends GdUnitTestSuite

const TABLE := preload("res://scenes/screens/table.tscn")


func _human_bot(s: Session) -> Bot:
	return Bot.new(Session.HUMAN, RandomNumberGenerator.new())


func _finish(s: Session, on_step: Callable = Callable()) -> void:
	var me := _human_bot(s)
	var guard := 0
	while not s.is_over() and guard < 400:
		guard += 1
		if s.waiting_for_human():
			var k := s.view()
			if k.request.is_empty():
				assert_bool(s.play(me.choose_move(k, s.m.legal_moves(Session.HUMAN)))).is_true()
			else:
				assert_bool(s.answer(me.choose_answer(k))).is_true()
		else:
			assert_bool(s.ai_step()).is_true()
		if on_step.is_valid():
			on_step.call()
	assert_bool(s.is_over()).is_true()


func test_session_finishes_with_human_seat_for_every_player_count() -> void:
	for n in range(3, 7):
		for g in 10:
			var s := Session.new(n, RngStreams.new(n * 100 + g))
			_finish(s)
			assert_int(s.events.size()).is_equal(s.m.history.filter(func(h: Dictionary) -> bool: return h.has(&"action")).size())


func test_ai_waits_for_human_and_human_cannot_act_out_of_turn() -> void:
	var s := Session.new(4, RngStreams.new(3))
	while not s.waiting_for_human():
		assert_bool(s.ai_step()).is_true()
	assert_bool(s.ai_step()).is_false()
	if s.view().request.is_empty():
		var mv: Dictionary = s.m.legal_moves(Session.HUMAN)[0]
		assert_bool(s.answer(0)).is_false()
		assert_bool(s.play(mv)).is_true()


func test_log_never_names_hidden_cards() -> void:
	Game.players = 5
	Game.rng = RngStreams.new(11)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	_finish(t.session, t.refresh)
	for mv in t.session.events:
		var line: String = t.describe(mv)
		if mv.action != Match.Action.PLAY:
			for id in Cards.DEFS:
				assert_str(line).not_contains(tr(Cards.name_key(id)))


func test_table_draws_whole_game_and_result() -> void:
	for n in range(3, 7):
		Game.players = n
		Game.rng = RngStreams.new(n)
		var t: Control = auto_free(TABLE.instantiate())
		add_child(t)
		_finish(t.session, t.refresh)
		t.refresh()
		assert_bool(t.session.is_over()).is_true()
		assert_int(t._overlay.get_child_count()).is_greater(0)
		for step in t.get_script().RESULT_STEPS:
			assert_int(t.result_step).is_equal(step)
			var labels := _labels(t._overlay)
			assert_bool(labels.has(tr("RESULT_STEP") % [step + 1, t.get_script().RESULT_STEPS])).is_true()
			var next := _button(t._overlay, tr("RESULT_NEXT"))
			if step < t.get_script().RESULT_STEPS - 1:
				next.pressed.emit()
			else:
				assert_object(next).is_null()
				assert_object(_button(t._overlay, tr("RESULT_AGAIN"))).is_not_null()
				assert_bool(labels.has(t.ending_text(t.session.result()))).is_true()
		t._timer.stop()
		remove_child(t)


func test_settlement_lists_envelope_and_note_kinds() -> void:
	var C := Cards.Id
	var m := Match.from_hands([[C.CHAIR, C.HR], [C.THIEF, C.ACCOUNTANT], [C.MISER, C.BUSYBODY]])
	m.turn = 0
	m.apply({ seat = 0, action = Match.Action.ENVELOPE, card = m.hands[0][1] })
	m.apply({ seat = 1, action = Match.Action.NOTE, card = m.hands[1][1], to = 2 })
	m.apply({ seat = 2, action = Match.Action.ENVELOPE, card = m.hands[2][1] })
	var r := m.resolve()
	assert_array(r.envelope_kinds).contains_exactly([C.HR, C.BUSYBODY])
	assert_array(r.note_kinds[2]).contains_exactly([C.ACCOUNTANT])
	assert_array(r.note_kinds[0]).is_empty()


func _labels(root: Node) -> PackedStringArray:
	var out := PackedStringArray()
	for n in root.find_children("*", "Label", true, false):
		out.append((n as Label).text)
	return out


func _button(root: Node, label: String) -> Button:
	for n in root.find_children("*", "Button", true, false):
		if (n as Button).text == label:
			return n
	return null


func test_drop_on_envelope_plays_selected_card() -> void:
	Game.players = 4
	Game.rng = RngStreams.new(8)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	var s: Session = t.session
	while not (s.waiting_for_human() and s.view().request.is_empty()):
		if s.waiting_for_human():
			s.answer(s.view().request.options[0])
		else:
			s.ai_step()
	t.refresh()
	var uid: int = s.m.legal_moves(Session.HUMAN)[0].card
	t._selected = uid
	t._do(Match.Action.ENVELOPE, -1)
	assert_bool(uid in s.view().envelope).is_true()
	t._timer.stop()


func test_note_move_options_are_distinct() -> void:
	Game.players = 3
	Game.rng = RngStreams.new(1)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	t._timer.stop()
	var m: Match = t.session.m
	m.notes[1].append_array([100, 101])
	m.placed_by[100] = 0
	m.placed_by[101] = 2
	t._k = t.session.view()
	var a: String = t.option_text(&"NOTE_MOVE", { note = 100, to = 2 })
	var b: String = t.option_text(&"NOTE_MOVE", { note = 101, to = 2 })
	assert_str(a).is_not_equal(b)


func _table_with(hands: Array) -> Control:
	Game.players = hands.size()
	Game.rng = RngStreams.new(1)
	var t: Control = auto_free(TABLE.instantiate())
	add_child(t)
	t._timer.stop()
	var m := Match.from_hands(hands)
	m.turn = 0
	t.session.m = m
	m.moved.connect(t.session._on_moved)
	t.refresh()
	t._timer.stop()
	return t


func test_hr_target_is_picked_on_the_table_and_shown_as_seen() -> void:
	var C := Cards.Id
	var t := _table_with([[C.HR, C.CHAIR, C.MISER], [C.THIEF, C.BOSS], [C.MISER, C.QUITTER]])
	t._selected = 0
	t._do(Match.Action.PLAY, -1)
	t._timer.stop()
	assert_str(t._k.request.get(&"ask", &"")).is_equal(&"PEEK_HAND")
	assert_int(t._overlay.get_child_count()).is_equal(0)
	assert_float(t._seat_panels[1].modulate.a).is_equal(1.0)
	t._on_zone_input(_click(), Match.Action.NOTE, 1)
	t._timer.stop()
	assert_bool(t._k.request.is_empty()).is_true()
	var seen: PackedStringArray = t.seen_in_hand(1)
	assert_bool(seen.has(tr("CARD_THIEF"))).is_true()


func test_boss_give_back_is_picked_from_hand() -> void:
	var C := Cards.Id
	var t := _table_with([[C.BOSS, C.CHAIR, C.MISER], [C.HR, C.HR], [C.MISER, C.QUITTER]])
	t._selected = 0
	t._do(Match.Action.PLAY, -1)
	t._on_zone_input(_click(), Match.Action.NOTE, 1)
	t._timer.stop()
	assert_str(t._k.request.get(&"ask", &"")).is_equal(&"GIVE_BACK")
	var give: int = t._k.request.options[0]
	t._on_card_pressed(give)
	t._timer.stop()
	assert_bool(give in t._k.hand).is_false()


func test_miser_takes_from_envelope_slot_button() -> void:
	var C := Cards.Id
	var t := _table_with([[C.MISER, C.CHAIR, C.HR, C.HR], [C.BOSS, C.BOSS, C.QUITTER], [C.QUITTER, C.SNIFFER, C.ACCOUNTANT]])
	var m: Match = t.session.m
	t._selected = 0
	t._do(Match.Action.PLAY, -1)
	while m.turn != 0 and not m.is_over():
		t.session.ai_step()
	t.refresh()
	t._timer.stop()
	if m.envelope.is_empty():
		return
	assert_str(t._k.request.get(&"ask", &"")).is_equal(&"MISER_TAKE")
	var b: Button = t._slots.get_child(0)
	b.pressed.emit()
	assert_int(t._k.request.size()).is_equal(0)


func _click() -> InputEventMouseButton:
	var e := InputEventMouseButton.new()
	e.button_index = MOUSE_BUTTON_LEFT
	e.pressed = true
	return e

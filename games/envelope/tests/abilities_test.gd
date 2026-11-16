extends GdUnitTestSuite

const C := Cards.Id
const A := Match.Action


## 자리 0이 `card`(uid 0)를 시킨다. 다른 자리는 손패를 그대로 받는다.
func _play(hands: Array) -> Match:
	var m := Match.from_hands(hands)
	m.turn = 0
	assert_bool(m.apply({ seat = 0, card = 0, action = A.PLAY })).is_true()
	return m


func _uid(m: Match, seat: int, kind: int) -> int:
	for u in m.hands[seat]:
		if m.kinds[u] == kind:
			return u
	return -1


func test_no_ability_passes_turn() -> void:
	var m := _play([[C.CHAIR, C.HR, C.HR], [C.BOSS, C.MISER], [C.MISER, C.MISER]])
	assert_array(m.pending).is_empty()
	assert_int(m.turn).is_equal(1)


func test_accountant_sees_envelope() -> void:
	var m := Match.from_hands([[C.ACCOUNTANT, C.HR, C.HR], [C.BOSS, C.MISER, C.HR], [C.MISER, C.MISER]])
	m.turn = 1
	m.apply({ seat = 1, card = 3, action = A.ENVELOPE })
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	assert_int(Knowledge.of(m, 0).kind_of(3)).is_equal(C.BOSS)
	assert_int(Knowledge.of(m, 2).kind_of(3)).is_equal(-1)


func test_hr_peeks_hand_and_blocks_moves_until_answered() -> void:
	var m := _play([[C.HR, C.CHAIR, C.MISER], [C.BOSS, C.THIEF], [C.MISER, C.QUITTER]])
	assert_str(m.request_for(0).ask).is_equal(&"PEEK_HAND")
	assert_array(m.legal_moves(0)).is_empty()
	assert_bool(m.answer(0, 0)).is_false()
	assert_bool(m.answer(0, 1)).is_true()
	assert_int(Knowledge.of(m, 0).kind_of(4)).is_equal(C.THIEF)
	assert_int(m.turn).is_equal(1)


func test_buddy_moves_note() -> void:
	var m := Match.from_hands([[C.BUDDY, C.HR, C.HR], [C.BOSS, C.MISER, C.HR], [C.MISER, C.MISER]])
	m.turn = 1
	m.apply({ seat = 1, card = 3, action = A.NOTE, to = 0 })
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	assert_bool(m.request_for(0).options.has({ note = 3, to = 0 })).is_false()
	assert_bool(m.answer(0, { note = 3, to = 2 })).is_true()
	assert_array(m.notes[0]).is_empty()
	assert_array(m.notes[2]).is_equal([3])


func test_buddy_without_notes_skips() -> void:
	var m := _play([[C.BUDDY, C.HR, C.HR], [C.BOSS, C.MISER], [C.MISER, C.MISER]])
	assert_array(m.pending).is_empty()


func test_miser_takes_from_envelope_next_turn() -> void:
	var m := Match.from_hands([[C.MISER, C.HR, C.HR], [C.BOSS, C.MISER, C.HR], [C.SUPPLIES, C.MISER, C.HR]])
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	m.apply({ seat = 1, card = 3, action = A.ENVELOPE })
	m.apply({ seat = 2, card = 7, action = A.ENVELOPE })
	assert_str(m.request_for(0).ask).is_equal(&"MISER_TAKE")
	assert_bool(m.answer(0, 0)).is_true()
	assert_array(m.envelope).is_equal([7])
	assert_bool(m.hands[0].has(3)).is_true()
	assert_int(m.turn).is_equal(0)
	assert_int(m.legal_moves(0).size()).is_greater(0)


func test_supplies_takes_armed_miser_and_disarms() -> void:
	var m := Match.from_hands([[C.MISER, C.HR, C.HR], [C.BOSS, C.MISER, C.HR], [C.SUPPLIES, C.MISER, C.HR]])
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	m.apply({ seat = 1, card = 3, action = A.ENVELOPE })
	m.apply({ seat = 2, card = 6, action = A.PLAY })
	assert_array(m.request_for(2).options).is_equal([0])
	m.answer(2, 0)
	assert_bool(m.hands[2].has(0)).is_true()
	assert_array(m.pending).is_empty()
	assert_int(m.turn).is_equal(0)


func test_sniffer_finds_thief() -> void:
	var m := _play([[C.SNIFFER, C.HR, C.HR], [C.BOSS, C.MISER], [C.THIEF, C.MISER]])
	assert_int(Knowledge.of(m, 0).thief_hint).is_equal(2)
	assert_int(Knowledge.of(m, 1).thief_hint).is_equal(Match.NO_HINT)


func test_newbie_can_cut_in_on_sniffer() -> void:
	var m := _play([[C.SNIFFER, C.HR, C.HR], [C.NEWBIE, C.MISER], [C.THIEF, C.MISER]])
	assert_str(m.request_for(1).ask).is_equal(&"CLAIM")
	m.answer(1, true)
	assert_int(m.sniffs[0]).is_equal(1)
	var n := _play([[C.SNIFFER, C.HR, C.HR], [C.NEWBIE, C.MISER], [C.THIEF, C.MISER]])
	n.answer(1, false)
	assert_int(n.sniffs[0]).is_equal(2)


func test_busybody_swaps_simultaneously() -> void:
	var m := _play([[C.BUSYBODY, C.HR, C.CHAIR], [C.BOSS, C.THIEF], [C.MISER, C.MISER]])
	m.answer(0, 1)
	assert_int(m.pending.size()).is_equal(2)
	assert_bool(m.answer(1, 4)).is_true()
	assert_bool(m.answer(0, 1)).is_true()
	assert_array(m.hands[0]).contains([4])
	assert_array(m.hands[1]).contains([1])
	assert_int(Knowledge.of(m, 1).kind_of(1)).is_equal(C.HR)
	assert_int(m.turn).is_equal(1)


func test_broadcast_passes_left_skipping_one_card_seats() -> void:
	var m := Match.from_hands([[C.BROADCAST, C.HR, C.CHAIR], [C.BOSS], [C.MISER, C.QUITTER], [C.SUPPLIES, C.THIEF]])
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	assert_object(m.request_for(1)).is_equal({})
	m.answer(0, 1)
	m.answer(2, 5)
	m.answer(3, 7)
	assert_bool(m.hands[2].has(1)).is_true()
	assert_bool(m.hands[3].has(5)).is_true()
	assert_bool(m.hands[0].has(7)).is_true()
	assert_array(m.hands[1]).is_equal([3])


func test_boss_draws_random_and_gives_back() -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3
	var m := Match.from_hands([[C.BOSS, C.HR, C.CHAIR], [C.MISER, C.THIEF], [C.MISER, C.MISER]], r)
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	m.answer(0, 1)
	assert_int(m.hands[0].size()).is_equal(3)
	assert_str(m.request_for(0).ask).is_equal(&"GIVE_BACK")
	m.answer(0, 2)
	assert_int(m.hands[1].size()).is_equal(2)
	assert_bool(m.hands[1].has(2)).is_true()
	assert_int(Knowledge.of(m, 1).kind_of(2)).is_equal(C.CHAIR)


func test_quitter_swaps_thief_into_envelope() -> void:
	var m := Match.from_hands([[C.QUITTER, C.THIEF, C.HR], [C.BOSS, C.MISER, C.HR], [C.MISER, C.MISER]])
	m.turn = 1
	m.apply({ seat = 1, card = 3, action = A.ENVELOPE })
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	assert_bool(m.answer(0, { slot = 0, card = 1 })).is_true()
	assert_array(m.envelope).is_equal([1])
	assert_bool(m.hands[0].has(3)).is_true()
	assert_int(m.seat_holding(C.THIEF)).is_equal(-1)


func test_random_full_games_keep_invariants() -> void:
	for n in range(3, 7):
		for g in 40:
			var deal_rng := RandomNumberGenerator.new()
			deal_rng.seed = n * 1000 + g
			var m := Match.deal(n, deal_rng, deal_rng)
			var steps := 0
			while not m.is_over() and steps < 500:
				steps += 1
				if not m.pending.is_empty():
					var req: Dictionary = m.pending[0]
					m.answer(req.seat, req.options[deal_rng.randi_range(0, req.options.size() - 1)])
					continue
				var moves := m.legal_moves(m.turn)
				assert_int(moves.size()).is_greater(0)
				m.apply(moves[deal_rng.randi_range(0, moves.size() - 1)])
			assert_bool(m.is_over()).is_true()
			var total := m.envelope.size()
			for s in n:
				assert_int(m.hands[s].size()).is_equal(1)
				total += m.hands[s].size() + m.face_up[s].size() + m.notes[s].size()
			assert_int(total).is_equal(Cards.deck(n).size())
			var r := m.resolve()
			assert_bool(r.winners.is_empty()).is_equal(r.priority == 0)


func test_synchronous_answers_from_asked_signal_finish_broadcast() -> void:
	var m := Match.from_hands([[C.BROADCAST, C.HR, C.CHAIR], [C.MISER, C.QUITTER], [C.SUPPLIES, C.THIEF]])
	m.turn = 0
	m.asked.connect(func(r: Dictionary) -> void: m.answer(r.seat, r.options[0]))
	m.apply({ seat = 0, card = 0, action = A.PLAY })
	assert_array(m.pending).is_empty()
	assert_int(m.turn).is_equal(1)

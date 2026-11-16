extends GdUnitTestSuite

const C := Cards.Id
const A := Match.Action


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func test_deal_splits_evenly_and_chair_starts() -> void:
	for n in range(3, 7):
		var m := Match.deal(n, _rng(n))
		var per := Cards.deck(n).size() / n
		for s in n:
			assert_int(m.hands[s].size()).is_equal(per)
		assert_int(m.seat_holding(C.CHAIR)).is_equal(m.turn)


func test_same_seed_same_deal() -> void:
	assert_array(Match.deal(5, _rng(7)).hands).is_equal(Match.deal(5, _rng(7)).hands)


func test_legal_moves_skip_thief_and_self_note() -> void:
	var m := Match.from_hands([[C.CHAIR, C.THIEF], [C.HR, C.BOSS], [C.MISER, C.QUITTER]])
	var moves := m.legal_moves(0)
	# 총무 1장만 낼 수 있다: 시키기 + 봉투 + 쪽지 2명
	assert_int(moves.size()).is_equal(4)
	for mv in moves:
		assert_int(mv.card).is_equal(0)
		assert_int(mv.get(&"to", -1)).is_not_equal(0)
	assert_bool(m.apply({ seat = 0, card = 1, action = A.ENVELOPE })).is_false()
	assert_bool(m.apply({ seat = 0, card = 0, action = A.NOTE, to = 0 })).is_false()
	assert_bool(m.apply({ seat = 1, card = 2, action = A.PLAY })).is_false()


func test_one_card_left_means_out_and_turn_skips() -> void:
	var m := Match.from_hands([[C.CHAIR, C.HR], [C.BOSS, C.MISER, C.QUITTER], [C.ACCOUNTANT, C.SUPPLIES]])
	assert_bool(m.apply({ seat = 0, card = 0, action = A.ENVELOPE })).is_true()
	assert_bool(m.out[0]).is_true()
	assert_int(m.turn).is_equal(1)
	m.apply({ seat = 1, card = 2, action = A.NOTE, to = 2 })
	assert_int(m.turn).is_equal(2)
	m.apply({ seat = 2, card = 6, action = A.PLAY })
	assert_bool(m.out[2]).is_true()
	assert_int(m.turn).is_equal(1)
	m.apply({ seat = 1, card = 3, action = A.ENVELOPE })
	assert_bool(m.is_over()).is_true()
	assert_array(m.envelope).is_equal([0, 3])
	assert_array(m.notes[2]).is_equal([2])
	assert_array(m.face_up[2]).is_equal([6])


## 손패를 정체 1장씩만 남긴 판을 만들고 봉투·쪽지를 직접 채운다.
func _ended(roles: Array, envelope_kinds: Array, notes_by_seat: Array) -> Match:
	var m := Match.from_hands(roles.map(func(r: int) -> Array: return [r]))
	for k in envelope_kinds:
		m.envelope.append(m.kinds.size())
		m.kinds.append(k)
	for s in notes_by_seat.size():
		for k in notes_by_seat[s]:
			m.notes[s].append(m.kinds.size())
			m.kinds.append(k)
	return m


func test_thief_caught_and_funded_staff_and_boss_win() -> void:
	# 5인 목표 7: 3+3+2 = 8
	var m := _ended([C.THIEF, C.HR, C.BOSS, C.CHAIR, C.MISER], [C.SUPPLIES, C.BOSS, C.ACCOUNTANT], [[C.SUPPLIES], [], [], [], []])
	var r := m.resolve()
	assert_bool(r.funded).is_true()
	assert_array(r.confined).is_equal([true, false, false, false, false])
	assert_int(r.priority).is_equal(4)
	assert_array(r.winners).is_equal([1, 2, 3])


func test_thief_free_wins_with_buddy() -> void:
	var m := _ended([C.THIEF, C.BUDDY, C.HR, C.CHAIR, C.MISER], [C.SUPPLIES, C.BOSS, C.ACCOUNTANT], [[], [], [C.SUPPLIES], [], []])
	var r := m.resolve()
	assert_int(r.priority).is_equal(2)
	assert_array(r.winners).is_equal([0, 1])


func test_newbie_confined_beats_everyone() -> void:
	var m := _ended([C.THIEF, C.NEWBIE, C.HR, C.CHAIR, C.MISER], [], [[C.HR], [C.SUPPLIES], [], [], []])
	assert_array(m.resolve().winners).is_equal([1])


func test_fund_failed_and_thief_caught_miser_wins() -> void:
	var m := _ended([C.THIEF, C.HR, C.MISER, C.CHAIR, C.MISER], [C.MISER, C.HR], [[C.BOSS], [], [], [], []])
	var r := m.resolve()
	assert_bool(r.funded).is_false()
	assert_array(r.winners).is_equal([2, 4])


func test_nobody_wins_quitter_wins() -> void:
	# 범인 검거, 모금 성공했지만 직원이 없다
	var m := _ended([C.THIEF, C.QUITTER, C.MISER, C.NEWBIE, C.BUDDY], [C.SUPPLIES, C.BOSS, C.ACCOUNTANT], [[C.BOSS], [], [], [], []])
	var r := m.resolve()
	assert_int(r.priority).is_equal(5)
	assert_array(r.winners).is_equal([1])


func test_everyone_equal_nobody_confined_ties_all_confined() -> void:
	var m := _ended([C.THIEF, C.HR, C.CHAIR], [], [[C.HR], [C.HR], [C.HR]])
	assert_array(m.resolve().confined).is_equal([false, false, false])
	var t := _ended([C.THIEF, C.HR, C.CHAIR], [], [[C.SUPPLIES], [C.SUPPLIES], []])
	assert_array(t.resolve().confined).is_equal([true, true, false])


func test_thief_in_envelope_means_no_thief() -> void:
	var m := _ended([C.HR, C.CHAIR, C.MISER], [C.THIEF, C.SUPPLIES, C.BOSS, C.BOSS], [[C.HR], [], []])
	var r := m.resolve()
	assert_bool(r.no_thief).is_true()
	assert_int(r.fund).is_equal(9)
	assert_array(r.winners).is_equal([0, 1])

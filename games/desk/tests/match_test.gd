extends GdUnitTestSuite

const A := Match.Action
const S := Match.Side
const P := Match.Phase


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _place(m: Match, card: int, sprints: Array = []) -> bool:
	return m.apply({ side = S.STAFF, action = A.PLACE, card = card, sprints = sprints })


func _draw(m: Match, s: int, zone: int) -> bool:
	return m.apply({ side = s, action = A.DRAW, zone = zone })


func _guess(m: Match, numbers: Array) -> bool:
	return m.apply({ side = S.CHIEF, action = A.GUESS, numbers = numbers })


func _pass(m: Match) -> bool:
	return m.apply({ side = S.STAFF, action = A.PASS })


## 더미 3개를 작은 카드로 채운 판. 맨 뒤가 맨 위.
func _setup(hand: Array) -> Match:
	return Match.setup(hand, [[4, 5], [15, 16], [29, 30]])


func test_deal_gives_start_hand_and_leaves_decks() -> void:
	var m := Match.deal(_rng(1))
	var hand: Array[int] = m.hands[S.STAFF]
	assert_int(hand.size()).is_equal(9)
	for c in [1, 2, 3, 42]:
		assert_bool(c in hand).is_true()
	assert_int(m.decks[0].size()).is_equal(8)
	assert_int(m.decks[1].size()).is_equal(12)
	assert_int(m.decks[2].size()).is_equal(13)
	assert_int(m.hands[S.CHIEF].size()).is_equal(0)
	assert_int(m.hideouts.size()).is_equal(1)
	assert_bool(m.hideouts[0].revealed).is_true()


func test_same_seed_same_deal() -> void:
	assert_array(Match.deal(_rng(7)).hands).is_equal(Match.deal(_rng(7)).hands)
	assert_array(Match.deal(_rng(7)).decks).is_equal(Match.deal(_rng(7)).decks)


func test_first_staff_turn_places_one_or_two_without_drawing() -> void:
	var m := _setup([1, 2, 3, 42])
	assert_int(m.phase).is_equal(P.ACT)
	assert_bool(_pass(m)).is_false()
	assert_bool(_place(m, 2)).is_true()
	assert_int(m.side).is_equal(S.STAFF)
	assert_bool(_place(m, 3)).is_true()
	assert_int(m.side).is_equal(S.CHIEF)
	var m2 := _setup([1, 2, 3, 42])
	_place(m2, 1)
	assert_bool(_pass(m2)).is_true()
	assert_int(m2.side).is_equal(S.CHIEF)


func test_place_must_go_up_by_at_most_three() -> void:
	var m := _setup([1, 2, 3, 7, 42])
	_place(m, 3)
	assert_bool(_place(m, 2)).is_false()
	assert_bool(_place(m, 7)).is_false()
	assert_bool(_place(m, 3)).is_false()


func test_sprint_extends_range_by_footprints() -> void:
	# 앞 기록 0, 뛰기 3(발자국 2) + 2(발자국 1) → 0 + 3 + 3 = 6까지
	var m := _setup([2, 3, 6, 7, 42])
	assert_bool(_place(m, 7, [3, 2])).is_false()
	assert_bool(_place(m, 6, [3])).is_false()
	assert_bool(_place(m, 6, [42])).is_false()
	assert_bool(_place(m, 6, [6])).is_false()
	assert_bool(_place(m, 6, [3, 2])).is_true()
	assert_array(m.hands[S.STAFF]).is_equal([7, 42])
	assert_array(m.hideouts[1].sprints).is_equal([3, 2])


func test_extra_sprints_allowed_as_bluff() -> void:
	var m := _setup([1, 2, 3, 42])
	assert_bool(_place(m, 1, [2, 3])).is_true()
	assert_int(m.hideouts[1].sprints.size()).is_equal(2)


func test_minimal_sprints_uses_fewest_cards() -> void:
	var m := _setup([1, 2, 4, 6, 9, 42])
	assert_array(m.minimal_sprints(2)).is_empty()
	assert_array(m.minimal_sprints(6)).is_equal([9, 4])
	assert_that(m.minimal_sprints(42)).is_null()


func test_chief_first_turn_draws_two_then_guesses() -> void:
	var m := _setup([1, 2, 3, 42])
	_place(m, 2)
	_pass(m)
	assert_int(m.phase).is_equal(P.DRAW)
	assert_bool(_guess(m, [2])).is_false()
	assert_bool(_draw(m, S.CHIEF, 0)).is_true()
	assert_bool(_draw(m, S.CHIEF, 2)).is_true()
	assert_array(m.hands[S.CHIEF]).is_equal([5, 30])
	assert_int(m.phase).is_equal(P.ACT)
	assert_bool(_draw(m, S.CHIEF, 0)).is_false()


func test_staff_normal_turn_draws_one_then_places_or_passes() -> void:
	var m := _setup([1, 2, 3, 42])
	_place(m, 1)
	_pass(m)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_guess(m, [10])
	assert_int(m.side).is_equal(S.STAFF)
	assert_int(m.phase).is_equal(P.DRAW)
	assert_bool(_place(m, 2)).is_false()
	_draw(m, S.STAFF, 1)
	assert_bool(16 in m.hands[S.STAFF]).is_true()
	assert_bool(_place(m, 2)).is_true()
	assert_int(m.side).is_equal(S.CHIEF)


func test_empty_deck_cannot_be_drawn() -> void:
	var m := Match.setup([1, 2, 3, 42], [[], [15], []])
	_place(m, 1)
	_pass(m)
	assert_bool(_draw(m, S.CHIEF, 0)).is_false()
	assert_bool(_draw(m, S.CHIEF, 1)).is_true()
	# 더미가 다 비면 남은 뽑기는 건너뛴다
	assert_int(m.phase).is_equal(P.ACT)


func test_single_guess_reveals_hideout_and_sprints() -> void:
	var m := _setup([1, 2, 3, 6, 42])
	_place(m, 6, [3, 2])
	assert_bool(_place(m, 1)).is_false()
	assert_int(m.side).is_equal(S.STAFF)
	_pass(m)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	assert_bool(_guess(m, [6])).is_true()
	assert_bool(m.history[-1].hit).is_true()
	assert_bool(m.hideouts[1].revealed).is_true()


func test_multi_guess_reveals_only_if_all_right() -> void:
	var m := _setup([1, 2, 3, 42])
	_place(m, 2)
	_place(m, 3)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	assert_bool(_guess(m, [2, 4])).is_true()
	assert_bool(m.history[-1].hit).is_false()
	assert_int(m.hidden_count()).is_equal(2)
	_draw(m, S.STAFF, 1)
	_pass(m)
	_draw(m, S.CHIEF, 2)
	assert_bool(_guess(m, [2, 2])).is_false()
	assert_bool(_guess(m, [0])).is_false()
	assert_bool(_guess(m, [2, 3])).is_true()
	assert_int(m.winner).is_equal(S.CHIEF)
	assert_bool(m.is_over()).is_true()


func test_escape_without_manhunt_when_chief_close() -> void:
	# 앞면 최고 번호가 29보다 크면 42를 내는 순간 사원 승리
	var m := Match.setup([1, 31, 33, 36, 39, 42], [[4, 5], [15, 16], [29, 30]])
	m.hideouts.append({ card = 30, sprints = [] as Array[int], revealed = true })
	_place(m, 33)
	_place(m, 36)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_guess(m, [33, 36])
	assert_int(m.hidden_count()).is_equal(0)
	assert_int(m.winner).is_equal(S.CHIEF)
	var m2 := Match.setup([1, 31, 33, 36, 39, 42], [[4, 5], [15, 16], [29, 30]])
	m2.hideouts.append({ card = 30, sprints = [] as Array[int], revealed = true })
	_place(m2, 33)
	_place(m2, 36)
	_draw(m2, S.CHIEF, 0)
	_draw(m2, S.CHIEF, 0)
	_guess(m2, [40])
	_draw(m2, S.STAFF, 1)
	_place(m2, 39)
	_draw(m2, S.CHIEF, 1)
	_guess(m2, [41])
	_draw(m2, S.STAFF, 2)
	assert_bool(_place(m2, 42)).is_true()
	assert_int(m2.winner).is_equal(S.STAFF)
	assert_bool(m2.is_over()).is_true()


func test_manhunt_hit_all_chief_wins() -> void:
	var m := _manhunt_ready()
	assert_int(m.phase).is_equal(P.MANHUNT)
	assert_int(m.side).is_equal(S.CHIEF)
	assert_bool(_guess(m, [1, 2])).is_false()
	assert_bool(_guess(m, [1])).is_true()
	assert_int(m.phase).is_equal(P.MANHUNT)
	assert_bool(_guess(m, [2])).is_true()
	assert_int(m.winner).is_equal(S.CHIEF)


func test_manhunt_miss_staff_wins() -> void:
	var m := _manhunt_ready()
	assert_bool(_guess(m, [5])).is_true()
	assert_int(m.winner).is_equal(S.STAFF)


## 기록 1, 2(뒷면) 뒤에 42를 뛰기로 내서 마지막 추궁이 시작된 판.
func _manhunt_ready() -> Match:
	var sprinters: Array[int] = []
	for n in range(3, 40, 3):
		sprinters.append(n)
	var hand: Array = [1, 2, 42]
	hand.append_array(sprinters)
	var m := Match.setup(hand, [[4], [15], [29]])
	_place(m, 1)
	_place(m, 2)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 1)
	_guess(m, [20])
	_draw(m, S.STAFF, 2)
	# 2 + 3 + 발자국 2×13 + 1(29) = 32 < 42 → 1장짜리 뛰기 카드가 더 필요
	assert_that(m.minimal_sprints(42)).is_null()
	m.hands[S.STAFF].append_array([4, 5, 7, 8, 10, 11, 13, 14, 16, 17, 19])
	var sprints: Variant = m.minimal_sprints(42)
	assert_that(sprints).is_not_null()
	assert_bool(_place(m, 42, sprints)).is_true()
	return m


func test_legal_moves_match_phase() -> void:
	var m := _setup([1, 2, 3, 42])
	var moves := m.legal_moves(S.STAFF)
	assert_int(moves.size()).is_equal(3)
	assert_array(m.legal_moves(S.CHIEF)).is_empty()
	_place(m, 3)
	_pass(m)
	assert_int(m.legal_moves(S.CHIEF).size()).is_equal(3)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	assert_int(m.legal_moves(S.CHIEF).size()).is_equal(41)
	for mv in m.legal_moves(S.CHIEF):
		assert_bool(m.is_legal(mv)).is_true()


func test_moved_signal_records_drawn_card() -> void:
	var m := _setup([1, 2, 3, 42])
	var got: Array[Dictionary] = []
	m.moved.connect(func(mv: Dictionary) -> void: got.append(mv))
	_place(m, 1)
	_pass(m)
	_draw(m, S.CHIEF, 2)
	assert_int(got.size()).is_equal(3)
	assert_int(got[-1].card).is_equal(30)

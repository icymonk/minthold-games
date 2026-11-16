extends GdUnitTestSuite
## 사건 카드(기획서 2.2): 뽑기, 효과, 단서가 Knowledge·Deduce로 이어지는지.

const A := Match.Action
const S := Match.Side
const P := Match.Phase
const E := Events.Id


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _act(m: Match, move: Dictionary) -> void:
	assert_bool(m.apply(move)).override_failure_message("illegal: %s" % move).is_true()


func _draw(m: Match, s: int, zone: int) -> void:
	_act(m, { side = s, action = A.DRAW, zone = zone })


## 사원이 1, 2를 내고(첫 차례) 팀장 차례가 된 판. 층 더미 맨 위에 사건 하나.
func _with_event(id: int, floor_deck: Array = [7, 8]) -> Match:
	var deck: Array = floor_deck.duplicate()
	deck.append(Events.card_of(id))
	var m := Match.setup([1, 2, 3, 4, 5, 6, 42], [deck, [15, 16, 17], [29, 30, 31]])
	_act(m, { side = S.STAFF, action = A.PLACE, card = 1, sprints = [] })
	_act(m, { side = S.STAFF, action = A.PLACE, card = 2, sprints = [] })
	return m


func test_deal_shuffles_six_events_two_per_zone_after_hand() -> void:
	var plain := Match.deal(_rng(5))
	var m := Match.deal(_rng(5), true)
	assert_bool(m.events_on).is_true()
	assert_array(m.hands[S.STAFF]).is_equal(plain.hands[S.STAFF])
	var seen := {}
	for z in m.decks.size():
		var ev: Array = m.decks[z].filter(Events.is_event)
		assert_int(ev.size()).is_equal(Events.PER_ZONE)
		for c in ev:
			seen[c] = true
	assert_int(seen.size()).is_equal(3 * Events.PER_ZONE)
	assert_bool(Match.deal(_rng(5)).decks[0].any(Events.is_event)).is_false()


func test_event_draw_is_free_and_skips_hand() -> void:
	var m := _with_event(E.CCTV)
	_draw(m, S.CHIEF, 0)
	assert_int(m.draws_left).is_equal(2)
	assert_array(m.hands[S.CHIEF]).is_empty()
	assert_int(m.history[-1].event).is_equal(E.CCTV)
	assert_bool(m.history[-1].clue.odd).is_false()
	assert_int(m.history[-1].clue.index).is_equal(2)


func test_meeting_blocks_next_staff_placement() -> void:
	var m := _with_event(E.MEETING)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [20] })
	_draw(m, S.STAFF, 1)
	var moves := m.legal_moves(S.STAFF)
	assert_int(moves.size()).is_equal(1)
	assert_int(moves[0].action).is_equal(A.PASS)
	_act(m, moves[0])
	assert_bool(m.limited(S.STAFF, &"no_place")).is_false()


func test_busy_allows_one_number_and_on_call_skips_draw() -> void:
	var m := _with_event(E.BUSY, [7, Events.card_of(E.ON_CALL)])
	_act(m, { side = S.CHIEF, action = A.DRAW, zone = 0 })
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 1)
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [20] })
	_draw(m, S.STAFF, 1)
	_act(m, { side = S.STAFF, action = A.PASS })
	assert_int(m.phase).is_equal(P.ACT)
	assert_int(m.draws_left).is_equal(0)
	assert_bool(m.is_legal({ side = S.CHIEF, action = A.GUESS, numbers = [1, 2] })).is_false()
	assert_bool(m.is_legal({ side = S.CHIEF, action = A.GUESS, numbers = [9] })).is_true()


func test_elevator_drawn_by_staff_adds_two_this_turn() -> void:
	var m := _with_event(E.CCTV, [7, 8, 9])
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	m.decks[1].append(Events.card_of(E.ELEVATOR))
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [20] })
	_draw(m, S.STAFF, 1)
	assert_int(m.reach([])).is_equal(2 + 3 + 2)
	_draw(m, S.STAFF, 1)
	_act(m, { side = S.STAFF, action = A.PLACE, card = 6, sprints = [] })
	assert_int(m.hideouts[-1].bonus).is_equal(2)
	var d := Deduce.run(Knowledge.of(m, S.CHIEF))
	assert_bool(d.possible(3, 11)).is_true()


func test_excuse_from_chief_gives_staff_two_more_next_turn() -> void:
	var m := _with_event(E.EXCUSE)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [20] })
	assert_int(m.draws_left).is_equal(3)


func test_corridor_miss_tells_how_many_records_are_earlier() -> void:
	var m := _with_event(E.CORRIDOR)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	_act(m, { side = S.CHIEF, action = A.GUESS, numbers = [3] })
	assert_dict(m.history[-1].below).is_equal({ number = 3, before = 3, count = 2 })
	var k := Knowledge.of(m, S.CHIEF)
	assert_int(k.clues[-1].kind).is_equal(Knowledge.Clue.BELOW)
	var d := Deduce.run(k)
	assert_that(d.range_of(1)).is_equal(Vector2i(1, 1))
	assert_that(d.range_of(2)).is_equal(Vector2i(2, 2))


func test_badge_and_tip_off_clues_reach_chief_knowledge() -> void:
	var m := _with_event(E.BADGE, [7, Events.card_of(E.TIP_OFF)])
	_draw(m, S.CHIEF, 0)
	_draw(m, S.CHIEF, 0)
	var k := Knowledge.of(m, S.CHIEF)
	assert_int(k.events.size()).is_equal(2)
	assert_array(k.staff_draws).is_empty()
	assert_int(k.clues[0].kind).is_equal(Knowledge.Clue.ZONE)
	assert_int(k.clues[0].zone).is_equal(Cards.zone_of(1))
	var tip: int = k.clues[1].card
	assert_bool(tip in m.hands[S.STAFF]).is_true()
	var d := Deduce.run(k)
	for i in [1, 2]:
		assert_bool(d.possible(i, tip)).is_false()


func test_events_sim_never_stalls() -> void:
	var stats := preload("res://tools/sim.gd").run(40, Bot.Persona.CAREFUL, Bot.Persona.CAREFUL, 7, Bot.Level.HARD, Bot.Level.HARD, true)
	assert_int(stats.stalled).is_equal(0)

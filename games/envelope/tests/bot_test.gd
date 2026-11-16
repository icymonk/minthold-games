extends GdUnitTestSuite

const C := Cards.Id
const Sim := preload("res://tools/sim.gd")


func _bots(n: int, r: RandomNumberGenerator) -> Array:
	var out := []
	for s in n:
		out.append(Bot.new(s, r, s % 3 as Bot.Persona))
	return out


func test_bots_finish_every_game_without_illegal_moves() -> void:
	for n in range(3, 7):
		for g in 30:
			var st := RngStreams.new(n * 777 + g)
			var m := Match.deal(n, st.deal, st.play)
			var bots := _bots(n, st.bots)
			var steps := 0
			while Bot.step(m, bots):
				steps += 1
			assert_bool(m.is_over()).is_true()
			assert_int(steps).is_less(300)


func test_same_seed_same_game() -> void:
	var a := _play(42)
	var b := _play(42)
	assert_array(a.history).is_equal(b.history)


func _play(s: int) -> Match:
	var st := RngStreams.new(s)
	var m := Match.deal(5, st.deal, st.play)
	var bots := _bots(5, st.bots)
	while Bot.step(m, bots):
		pass
	return m


func test_bot_keeps_thief_and_never_discards_keep() -> void:
	var m := Match.from_hands([[C.THIEF, C.SUPPLIES, C.MISER], [C.HR, C.BOSS, C.CHAIR], [C.MISER, C.MISER, C.HR]])
	m.turn = 0
	var b := Bot.new(0, RandomNumberGenerator.new())
	var mv := b.choose_move(Knowledge.of(m, 0), m.legal_moves(0))
	assert_int(b.keep).is_equal(0)
	assert_int(mv.card).is_not_equal(0)


func test_staff_bot_notes_the_sniffed_thief() -> void:
	var m := Match.from_hands([[C.SNIFFER, C.SUPPLIES, C.ACCOUNTANT], [C.HR, C.BOSS, C.CHAIR], [C.THIEF, C.MISER, C.HR]])
	m.turn = 0
	m.apply({ seat = 0, card = 0, action = Match.Action.PLAY })
	m.turn = 0
	var b := Bot.new(0, RandomNumberGenerator.new())
	var k := Knowledge.of(m, 0)
	assert_int(k.thief_hint).is_equal(2)
	assert_float(b.thief_belief(k, 2)).is_greater(b.thief_belief(k, 1))


func test_simulator_runs() -> void:
	var stats := Sim.run(40, 5, 1)
	assert_int(stats.stalled).is_equal(0)
	assert_int(stats.games).is_equal(40)

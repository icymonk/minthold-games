extends GdUnitTestSuite

const Sim := preload("res://tools/sim.gd")
const A := Match.Action
const S := Match.Side
const H := Knowledge.HIDDEN


func _rng(s: int) -> RandomNumberGenerator:
	var r := RandomNumberGenerator.new()
	r.seed = s
	return r


func _hideout(card: int, sprints: Array = []) -> Dictionary:
	var spr: Array[int] = []
	spr.assign(sprints)
	return { card = card, sprint_count = spr.size(), sprints = spr, revealed = card != H }


func test_every_persona_pair_finishes() -> void:
	for c in Bot.Persona.values():
		for st in Bot.Persona.values():
			var stats := Sim.run(5, c, st, 3)
			assert_int(stats.stalled).is_equal(0)


func test_simulator_is_deterministic() -> void:
	assert_dict(Sim.run(10, Bot.Persona.CAREFUL, Bot.Persona.WILD, 9)) \
		.is_equal(Sim.run(10, Bot.Persona.CAREFUL, Bot.Persona.WILD, 9))


func test_chief_guesses_sure_numbers_together() -> void:
	# 뒷면 1번은 1~3인데 앞면 6이 바로 뒤라 3뿐이다.
	var k := Knowledge.new()
	k.side = S.CHIEF
	k.phase = Match.Phase.ACT
	k.start_counts.assign([3, 2, 0])
	k.hideouts.assign([_hideout(0), _hideout(H), _hideout(6)])
	var b := ChiefBot.new(_rng(1))
	var moves: Array[Dictionary] = [{ side = S.CHIEF, action = A.GUESS, numbers = [1] as Array[int] }]
	assert_array(b.choose(k, moves).numbers).is_equal([3])


func test_staff_takes_escape_when_possible() -> void:
	var m := Match.setup([1, 39, 41, 42], [[4, 5], [15, 16], [29, 30]])
	m.hideouts.append({ card = 39, sprints = [] as Array[int], revealed = true })
	var b := StaffBot.new(_rng(1))
	var mv := b.choose(Knowledge.of(m, S.STAFF), m.legal_moves(S.STAFF))
	assert_int(mv.card).is_equal(42)


func test_staff_spends_passed_cards_on_sprints_first() -> void:
	var k := Knowledge.new()
	k.side = S.STAFF
	k.hand.assign([4, 9, 12, 15, 42])
	k.hideouts.assign([_hideout(0), _hideout(10)])
	assert_array(StaffBot.new(_rng(1)).sprints_for(k, 15)).is_equal([9])

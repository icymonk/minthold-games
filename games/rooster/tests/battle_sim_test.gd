extends GdUnitTestSuite


func _bag_with(kinds: Array, at: Array) -> Bag:
	var bag := Bag.new(5, 4)
	for i in kinds.size():
		bag.place(Piece.create(kinds[i]), at[i])
	return bag


func test_same_seed_same_battle() -> void:
	var r1 := RunState.new(42)
	var r2 := RunState.new(42)
	for r in [r1, r2]:
		r.bag.place(Piece.create(&"foxfire"), Vector2i(4, 1))
		r.bag.place(Piece.create(&"haetae"), Vector2i(3, 2))
	var a := r1.fight()
	var b := r2.fight()
	assert_int(a.events.size()).is_equal(b.events.size())
	assert_bool(a.won).is_equal(b.won)


func test_empty_bag_loses() -> void:
	var run := RunState.new(1)
	assert_bool(run.fight().won).is_false()


func test_three_starters_beat_night_one() -> void:
	var wins := 0
	for s in 20:
		var run := RunState.new(s)
		run.bag.place(Piece.create(&"haetae"), Vector2i(3, 1))
		run.bag.place(Piece.create(&"mongdal"), Vector2i(1, 1))
		run.bag.place(Piece.create(&"dokkaebi"), Vector2i(2, 2))
		if run.fight().won:
			wins += 1
	assert_int(wins).is_greater(14)


func test_guard_shields_touching_allies() -> void:
	var bag := _bag_with([&"haetae", &"foxfire"], [Vector2i(3, 0), Vector2i(2, 0)])
	var pr := Procession.new()
	pr.lanes = [[], [], [], []]
	var sim := BattleSim.new(bag, pr, RandomNumberGenerator.new())
	sim._battle_start()
	assert_int(sim.units[1].shield).is_equal(1)


func test_finish_battle_advances_and_pays() -> void:
	var run := RunState.new(3)
	run.coins = 7
	var sim := BattleSim.new(run.bag, run.procession, run.rng.battle)
	sim.won = true
	sim.coins = 2
	run.finish_battle(sim)
	assert_int(run.night).is_equal(2)
	assert_int(run.coins).is_equal(5 + RunState.INCOME)

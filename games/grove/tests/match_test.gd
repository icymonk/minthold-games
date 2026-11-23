extends GdUnitTestSuite
## 여러 명 한 판(Match): 덱 크기, 차례 넘김, 한 번 더, 다른 숲과 견주는 점수, 같은 행동이면 같은 결과


func _first_tree(m: Match) -> Dictionary:
	for c in m.hand_of(m.turn):
		if Cards.is_tree(c) and Cards.cost_of(c, 0) == 0:
			return c
	return {}


func test_deck_size_follows_player_count() -> void:
	# 158장 − 빼는 장수 − 손패 6장씩 + 겨울 3장
	for n in [2, 3, 4, 5]:
		var m := Match.new(n, 7)
		assert_int(m.season.deck.size()).is_equal(158 - Match.REMOVE[n] - 6 * n + 3)
		for p in n:
			assert_int(m.hand_of(p).size()).is_equal(6)


func test_players_clamped() -> void:
	assert_int(Match.new(1, 1).players).is_equal(2)
	assert_int(Match.new(9, 1).players).is_equal(5)


func test_two_draws_pass_the_turn() -> void:
	var m := Match.new(3, 11)
	assert_bool(m.act(1, {k = "draw"})).is_false()
	assert_bool(m.act(0, {k = "draw"})).is_true()
	assert_int(m.turn).is_equal(0)
	assert_bool(m.act(0, {k = "draw"})).is_true()
	assert_int(m.turn).is_equal(1)
	assert_int(m.hand_of(0).size()).is_equal(8)
	assert_int(m.hand_of(1).size()).is_equal(6)


func test_play_tree_goes_to_own_forest() -> void:
	var m := Match.new(2, 5)
	var c := {id = 9001, tree = &"birch", sym = &"birch"}
	m.hand_of(0).append(c)
	assert_bool(m.act(0, {k = "play", id = 9001, half = 0, plot = 0, pay = []})).is_true()
	assert_bool(m.forests[0].trees.has(0)).is_true()
	assert_bool(m.forests[1].trees.is_empty()).is_true()
	assert_int(m.turn).is_equal(1)


func test_json_numbers_are_accepted() -> void:
	var m := Match.new(2, 5)
	m.hand_of(0).append({id = 9002, tree = &"birch", sym = &"birch"})
	assert_bool(m.act(0, JSON.parse_string('{"k":"play","id":9002,"half":0,"plot":3,"pay":[]}'))).is_true()
	assert_bool(m.forests[0].trees.has(3)).is_true()


func test_again_keeps_the_turn() -> void:
	var m := Match.new(2, 5)
	m.forests[0].plant(0, {id = 9100, tree = &"oak", sym = &"oak"}, &"oak")
	var jay := Cards.pair(9101, &"jay", &"jay", &"v", [&"oak", &"oak"])
	m.hand_of(0).append(jay)
	m.hand_of(0).append({id = 9102, tree = &"oak", sym = &"oak"})
	var cost := Cards.cost_of(jay, 0)
	var pay: Array = [9102] if cost == 1 else []
	var half := 0 if Cards.side_of(jay, 0) == &"Top" else 1
	assert_bool(m.act(0, {k = "play", id = 9101, half = half, plot = 0, pay = pay})).is_true()
	assert_int(m.turn).is_equal(0)
	assert_bool(m.turns[-1].again).is_true()


func test_linden_compares_with_other_forests() -> void:
	var m := Match.new(2, 5)
	for i in 2:
		m.forests[0].plant(i, Cards.tree(9200 + i, &"linden"), &"linden")
	m.forests[1].plant(0, Cards.tree(9210, &"linden"), &"linden")
	assert_int(m.score_of(0).total).is_equal(2 * Cards.TREES.linden.score.most)
	assert_int(m.score_of(1).total).is_equal(Cards.TREES.linden.score.other)
	m.forests[1].plant(1, Cards.tree(9211, &"linden"), &"linden")
	assert_int(m.score_of(1).total).is_equal(2 * Cards.TREES.linden.score.most)


func test_woodpecker_compares_tree_count() -> void:
	var m := Match.new(2, 5)
	m.forests[0].plant(0, Cards.tree(9300, &"oak"), &"oak")
	m.forests[0].attach(0, &"Top", Cards.pair(9301, &"woodpecker", &"woodpecker", &"v", [&"oak", &"oak"]), &"woodpecker")
	m.forests[1].plant(0, Cards.tree(9302, &"oak"), &"oak")
	var pts: int = Cards.SPECIES.woodpecker.score.pts
	assert_int(m.score_of(0).total).is_equal(pts)
	m.forests[1].plant(1, Cards.tree(9303, &"oak"), &"oak")
	assert_int(m.score_of(0).total).is_equal(0)


func test_same_actions_replay_the_same() -> void:
	var a := Match.new(3, 42)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var guard := 0
	while not a.over() and guard < 2000:
		guard += 1
		var p := a.turn
		var tree := _first_tree(a)
		var free := a.forests[p].free_plots()
		if not tree.is_empty() and not free.is_empty() and rng.randf() < 0.5:
			a.act(p, {k = "play", id = tree.id, half = 0, plot = free[0], pay = []})
		elif not a.act(p, {k = "draw"}):
			if free.is_empty():
				break
			a.act(p, {k = "sapling", id = a.hand_of(p)[0].id, plot = free[0]})
	assert_int(a.actions.size()).is_greater(60)
	var b := Match.new(3, 42)
	for x in a.actions:
		assert_bool(b.act(b.turn, x)).is_true()
	assert_bool(b.over()).is_equal(a.over())
	for p in 3:
		assert_int(b.score_of(p).total).is_equal(a.score_of(p).total)
		assert_int(b.hand_of(p).size()).is_equal(a.hand_of(p).size())
	assert_int(a.ranking().size()).is_equal(3)


func test_online_forest_grows_without_limit() -> void:
	var f := Forest.new()
	f.grows = true
	for i in 40:
		assert_bool(f.plant(i, {}, &"oak")).is_true()
	assert_int(f.plots).is_equal(42)
	assert_int(f.free_plots().size()).is_equal(2)
	var solo := Forest.new()
	for i in 9:
		solo.plant(i, {}, &"oak")
	assert_bool(solo.plant(9, {}, &"oak")).is_false()

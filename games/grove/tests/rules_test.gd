extends GdUnitTestSuite
## 카드 데이터·숲·계절(가져오기·내기·비용·반쪽·효과→보너스·공터 쓸림)과 원작 효과(공짜·더 내기·굴·한 번 더)

var _id := 5000


func _season(seed_value := 3) -> Season:
	return Season.new(Cards.start_bag(), seed_value)


func _tree(s: Season, kind: StringName, sym: StringName = &"") -> Dictionary:
	_id += 1
	var c := {id = _id, tree = kind, sym = sym if sym != &"" else kind}
	s.hand.append(c)
	return c


func _pair(s: Season, a: StringName, b: StringName, axis: StringName, syms := [&"oak", &"oak"]) -> Dictionary:
	_id += 1
	var c := Cards.pair(_id, a, b, axis, syms)
	s.hand.append(c)
	return c


## 비용으로 낼 카드 n장(그 나무 색)
func _pay(s: Season, n: int, sym: StringName) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(_tree(s, &"birch", sym).id)
	return out


func _planted(s: Season, plot := 0, kind := &"oak") -> void:
	s.forest.plant(plot, {id = 99000 + plot, tree = kind, sym = kind}, kind)


func test_start_bag_is_36_cards() -> void:
	var bag := Cards.start_bag()
	assert_int(bag.size()).is_equal(36)
	assert_int(bag.filter(Cards.is_tree).size()).is_equal(12)
	var ids := {}
	for c in bag:
		ids[c.id] = true
		for h in (1 if Cards.is_tree(c) else 2):
			assert_bool(Cards.TREES.has(Cards.sym_of(c, h))).is_true()
		if not Cards.is_tree(c):
			for h in 2:
				assert_bool(Cards.fits(c.halves[h], Cards.side_of(c, h))).is_true()
	assert_int(ids.size()).is_equal(36)


func test_full_deck_matches_the_original() -> void:
	var n := 0
	for k in Cards.FULL_TREES:
		n += Cards.FULL_TREES[k]
	assert_int(n).is_equal(66)
	assert_int(Cards.FULL_PAIRS.size()).is_equal(92)
	var seen := {}
	for p in Cards.FULL_PAIRS:
		var c := Cards.pair(0, p[0], p[1], p[2], [p[3], p[4]])
		for h in 2:
			assert_bool(Cards.fits(c.halves[h], Cards.side_of(c, h))).override_failure_message(String(c.halves[h])).is_true()
			seen[c.halves[h]] = true
	assert_int(seen.size()).is_equal(Cards.SPECIES.size())


func test_every_species_has_a_3d_model() -> void:
	for k in Cards.SPECIES:
		assert_bool(Dweller.KINDS.has(k)).is_true()
		for side in Dweller.KINDS[k].sides:
			assert_bool(Cards.fits(k, side)).is_true()
	for k in Cards.TREES:
		assert_bool(ForestTree.SPECIES.has(k)).is_true()


func test_same_seed_same_deck() -> void:
	var a := _season(9)
	var b := _season(9)
	assert_array(a.hand.map(func(c: Dictionary) -> int: return c.id)).is_equal(b.hand.map(func(c: Dictionary) -> int: return c.id))
	assert_int(a.hand.size()).is_equal(Season.START_HAND)


func test_forest_sides_and_stack() -> void:
	var f := Forest.new()
	assert_bool(f.plant(4, {id = 0}, &"oak")).is_true()
	assert_bool(f.plant(4, {id = 1}, &"oak")).is_false()
	assert_bool(f.can_attach(4, &"Top", &"fox")).is_false()
	assert_bool(f.attach(4, &"Left", {id = 2}, &"fox")).is_true()
	assert_bool(f.can_attach(4, &"Left", &"badger")).is_false()
	for i in Forest.STACK:
		assert_bool(f.attach(4, &"Right", {id = 10 + i}, &"hare")).is_true()
	assert_bool(f.can_attach(4, &"Right", &"hare")).is_false()
	assert_bool(f.is_complete(4)).is_false()
	f.attach(4, &"Top", {id = 3}, &"tawny_owl")
	f.attach(4, &"Bottom", {id = 4}, &"moss")
	assert_bool(f.is_complete(4)).is_true()
	assert_int(f.neighbors().size()).is_equal(3 + Forest.STACK)


func test_take_two_then_turn_ends() -> void:
	var s := _season()
	assert_bool(s.draw()).is_true()
	assert_bool(s.draw()).is_true()
	assert_bool(s.draw()).is_false()
	s.end_turn()
	assert_int(s.hand.size()).is_equal(Season.START_HAND + 2)


func test_cannot_play_after_drawing() -> void:
	var s := _season()
	var birch := _tree(s, &"birch")
	s.draw()
	assert_bool(s.play(birch.id, 0, 0, [])).is_false()


func test_tree_costs_cards_and_drifts_one_into_clearing() -> void:
	var s := _season()
	var oak := _tree(s, &"oak")
	var pay := _pay(s, 2, &"fir")
	assert_bool(s.play(oak.id, 0, 4, [pay[0]])).is_false()
	var deck_before := s.deck.size()
	assert_bool(s.play(oak.id, 0, 4, pay)).is_true()
	assert_str(String(s.forest.kind_at(4))).is_equal("oak")
	# 비용 2장 + 날아온 1장
	assert_int(s.clearing.size()).is_equal(3)
	assert_int(s.deck.size()).is_less_equal(deck_before - 1)
	assert_bool(s.play(s.hand[0].id, 0, 5, [])).is_false()


func test_half_picks_side_and_cost() -> void:
	var s := _season()
	_planted(s)
	var c := _pair(s, &"fox", &"hare", &"h")
	# 오른쪽 반쪽(멧토끼)은 비용 0, 나무 오른쪽에만 붙는다
	assert_bool(s.play(c.id, 1, 0, [])).is_true()
	assert_int(s.forest.occupants(0, &"Right").size()).is_equal(1)
	assert_int(s.forest.occupants(0, &"Left").size()).is_equal(0)


func test_neighbor_needs_a_tree() -> void:
	var s := _season()
	var c := _pair(s, &"peacock_butterfly", &"moss", &"v")
	assert_bool(s.play(c.id, 0, 3, [])).is_false()


func test_bonus_only_when_paid_in_the_halfs_color() -> void:
	var s := _season()
	_planted(s)
	# 올빼미(비용 2, 효과 1장, 보너스 2장): 위 반쪽 색은 피나무
	var owl := _pair(s, &"tawny_owl", &"moss", &"v", [&"linden", &"oak"])
	var pay := _pay(s, 2, &"linden")
	var before := s.hand.size()
	assert_bool(s.play(owl.id, 0, 0, pay)).is_true()
	assert_int(s.hand.size()).is_equal(before - 3 + 1 + 2)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"bonus")).is_true()
	s.end_turn()
	var owl2 := _pair(s, &"tawny_owl", &"moss", &"v", [&"linden", &"oak"])
	_planted(s, 1)
	var mixed: Array[int] = [_pay(s, 1, &"oak")[0], _pay(s, 1, &"linden")[0]]
	var bonuses := s.log.filter(func(e: Dictionary) -> bool: return e.t == &"bonus").size()
	assert_bool(s.play(owl2.id, 0, 1, mixed)).is_true()
	assert_int(s.log.filter(func(e: Dictionary) -> bool: return e.t == &"bonus").size()).is_equal(bonuses)


func test_split_card_pays_with_either_color() -> void:
	assert_bool(Cards.has_sym(Cards.pair(0, &"hare", &"fox", &"h", [&"oak", &"birch"]), &"birch")).is_true()
	assert_bool(Cards.has_sym(Cards.pair(0, &"hare", &"fox", &"h", [&"oak", &"birch"]), &"fir")).is_false()


func test_free_play_after_bonus() -> void:
	var s := _season()
	# 전나무(비용 2) 보너스: 발 동물 1장 공짜
	var fir := _tree(s, &"fir")
	assert_bool(s.play(fir.id, 0, 0, _pay(s, 2, &"fir"))).is_true()
	assert_bool(s.can_play_more()).is_true()
	var deer := _pair(s, &"red_deer", &"fallow_deer", &"h")
	assert_int(s.cost_now(deer, 0)).is_equal(2)
	var fox := _pair(s, &"fox", &"hare", &"h")
	assert_int(s.cost_now(fox, 0)).is_equal(0)
	var before := s.hand.size()
	assert_bool(s.play(fox.id, 0, 0, [])).is_true()
	# 공짜로 낸 카드는 효과(멧토끼마다 뽑기)도 없다
	assert_int(s.hand.size()).is_equal(before - 1)
	assert_bool(s.can_play_more()).is_false()
	assert_bool(s.play(deer.id, 0, 0, [])).is_false()


func test_gnat_plays_any_number_of_bats_free() -> void:
	var s := _season()
	_planted(s, 0)
	_planted(s, 1)
	var gnat := _pair(s, &"wolf", &"gnat", &"h")
	assert_bool(s.play(gnat.id, 1, 0, [])).is_true()
	var a := _pair(s, &"barbastelle_bat", &"hare", &"h")
	var b := _pair(s, &"bechstein_bat", &"hare", &"h")
	assert_bool(s.play(a.id, 0, 0, [])).is_true()
	assert_bool(s.play(b.id, 0, 1, [])).is_true()
	assert_bool(s.can_play_more()).is_true()
	s.skip()
	assert_bool(s.can_play_more()).is_false()


func test_mole_plays_more_paying_costs() -> void:
	var s := _season()
	_planted(s)
	var mole := _pair(s, &"large_tortoiseshell", &"mole", &"v")
	assert_bool(s.play(mole.id, 1, 0, _pay(s, 2, &"fir"))).is_true()
	var birch := _tree(s, &"birch")
	assert_bool(s.play(birch.id, 0, 1, [])).is_true()
	var oak := _tree(s, &"oak")
	assert_bool(s.play(oak.id, 0, 2, [])).is_false()
	assert_bool(s.play(oak.id, 0, 2, _pay(s, 2, &"fir"))).is_true()
	s.end_turn()
	assert_bool(s.can_play_more()).is_false()


func test_raccoon_stashes_and_draws() -> void:
	var s := _season()
	_planted(s)
	var raccoon := _pair(s, &"raccoon", &"hare", &"h")
	assert_bool(s.play(raccoon.id, 0, 0, _pay(s, 1, &"fir"))).is_true()
	assert_bool(s.wants_stash()).is_true()
	var size := s.hand.size()
	var ids: Array[int] = [s.hand[0].id, s.hand[1].id]
	assert_bool(s.stash(ids)).is_true()
	assert_int(s.forest.cave.size()).is_equal(2)
	assert_int(s.hand.size()).is_equal(size)
	assert_bool(s.wants_stash()).is_false()


func test_bear_takes_the_clearing_into_the_cave() -> void:
	var s := _season()
	_planted(s)
	for i in 3:
		s.clearing.append(s.deck.pop_back())
	var bear := _pair(s, &"brown_bear", &"hare", &"h")
	assert_bool(s.play(bear.id, 0, 0, _pay(s, 3, &"fir"))).is_true()
	# 비용 3장도 공터에 들어간 뒤 모두 굴로
	assert_int(s.forest.cave.size()).is_equal(6)
	assert_int(s.clearing.size()).is_equal(0)


func test_fox_draws_per_hare_and_jay_again() -> void:
	var s := _season()
	_planted(s)
	s.forest.attach(0, &"Right", {id = 1}, &"hare")
	s.forest.attach(0, &"Right", {id = 2}, &"hare")
	var fox := _pair(s, &"fox", &"hare", &"h")
	var before := s.hand.size()
	var pay := _pay(s, 2, &"fir")
	assert_bool(s.play(fox.id, 0, 0, pay)).is_true()
	assert_int(s.hand.size()).is_equal(before + 2 - 2 - 1 + 2)
	s.end_turn()
	var jay := _pair(s, &"jay", &"moss", &"v")
	assert_bool(s.play(jay.id, 0, 0, _pay(s, 1, &"fir"))).is_true()
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"again")).is_true()


func test_sapling_is_free_and_counts_as_no_species() -> void:
	var s := _season()
	var any := s.hand[0]
	assert_bool(s.sapling(any.id, 2)).is_true()
	assert_str(String(s.forest.kind_at(2))).is_equal("sapling")
	s.end_turn()
	var c := _pair(s, &"fox", &"hare", &"h")
	assert_bool(s.play(c.id, 1, 2, [])).is_true()


func test_full_clearing_is_swept_at_turn_end() -> void:
	var s := _season()
	for i in Season.CLEARING_LIMIT:
		s.clearing.append(s.deck.pop_back())
	s.end_turn()
	assert_int(s.clearing.size()).is_equal(0)
	assert_int(s.discard.size()).is_equal(Season.CLEARING_LIMIT)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"sweep")).is_true()


func test_hand_limit() -> void:
	var s := _season()
	while s.hand.size() < Season.HAND_LIMIT:
		s.hand.append(s.deck.pop_back())
	assert_bool(s.draw()).is_false()

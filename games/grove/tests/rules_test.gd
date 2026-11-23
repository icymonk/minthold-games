extends GdUnitTestSuite
## 규칙 1-1: 카드 데이터·숲·계절(가져오기·내기·비용·반쪽·효과→보너스·공터 쓸림)


func _season(seed_value := 3) -> Season:
	return Season.new(Cards.start_bag(), seed_value)


## 손패에 원하는 카드를 넣는다(테스트용): 덱에서 꺼내 손패 맨 뒤로
func _give(s: Season, pick: Callable) -> Dictionary:
	for pile: Array[Dictionary] in [s.hand, s.deck]:
		for c in pile:
			if pick.call(c):
				pile.erase(c)
				s.hand.append(c)
				return c
	return {}


func test_start_bag_is_36_cards() -> void:
	var bag := Cards.start_bag()
	assert_int(bag.size()).is_equal(36)
	assert_int(bag.filter(Cards.is_tree).size()).is_equal(12)
	var ids := {}
	for c in bag:
		ids[c.id] = true
		assert_bool(Cards.TREES.has(c.sym)).is_true()
		if not Cards.is_tree(c):
			for h in 2:
				assert_bool(Cards.fits(c.halves[h], Cards.side_of(c, h))).is_true()
	assert_int(ids.size()).is_equal(36)


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
	assert_bool(f.can_attach(4, &"Left", &"marmot")).is_false()
	for i in Forest.STACK:
		assert_bool(f.attach(4, &"Right", {id = 10 + i}, &"hare")).is_true()
	assert_bool(f.can_attach(4, &"Right", &"hare")).is_false()
	assert_bool(f.is_complete(4)).is_false()
	f.attach(4, &"Top", {id = 3}, &"owl")
	f.attach(4, &"Bottom", {id = 4}, &"flower")
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
	var birch := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"birch")
	s.draw()
	assert_bool(s.play(birch.id, 0, 0, [])).is_false()


func test_tree_costs_cards_and_drifts_one_into_clearing() -> void:
	var s := _season()
	var oak := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"oak")
	var others: Array[int] = []
	for c in s.hand:
		if c.id != oak.id and others.size() < 2:
			others.append(c.id)
	assert_bool(s.play(oak.id, 0, 4, [others[0]])).is_false()
	var deck_before := s.deck.size()
	assert_bool(s.play(oak.id, 0, 4, others)).is_true()
	assert_str(String(s.forest.kind_at(4))).is_equal("oak")
	# 비용 2장 + 날아온 씨앗 1장
	assert_int(s.clearing.size()).is_equal(3)
	assert_int(s.deck.size()).is_less_equal(deck_before - 1)
	assert_bool(s.play(s.hand[0].id, 0, 5, [])).is_false()


func test_half_picks_side_and_cost() -> void:
	var s := _season()
	var pine := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"pine")
	var fox_card := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"fox", &"hare"])
	var pay: Array[int] = [s.hand.filter(func(c: Dictionary) -> bool: return c.id != pine.id and c.id != fox_card.id)[0].id]
	s.play(pine.id, 0, 0, pay)
	s.end_turn()
	# 오른쪽 반쪽(산토끼)은 비용 0, 나무 오른쪽에만 붙는다
	assert_bool(s.play(fox_card.id, 1, 0, [])).is_true()
	assert_int(s.forest.occupants(0, &"Right").size()).is_equal(1)
	assert_int(s.forest.occupants(0, &"Left").size()).is_equal(0)


func test_neighbor_needs_a_tree() -> void:
	var s := _season()
	var butterfly := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"butterfly", &"flower"])
	assert_bool(s.play(butterfly.id, 0, 3, [])).is_false()


func test_effect_then_bonus_when_paid_in_same_color() -> void:
	var s := _season()
	var birch := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"birch")
	s.play(birch.id, 0, 0, [])
	s.end_turn()
	# 올빼미(위, 비용 2, 보너스 1장 뽑기) 카드 색은 참나무: 참나무 색 2장으로 내면 보너스
	var owl := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"owl", &"mushroom"])
	var oaks: Array[int] = []
	for k in 2:
		oaks.append(_give(s, func(c: Dictionary) -> bool: return c.sym == &"oak" and c.id != owl.id and not oaks.has(c.id)).id)
	var before := s.hand.size()
	assert_bool(s.play(owl.id, 0, 0, oaks)).is_true()
	assert_int(s.hand.size()).is_equal(before - 3 + 1)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"bonus")).is_true()


func test_no_bonus_with_mixed_colors() -> void:
	var s := _season()
	var birch := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"birch")
	s.play(birch.id, 0, 0, [])
	s.end_turn()
	var owl := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"owl", &"mushroom"])
	var pay: Array[int] = [
		_give(s, func(c: Dictionary) -> bool: return c.sym == &"oak" and c.id != owl.id).id,
		_give(s, func(c: Dictionary) -> bool: return c.sym == &"fir").id,
	]
	s.play(owl.id, 0, 0, pay)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"bonus")).is_false()


func test_effect_cave_and_pick() -> void:
	var s := _season()
	var birch := _give(s, func(c: Dictionary) -> bool: return c.get("tree") == &"birch")
	s.play(birch.id, 0, 0, [])
	s.end_turn()
	var mole := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"bat", &"mole"])
	var pay: Array[int] = []
	for c in s.hand:
		if c.id != mole.id and pay.size() < 2:
			pay.append(c.id)
	assert_bool(s.play(mole.id, 1, 0, pay)).is_true()
	assert_int(s.forest.cave.size()).is_equal(2)
	s.end_turn()
	# 마멋(효과: 공터에서 1장 줍기) — 고른 카드를 줍는다
	var marmot := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"fox", &"marmot"])
	var want: int = s.clearing[0].id
	assert_bool(s.play(marmot.id, 1, 0, [s.hand.filter(func(c: Dictionary) -> bool: return c.id != marmot.id)[0].id], [want])).is_true()
	assert_int(s.find(want, s.hand)).is_greater_equal(0)


func test_sapling_is_free_and_counts_as_no_species() -> void:
	var s := _season()
	var any := s.hand[0]
	assert_bool(s.sapling(any.id, 2)).is_true()
	assert_str(String(s.forest.kind_at(2))).is_equal("sapling")
	s.end_turn()
	var fox_card := _give(s, func(c: Dictionary) -> bool: return c.get("halves", []) == [&"fox", &"hare"])
	assert_bool(s.play(fox_card.id, 1, 2, [])).is_true()


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

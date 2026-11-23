extends GdUnitTestSuite
## 점수(Score/ScoreLog)·버섯 지속 효과(Hook)·계절 바람 — 원작 기본판 규칙

var _id := 0


func _forest(layout: Dictionary) -> Forest:
	var f := Forest.new()
	for p in layout:
		f.plant(p, {id = _next(), tree = layout[p], sym = layout[p]}, layout[p])
	return f


func _next() -> int:
	_id += 1
	return _id


func _card(syms := [&"", &""]) -> Dictionary:
	return {id = _next(), halves = [&"", &""], axis = &"v", syms = syms}


func _pts(log: ScoreLog, what: StringName) -> int:
	return log.by_what().get(what, 0)


func test_every_card_has_a_score_rule() -> void:
	var f := Forest.new()
	for k in Cards.TREES:
		assert_bool(Cards.TREES[k].has("score")).is_true()
	for k in Cards.SPECIES:
		assert_bool(Cards.SPECIES[k].has("score")).is_true()
	# 모든 규칙이 알려진 말이다(모르면 push_error)
	var all := _forest({0: &"oak", 1: &"birch", 2: &"pine", 3: &"fir", 4: &"maple", 5: &"chestnut", 6: &"linden", 7: &"beech"})
	for k in Cards.SPECIES:
		for p in 8:
			var side: StringName = Cards.SPECIES[k].side
			side = &"Left" if side == &"Side" else side
			if all.attach(p, side, _card(), k):
				break
	assert_int(Score.count(all).total).is_greater(0)
	assert_int(Score.count(f).total).is_equal(0)


func test_simple_trees() -> void:
	# 자작나무 1 + 미송 5, 묘목은 점수가 없다
	var log := Score.count(_forest({0: &"birch", 1: &"pine", 2: Forest.SAPLING}))
	assert_int(log.total).is_equal(6)
	assert_int(log.lines.size()).is_equal(2)


func test_oak_needs_all_eight_tree_kinds() -> void:
	var f := _forest({0: &"oak", 1: &"birch", 2: &"pine", 3: &"fir", 4: &"maple", 5: &"chestnut", 6: &"linden"})
	assert_int(_pts(Score.count(f), &"oak")).is_equal(0)
	f.plant(7, {id = _next()}, &"beech")
	assert_int(_pts(Score.count(f), &"oak")).is_equal(10)


func test_chestnut_set_scores_once() -> void:
	var log := Score.count(_forest({0: &"chestnut", 1: &"chestnut", 2: &"chestnut"}))
	assert_int(_pts(log, &"chestnut")).is_equal(9)
	assert_int(log.lines.filter(func(l: Dictionary) -> bool: return l.pts > 0).size()).is_equal(1)


func test_beech_four_or_more() -> void:
	var f := _forest({0: &"beech", 1: &"beech", 2: &"beech"})
	assert_int(Score.count(f).total).is_equal(0)
	f.plant(3, {id = _next()}, &"beech")
	assert_int(Score.count(f).total).is_equal(20)


func test_linden_most_common() -> void:
	var f := _forest({0: &"linden", 1: &"birch", 2: &"birch"})
	assert_int(_pts(Score.count(f), &"linden")).is_equal(1)
	f.plant(3, {id = _next()}, &"linden")
	assert_int(_pts(Score.count(f), &"linden")).is_equal(6)


func test_silver_fir_counts_its_neighbors_and_hares_stack() -> void:
	var f := _forest({0: &"fir"})
	f.attach(0, &"Top", _card(), &"tawny_owl")
	f.attach(0, &"Right", _card(), &"hare")
	f.attach(0, &"Right", _card(), &"hare")
	assert_int(_pts(Score.count(f), &"fir")).is_equal(6)
	assert_int(_pts(Score.count(f), &"hare")).is_equal(4)


func test_sycamore_counts_trees() -> void:
	var f := _forest({0: &"maple", 1: &"oak", 2: Forest.SAPLING})
	assert_int(_pts(Score.count(f), &"maple")).is_equal(2)


func test_neighbor_patterns() -> void:
	var f := _forest({0: &"oak", 1: &"beech", 2: &"birch"})
	f.attach(1, &"Top", _card(), &"chaffinch")       # 너도밤나무 위: 5
	f.attach(0, &"Top", _card(), &"red_squirrel")    # 참나무 위: 5
	f.attach(2, &"Top", _card(), &"goshawk")         # 새 2마리 × 3
	f.attach(2, &"Bottom", _card(), &"moss")
	f.attach(1, &"Bottom", _card(), &"wood_ant")     # 아래 자리 2장 × 2
	f.attach(0, &"Left", _card(), &"red_deer")       # 나무 3 + 식물 1
	f.attach(1, &"Left", _card(), &"fallow_deer")    # 발굽 2마리 × 3
	f.attach(2, &"Left", _card(), &"wolf")           # 사슴 2마리 × 5
	var log := Score.count(f)
	assert_int(_pts(log, &"chaffinch")).is_equal(5)
	assert_int(_pts(log, &"red_squirrel")).is_equal(5)
	assert_int(_pts(log, &"goshawk")).is_equal(6)
	assert_int(_pts(log, &"wood_ant")).is_equal(4)
	assert_int(_pts(log, &"red_deer")).is_equal(4)
	assert_int(_pts(log, &"fallow_deer")).is_equal(6)
	assert_int(_pts(log, &"wolf")).is_equal(10)


func test_bullfinch_counts_butterflies_as_insects() -> void:
	var f := _forest({0: &"oak", 1: &"birch"})
	f.attach(0, &"Top", _card(), &"bullfinch")
	f.attach(1, &"Top", _card(), &"peacock_butterfly")
	f.attach(1, &"Bottom", _card(), &"firefly")
	assert_int(_pts(Score.count(f), &"bullfinch")).is_equal(4)


func test_bats_need_three_species() -> void:
	var f := _forest({0: &"oak", 1: &"fir", 2: &"pine"})
	f.attach(0, &"Left", _card(), &"barbastelle_bat")
	f.attach(1, &"Left", _card(), &"bechstein_bat")
	assert_int(Score.count(f).total - 5).is_equal(2)
	f.attach(2, &"Left", _card(), &"long_eared_bat")
	var log := Score.count(f)
	assert_int(_pts(log, &"barbastelle_bat") + _pts(log, &"bechstein_bat") + _pts(log, &"long_eared_bat")).is_equal(15)


func test_butterfly_sets() -> void:
	var f := _forest({0: &"oak", 1: &"fir", 2: &"pine", 3: &"birch"})
	f.attach(0, &"Top", _card(), &"peacock_butterfly")
	f.attach(1, &"Top", _card(), &"peacock_butterfly")
	f.attach(2, &"Top", _card(), &"purple_emperor")
	var by := Score.count(f).by_what()
	# 묶음 {공작, 번개오색} 3 + {공작} 0
	assert_int(by.get(&"peacock_butterfly", 0) + by.get(&"purple_emperor", 0)).is_equal(3)
	f.attach(3, &"Top", _card(), &"fritillary")
	by = Score.count(f).by_what()
	assert_int(by.get(&"peacock_butterfly", 0) + by.get(&"purple_emperor", 0) + by.get(&"fritillary", 0)).is_equal(6)


func test_count_tables() -> void:
	var f := _forest({0: &"oak", 1: &"birch"})
	f.attach(0, &"Bottom", _card(), &"firefly")
	f.attach(1, &"Bottom", _card(), &"firefly")
	assert_int(_pts(Score.count(f), &"firefly")).is_equal(10)
	var g := _forest({0: &"oak"})
	g.attach(0, &"Bottom", _card(), &"fire_salamander")
	assert_int(_pts(Score.count(g), &"fire_salamander")).is_equal(5)


func test_toads_score_when_two_share() -> void:
	var f := _forest({0: &"oak"})
	f.attach(0, &"Bottom", _card(), &"toad")
	assert_int(_pts(Score.count(f), &"toad")).is_equal(0)
	assert_bool(f.attach(0, &"Bottom", _card(), &"toad")).is_true()
	assert_int(_pts(Score.count(f), &"toad")).is_equal(10)
	assert_bool(f.can_attach(0, &"Bottom", &"toad")).is_false()


func test_roe_deer_counts_its_tree_color() -> void:
	var f := _forest({0: &"oak", 1: &"oak", 2: &"birch"})
	var c := {id = _next(), halves = [&"roe_deer", &"squeaker"], axis = &"h", syms = [&"oak", &"birch"]}
	f.attach(2, &"Left", c, &"roe_deer")
	# 참나무 2그루 + 노루 반쪽(참나무 색) 1장 = 3 × 3
	assert_int(_pts(Score.count(f), &"roe_deer")).is_equal(9)


func test_with_another_species() -> void:
	var f := _forest({0: &"oak", 1: &"birch"})
	f.attach(0, &"Left", _card(), &"lynx")
	f.attach(1, &"Left", _card(), &"boar")
	assert_int(Score.count(f).total).is_equal(1)
	f.attach(0, &"Right", _card(), &"roe_deer")
	f.attach(1, &"Right", _card(), &"squeaker")
	var log := Score.count(f)
	assert_int(_pts(log, &"lynx")).is_equal(10)
	assert_int(_pts(log, &"boar")).is_equal(10)
	assert_int(_pts(log, &"squeaker")).is_equal(1)


func test_dormouse_wants_a_bat_on_its_tree() -> void:
	var f := _forest({0: &"oak"})
	f.attach(0, &"Left", _card(), &"dormouse")
	assert_int(_pts(Score.count(f), &"dormouse")).is_equal(0)
	f.attach(0, &"Right", _card(), &"horseshoe_bat")
	assert_int(_pts(Score.count(f), &"dormouse")).is_equal(15)


func test_carpenter_bee_counts_its_tree_twice() -> void:
	var f := _forest({0: &"linden", 1: &"birch", 2: &"birch"})
	assert_int(_pts(Score.count(f), &"linden")).is_equal(1)
	f.attach(0, &"Left", _card(), &"carpenter_bee")
	assert_int(_pts(Score.count(f), &"linden")).is_equal(3)


func test_dew_adds_two() -> void:
	var f := Forest.new()
	f.plant(0, {id = 1, deco = &"dew"}, &"pine")
	assert_int(Score.count(f).total).is_equal(7)


func test_cave_and_score_log_lines() -> void:
	var f := _forest({4: &"pine"})
	f.cave.append(_card())
	f.cave.append(_card())
	var log := Score.count(f)
	assert_int(log.cave).is_equal(2)
	assert_int(log.total).is_equal(7)
	assert_dict(log.lines[0]).contains_key_value("plot", 4)
	assert_str(String(log.lines[0].rule)).is_equal("flat")


func test_gold_leaf_counts_as_any_color() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, {id = _next()}, &"oak")
	s.hand.append({id = 900, halves = [&"tawny_owl", &"chanterelle"], axis = &"v", syms = [&"oak", &"oak"]})
	s.hand.append({id = 901, tree = &"fir", sym = &"fir", deco = &"gold"})
	s.hand.append({id = 902, tree = &"oak", sym = &"oak"})
	assert_bool(s.play(900, 0, 0, [901, 902])).is_true()
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"bonus")).is_true()


func test_chanterelle_draws_when_planting() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, {id = _next()}, &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"chanterelle")
	s.hand.append({id = 900, tree = &"birch", sym = &"birch"})
	var before := s.hand.size()
	assert_bool(s.play(900, 0, 1, [])).is_true()
	# 자작나무 효과 1장 + 꾀꼬리버섯 1장
	assert_int(s.hand.size()).is_equal(before - 1 + 2)


func test_fly_agaric_draws_for_paw_animals_only() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, {id = _next()}, &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"fly_agaric")
	s.hand.append({id = 900, halves = [&"fox", &"hare"], axis = &"h", syms = [&"oak", &"oak"]})
	var before := s.hand.size()
	assert_bool(s.play(900, 1, 0, [])).is_true()
	assert_int(s.hand.size()).is_equal(before - 1 + 1)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"hook")).is_true()


func test_penny_bun_ignores_other_sides() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, {id = _next()}, &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"penny_bun")
	s.hand.append({id = 900, halves = [&"fox", &"hare"], axis = &"h", syms = [&"oak", &"oak"]})
	s.play(900, 1, 0, [])
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"hook")).is_false()


func test_three_winds_end_the_season() -> void:
	var s := Season.new(Cards.start_bag(), 5)
	assert_int(s.deck.filter(func(c: Dictionary) -> bool: return c.get("wind", false)).size()).is_equal(Season.WINDS)
	assert_int(s.hand.filter(func(c: Dictionary) -> bool: return c.get("wind", false)).size()).is_equal(0)
	var turns := 0
	while not s.over and turns < 100:
		s.draw()
		s.draw()
		s.hand.clear()
		s.end_turn()
		turns += 1
	assert_bool(s.over).is_true()
	assert_int(s.winds_seen).is_equal(Season.WINDS)
	assert_bool(s.draw()).is_false()
	assert_str(String(s.log.back().t)).is_equal("over")
	assert_int(s.log.filter(func(e: Dictionary) -> bool: return e.t == &"wind").size()).is_equal(3)


func test_wind_count_can_change() -> void:
	var s := Season.new(Cards.start_bag(), 5, null, 4)
	assert_int(s.deck.filter(func(c: Dictionary) -> bool: return c.get("wind", false)).size()).is_equal(4)


func test_forest_survives_into_next_season() -> void:
	var a := Season.new(Cards.start_bag(), 1)
	a.forest.plant(4, {id = _next()}, &"pine")
	var b := Season.new(Cards.start_bag(), 2, a.forest)
	assert_int(Score.count(b.forest, 1).total).is_equal(5)

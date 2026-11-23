extends GdUnitTestSuite
## 규칙 1-2: 점수(Score/ScoreLog)·버섯 지속 효과(Hook)·계절 바람

var _id := 0


func _forest(layout: Dictionary) -> Forest:
	var f := Forest.new()
	for p in layout:
		f.plant(p, _card(), layout[p])
	return f


func _card() -> Dictionary:
	_id += 1
	return {id = _id, sym = &""}


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
	var log := Score.count(_forest({0: &"birch", 1: &"fir", 2: Forest.SAPLING}))
	assert_int(log.total).is_equal(1 + 6)
	assert_int(log.lines.size()).is_equal(2)


func test_oak_needs_six_tree_kinds() -> void:
	var f := _forest({0: &"oak", 1: &"birch", 2: &"pine", 3: &"fir", 4: &"maple"})
	assert_int(_pts(Score.count(f), &"oak")).is_equal(0)
	f.plant(5, _card(), &"beech")
	assert_int(_pts(Score.count(f), &"oak")).is_equal(8)


func test_maple_late_seasons() -> void:
	var f := _forest({0: &"maple"})
	assert_int(Score.count(f, 0).total).is_equal(3)
	assert_int(Score.count(f, 2).total).is_equal(7)


func test_chestnut_set_scores_once() -> void:
	var f := _forest({0: &"chestnut", 1: &"chestnut", 2: &"chestnut"})
	var log := Score.count(f)
	assert_int(_pts(log, &"chestnut")).is_equal(8)
	assert_int(log.lines.filter(func(l: Dictionary) -> bool: return l.pts > 0).size()).is_equal(1)


func test_beech_three_or_more() -> void:
	var f := _forest({0: &"beech", 1: &"beech"})
	assert_int(Score.count(f).total).is_equal(0)
	f.plant(2, _card(), &"beech")
	assert_int(Score.count(f).total).is_equal(15)


func test_linden_most_common() -> void:
	var f := _forest({0: &"linden", 1: &"fir", 2: &"fir"})
	assert_int(_pts(Score.count(f), &"linden")).is_equal(1)
	f.plant(3, _card(), &"linden")
	assert_int(_pts(Score.count(f), &"linden")).is_equal(8)


func test_pine_counts_its_neighbors() -> void:
	var f := _forest({0: &"pine"})
	f.attach(0, &"Top", _card(), &"owl")
	f.attach(0, &"Right", _card(), &"hare")
	f.attach(0, &"Right", _card(), &"hare")
	assert_int(_pts(Score.count(f), &"pine")).is_equal(6)
	# 산토끼 2마리 × 2마리
	assert_int(_pts(Score.count(f), &"hare")).is_equal(4)


func test_neighbor_patterns() -> void:
	var f := _forest({0: &"oak", 1: &"pine", 2: &"birch"})
	f.attach(0, &"Left", _card(), &"boar")      # 참나무 위: 7
	f.attach(1, &"Left", _card(), &"boar")      # 소나무 위: 2
	f.attach(1, &"Bottom", _card(), &"axolotl") # 소나무: 5
	f.attach(0, &"Bottom", _card(), &"flower")
	f.attach(2, &"Bottom", _card(), &"bee")     # 풀꽃 1 × 2
	f.attach(0, &"Top", _card(), &"finch")      # 같은 나무에 나비 없음: 2
	f.attach(2, &"Top", _card(), &"butterfly")
	f.attach(2, &"Left", _card(), &"fox")
	f.attach(2, &"Right", _card(), &"marmot")   # 발바닥 2종 × 2
	var log := Score.count(f)
	assert_int(_pts(log, &"boar")).is_equal(9)
	assert_int(_pts(log, &"axolotl")).is_equal(5)
	assert_int(_pts(log, &"bee")).is_equal(2)
	assert_int(_pts(log, &"finch")).is_equal(2)
	assert_int(_pts(log, &"marmot")).is_equal(4)
	# 나비가 붙은 나무 종류 1가지
	assert_int(_pts(log, &"butterfly")).is_equal(3)
	# 자작나무는 4방향이 다 찼다
	f.attach(1, &"Right", _card(), &"goat")
	assert_int(_pts(Score.count(f), &"goat")).is_equal(4)


func test_bats_need_three_species() -> void:
	var f := _forest({0: &"oak", 1: &"fir", 2: &"pine", 3: &"birch"})
	f.attach(0, &"Top", _card(), &"bat")
	f.attach(1, &"Top", _card(), &"bat")
	f.attach(2, &"Top", _card(), &"long_eared_bat")
	assert_int(Score.count(f).by_what()[&"bat"]).is_equal(2)
	f.attach(3, &"Top", _card(), &"horseshoe_bat")
	var log := Score.count(f)
	assert_int(log.by_what()[&"bat"] + log.by_what()[&"long_eared_bat"] + log.by_what()[&"horseshoe_bat"]).is_equal(20)


func test_butterfly_set_counts_species_once() -> void:
	var f := _forest({0: &"oak", 1: &"fir", 2: &"pine"})
	f.attach(0, &"Top", _card(), &"butterfly")
	f.attach(1, &"Top", _card(), &"morpho")
	f.attach(2, &"Top", _card(), &"butterfly")
	var log := Score.count(f)
	assert_int(log.by_what().get(&"butterfly", 0) + log.by_what().get(&"morpho", 0)).is_equal(7)


func test_new_tree_rules() -> void:
	var f := _forest({0: &"oak", 1: &"oak", 2: &"fir", 3: Forest.SAPLING})
	f.attach(0, &"Top", _card(), &"woodpecker")
	f.attach(1, &"Top", _card(), &"jay")
	f.attach(2, &"Left", _card(), &"roe_deer")
	f.attach(2, &"Right", _card(), &"moon_bear")
	f.cave.append(_card())
	var log := Score.count(f)
	assert_int(log.by_what()[&"woodpecker"]).is_equal(3)
	assert_int(log.by_what()[&"jay"]).is_equal(6)
	assert_int(log.by_what()[&"roe_deer"]).is_equal(2)
	assert_int(log.by_what()[&"moon_bear"]).is_equal(1)


func test_dew_adds_two() -> void:
	var f := Forest.new()
	f.plant(0, {id = 1, deco = &"dew"}, &"fir")
	assert_int(Score.count(f).total).is_equal(8)


func test_gold_leaf_counts_as_any_color() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, _card(), &"oak")
	s.hand.append({id = 900, halves = [&"owl", &"mushroom"], axis = &"v", sym = &"oak"})
	s.hand.append({id = 901, tree = &"fir", sym = &"fir", deco = &"gold"})
	s.hand.append({id = 902, tree = &"fir", sym = &"oak"})
	assert_bool(s.play(900, 0, 0, [901, 902])).is_true()
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"bonus")).is_true()


func test_fly_agaric_draws_when_planting() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, _card(), &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"fly_agaric")
	s.hand.append({id = 900, tree = &"birch", sym = &"birch"})
	var before := s.hand.size()
	assert_bool(s.play(900, 0, 1, [])).is_true()
	# 자작 효과 1장 + 광대버섯 1장
	assert_int(s.hand.size()).is_equal(before - 1 + 2)


func test_cave_and_score_log_lines() -> void:
	var f := _forest({4: &"fir"})
	f.cave.append(_card())
	f.cave.append(_card())
	var log := Score.count(f)
	assert_int(log.cave).is_equal(2)
	assert_int(log.total).is_equal(8)
	assert_dict(log.lines[0]).contains_key_value("plot", 4)
	assert_str(String(log.lines[0].rule)).is_equal("flat")


func test_mushroom_hook_draws_when_placing_left() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, _card(), &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"mushroom")
	var fox := {id = 900, halves = [&"fox", &"hare"], axis = &"h", sym = &"oak"}
	s.hand.append(fox)
	var pay: Array[int] = [s.hand[0].id, s.hand[1].id]
	var before := s.hand.size()
	# 여우 효과 1장 + 버섯 1장
	assert_bool(s.play(900, 0, 0, pay)).is_true()
	assert_int(s.hand.size()).is_equal(before - 3 + 2)
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"hook")).is_true()


func test_mushroom_hook_ignores_other_sides() -> void:
	var s := Season.new(Cards.start_bag(), 3)
	s.forest.plant(0, _card(), &"oak")
	s.forest.attach(0, &"Bottom", _card(), &"mushroom")
	s.hand.append({id = 900, halves = [&"fox", &"hare"], axis = &"h", sym = &"oak"})
	s.play(900, 1, 0, [])
	assert_bool(s.log.any(func(e: Dictionary) -> bool: return e.t == &"hook")).is_false()


func test_three_winds_end_the_season() -> void:
	var s := Season.new(Cards.start_bag(), 5)
	assert_int(s.deck.filter(func(c: Dictionary) -> bool: return c.get("wind", false)).size()).is_equal(Season.WINDS)
	# 바람은 아래 1/3에 있다(시작 손패에는 없다)
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
	a.forest.plant(4, _card(), &"fir")
	var b := Season.new(Cards.start_bag(), 2, a.forest)
	assert_int(Score.count(b.forest, 1).total).is_equal(6)

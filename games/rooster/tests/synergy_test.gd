extends GdUnitTestSuite


func _sim(bag: Bag, lanes: Array) -> BattleSim:
	var pr := Procession.new()
	pr.lanes = lanes
	return BattleSim.new(bag, pr, RandomNumberGenerator.new())


func _bag_with(kinds: Array, at: Array) -> Bag:
	var bag := Bag.new(5, 4)
	for i in kinds.size():
		assert_bool(bag.place(Piece.create(kinds[i]), at[i])).is_true()
	return bag


func test_roster_has_24_with_four_per_family_and_valid_forms() -> void:
	assert_int(YokaiDb.ALLIES.size()).is_equal(24)
	var per := {}
	for kind in YokaiDb.ALLIES:
		var def: Dictionary = YokaiDb.ALLIES[kind]
		per[def["family"]] = per.get(def["family"], 0) + 1
		assert_bool(YokaiDb.FORMS.has(def["evolve"])).is_true()
		assert_str(String(YokaiDb.FORMS[def["evolve"]]["base"])).is_equal(String(kind))
		assert_bool(ResourceLoader.exists("res://assets/yokai/%s.png" % kind)).is_true()
		assert_bool(ResourceLoader.exists("res://assets/yokai/%s.png" % def["evolve"])).is_true()
		assert_str(TranslationServer.translate("TRAIT_" + String(def["trait"]).to_upper() + "_DESC")).is_not_equal("TRAIT_" + String(def["trait"]).to_upper() + "_DESC")
	for f in YokaiDb.FAMILIES:
		assert_int(per[f]).is_equal(4)


func test_market_pool_unlocks_tiers_by_night() -> void:
	for kind in YokaiDb.market_pool(1):
		assert_int(YokaiDb.tier(kind)).is_equal(1)
	var tiers := {}
	for kind in YokaiDb.market_pool(4):
		tiers[YokaiDb.tier(kind)] = true
	assert_bool(tiers.has(3)).is_true()


func test_family_levels_and_fire_bonus() -> void:
	var bag := _bag_with([&"foxfire", &"bulgae"], [Vector2i(0, 0), Vector2i(0, 2)])
	assert_int(Synergy.levels(bag)[&"fire"]).is_equal(1)
	var b: Dictionary = Synergy.bonuses(bag)[bag.pieces[0].id]
	assert_int(b["atk"]).is_equal(1)


func test_forge_link_gives_metal_attack_per_touching_fire() -> void:
	var bag := _bag_with([&"bulgasari", &"foxfire"], [Vector2i(0, 0), Vector2i(0, 1)])
	var b: Dictionary = Synergy.bonuses(bag)[bag.pieces[0].id]
	assert_int(b["atk"]).is_equal(1)
	assert_bool(&"forge" in b["why"]).is_true()


func test_undying_survives_once_at_one_hp() -> void:
	var bag := _bag_with([&"mudu"], [Vector2i(0, 0)])
	var sim := _sim(bag, [[], [], [], []])
	var u := sim.units[0]
	assert_bool(sim._damage(null, u, 99)).is_false()
	assert_int(u.hp).is_equal(1)
	assert_bool(sim._damage(null, u, 99)).is_true()
	assert_bool(u.alive).is_false()


func test_burn_ticks_enemy_on_its_action() -> void:
	var bag := _bag_with([&"bulgae"], [Vector2i(3, 0)])
	var sim := _sim(bag, [[&"shade"], [], [], []])
	var enemy := sim.units[1]
	var hp := enemy.hp
	sim._act(sim.units[0])
	assert_int(enemy.burn).is_equal(BattleSim.BURN_STACKS)
	sim._act(enemy)
	assert_int(enemy.hp).is_equal(hp - sim.units[0].atk - 1)


func test_mimic_copies_strongest_touching_ability() -> void:
	var bag := _bag_with([&"jangsanbeom", &"haetae"], [Vector2i(0, 0), Vector2i(2, 0)])
	var sim := _sim(bag, [[], [], [], []])
	sim._battle_start()
	assert_bool(sim.units[0].has_trait(&"guard")).is_true()


func test_rebirth_revives_other_ally_once() -> void:
	var bag := _bag_with([&"bonghwang", &"foxfire"], [Vector2i(0, 0), Vector2i(4, 3)])
	var sim := _sim(bag, [[], [], [], []])
	var fox := sim.units[1]
	assert_bool(sim._damage(null, fox, 99)).is_false()
	assert_int(fox.hp).is_equal(ceili(fox.max_hp / 2.0))
	assert_bool(sim._damage(null, fox, 99)).is_true()


func test_hoard_pays_if_alive_at_end() -> void:
	var bag := _bag_with([&"geumdwaeji"], [Vector2i(0, 0)])
	var sim := _sim(bag, [[], [], [], []])
	sim.run()
	assert_int(sim.coins).is_equal(BattleSim.HOARD_COINS)


func test_steal_triggers_on_splash_kill() -> void:
	var bag := _bag_with([&"yagwang"], [Vector2i(0, 0)])
	var sim := _sim(bag, [[&"shade"], [], [], []])
	var u := sim.units[0]
	var e := sim.units[1]
	var atk := u.atk
	e.hp = 1
	assert_bool(sim._damage(u, e, 5)).is_true()
	assert_int(u.atk).is_equal(atk + ceili(e.atk / 2.0))

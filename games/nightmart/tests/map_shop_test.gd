extends GdUnitTestSuite

const MAP := preload("res://scenes/screens/map.tscn")
const SHOP := preload("res://scenes/screens/shop.tscn")
const RUN_END := preload("res://scenes/screens/run_end.tscn")


func _screen(scene: PackedScene) -> Control:
	var node: Control = auto_free(scene.instantiate())
	add_child(node)
	return node


func _texts(node: Node) -> Array:
	return node.find_children("*", "Label", true, false).map(func(l: Label) -> String: return l.text)


func test_map_shows_skip_reward_and_skips() -> void:
	Game.run = Run.new(3)
	var map := _screen(MAP)
	assert_array(_texts(map)).contains([tr("MAP_SKIP_GETS") % Names.token(Game.run.skip_reward)])
	map._on_skip()
	assert_int(Game.run.slot).is_equal(Run.REGULAR)
	assert_array(_texts(map)).contains([tr("MAP_SKIPPED")])


func test_map_boss_cannot_skip() -> void:
	Game.run = Run.new(3)
	Game.run.skip()
	Game.run.skip()
	var map := _screen(MAP)
	assert_bool(map._skip.disabled).is_true()


func _shop_run() -> Run:
	var run := Run.new(3)
	run.phase = Run.Phase.SHOP
	run.shop.offers = Shop.roll(run.rng.shop, [], [])
	run.money = 50000
	Game.run = run
	return run


func test_shop_buys_tip() -> void:
	var run := _shop_run()
	var shop := _screen(SHOP)
	assert_int(shop.offer_buttons().size()).is_equal(run.shop.offers.size())
	shop._buy(0)
	assert_int(run.tips.size()).is_equal(1)
	assert_array(_texts(shop)).contains([tr("SHOP_SOLD")])


func test_shop_full_inventory_fits_screen() -> void:
	var run := _shop_run()
	for id in [&"waste_snack", &"row_obsessed", &"boss_nephew", &"same_aisle", &"last_five"]:
		run.tips.append(Tips.make(id))
	run.consumables.assign([Combo.Kind.STRAIGHT_FLUSH, Combo.Kind.FULL_HOUSE])
	for id in Expansions.MAKERS:
		run.expansions.append(Expansions.make(id))
	var shop := _screen(SHOP)
	var owned: HBoxContainer = shop.find_child("Owned", true, false)
	assert_int(owned.get_child_count()).is_equal(5 + 2 + 1)
	assert_float(owned.get_combined_minimum_size().x).is_less_equal(1920 * 0.9)


func test_shop_pack_pick_adds_card() -> void:
	var run := _shop_run()
	var shop := _screen(SHOP)
	var pack := run.shop.offers.find_custom(func(o: Dictionary) -> bool: return o.kind == Shop.PACK)
	shop._buy(pack)
	assert_int(run.phase).is_equal(Run.Phase.PACK)
	assert_int(shop.find_children("*", "ProductCard", true, false).size()).is_equal(Shop.PACK_SIZE)
	shop._choose(0)
	assert_int(run.deck.size()).is_equal(53)
	assert_int(run.phase).is_equal(Run.Phase.SHOP)


func test_run_end_lists_result() -> void:
	Game.run = Run.new(3)
	Game.run.phase = Run.Phase.LOST
	var node := _screen(RUN_END)
	assert_array(_texts(node)).contains([tr("END_LOST")])

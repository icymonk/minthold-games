extends GdUnitTestSuite
## 0-3 카드 → 숲 붙이기(규칙 없음): 자리 찾기·미리 보기·놓기


func _view() -> ForestView:
	var view: ForestView = auto_free(ForestView.new())
	add_child(view)
	view.plant_layout(ForestView.START_FOREST)
	return view


func test_tree_card_targets_empty_plots() -> void:
	var view := _view()
	var empty := ForestView.START_FOREST.count(&"")
	assert_int(view.targets_for(&"oak").size()).is_equal(empty)


func test_neighbor_targets_free_side_of_every_tree() -> void:
	var view := _view()
	var trees := ForestView.START_FOREST.size() - ForestView.START_FOREST.count(&"")
	var targets := view.targets_for(&"tawny_owl", &"Top")
	assert_int(targets.size()).is_equal(trees)
	view.place(targets[0], &"tawny_owl")
	assert_int(view.targets_for(&"chaffinch", &"Top").size()).is_equal(trees - 1)
	var tree := view.tree_at(targets[0].plot)
	assert_int(tree.occupants(&"Top").size()).is_equal(1)
	assert_object(tree.occupants(&"Top")[0].get_parent()).is_same(tree.socket(&"Top"))


func test_hares_stack_up_to_five() -> void:
	var view := _view()
	var t: Dictionary = view.targets_for(&"hare", &"Left")[0]
	for i in 5:
		assert_bool(view.tree_at(t.plot).can_attach(&"Left", &"hare")).is_true()
		view.place(t, &"hare")
	assert_bool(view.tree_at(t.plot).can_attach(&"Left", &"hare")).is_false()
	assert_bool(view.tree_at(t.plot).can_attach(&"Left", &"fox")).is_false()


func test_planting_fills_plot() -> void:
	var view := _view()
	var t: Dictionary = view.targets_for(&"linden")[0]
	view.place(t, &"linden")
	assert_str(String(view.tree_at(t.plot).species)).is_equal("linden")
	assert_int(view.targets_for(&"oak").size()).is_equal(ForestView.START_FOREST.count(&"") - 1)


func test_full_tree_shows_ring() -> void:
	var view := _view()
	var plot: int = view.targets_for(&"tawny_owl", &"Top")[0].plot
	var tree := view.tree_at(plot)
	for pair in [[&"tawny_owl", &"Top"], [&"mole", &"Bottom"], [&"fox", &"Left"], [&"fallow_deer", &"Right"]]:
		view.place({plot = plot, side = pair[1]}, pair[0])
	assert_bool(tree.is_complete()).is_true()
	assert_bool(tree._ring.visible).is_true()


func test_preview_ghost_comes_and_goes() -> void:
	var view := _view()
	var t: Dictionary = view.targets_for(&"fox", &"Right")[0]
	view.preview(t, &"fox")
	assert_object(view._ghost).is_not_null()
	view.preview({}, &"")
	assert_object(view._ghost).is_null()


func test_placed_signal() -> void:
	var view := _view()
	var got := []
	view.placed.connect(func(t: Dictionary, k: StringName) -> void: got.append([t, k]))
	var t: Dictionary = view.targets_for(&"toad", &"Bottom")[0]
	view.place(t, &"toad")
	assert_int(got.size()).is_equal(1)
	assert_str(String(got[0][1])).is_equal("toad")


func test_demo_cards_fit_their_sides() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	for i in 200:
		var c := DemoCards.deal(rng)
		if DemoCards.is_tree(c):
			assert_bool(ForestTree.SPECIES.has(c.tree)).is_true()
			continue
		for h in 2:
			assert_bool(DemoCards.side_of(c, h) in Dweller.KINDS[DemoCards.kind_of(c, h)].sides).is_true()


func test_coach_waits_for_its_signal() -> void:
	var view := _view()
	var coach: Coach = auto_free(Coach.new())
	add_child(coach)
	coach.start([
		{text = "COACH_PLANT", wait = view.placed, check = func(a: Array) -> bool: return a[0].side == &""},
		{text = "COACH_WIND"},
	] as Array[Dictionary])
	view.place(view.targets_for(&"tawny_owl", &"Top")[0], &"tawny_owl")
	await get_tree().process_frame
	assert_int(coach.index).is_equal(0)
	view.place(view.targets_for(&"oak")[0], &"oak")
	await get_tree().process_frame
	assert_int(coach.index).is_equal(1)
	Coach.mark_seen(false)

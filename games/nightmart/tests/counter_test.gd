extends GdUnitTestSuite

const COUNTER := preload("res://scenes/screens/counter.tscn")


func _deal(seed_value: int) -> Array:
	Game.rng = RngStreams.new(seed_value)
	var counter: Control = auto_free(COUNTER.instantiate())
	add_child(counter)
	return counter.hand().map(func(c: ProductCard) -> Array: return [c.corner, c.rank])


func test_same_seed_deals_same_hand() -> void:
	var hand := _deal(77)
	assert_int(hand.size()).is_equal(8)
	assert_array(_deal(77)).is_equal(hand)
	assert_array(_deal(78)).is_not_equal(hand)


func test_pick_limit_is_five() -> void:
	Game.rng = RngStreams.new(5)
	var counter: Control = auto_free(COUNTER.instantiate())
	add_child(counter)
	for card in counter.hand():
		card.button_pressed = true
	assert_int(counter.picked().size()).is_equal(5)

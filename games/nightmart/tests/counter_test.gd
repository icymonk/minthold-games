extends GdUnitTestSuite

const COUNTER := preload("res://scenes/screens/counter.tscn")


func _counter(seed_value: int) -> Control:
	Game.run = Run.new(seed_value)
	var counter: Control = auto_free(COUNTER.instantiate())
	counter.speed = 50.0
	add_child(counter)
	return counter


func _deal(seed_value: int) -> Array:
	return _counter(seed_value).hand().map(func(c: ProductCard) -> String: return str(c.card))


func test_same_seed_deals_same_hand() -> void:
	var hand := _deal(77)
	assert_int(hand.size()).is_equal(8)
	assert_array(_deal(77)).is_equal(hand)
	assert_array(_deal(78)).is_not_equal(hand)


func test_pick_limit_is_five() -> void:
	var counter := _counter(5)
	for card in counter.hand():
		card.button_pressed = true
	assert_int(counter.picked().size()).is_equal(5)


func test_pick_previews_combo() -> void:
	var counter := _counter(5)
	var card: ProductCard = counter.hand()[0]
	card.button_pressed = true
	var r := Game.run.shift.preview([card.card])
	assert_str(counter.combo_text()).is_equal(tr("COMBO_" + Combo.Kind.keys()[r.kind]))


func test_checkout_plays_and_refills() -> void:
	var counter := _counter(5)
	counter.hand()[0].button_pressed = true
	counter._on_checkout()
	assert_int(Game.run.shift.receipts.size()).is_equal(1)
	await counter.checkout_done
	assert_int(counter.hand().size()).is_equal(Shift.HAND_SIZE)
	assert_int(Game.run.shift.checkouts_left).is_equal(Shift.CHECKOUTS - 1)


func test_cleared_customer_shows_next_button() -> void:
	var counter := _counter(5)
	Game.run.shift.target = 1
	counter.hand()[0].button_pressed = true
	counter._on_checkout()
	await counter.checkout_done
	assert_int(Game.run.phase).is_equal(Run.Phase.SHOP)
	var texts := counter.find_children("*", "Button", true, false).map(func(b: Button) -> String: return b.text)
	assert_array(texts).contains([tr("END_NEXT")])
	Game.goto(&"title")

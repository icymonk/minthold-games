extends GdUnitTestSuite

const Z := Cards.Zone


func test_time_text_reads_card_as_minutes_after_1718() -> void:
	assert_str(Cards.time_text(0)).is_equal("17:18")
	assert_str(Cards.time_text(13)).is_equal("17:31")
	assert_str(Cards.time_text(42)).is_equal("18:00")


func test_zones_cover_4_to_41() -> void:
	assert_int(Cards.zone_of(3)).is_equal(-1)
	assert_int(Cards.zone_of(4)).is_equal(Z.FLOOR)
	assert_int(Cards.zone_of(28)).is_equal(Z.BUILDING)
	assert_int(Cards.zone_of(41)).is_equal(Z.OUTSIDE)
	assert_int(Cards.zone_of(42)).is_equal(-1)
	var total := 0
	for z in Cards.ZONE_RANGES:
		total += Cards.zone_cards(z).size()
	assert_int(total).is_equal(38)


func test_sprint_two_on_multiples_of_three() -> void:
	assert_int(Cards.sprint_of(0)).is_equal(0)
	assert_int(Cards.sprint_of(42)).is_equal(0)
	assert_int(Cards.sprint_of(3)).is_equal(2)
	assert_int(Cards.sprint_of(4)).is_equal(1)
	assert_int(Cards.sprint_of(39)).is_equal(2)

extends GdUnitTestSuite


func _draw(rng: RandomNumberGenerator, n: int) -> Array[int]:
	var out: Array[int] = []
	for i in n:
		out.append(rng.randi())
	return out


func test_same_seed_same_sequence() -> void:
	var a := RngStreams.new(42)
	var b := RngStreams.new(42)
	assert_array(_draw(a.market, 5)).is_equal(_draw(b.market, 5))
	assert_array(_draw(a.battle, 5)).is_equal(_draw(b.battle, 5))


func test_streams_are_independent() -> void:
	var a := RngStreams.new(42)
	var b := RngStreams.new(42)
	_draw(a.battle, 100)
	assert_array(_draw(a.market, 5)).is_equal(_draw(b.market, 5))


func test_different_seeds_differ() -> void:
	assert_array(_draw(RngStreams.new(1).market, 5)).is_not_equal(_draw(RngStreams.new(2).market, 5))

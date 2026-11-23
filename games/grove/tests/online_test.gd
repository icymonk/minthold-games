extends GdUnitTestSuite
## 온라인 방(Online)을 가짜 데이터베이스(MemDb)로: 방 만들기·들어가기·시작·행동이 다른 기기에 같은 판으로 보이는지


func _client(store: Dictionary, uid: String) -> Online:
	var o := Online.new(MemDb.new(store, uid))
	add_child(o)
	o.set_process(false)
	return o


func _first_free_tree(o: Online) -> Dictionary:
	for c in o.game.hand_of(o.seat):
		if Cards.is_tree(c) and Cards.cost_of(c, 0) == 0:
			return c
	return {}


func test_create_join_start_and_sync() -> void:
	var store := {}
	var a := _client(store, "ua")
	var b := _client(store, "ub")
	assert_bool(await a.create("A")).is_true()
	assert_int(a.code.length()).is_equal(Online.CODE_LEN)
	assert_bool(await b.join(a.code.to_lower(), "B")).is_true()
	assert_bool(await b.start()).is_false()
	await a.poll()
	assert_int(a.members().size()).is_equal(2)
	assert_bool(await a.start()).is_true()
	await b.poll()
	assert_object(b.game).is_not_null()
	assert_int(a.seat).is_equal(0)
	assert_int(b.seat).is_equal(1)
	assert_bool(b.act({k = "draw"})).is_false()
	assert_bool(a.act({k = "draw"})).is_true()
	assert_bool(a.act({k = "draw"})).is_true()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await b.poll()
	assert_int(b.game.turn).is_equal(1)
	assert_int(b.game.hand_of(0).size()).is_equal(8)
	assert_bool(b.act({k = "draw", from = -1})).is_true()
	assert_bool(b.act({k = "draw"})).is_true()
	for i in 4:
		await get_tree().process_frame
	await a.poll()
	assert_int(a.game.turn).is_equal(0)
	assert_int(a.game.season.deck.size()).is_equal(b.game.season.deck.size())
	assert_str(a.name_of(1)).is_equal("B")
	a.queue_free()
	b.queue_free()


func test_join_rules() -> void:
	var store := {}
	var a := _client(store, "ua")
	var c := _client(store, "uc")
	assert_bool(await c.join("ZZZZZ", "C")).is_false()
	await a.create("A")
	await a.db.req("PUT", "rooms/%s/players/ub" % a.code, {name = "B", at = 1})
	await a.poll()
	await a.start()
	assert_bool(await c.join(a.code, "C")).is_false()
	a.queue_free()
	c.queue_free()


func test_conflicting_write_reloads() -> void:
	var store := {}
	var a := _client(store, "ua")
	var b := _client(store, "ub")
	await a.create("A")
	await b.join(a.code, "B")
	await a.poll()
	await a.start()
	await b.poll()
	# 다른 기기가 a00000 칸을 먼저 차지했다(엉뚱한 행동) → a는 처음부터 다시 맞춘다
	store.rooms[a.code]["actions"] = {a00000 = {by = "ub", a = {k = "draw"}}}
	assert_bool(a.act({k = "draw"})).is_true()
	await a.resynced
	assert_int(a.game.actions.size()).is_equal(0)
	assert_int(a.game.hand_of(0).size()).is_equal(6)
	a.queue_free()
	b.queue_free()

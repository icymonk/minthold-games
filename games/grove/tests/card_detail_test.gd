extends GdUnitTestSuite
## 상세 창: 모든 카드 종류로 만들 수 있고, 용어·아이콘 풀이가 비어 있지 않다.


func test_every_card_kind_builds_a_detail() -> void:
	TranslationServer.set_locale("ko")
	var seen := {}
	for c: Dictionary in Cards.full_bag():
		var key: String = String(c.tree) if Cards.is_tree(c) else "%s/%s" % [c.halves[0], c.halves[1]]
		if seen.has(key):
			continue
		seen[key] = true
		var d: CardDetail = auto_free(CardDetail.for_card(c, null, 0))
		add_child(d)
		assert_object(d).is_not_null()
		assert_bool(d.get_combined_minimum_size().x > 0).is_true()
		d.queue_free()
	assert_int(seen.size()).is_greater(20)


func test_legend_and_tips_explain_every_icon() -> void:
	TranslationServer.set_locale("ko")
	var d: CardDetail = auto_free(CardDetail.legend())
	add_child(d)
	for n: StringName in Art.ICONS:
		var key := "ICON_" + String(n).to_upper()
		assert_str(CardDetail.tip_of(key)).override_failure_message(key).is_not_equal(key)


func test_placed_card_detail_builds_for_every_kind() -> void:
	for k: StringName in Cards.SPECIES:
		var d: CardDetail = auto_free(CardDetail.for_kind(k, 3, "x"))
		add_child(d)
		d.queue_free()
	for k: StringName in Cards.TREES:
		var d: CardDetail = auto_free(CardDetail.for_kind(k, 3, "x"))
		add_child(d)
		d.queue_free()

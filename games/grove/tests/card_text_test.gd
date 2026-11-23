extends GdUnitTestSuite
## 카드 글: 모든 나무·이웃의 점수 규칙과 효과가 사람이 읽는 말로 나온다.


func before() -> void:
	TranslationServer.set_locale("ko")


func test_every_kind_has_readable_rule() -> void:
	var kinds: Array = Cards.TREES.keys() + Cards.SPECIES.keys()
	for k in kinds:
		var text := CardText.rule(k)
		assert_str(text).is_not_empty()
		assert_bool(text.contains("RULE_") or text.contains("GROUP_") or text.contains("KIND_") or text.contains("SIDE_")).override_failure_message("%s: %s" % [k, text]).is_false()


func test_every_group_and_side_translated() -> void:
	for k in Cards.SPECIES:
		var d: Dictionary = Cards.SPECIES[k]
		assert_bool(CardText.group_of(d.kind).begins_with("GROUP_")).override_failure_message(String(d.kind)).is_false()
		assert_bool(CardText.side_of(d.side).begins_with("SIDE_")).override_failure_message(String(d.side)).is_false()


func test_chips_show_effect_and_bonus() -> void:
	assert_str(CardText.gives({draw = 1, pick = 2}, true)).is_equal("덱+1 공터+2")
	var oak := CardText.chips(&"oak")
	assert_int(oak.size()).is_equal(1)
	assert_str(oak[0].tone).is_equal("bonus")
	assert_str(CardText.rule(&"oak")).is_equal("나무가 6종 이상이면 8점")
	assert_str(CardText.rule(&"bee")).is_equal("풀꽃 하나마다 2점")

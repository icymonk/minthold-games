extends GdUnitTestSuite
## 카드 글: 모든 나무·이웃의 점수 규칙과 효과가 사람이 읽는 말로 나온다.


func before() -> void:
	TranslationServer.set_locale("ko")


func test_every_kind_has_readable_rule() -> void:
	var kinds: Array = Cards.TREES.keys() + Cards.SPECIES.keys()
	for k in kinds:
		var text := CardText.rule(k)
		assert_str(text).is_not_empty()
		assert_bool(text.contains("RULE_") or text.contains("GIVE_") or text.contains("GROUP_") or text.contains("KIND_") or text.contains("SIDE_")).override_failure_message("%s: %s" % [k, text]).is_false()


func test_every_group_and_side_translated() -> void:
	for k in Cards.SPECIES:
		var d: Dictionary = Cards.SPECIES[k]
		assert_bool(CardText.group_of(d.kind).begins_with("GROUP_")).override_failure_message(String(d.kind)).is_false()
		assert_bool(CardText.side_of(d.side).begins_with("SIDE_")).override_failure_message(String(d.side)).is_false()


func test_chips_show_effect_and_bonus() -> void:
	assert_str(CardText.gives({draw = 1, pick = 2}, true)).is_equal("덱+1 공터+2")
	assert_str(CardText.gives({free = &"paw"}, true)).is_equal("발 동물 공짜")
	var oak := CardText.chips(&"oak")
	assert_int(oak.size()).is_equal(1)
	assert_str(oak[0].tone).is_equal("bonus")
	assert_str(CardText.rule(&"oak")).is_equal("나무 8종이 모두 있으면 도토리 10개")
	assert_str(CardText.rule(&"goshawk")).is_equal("숲의 새 카드 1장마다 도토리 3개")
	assert_dict(CardText.face(&"goshawk")).is_equal({pts = "3", text = "× 새"})
	assert_dict(CardText.face(&"chanterelle")).is_empty()


func test_every_card_face_and_terms_are_translated() -> void:
	for k in Cards.TREES.keys() + Cards.SPECIES.keys():
		var f := CardText.face(k)
		var text: String = f.get("text", "") + " ".join(CardText.terms(k)) + CardText.hook(k) + CardText.hook(k, true)
		for c in CardText.chips(k):
			text += c.text
		assert_bool(text.contains("FACE_") or text.contains("TERM_") or text.contains("GIVE_") or text.contains("GROUP_") or text.contains("HOOK_") or text.contains("KIND_")).override_failure_message("%s: %s" % [k, text]).is_false()

extends SceneTree
## 기획서용 카드 표(마크다운)를 찍는다: godot --headless -s res://tools/card_table.gd


func _initialize() -> void:
	TranslationServer.set_locale("ko")
	var out: Array[String] = ["| 나무 | 장수 | 비용 | 효과 | 보너스 | 점수 |", "|---|---|---|---|---|---|"]
	for k: StringName in Cards.TREES:
		var d: Dictionary = Cards.TREES[k]
		out.append("| %s | %d | %d | %s | %s | %s |" % [CardText.name_of(k), Cards.FULL_TREES[k], d.cost, _or(CardText.gives(d.effect)), _or(CardText.gives(d.bonus)), CardText.rule(k)])
	out.append("")
	out.append("| 이웃 | 상징 | 자리 | 장수 | 비용 | 효과 | 보너스 | 점수 |")
	out.append("|---|---|---|---|---|---|---|---|")
	var count := {}
	for p in Cards.FULL_PAIRS:
		for i in 2:
			count[p[i]] = count.get(p[i], 0) + 1
	for k: StringName in Cards.SPECIES:
		var d: Dictionary = Cards.SPECIES[k]
		var tags: Array[String] = []
		for t in Cards.tags_of(k):
			tags.append(CardText.group_of(t))
		var effect := CardText.gives(d.effect)
		if d.has("hook"):
			effect = CardText.hook(k)
		out.append("| %s | %s | %s | %d | %d | %s | %s | %s |" % [CardText.name_of(k), "·".join(tags), CardText.side_of(d.side), count.get(k, 0), d.cost, _or(effect), _or(CardText.gives(d.bonus)), CardText.rule(k) if not CardText.face(k).is_empty() else "-"])
	print("\n".join(out))
	quit()


func _or(s: String) -> String:
	return s if s != "" else "-"

class_name CardText
extends RefCounted
## 카드 글: 비용·효과·보너스·점수 규칙(Cards의 데이터)을 사람이 읽는 말로 바꾼다.
## rule()은 상세 창의 긴 글, face()는 카드 면의 짧은 글(도토리 그림 + 수 + 조건), terms()는 상세 창의 용어 풀이.

const GIVES: Array[StringName] = [&"draw", &"pick", &"cave", &"draw_per", &"free", &"free_all", &"more", &"stash", &"clear_to_cave", &"boost", &"again"]
const GROUP_NAMES_SHOWN := 8


static func def_of(kind: StringName) -> Dictionary:
	return Cards.TREES.get(kind, Cards.SPECIES.get(kind, {}))


static func name_of(kind: StringName) -> String:
	return _t("KIND_%s" % String(kind).to_upper())


static func group_of(group: StringName) -> String:
	return _t("GROUP_%s" % String(group).to_upper())


## 분류 아이콘 토큰({g_bird}); 아이콘이 없으면 이름
static func gicon(group: StringName) -> String:
	var n := StringName("g_" + String(group))
	return "{%s}" % n if Art.ICONS.has(n) else group_of(group)


## 자리 아이콘 토큰({side_left})
static func sicon(side: StringName) -> String:
	var n := StringName("side_" + String(side).to_lower())
	return "{%s}" % n if Art.ICONS.has(n) else side_of(side)


static func side_of(side: StringName) -> String:
	return _t("SIDE_%s" % String(side).to_upper())


## 종 이름 또는 상징 이름
static func thing(what: StringName) -> String:
	return name_of(what) if def_of(what).size() > 0 else group_of(what)


## {draw = 1, again = true} → "덱에서 1장, 한 번 더 하기" (short: "덱+1 한 번 더")
static func gives(give: Dictionary, short := false) -> String:
	var parts: Array[String] = []
	for k in GIVES:
		if not give.has(k) or (give[k] is bool and not give[k]):
			continue
		var key := "GIVE_%s%s" % [String(k).to_upper(), "_S" if short else ""]
		match k:
			&"draw", &"pick", &"cave":
				parts.append(_t(key) % give[k])
			&"draw_per", &"free", &"free_all":
				parts.append(_t(key) % (thing(give[k]) if not short or def_of(give[k]).size() > 0 else gicon(give[k])))
			_:
				parts.append(_t(key))
	return (" " if short else ", ").join(parts)


static func hook(kind: StringName, short := false) -> String:
	var h: Dictionary = def_of(kind).get("hook", {})
	if h.is_empty():
		return ""
	var s := "_S" if short else ""
	var give := gives(h.give, short)
	if h.on == &"plant":
		return _t("HOOK_PLANT" + s) % give
	if h.has("tag"):
		return _t("HOOK_TAG" + s) % [gicon(h.tag) if short else group_of(h.tag), give]
	return _t("HOOK_PLACE" + s) % [sicon(h.side) if short else side_of(h.side), give]


## 점수 규칙 한 줄(상세 창)
static func rule(kind: StringName) -> String:
	var d := def_of(kind)
	var r: Dictionary = d.get("score", {})
	if r.has("butterfly_sets"):
		return _t("RULE_BUTTERFLY") % _table(r.butterfly_sets, 2)
	if r.has("set"):
		return _t("RULE_SET") % _table(r.set, 1)
	if r.has("distinct_at_least"):
		return _t("RULE_DISTINCT_AT_LEAST") % [group_of(d.kind), r.distinct_at_least, r.each]
	if r.has("at_least"):
		return _t("RULE_AT_LEAST") % [r.at_least, r.each]
	if r.has("tree_kinds"):
		return _t("RULE_TREE_KINDS") % [r.tree_kinds, r.pts]
	if r.has("trees_at_least"):
		return _t("RULE_TREES_AT_LEAST") % [r.trees_at_least, r.pts]
	if r.has("most"):
		return _t("RULE_MOST") % [r.most, r.get("other", 0)]
	if r.has("same_tree"):
		return _t("RULE_SAME_TREE") % [group_of(r.same_tree), r.pts]
	if r.has("on"):
		return _t("RULE_ON") % [_names(r.on), r.pts]
	if r.has("with"):
		return _t("RULE_WITH") % [name_of(r.with), r.pts]
	if r.has("pair"):
		return _t("RULE_PAIR") % r.pair
	if r.has("per_sym"):
		return _t("RULE_PER_SYM") % r.per_sym
	if r.has("per_kind"):
		return _t("RULE_PER") % [_groups(r.per_kind), r.pts]
	if r.has("per_species"):
		return _t("RULE_PER") % [name_of(r.per_species), r.pts]
	if r.has("per_side"):
		return _t("RULE_PER_SIDE") % [side_of(r.per_side), r.pts]
	if r.has("full"):
		return _t("RULE_FULL") % r.full
	if r.has("per_tree"):
		return _t("RULE_PER_TREE") % r.per_tree
	if r.has("per_here"):
		return _t("RULE_PER_HERE") % r.per_here
	return _t("RULE_FLAT") % r.get("flat", 0)


## 카드 면의 점수: {pts = 도토리 수 글("" = 표), text = 조건}. 점수가 없으면 빈 사전.
static func face(kind: StringName) -> Dictionary:
	var d := def_of(kind)
	var r: Dictionary = d.get("score", {})
	if r.has("butterfly_sets"):
		return {pts = "", text = _t("FACE_BUTTERFLY"), table = cells(r.butterfly_sets, 2)}
	if r.has("set"):
		return {pts = "", text = _t("FACE_SET"), table = cells(r.set, 1)}
	if r.has("distinct_at_least"):
		return {pts = str(r.each), text = _t("FACE_DISTINCT_AT_LEAST") % [gicon(d.kind), r.distinct_at_least]}
	if r.has("at_least"):
		return {pts = str(r.each), text = _t("FACE_AT_LEAST") % r.at_least}
	if r.has("tree_kinds"):
		return {pts = str(r.pts), text = _t("FACE_TREE_KINDS") % r.tree_kinds}
	if r.has("trees_at_least"):
		return {pts = str(r.pts), text = _t("FACE_TREES_AT_LEAST") % r.trees_at_least}
	if r.has("most"):
		return {pts = str(r.most), text = _t("FACE_MOST") % r.get("other", 0)}
	if r.has("same_tree"):
		return {pts = str(r.pts), text = _t("FACE_SAME_TREE") % gicon(r.same_tree)}
	if r.has("on"):
		return {pts = str(r.pts), text = _t("FACE_ON") % _names(r.on)}
	if r.has("with"):
		return {pts = str(r.pts), text = _t("FACE_WITH") % name_of(r.with)}
	if r.has("pair"):
		return {pts = str(r.pair), text = _t("FACE_PAIR")}
	if r.has("per_sym"):
		return {pts = str(r.per_sym), text = _t("FACE_PER_SYM")}
	if r.has("per_kind"):
		return {pts = str(r.pts), text = _t("FACE_PER") % _groups(r.per_kind, true)}
	if r.has("per_species"):
		return {pts = str(r.pts), text = _t("FACE_PER") % name_of(r.per_species)}
	if r.has("per_side"):
		return {pts = str(r.pts), text = _t("FACE_PER_SIDE") % sicon(r.per_side)}
	if r.has("full"):
		return {pts = str(r.full), text = _t("FACE_FULL")}
	if r.has("per_tree"):
		return {pts = str(r.per_tree), text = _t("FACE_PER_TREE")}
	if r.has("per_here"):
		return {pts = str(r.per_here), text = _t("FACE_PER_HERE")}
	if r.get("flat", 0) <= 0:
		return {}
	return {pts = str(r.flat), text = ""}


## 카드 위 작은 표시: [{text, tone}] tone = effect | bonus | hook
static func chips(kind: StringName) -> Array[Dictionary]:
	var d := def_of(kind)
	var out: Array[Dictionary] = []
	if not d.get("effect", {}).is_empty():
		out.append({text = gives(d.effect, true), tone = &"effect"})
	if not d.get("bonus", {}).is_empty():
		out.append({text = "★ " + gives(d.bonus, true), tone = &"bonus"})
	if d.has("hook"):
		out.append({text = "∞ " + hook(kind, true), tone = &"hook"})
	return out


## 상세 창 용어 풀이: 이 카드에 나오는 말만 [글]
static func terms(kind: StringName) -> Array[String]:
	var out: Array[String] = []
	for k in term_keys(kind):
		out.append(_t(k))
	for g in groups_in(kind):
		out.append(_t("TERM_GROUP") % [group_of(g), members(g)])
	return out


## 이 카드 점수·효과에 나오는 분류(새·발굽 등)
static func groups_in(kind: StringName) -> Array[StringName]:
	var d := def_of(kind)
	var r: Dictionary = d.get("score", {})
	var give: Dictionary = d.get("effect", {}).merged(d.get("bonus", {})).merged(d.get("hook", {}).get("give", {}))
	var groups: Array[StringName] = []
	for g in [r.get("per_kind", []), r.get("same_tree", []), give.get("free", []), give.get("free_all", []), give.get("draw_per", []), d.get("hook", {}).get("tag", [])]:
		for x in (g if g is Array else [g]):
			if not def_of(x).size() and x != &"tree" and not x in groups:
				groups.append(x)
	if r.has("distinct_at_least") and not d.kind in groups:
		groups.append(d.kind)
	return groups


## 이 카드에 나오는 용어 키(TERM_*)
static func term_keys(kind: StringName) -> Array[String]:
	var d := def_of(kind)
	var keys: Array[String] = ["TERM_COST"]
	var r: Dictionary = d.get("score", {})
	if not face(kind).is_empty():
		keys.push_front("TERM_ACORN")
	if not d.get("effect", {}).is_empty():
		keys.append("TERM_EFFECT")
	if not d.get("bonus", {}).is_empty():
		keys.append_array(["TERM_BONUS", "TERM_COLOR"])
	var give: Dictionary = d.get("effect", {}).merged(d.get("bonus", {})).merged(d.get("hook", {}).get("give", {}))
	for k in give:
		var t: String = {draw = "TERM_DECK", again = "TERM_AGAIN", free = "TERM_FREE", free_all = "TERM_FREE", more = "TERM_MORE",
			clear_to_cave = "TERM_CAVE", stash = "TERM_CAVE", boost = "TERM_BOOST", pick = "TERM_CLEARING", cave = "TERM_CAVE"}.get(k, "")
		if t != "" and not t in keys:
			keys.append(t)
	if d.has("hook"):
		keys.append("TERM_HOOK")
	if d.has("side"):
		keys.append("TERM_SIDE")
	if r.has("set"):
		keys.append("TERM_SET")
	if r.has("butterfly_sets"):
		keys.append("TERM_BUTTERFLY")
	if r.has("most"):
		keys.append("TERM_MOST")
	if r.has("full"):
		keys.append("TERM_FULL")
	if r.has("per_sym") and not "TERM_COLOR" in keys:
		keys.append("TERM_COLOR")
	return keys


## 그 상징을 가진 종들 이름("올빼미·참매 … 외 n종")
static func members(tag: StringName) -> String:
	var names: Array[String] = []
	for k in Cards.SPECIES:
		if tag in Cards.tags_of(k):
			names.append(name_of(k))
	var more := names.size() - GROUP_NAMES_SHOWN
	if more > 0:
		names.resize(GROUP_NAMES_SHOWN)
		return "·".join(names) + " " + _t("TERM_MORE_KINDS") % more
	return "·".join(names)


## 점수 표: from번째부터 "1→1 2→4" (short: "1:1 2:4")
## 장수별 점수표의 칸: [[장수, 점수]] (0점 칸은 뺀다). 카드 면은 위에 장수, 아래에 도토리 점수로 그린다.
static func cells(t: Array, from: int) -> Array:
	var out := []
	for i in range(from, t.size()):
		if t[i] > 0:
			out.append([i, t[i]])
	return out


static func _table(t: Array, from: int, short := false) -> String:
	var out: Array[String] = []
	for i in range(from, t.size()):
		out.append(("%d:%d" if short else "%d→%d") % [i, t[i]])
	return " ".join(out)


static func _names(list: Array) -> String:
	var out: Array[String] = []
	for k in list:
		out.append(name_of(k))
	return "·".join(out)


static func _groups(g: Variant, icons := false) -> String:
	var out: Array[String] = []
	for k in (g if g is Array else [g]):
		out.append(gicon(k) if icons else group_of(k))
	return ("" if icons else "·").join(out)


static func _t(key: String) -> String:
	return TranslationServer.translate(key)

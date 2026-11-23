class_name Spirits
extends RefCounted
## 숲 정령(규칙 1-3, 유물 5칸). 계절 끝 점수 = (나무·이웃 + 굴) × (1 + 정령 배수 합).
## 말: kinds + at_least + x(그 종류 이웃이 at_least마리 이상이면 +x), distinct_kind + x(그 종류 이웃 종 가짓수마다 +x),
##     wind_draw(첫 바람에 더 뽑기), ignore_winter(겨울 사건 무시), cave(굴 1장 점수)

const SLOTS := 5
const ALL := {
	&"firefly": {kinds = [&"butterfly", &"insect"], at_least = 5, x = 0.5},
	&"old_owl": {distinct_kind = &"bird", x = 0.1},
	&"wind_child": {wind_draw = 2},
	&"hibernating_bear": {ignore_winter = true},
	&"acorn_squirrel": {cave = 2},
}


static func mult(forest: Forest, owned: Array[StringName]) -> float:
	var m := 1.0
	var kinds := {}
	var species := {}
	for n in forest.neighbors():
		var k: StringName = Cards.SPECIES[n.species].kind
		kinds[k] = kinds.get(k, 0) + 1
		species[n.species] = k
	for id in owned:
		var d: Dictionary = ALL[id]
		if d.has("at_least"):
			var n := 0
			for k in d.kinds:
				n += kinds.get(k, 0)
			if n >= d.at_least:
				m += d.x
		elif d.has("distinct_kind"):
			m += d.x * species.values().count(d.distinct_kind)
	return m


static func value(owned: Array[StringName], key: String, default: Variant) -> Variant:
	for id in owned:
		if ALL[id].has(key):
			return ALL[id][key]
	return default

class_name Hook
extends RefCounted
## 지속 효과(규칙 1-2): 숲에 있는 버섯 등이 발동 지점에 건 효과. 정령·사건도 1-3부터 같은 지점에 붙는다.
## hook = {on = 발동 지점, side?, tag?, give = 효과}. 지점: place(이웃을 붙일 때), plant(나무를 심을 때).


## 숲에 걸린 hook들
static func collect(forest: Forest) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for n in forest.neighbors():
		var h: Dictionary = Cards.SPECIES[n.species].get("hook", {})
		if not h.is_empty():
			out.append(h.merged({card = n.card.id}))
	return out


## 그 사건에 맞는 hook들. ctx = {side, tags}
static func matching(hooks: Array[Dictionary], on: StringName, ctx: Dictionary) -> Array[Dictionary]:
	return hooks.filter(func(h: Dictionary) -> bool:
		return h.on == on and (not h.has("side") or h.side == ctx.get("side")) \
			and (not h.has("tag") or h.tag in ctx.get("tags", [])))

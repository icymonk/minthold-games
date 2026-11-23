class_name Reward
extends RefCounted
## 오두막 보상(규칙 1-3): 3장 중 1장 — 새 이웃 카드 2장 묶음, 숲 정령 1개, 주머니에서 카드 2장 빼기.
## 솔방울 가게: 같은 것들을 값을 내고 사고, 땅 2칸 넓히기와 카드 꾸미기(이슬·금빛 잎)도 판다.

const PRICES := {pair = 3, spirit = 6, remove = 2, land = 4, deco = 3}
const REMOVE := 2


## 새 이웃 카드 1장: 위/아래 또는 왼/오른 반쪽 둘, 나무 색은 무작위
static func new_pair(rng: RandomNumberGenerator, id: int) -> Dictionary:
	var axis: StringName = [&"v", &"h"][rng.randi_range(0, 1)]
	var halves: Array[StringName] = []
	for side in Cards.SIDES[axis]:
		var fit := Cards.SPECIES.keys().filter(func(k: StringName) -> bool: return Cards.fits(k, side))
		halves.append(fit[rng.randi_range(0, fit.size() - 1)])
	var syms := Cards.TREES.keys()
	return Cards.pair(id, halves[0], halves[1], axis, syms[rng.randi_range(0, syms.size() - 1)])


## 보상 3장: [{t = pair, cards} | {t = spirit, id} | {t = remove}]
static func roll(rng: RandomNumberGenerator, run: Run) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var free := Spirits.ALL.keys().filter(func(k: StringName) -> bool: return not run.owned().has(k))
	for kind: StringName in [&"pair", &"spirit", &"remove"]:
		if kind == &"spirit" and (free.is_empty() or run.spirits.size() >= Spirits.SLOTS):
			kind = &"pair"
		match kind:
			&"pair":
				out.append({t = &"pair", cards = [new_pair(rng, run.new_id()), new_pair(rng, run.new_id())]})
			&"spirit":
				out.append({t = &"spirit", id = free[rng.randi_range(0, free.size() - 1)]})
			&"remove":
				out.append({t = &"remove"})
	return out
